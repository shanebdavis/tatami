import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var store = PresetStore.shared

    private var filledSlots: [(key: String, preset: Preset)] {
        PresetStore.slotKeys.compactMap { key in store.slots[key].map { (key, $0) } }
    }

    var body: some View {
        Form {
            Section("Grid Panel") {
                KeyboardShortcuts.Recorder("Show grid panel:", name: .summonGrid)
            }
            Section {
                ForEach(filledSlots, id: \.preset.id) { key, preset in
                    PresetRow(key: key, preset: preset) {
                        store.clear(key)
                    }
                }
            } header: {
                Text("Presets")
            } footer: {
                Text("Set presets in the grid panel: click an empty slot (or press its key) and paint the region. Drag a preset onto another slot to swap them. Record a global shortcut here to apply a preset without opening the panel.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .frame(minHeight: 320)
    }
}

/// One preset: panel key + thumbnail + global shortcut + clear.
private struct PresetRow: View {
    let key: String
    let preset: Preset
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(key.uppercased())
                .font(.body.monospaced().weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            PresetThumbnail(preset: preset)
                .frame(width: 66, height: 55)

            Spacer()

            KeyboardShortcuts.Recorder(for: preset.shortcutName)

            Button(role: .destructive) {
                onClear()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}
