import KeyboardShortcuts
import SwiftUI

@main
struct TatamiApp: App {
    init() {
        // Trigger the system permission prompt on first launch rather than
        // surprising the user on first hotkey press.
        if !WindowManager.hasAccessibilityPermission {
            WindowManager.requestAccessibilityPermission()
        }
        KeyboardShortcuts.onKeyDown(for: .summonGrid) {
            LayoutActions.snapFocusedWindowToLeftHalf()
        }
    }

    var body: some Scene {
        MenuBarExtra("Tatami", systemImage: "rectangle.split.3x3") {
            Text("Tatami v0.1 — Phase 3")
            Text("⌃⌥⌘Space: snap window to left half")
            Divider()
            Button("Quit Tatami") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
