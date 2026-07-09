import SwiftUI

@main
struct ShaneDivvyApp: App {
    var body: some Scene {
        MenuBarExtra("Shane Divvy", systemImage: "rectangle.split.3x3") {
            Text("Shane Divvy v0.1 — Phase 1")
            Divider()
            Button("Quit Shane Divvy") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
