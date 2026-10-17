import AppKit

/// A cell on the layout grid. Column 0 is leftmost, row 0 is the TOP row
/// (grid coordinates read like a table, not like Cocoa).
struct GridCell: Equatable {
    var col: Int
    var row: Int
}

/// A rectangular region of grid cells, inclusive on both ends.
/// Resolution-independent: resolve to a concrete frame on any screen with
/// `rect(on:columns:rows:)`. Codable so presets can persist it.
struct GridRegion: Equatable, Codable {
    var minCol: Int
    var minRow: Int
    var maxCol: Int
    var maxRow: Int

    init(from a: GridCell, to b: GridCell) {
        minCol = min(a.col, b.col)
        maxCol = max(a.col, b.col)
        minRow = min(a.row, b.row)
        maxRow = max(a.row, b.row)
    }

    func contains(_ cell: GridCell) -> Bool {
        (minCol...maxCol).contains(cell.col) && (minRow...maxRow).contains(cell.row)
    }

    /// Frame (Cocoa coordinates) this region occupies on `screen`, dividing
    /// the screen's visible area into `columns` × `rows` cells.
    func rect(on screen: NSScreen, columns: Int, rows: Int) -> CGRect {
        let area = screen.visibleFrame
        let cellWidth = area.width / CGFloat(columns)
        let cellHeight = area.height / CGFloat(rows)
        return CGRect(
            x: area.minX + CGFloat(minCol) * cellWidth,
            y: area.maxY - CGFloat(maxRow + 1) * cellHeight,
            width: CGFloat(maxCol - minCol + 1) * cellWidth,
            height: CGFloat(maxRow - minRow + 1) * cellHeight
        )
    }
}
