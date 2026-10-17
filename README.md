# Tatami

Keyboard-driven window layout for macOS. Press a hotkey, a grid appears over the focused window's screen, and one more keypress (or a quick drag across the grid) puts the window exactly where you want it.

Named for the Japanese mats laid out in clean grids: rooms are measured and planned in mat-grid units, and Tatami lays out your windows the same way.

## Why

Tatami started because [Divvy](https://mizage.com/divvy/) is no longer supported. Its keyboard shortcuts kept breaking, and on macOS 27 it stopped working entirely. Divvy got the idea right: summon a grid, paint where the window goes, done. Tatami keeps that idea in a native, modern Swift app and builds on it with keyboard presets.

The goal is to make window layout so fast that a single laptop screen feels like a wall of monitors: the right two or three windows side by side, rearranged every few minutes as tasks change.

## Using it

Press **⌃⌥⌘Space** (configurable in Settings) or pick **Show Grid** from the menu bar icon. The grid targets whichever window had focus.

- **Paint**: drag across the grid and the window lands on that region. **Space** toggles a finer grid (6×6 ↔ 12×12). The grid takes the screen's shape.
- **Arrows**: ← → ↑ ↓ snap to that half of the screen. Hold **⌘** for thirds, **⇧** for two thirds, **⌘⇧** for five sixths. The panel's legend shows what each arrow does with the modifiers you're holding.
- **Presets**: fourteen slots keyed `1`–`9`, `0`, `-`, `=`, `F`, `C`. Press a filled slot's key (or click it) to apply it. Click an empty slot (or press its key), then paint the grid to set it. Drag a preset onto another slot to swap them; hover to clear one. `F` (full screen) and `C` (centered) come preloaded.
- **Global shortcuts**: in Settings, any preset can get its own system-wide shortcut that applies it with no grid shown.

**Escape** or clicking elsewhere closes the grid without moving anything.

## Building

Requires macOS 15 or later and a recent Xcode.

1. Set your own signing team: change `DEVELOPMENT_TEAM` in `project.yml` and regenerate the project with [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`xcodegen generate`), or pick your team under Signing & Capabilities in Xcode.
2. Open `Tatami.xcodeproj` and run.
3. On first launch, grant Accessibility permission when prompted (System Settings → Privacy & Security → Accessibility). Tatami needs it to move other apps' windows.

Tatami lives in the menu bar with no Dock icon. The only dependency is [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts).

## License

[MIT](LICENSE)
