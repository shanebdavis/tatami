import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var store = PresetStore.shared

    var body: some View {
        Form {
            Section("Grid Panel") {
                KeyboardShortcuts.Recorder("Show grid panel:", name: .summonGrid)
            }
            Section {
                ForEach(Array(zip(PresetStore.slotKeys, store.presets)), id: \.1.id) { key, preset in
                    PresetRow(key: key, preset: preset) {
                        store.delete(preset)
                    }
                }
            } header: {
                Text("Presets")
            } footer: {
                Text("Add, reorder, and delete presets in the grid panel, where each preset's key applies it. Record a global shortcut here to apply a preset without opening the panel.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .frame(minHeight: 320)
    }
}

/// One preset: panel key + thumbnail + global shortcut + delete.
private struct PresetRow: View {
    let key: String
    let preset: Preset
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.body.monospaced().weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            PresetThumbnail(preset: preset)
                .frame(width: 66, height: 55)

            Spacer()

            KeyboardShortcuts.Recorder(for: preset.shortcutName)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}
