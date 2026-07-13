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
                ForEach($store.presets) { $preset in
                    PresetRow(preset: $preset) {
                        store.delete(preset)
                    }
                }
                Button {
                    store.add()
                } label: {
                    Label("Add Preset", systemImage: "plus")
                }
            } header: {
                Text("Presets")
            } footer: {
                Text("Each preset lays out the focused window instantly — no grid panel shown. Click the thumbnail to change its region.")
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .frame(minHeight: 320)
    }
}

/// One preset: thumbnail (click to edit region) + name + shortcut + delete.
private struct PresetRow: View {
    @Binding var preset: Preset
    let onDelete: () -> Void

    @State private var showingPicker = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                showingPicker = true
            } label: {
                GridThumbnail(preset: preset)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingPicker, arrowEdge: .trailing) {
                RegionPickerView(preset: $preset)
            }

            TextField("Name", text: $preset.name)
                .textFieldStyle(.plain)

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

/// Miniature rendering of a preset's grid + region.
private struct GridThumbnail: View {
    let preset: Preset

    var body: some View {
        Canvas { context, size in
            let cellWidth = size.width / CGFloat(preset.columns)
            let cellHeight = size.height / CGFloat(preset.rows)

            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 4),
                with: .color(.primary.opacity(0.08))
            )
            let region = preset.region
            let regionRect = CGRect(
                x: CGFloat(region.minCol) * cellWidth,
                y: CGFloat(region.minRow) * cellHeight,
                width: CGFloat(region.maxCol - region.minCol + 1) * cellWidth,
                height: CGFloat(region.maxRow - region.minRow + 1) * cellHeight
            )
            context.fill(
                Path(roundedRect: regionRect, cornerRadius: 2),
                with: .color(.accentColor.opacity(0.8))
            )
            var lines = Path()
            for col in 1..<preset.columns {
                lines.move(to: CGPoint(x: CGFloat(col) * cellWidth, y: 0))
                lines.addLine(to: CGPoint(x: CGFloat(col) * cellWidth, y: size.height))
            }
            for row in 1..<preset.rows {
                lines.move(to: CGPoint(x: 0, y: CGFloat(row) * cellHeight))
                lines.addLine(to: CGPoint(x: size.width, y: CGFloat(row) * cellHeight))
            }
            context.stroke(lines, with: .color(.primary.opacity(0.15)), lineWidth: 0.5)
        }
        .frame(width: 66, height: 55)
        .help("Click to edit this preset's region")
    }
}

/// Popover: paint the preset's region on the same grid UX as the panel.
private struct RegionPickerView: View {
    @Binding var preset: Preset

    @State private var finer: Bool

    init(preset: Binding<Preset>) {
        _preset = preset
        _finer = State(initialValue: preset.wrappedValue.columns > 6)
    }

    private var columns: Int { finer ? 12 : 6 }
    private var rows: Int { finer ? 10 : 5 }

    var body: some View {
        VStack(spacing: 12) {
            Text("Drag to set the region")
                .font(.caption)
                .foregroundStyle(.secondary)
            GridPanelView(
                columns: columns,
                rows: rows,
                cellSize: finer ? 14 : 32,
                committedRegion: preset.columns == columns && preset.rows == rows ? preset.region : nil,
                onCommit: { region in
                    preset.region = region
                    preset.columns = columns
                    preset.rows = rows
                }
            )
            Toggle("Finer grid (12×10)", isOn: $finer)
                .toggleStyle(.checkbox)
        }
        .padding(16)
    }
}
