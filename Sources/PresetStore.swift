import Foundation
import KeyboardShortcuts

/// A saved layout: a grid region plus the grid dimensions it was defined on,
/// bound to a user-recorded global shortcut. Resolution-independent.
struct Preset: Codable, Identifiable, Equatable {
    var id = UUID()
    var name = "New Preset"
    var region = GridRegion(from: GridCell(col: 0, row: 0), to: GridCell(col: 2, row: 4))
    var columns = 6
    var rows = 5

    var shortcutName: KeyboardShortcuts.Name {
        KeyboardShortcuts.Name("preset-\(id.uuidString)")
    }
}

/// Owns the preset list: persistence (UserDefaults JSON) and global hotkey
/// registration/dispatch for every preset.
@MainActor
final class PresetStore: ObservableObject {
    static let shared = PresetStore()

    private static let defaultsKey = "presets"

    @Published var presets: [Preset] {
        didSet { save() }
    }

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

    func add() {
        let preset = Preset()
        presets.append(preset)
        register(preset)
    }

    func delete(_ preset: Preset) {
        // Clears the recorded shortcut so the hotkey stops firing and the
        // key combo is freed up for other uses.
        KeyboardShortcuts.reset(preset.shortcutName)
        presets.removeAll { $0.id == preset.id }
    }

    private func register(_ preset: Preset) {
        let id = preset.id
        KeyboardShortcuts.onKeyDown(for: preset.shortcutName) { [weak self] in
            self?.apply(id)
        }
    }

    private func apply(_ id: UUID) {
        guard let preset = presets.first(where: { $0.id == id }) else { return }
        LayoutEngine.apply(region: preset.region, columns: preset.columns, rows: preset.rows)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(presets) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
