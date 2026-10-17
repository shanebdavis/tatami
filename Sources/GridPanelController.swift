import AppKit
import SwiftUI

/// Owns the grid panel lifecycle: summon on hotkey, live preview overlay
/// while painting or hovering a preset, commit on mouse-up or preset pick,
/// dismiss on Escape / click-away / second hotkey press.
@MainActor
final class GridPanelController: ObservableObject {
    static let shared = GridPanelController()

    private let baseColumns = 6
    private let baseRows = 6

    /// Transient: pressing space while the panel is open doubles the grid
    /// resolution; the panel always reopens at the base grid.
    @Published private(set) var doubled = false

    /// Transient: after "Add Preset", the next painted region is saved as a
    /// preset instead of moving the window.
    @Published private(set) var definingPreset = false

    /// Modifier keys held right now, tracked while the panel is open so
    /// the arrow-key legend can show what ⌘ and ⇧ do.
    @Published private(set) var modifiers: NSEvent.ModifierFlags = []

    private var panel: GridPanel?
    private var previewWindow: NSWindow?
    private var target: LayoutEngine.Target?
    private var modifiersMonitor: Any?

    var columns: Int { doubled ? baseColumns * 2 : baseColumns }
    var rows: Int { doubled ? baseRows * 2 : baseRows }

    func toggle() {
        if panel != nil {
            dismiss()
        } else {
            summon()
        }
    }

    func summon() {
        guard let target = LayoutEngine.focusedTarget() else { return }
        self.target = target
        doubled = false
        definingPreset = false
        modifiers = NSEvent.modifierFlags
        modifiersMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.modifiers = event.modifierFlags
            return event
        }

        let area = target.screen.visibleFrame
        let hosting = NSHostingView(rootView: GridPanelView(
            controller: self,
            appIcon: target.appIcon,
            appName: target.appName,
            screenAspect: area.width / area.height
        ))
        hosting.frame.size = hosting.fittingSize

        let panel = GridPanel(
            contentRect: NSRect(origin: .zero, size: hosting.frame.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.contentView = hosting
        panel.onKey = { [weak self] event in self?.handleKey(event) ?? false }
        panel.onEscape = { [weak self] in self?.cancel() }
        panel.onResignKey = { [weak self] in self?.dismiss() }

        panel.setFrameOrigin(NSPoint(
            x: area.midX - hosting.frame.width / 2,
            y: area.midY - hosting.frame.height / 2
        ))
        // Non-activating panel: becomes key (receives keys) without
        // activating our app, so the target app stays frontmost.
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func dismiss() {
        guard let panel else { return }
        self.panel = nil
        panel.close()
        if let modifiersMonitor {
            NSEvent.removeMonitor(modifiersMonitor)
            self.modifiersMonitor = nil
        }
        previewWindow?.close()
        previewWindow = nil
        target = nil
    }

    func toggleDefiningPreset() {
        definingPreset.toggle()
        preview(nil)
    }

    func selectionChanged(_ region: GridRegion?) {
        preview(region.map(layout))
    }

    /// Mouse-up on the grid: saves the region as a preset while defining
    /// one, otherwise moves the window there.
    func commit(_ region: GridRegion) {
        if definingPreset {
            PresetStore.shared.add(layout(region))
            toggleDefiningPreset()
        } else {
            apply(layout(region))
        }
    }

    func apply(_ preset: Preset) {
        if let target {
            WindowManager.setFrame(preset.rect(on: target.screen), of: target.window)
        }
        dismiss()
    }

    /// The region painted on the current grid, as a preset.
    private func layout(_ region: GridRegion) -> Preset {
        Preset(region: region, columns: columns, rows: rows)
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        let key = event.charactersIgnoringModifiers ?? ""
        if key == " " {
            doubled.toggle()
            preview(nil)
        } else if let preset = Preset.edge(for: event) ?? PresetStore.shared.preset(forKey: key) {
            apply(preset)
        } else {
            return false
        }
        return true
    }

    /// Escape backs out of defining a preset first, then closes the panel.
    private func cancel() {
        if definingPreset {
            toggleDefiningPreset()
        } else {
            dismiss()
        }
    }

    // MARK: - Live preview

    /// Shows where `preset` would put the window, or hides the preview.
    func preview(_ preset: Preset?) {
        guard let target, let preset else {
            previewWindow?.orderOut(nil)
            return
        }
        let window = previewWindow ?? makePreviewWindow()
        window.setFrame(preset.rect(on: target.screen), display: true)
        if let panel {
            window.order(.below, relativeTo: panel.windowNumber)
        }
    }

    private func makePreviewWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.level = .floating
        window.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.3)
        previewWindow = window
        return window
    }
}

/// Borderless panels can't become key by default; the grid panel must, so it
/// can receive keys (space, arrows, preset slots, Escape via
/// cancelOperation) and dismiss on click-away (via resignKey), all without
/// activating the app.
private final class GridPanel: NSPanel {
    /// Returns true when the key was handled.
    var onKey: ((NSEvent) -> Bool)?
    var onEscape: (() -> Void)?
    var onResignKey: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    /// ⌘-key events arrive here before keyDown.
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        onKey?(event) == true || super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if onKey?(event) == true { return }
        super.keyDown(with: event)
    }

    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }
}
