import AppKit

/// Phase 3's hardcoded action: snap the focused window to the left half of
/// its screen. Replaced by the grid panel in Phase 4.
@MainActor
enum LayoutActions {
    static func snapFocusedWindowToLeftHalf() {
        guard WindowManager.hasAccessibilityPermission else {
            WindowManager.requestAccessibilityPermission()
            HUD.shared.flash("Grant Accessibility permission, then try again", for: .seconds(2))
            return
        }
        guard let window = WindowManager.focusedWindow(),
              let windowFrame = WindowManager.frame(of: window)
        else {
            HUD.shared.flash("No focused window found", for: .seconds(1.5))
            return
        }
        guard let screen = WindowManager.screen(containing: windowFrame) ?? NSScreen.main else {
            return
        }

        var target = screen.visibleFrame
        target.size.width /= 2
        WindowManager.setFrame(target, of: window)
    }
}
