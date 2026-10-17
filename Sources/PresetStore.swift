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

/// Owns the preset slots: one optional preset per grid panel key,
/// persistence (UserDefaults JSON), and global hotkey registration/dispatch.
@MainActor
final class PresetStore: ObservableObject {
    static let shared = PresetStore()

    /// Slot keys along the number row, shown as two rows of six.
    static let numberKeys = "1234567890-=".map(String.init)
    /// Slot keys shown in the panel footer: F and C.
    static let letterKeys = ["f", "c"]
    static let slotKeys = numberKeys + letterKeys

    /// Fresh installs start with F filling the screen and C centering the
    /// window one grid unit in from each edge of the 6×6 grid.
    private static let defaultSlots = [
        "f": Preset(region: GridRegion(from: GridCell(col: 0, row: 0), to: GridCell(col: 5, row: 5)), columns: 6, rows: 6),
        "c": Preset(region: GridRegion(from: GridCell(col: 1, row: 1), to: GridCell(col: 4, row: 4)), columns: 6, rows: 6),
    ]

    private static let defaultsKey = "presetSlots"

    /// Presets by slot key. Empty slots have no entry.
    @Published private(set) var slots: [String: Preset] {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([String: Preset].self, from: data) {
            slots = decoded
        } else {
            slots = Self.defaultSlots
        }
    }

    /// Call once at launch: hooks up handlers for all saved presets.
    func registerHotkeys() {
        for preset in slots.values {
            register(preset)
        }
    }

    func set(_ preset: Preset, for key: String) {
        clear(key)
        slots[key] = preset
        register(preset)
    }

    func clear(_ key: String) {
        guard let preset = slots[key] else { return }
        // Clears the recorded shortcut so the hotkey stops firing and the
        // key combo is freed up for other uses.
        KeyboardShortcuts.reset(preset.shortcutName)
        slots[key] = nil
    }

    /// Swaps the contents of two slots, either of which may be empty.
    func swap(_ a: String, _ b: String) {
        var swapped = slots
        swapped[a] = slots[b]
        swapped[b] = slots[a]
        slots = swapped
    }

    private func register(_ preset: Preset) {
        let id = preset.id
        KeyboardShortcuts.onKeyDown(for: preset.shortcutName) { [weak self] in
            if let preset = self?.slots.values.first(where: { $0.id == id }) {
                LayoutEngine.apply(preset)
            }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
