import AppKit

extension Preset {
    /// The modifiers that pick the arrow keys' fraction; others are ignored.
    static let edgeModifiers: NSEvent.ModifierFlags = [.command, .shift]

    /// The built-in layout `event` applies in the grid panel, if it's an
    /// arrow key. See `edge(_:modifiers:)`.
    static func edge(for event: NSEvent) -> Preset? {
        event.specialKey.flatMap { edge($0, modifiers: event.modifierFlags) }
    }

    /// The built-in layout an arrow key applies: the half (no modifier),
    /// third (⌘), two thirds (⇧), or five sixths (⌘⇧) of the screen on the
    /// arrow's side. Other modifiers are ignored. Nil for non-arrow keys.
    static func edge(_ arrow: NSEvent.SpecialKey, modifiers: NSEvent.ModifierFlags) -> Preset? {
        let share: Int, parts: Int
        switch modifiers.intersection(edgeModifiers) {
        case []: (share, parts) = (1, 2)
        case .command: (share, parts) = (1, 3)
        case .shift: (share, parts) = (2, 3)
        default: (share, parts) = (5, 6)
        }
        let leading = 0...(share - 1)
        let trailing = (parts - share)...(parts - 1)
        switch arrow {
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
