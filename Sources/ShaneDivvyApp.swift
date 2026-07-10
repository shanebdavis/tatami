import KeyboardShortcuts
import SwiftUI

@main
struct ShaneDivvyApp: App {
    init() {
        KeyboardShortcuts.onKeyDown(for: .summonGrid) {
            HUD.shared.flash("⌃⌥⌘Space — hotkey works!")
        }
    }

    var body: some Scene {
        MenuBarExtra("Shane Divvy", systemImage: "rectangle.split.3x3") {
            Text("Shane Divvy v0.1 — Phase 2")
            Text("Hotkey: ⌃⌥⌘Space")
            Divider()
            Button("Quit Shane Divvy") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
