import AppKit
import SwiftUI

/// Owns the grid panel lifecycle: summon on hotkey, live preview overlay
/// while painting, commit on mouse-up, dismiss on Escape / click-away /
/// second hotkey press.
@MainActor
final class GridPanelController {
    static let shared = GridPanelController()

    let columns = 6
    let rows = 5
    private let baseCellSize: CGFloat = 52
    private let cellSpacing: CGFloat = 6

    /// Transient: pressing space while the panel is open doubles the grid
    /// resolution; the panel always reopens at the base grid.
    private var doubled = false

    private var panel: GridPanel?
    private var hosting: NSHostingView<GridPanelView>?
    private var previewWindow: NSWindow?
    private var target: (window: AXUIElement, screen: NSScreen)?

    private var effectiveColumns: Int { doubled ? columns * 2 : columns }
    private var effectiveRows: Int { doubled ? rows * 2 : rows }

    /// Cell size that keeps the grid footprint identical in both modes.
    private var effectiveCellSize: CGFloat {
        guard doubled else { return baseCellSize }
        let gridWidth = CGFloat(columns) * (baseCellSize + cellSpacing) - cellSpacing
        return (gridWidth - CGFloat(2 * columns - 1) * cellSpacing) / CGFloat(2 * columns)
    }

    func toggle() {
        if panel != nil {
            dismiss()
        } else {
            summon()
        }
    }

    func summon() {
        guard WindowManager.hasAccessibilityPermission else {
            WindowManager.requestAccessibilityPermission()
            HUD.shared.flash("Grant Accessibility permission, then try again", for: .seconds(2))
            return
        }
        guard let window = WindowManager.focusedWindow(),
              let windowFrame = WindowManager.frame(of: window),
              let screen = WindowManager.screen(containing: windowFrame) ?? NSScreen.main
        else {
            HUD.shared.flash("No focused window found", for: .seconds(1.5))
            return
        }

        let app = NSWorkspace.shared.frontmostApplication
        target = (window, screen)
        doubled = false

        let hosting = NSHostingView(rootView: makeView(
            appIcon: app?.icon,
            appName: app?.localizedName ?? "Window"
        ))
        hosting.frame.size = hosting.fittingSize
        self.hosting = hosting

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
        panel.onCancel = { [weak self] in self?.dismiss() }
        panel.onToggleDouble = { [weak self] in self?.toggleDouble() }

        let area = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(
            x: area.midX - hosting.frame.width / 2,
            y: area.midY - hosting.frame.height / 2
        ))
        // Non-activating panel: becomes key (receives Escape) without
        // activating our app, so the target app stays frontmost.
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func dismiss() {
        guard let panel else { return }
        self.panel = nil
        panel.close()
        hosting = nil
        previewWindow?.close()
        previewWindow = nil
        target = nil
    }

    private func makeView(appIcon: NSImage?, appName: String) -> GridPanelView {
        GridPanelView(
            columns: effectiveColumns,
            rows: effectiveRows,
            cellSize: effectiveCellSize,
            appIcon: appIcon,
            appName: appName,
            onSelectionChanged: { [weak self] region in self?.updatePreview(region) },
            onCommit: { [weak self] region in self?.commit(region) }
        )
    }

    private func toggleDouble() {
        guard let hosting else { return }
        doubled.toggle()
        let old = hosting.rootView
        hosting.rootView = makeView(appIcon: old.appIcon, appName: old.appName)
        updatePreview(nil)
    }

    private func commit(_ region: GridRegion) {
        if let target {
            WindowManager.setFrame(
                region.rect(on: target.screen, columns: effectiveColumns, rows: effectiveRows),
                of: target.window
            )
        }
        dismiss()
    }

    // MARK: - Live preview

    private func updatePreview(_ region: GridRegion?) {
        guard let target else { return }
        guard let region else {
            previewWindow?.orderOut(nil)
            return
        }
        let rect = region.rect(on: target.screen, columns: effectiveColumns, rows: effectiveRows)
        let window = previewWindow ?? makePreviewWindow()
        window.setFrame(rect, display: true)
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
/// can receive Escape (via cancelOperation) and dismiss on click-away (via
/// resignKey) — all without activating the app.
private final class GridPanel: NSPanel {
    var onCancel: (() -> Void)?
    var onToggleDouble: (() -> Void)?

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == " " {
            onToggleDouble?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func resignKey() {
        super.resignKey()
        onCancel?()
    }
}
