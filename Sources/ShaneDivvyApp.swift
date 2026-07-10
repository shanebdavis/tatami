import KeyboardShortcuts
import SwiftUI

@main
struct ShaneDivvyApp: App {
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
        MenuBarExtra("Shane Divvy", systemImage: "rectangle.split.3x3") {
            Text("Shane Divvy v0.1 — Phase 3")
            Text("⌃⌥⌘Space: snap window to left half")
            Divider()
            Button("Quit Shane Divvy") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
