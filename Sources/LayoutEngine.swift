import AppKit

/// Shared entry point for "lay out the focused window": used by the grid
/// panel (interactive) and by preset shortcuts (instant, no UI).
@MainActor
enum LayoutEngine {
    struct Target {
        let window: AXUIElement
        let screen: NSScreen
        let appIcon: NSImage?
        let appName: String
    }

    /// The focused window of the frontmost app plus the screen it lives on.
    /// Reports problems via HUD and returns nil when there's nothing to move.
    static func focusedTarget() -> Target? {
        guard WindowManager.hasAccessibilityPermission else {
            WindowManager.requestAccessibilityPermission()
            HUD.shared.flash("Grant Accessibility permission, then try again", for: .seconds(2))
            return nil
        }
        guard let window = WindowManager.focusedWindow(),
              let windowFrame = WindowManager.frame(of: window),
              let screen = WindowManager.screen(containing: windowFrame) ?? NSScreen.main
        else {
            HUD.shared.flash("No focused window found", for: .seconds(1.5))
            return nil
        }
        let app = NSWorkspace.shared.frontmostApplication
        return Target(
            window: window,
            screen: screen,
            appIcon: app?.icon,
            appName: app?.localizedName ?? "Window"
        )
    }

    /// Instantly applies a grid region to the focused window.
    static func apply(region: GridRegion, columns: Int, rows: Int) {
        guard let target = focusedTarget() else { return }
        WindowManager.setFrame(
            region.rect(on: target.screen, columns: columns, rows: rows),
            of: target.window
        )
    }
}
