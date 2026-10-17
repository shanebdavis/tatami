import AppKit
import SwiftUI

/// A transient floating message panel for status and errors (e.g. missing
/// permission). Does not activate the app or steal focus.
@MainActor
final class HUD {
    static let shared = HUD()

    private var panel: NSPanel?
    private var hideTask: Task<Void, Never>?

    func flash(_ message: String, for duration: Duration = .seconds(1)) {
        hideTask?.cancel()
        panel?.close()

        let view = NSHostingView(rootView: HUDView(message: message))
        view.frame.size = view.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: view.frame.size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.contentView = view

        if let screen = NSScreen.main {
            let frame = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(
                x: frame.midX - view.frame.width / 2,
                y: frame.midY - view.frame.height / 2
            ))
        }
        panel.orderFrontRegardless()
        self.panel = panel

        hideTask = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            self.panel?.close()
            self.panel = nil
        }
    }
}

private struct HUDView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.title2.weight(.semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
