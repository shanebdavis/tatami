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
        PresetStore.shared.registerHotkeys()
    }

    var body: some Scene {
        MenuBarExtra("Tatami", systemImage: "rectangle.split.3x3") {
            MenuContent()
        }
        Settings {
            SettingsView()
        }
    }
}

private struct MenuContent: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text("Tatami v0.1 (Phase 7)")
        Button("Show Grid") {
            GridPanelController.shared.summon()
        }
        .globalKeyboardShortcut(.summonGrid)
        Button("Settings…") {
            // Accessory apps (no Dock icon) don't come forward on their own;
            // activate so the settings window isn't buried.
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")
        Divider()
        Button("Quit Tatami") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
