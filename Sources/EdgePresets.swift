import AppKit

extension Preset {
    /// The built-in layout an arrow key applies in the grid panel: the half
    /// (no modifier), third (⌘), or two thirds (⇧) of the screen on the
    /// arrow's side. Nil for any other key or modifier combination.
    static func edge(for event: NSEvent) -> Preset? {
        let share: Int, parts: Int
        switch event.modifierFlags.intersection([.shift, .control, .option, .command]) {
        case []: (share, parts) = (1, 2)
        case .command: (share, parts) = (1, 3)
        case .shift: (share, parts) = (2, 3)
        default: return nil
        }
        let leading = 0...(share - 1)
        let trailing = (parts - share)...(parts - 1)
        switch event.specialKey {
        case .leftArrow: return band(leading, of: parts, vertical: false)
        case .rightArrow: return band(trailing, of: parts, vertical: false)
        case .upArrow: return band(leading, of: parts, vertical: true)
        case .downArrow: return band(trailing, of: parts, vertical: true)
        default: return nil
        }
    }

    /// A full-height column band or full-width row band spanning `cells`
    /// of `parts` equal divisions.
    private static func band(_ cells: ClosedRange<Int>, of parts: Int, vertical: Bool) -> Preset {
        let (first, last) = (cells.lowerBound, cells.upperBound)
        return vertical
            ? Preset(region: GridRegion(from: GridCell(col: 0, row: first), to: GridCell(col: 0, row: last)), columns: 1, rows: parts)
            : Preset(region: GridRegion(from: GridCell(col: first, row: 0), to: GridCell(col: last, row: 0)), columns: parts, rows: 1)
    }
}
