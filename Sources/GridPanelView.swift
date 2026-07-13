import SwiftUI

/// The grid the user paints a selection onto. Pure view: reports selection
/// changes and the final committed region via callbacks. Used both as the
/// floating layout panel (with app header + hint) and as the region picker
/// in Settings (bare grid showing the saved region).
struct GridPanelView: View {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    var appIcon: NSImage? = nil
    var appName: String? = nil
    var hint: String? = nil
    /// Shown highlighted when no drag is in progress (picker mode).
    var committedRegion: GridRegion? = nil
    var onSelectionChanged: (GridRegion?) -> Void = { _ in }
    let onCommit: (GridRegion) -> Void

    @State private var startCell: GridCell?
    @State private var currentCell: GridCell?

    private let cellSpacing: CGFloat = 6

    private var selection: GridRegion? {
        guard let startCell, let currentCell else { return nil }
        return GridRegion(from: startCell, to: currentCell)
    }

    private var highlightedRegion: GridRegion? {
        selection ?? committedRegion
    }

    var body: some View {
        VStack(spacing: 14) {
            if let appName {
                HStack(spacing: 10) {
                    if let appIcon {
                        Image(nsImage: appIcon)
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                    Text(appName)
                        .font(.title3.weight(.semibold))
                }
            }
            grid
            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(appName == nil ? 0 : 24)
        .background {
            if appName != nil {
                RoundedRectangle(cornerRadius: 18).fill(.regularMaterial)
            }
        }
    }

    private var grid: some View {
        let gridWidth = CGFloat(columns) * (cellSize + cellSpacing) - cellSpacing
        let gridHeight = CGFloat(rows) * (cellSize + cellSpacing) - cellSpacing

        return VStack(spacing: cellSpacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<columns, id: \.self) { col in
                        let cell = GridCell(col: col, row: row)
                        let isSelected = highlightedRegion?.contains(cell) ?? false
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
                        startCell = cell(at: drag.startLocation, gridWidth: gridWidth, gridHeight: gridHeight)
                    }
                    currentCell = cell(at: drag.location, gridWidth: gridWidth, gridHeight: gridHeight)
                    onSelectionChanged(selection)
                }
                .onEnded { _ in
                    if let selection { onCommit(selection) }
                    startCell = nil
                    currentCell = nil
                }
        )
    }

    /// Maps a point in grid-local coordinates to a cell, clamped to the grid
    /// so drags that wander outside still track the nearest edge cell.
    private func cell(at point: CGPoint, gridWidth: CGFloat, gridHeight: CGFloat) -> GridCell {
        let x = min(max(point.x, 0), gridWidth - 1)
        let y = min(max(point.y, 0), gridHeight - 1)
        let col = min(Int(x / (cellSize + cellSpacing)), columns - 1)
        let row = min(Int(y / (cellSize + cellSpacing)), rows - 1)
        return GridCell(col: col, row: row)
    }
}
