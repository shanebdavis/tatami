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
            GridPanelController.shared.toggle()
        }
    }

    var body: some Scene {
        MenuBarExtra("Tatami", systemImage: "rectangle.split.3x3") {
            Text("Tatami v0.1 — Phase 4")
            Text("⌃⌥⌘Space: lay out focused window")
            Divider()
            Button("Quit Tatami") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
