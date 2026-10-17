import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// The main "summon the grid panel" hotkey. User-configurable in
    /// Settings.
    static let summonGrid = Self("summonGrid", default: .init(.space, modifiers: [.control, .option, .command]))
}
