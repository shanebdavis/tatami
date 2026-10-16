import SwiftUI

/// Contents of the floating grid panel: the target app's header, the grid
/// the user paints a region onto, the preset slots, and a footer with the
/// "Add Preset" button. Reports everything to the controller.
struct GridPanelView: View {
    @ObservedObject var controller: GridPanelController
    let appIcon: NSImage?
    let appName: String

    @ObservedObject private var store = PresetStore.shared
    @State private var startCell: GridCell?
    @State private var currentCell: GridCell?

    /// Fixed grid footprint: six 52pt cells with 6pt gaps. Cells shrink to
    /// fit when the grid doubles.
    private let gridWidth: CGFloat = 342
    private let cellSpacing: CGFloat = 6

    private var columns: Int { controller.columns }
    private var rows: Int { controller.rows }

    private var cellSize: CGFloat {
        (gridWidth - CGFloat(columns - 1) * cellSpacing) / CGFloat(columns)
    }

    private var selection: GridRegion? {
        guard let startCell, let currentCell else { return nil }
        return GridRegion(from: startCell, to: currentCell)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                if let appIcon {
                    Image(nsImage: appIcon)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                Text(appName)
                    .font(.title3.weight(.semibold))
            }
            grid
            PresetSlotsView(
                width: gridWidth,
                spacing: cellSpacing,
                highlightsNextSlot: controller.definingPreset,
                onHover: controller.preview,
                onApply: controller.apply
            )
            footer
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 18).fill(.regularMaterial))
    }

    private var footer: some View {
        let defining = controller.definingPreset
        return HStack {
            Text(defining ? "Drag on the grid to define the preset" : "space: finer grid")
                .font(.caption)
                .foregroundStyle(defining ? Color.accentColor : .secondary)
            Spacer()
            Button(defining ? "Cancel" : "Add Preset", systemImage: defining ? "xmark" : "plus") {
                controller.toggleDefiningPreset()
            }
            .controlSize(.small)
            .disabled(!defining && store.isFull)
        }
        .frame(width: gridWidth)
    }

    private var grid: some View {
        let gridHeight = CGFloat(rows) * (cellSize + cellSpacing) - cellSpacing

        return VStack(spacing: cellSpacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        let isSelected = selection?.contains(GridCell(col: col, row: row)) ?? false
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected ? Color.accentColor.opacity(0.75) : Color.primary.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(Color.primary.opacity(0.25), lineWidth: 1)
                            )
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .frame(width: gridWidth, height: gridHeight)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    if startCell == nil {
                        startCell = cell(at: drag.startLocation, gridHeight: gridHeight)
                    }
                    currentCell = cell(at: drag.location, gridHeight: gridHeight)
                    controller.selectionChanged(selection)
                }
                .onEnded { _ in
                    if let selection { controller.commit(selection) }
                    startCell = nil
                    currentCell = nil
                }
        )
    }

    /// Maps a point in grid-local coordinates to a cell, clamped to the grid
    /// so drags that wander outside still track the nearest edge cell.
    private func cell(at point: CGPoint, gridHeight: CGFloat) -> GridCell {
        let x = min(max(point.x, 0), gridWidth - 1)
        let y = min(max(point.y, 0), gridHeight - 1)
        let col = min(Int(x / (cellSize + cellSpacing)), columns - 1)
        let row = min(Int(y / (cellSize + cellSpacing)), rows - 1)
        return GridCell(col: col, row: row)
    }
}
