import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// The main "summon the grid panel" hotkey. Hardcoded default for now;
    /// becomes user-configurable in Phase 6.
    static let summonGrid = Self("summonGrid", default: .init(.space, modifiers: [.control, .option, .command]))
}
