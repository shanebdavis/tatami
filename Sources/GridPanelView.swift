import SwiftUI

/// Contents of the floating grid panel: the target app's header, the grid
/// the user paints a region onto, the number-row preset slots, and a footer
/// with the arrow-key legend, the F and C slots, and a hint. Reports
/// everything to the controller.
struct GridPanelView: View {
    @ObservedObject var controller: GridPanelController
    let appIcon: NSImage?
    let appName: String
    /// Width over height of the target screen's visible area. The grid
    /// takes this shape, so its cells match the screen's proportions.
    let screenAspect: CGFloat

    @ObservedObject private var store = PresetStore.shared
    @StateObject private var drag = SlotDrag()
    @State private var startCell: GridCell?
    @State private var currentCell: GridCell?

    /// Fixed grid width: six 52pt cells with 6pt gaps. Cells shrink to fit
    /// when the grid doubles.
    private let gridWidth: CGFloat = 342
    private let cellSpacing: CGFloat = 6

    private var gridHeight: CGFloat { gridWidth / screenAspect }
    private var columns: Int { controller.columns }
    private var rows: Int { controller.rows }

    private var cellSize: CGSize {
        CGSize(
            width: (gridWidth - CGFloat(columns - 1) * cellSpacing) / CGFloat(columns),
            height: (gridHeight - CGFloat(rows - 1) * cellSpacing) / CGFloat(rows)
        )
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
            numberSlots
            footer
        }
        .overlay(alignment: .topLeading) { draggedTile }
        .coordinateSpace(SlotDrag.space)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 18).fill(.regularMaterial))
    }

    private var slotSize: CGSize {
        Slot.size(rowWidth: gridWidth, spacing: cellSpacing, screenAspect: screenAspect)
    }

    private var numberSlots: some View {
        let keys = PresetStore.numberKeys
        return Grid(horizontalSpacing: cellSpacing, verticalSpacing: cellSpacing) {
            ForEach(Array(stride(from: 0, to: keys.count, by: Slot.perRow)), id: \.self) { start in
                GridRow {
                    ForEach(keys[start..<start + Slot.perRow], id: \.self) { slot($0) }
                }
            }
        }
    }

    /// Row 1: ⌘ ⅓, ↑, ⇧ ⅔, ⌘⇧ ⅚, then the F and C slots.
    /// Row 2: ←, ↓, →, then the hint across the last three columns.
    private var footer: some View {
        Grid(horizontalSpacing: cellSpacing, verticalSpacing: cellSpacing) {
            GridRow {
                modifierCell("⌘", "⅓", .command)
                arrowCell(.upArrow, "↑")
                modifierCell("⇧", "⅔", .shift)
                modifierCell("⌘⇧", "⅚", [.command, .shift])
                ForEach(PresetStore.letterKeys, id: \.self) { slot($0) }
            }
            GridRow {
                arrowCell(.leftArrow, "←")
                arrowCell(.downArrow, "↓")
                arrowCell(.rightArrow, "→")
                hint.gridCellColumns(3)
            }
        }
    }

    private var hint: some View {
        let defining = controller.definingSlot
        return Text(defining.map { "Drag on the grid to set \($0.uppercased())\nesc: cancel" } ?? "space: finer grid")
            .font(.caption)
            .foregroundStyle(defining == nil ? .secondary : Color.accentColor)
            .multilineTextAlignment(.trailing)
            .frame(width: 3 * slotSize.width + 2 * cellSpacing, alignment: .trailing)
    }

    /// The preset being dragged, following the cursor above everything.
    @ViewBuilder private var draggedTile: some View {
        if let key = drag.key, let preset = store.slots[key] {
            PresetSlotView.tile(key, preset, highlighted: true)
                .frame(width: slotSize.width, height: slotSize.height)
                .shadow(radius: 6)
                .offset(x: drag.tileOrigin.x, y: drag.tileOrigin.y)
                .allowsHitTesting(false)
        }
    }

    private func slot(_ key: String) -> some View {
        PresetSlotView(key: key, slotSize: slotSize, controller: controller, drag: drag)
    }

    private func arrowCell(_ arrow: NSEvent.SpecialKey, _ label: String) -> some View {
        ArrowKeyCell(arrow: arrow, label: label, slotSize: slotSize, controller: controller)
    }

    private func modifierCell(_ label: String, _ fraction: String, _ modifiers: NSEvent.ModifierFlags) -> some View {
        ModifierCell(label: label, fraction: fraction, modifiers: modifiers, slotSize: slotSize, controller: controller)
    }

    private var grid: some View {
        VStack(spacing: cellSpacing) {
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
                            .frame(width: cellSize.width, height: cellSize.height)
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
                        startCell = cell(at: drag.startLocation)
                    }
                    currentCell = cell(at: drag.location)
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
    private func cell(at point: CGPoint) -> GridCell {
        let x = min(max(point.x, 0), gridWidth - 1)
        let y = min(max(point.y, 0), gridHeight - 1)
        let col = min(Int(x / (cellSize.width + cellSpacing)), columns - 1)
        let row = min(Int(y / (cellSize.height + cellSpacing)), rows - 1)
        return GridCell(col: col, row: row)
    }
}
