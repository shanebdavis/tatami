import AppKit
import KeyboardShortcuts

/// A saved layout: a grid region plus the grid dimensions it was defined on.
/// Resolution-independent: resolves to a frame on whatever screen it's
/// applied to.
struct Preset: Codable, Identifiable, Equatable {
    var id = UUID()
    var region: GridRegion
    var columns: Int
    var rows: Int

    /// Optional global shortcut that applies the preset with no panel shown.
    var shortcutName: KeyboardShortcuts.Name {
        KeyboardShortcuts.Name("preset-\(id.uuidString)")
    }

    func rect(on screen: NSScreen) -> CGRect {
        region.rect(on: screen, columns: columns, rows: rows)
    }
}

/// Owns the ordered preset list: persistence (UserDefaults JSON), the slot
/// keys that apply presets from the grid panel, and global hotkey
/// registration/dispatch.
@MainActor
final class PresetStore: ObservableObject {
    static let shared = PresetStore()

    /// Grid panel keys in slot order. Their count caps the preset list.
    static let slotKeys = "1234567890-=".map(String.init)

    /// Built-in halves the grid panel applies with the arrow keys: one cell
    /// of a 1×2 or 2×1 grid.
    private static let arrowPresets = [
        arrowKey(.upArrow): half(col: 0, row: 0, columns: 1, rows: 2),
        arrowKey(.downArrow): half(col: 0, row: 1, columns: 1, rows: 2),
        arrowKey(.leftArrow): half(col: 0, row: 0, columns: 2, rows: 1),
        arrowKey(.rightArrow): half(col: 1, row: 0, columns: 2, rows: 1),
    ]

    private static let defaultsKey = "presets"

    @Published private(set) var presets: [Preset] {
        didSet { save() }
    }

    var isFull: Bool { presets.count >= Self.slotKeys.count }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([Preset].self, from: data) {
            presets = decoded
        } else {
            presets = []
        }
    }

    /// Call once at launch: hooks up handlers for all saved presets.
    func registerHotkeys() {
        for preset in presets {
            register(preset)
        }
    }

    func add(_ preset: Preset) {
        guard !isFull else { return }
        presets.append(preset)
        register(preset)
    }

    func delete(_ preset: Preset) {
        // Clears the recorded shortcut so the hotkey stops firing and the
        // key combo is freed up for other uses.
        KeyboardShortcuts.reset(preset.shortcutName)
        presets.removeAll { $0.id == preset.id }
    }

    /// Moves `preset` to slot `index`, shifting the presets in between.
    func move(_ preset: Preset, to index: Int) {
        guard let from = presets.firstIndex(where: { $0.id == preset.id }), from != index else { return }
        var reordered = presets
        reordered.insert(reordered.remove(at: from), at: index)
        presets = reordered
    }

    /// The preset `key` applies in the grid panel: a built-in half for the
    /// arrow keys, otherwise the preset in that key's slot, if filled.
    func preset(forKey key: String) -> Preset? {
        if let half = Self.arrowPresets[key] { return half }
        guard let slot = Self.slotKeys.firstIndex(of: key), slot < presets.count else { return nil }
        return presets[slot]
    }

    private static func arrowKey(_ key: NSEvent.SpecialKey) -> String {
        String(key.unicodeScalar)
    }

    private static func half(col: Int, row: Int, columns: Int, rows: Int) -> Preset {
        let cell = GridCell(col: col, row: row)
        return Preset(region: GridRegion(from: cell, to: cell), columns: columns, rows: rows)
    }

    private func register(_ preset: Preset) {
        let id = preset.id
        KeyboardShortcuts.onKeyDown(for: preset.shortcutName) { [weak self] in
            if let preset = self?.presets.first(where: { $0.id == id }) {
                LayoutEngine.apply(preset)
            }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
