# Tatami — Requirements

**Tatami** — named for the Japanese mats laid out in clean grids; rooms are literally measured and planned in mat-grid units. This app lays your windows out the same way.

## Why

**Make laying out windows so fast and easy that working on a single MacBook screen feels like having a wall of large monitors in front of you.**

The screen is a limited window onto everything you're working with. The way to reclaim that flexibility is to get exactly the right windows in front of you at the moment you need them — often two or three side by side in a clean layout so you can see and compare all the information a task requires, simultaneously.

This is not a once-a-day setup chore. It's a rapid-fire, repeated action performed every 5–15 minutes, all workday long, as tasks shift. That drives the guiding principle:

> **Fast, easy window layout, over and over again** — get the right information on screen the instant it's needed, with near-zero friction and near-zero thought.

[Divvy](https://mizage.com/divvy/) solved this well: summon a grid with a hotkey, paint the region where the focused window should go, done. But Divvy is unmaintained Intel-era code and its OS-level keyboard shortcuts no longer work reliably. This app replicates Divvy's solution in a modern, working, native form — taking cues from Divvy initially, with room to go beyond it later.

## Goals

- **A native macOS app, written in Swift** — no Electron, no cross-platform framework, no web tech
- Instant, keyboard-driven window layout on a configurable grid
- Fast enough to invoke dozens of times a day without friction
- Feels native and current: Apple Silicon, modern macOS APIs
- Zero ceremony: lives as a menu bar icon, no Dock icon, no windows unless summoned
- Trivial to build in Xcode and drop into `/Applications`

## Non-Goals

- Public distribution or the Mac App Store — this is for personal use and possibly the team; open-sourcing later is an option, publishing is not the goal (Accessibility permission precludes sandboxing anyway)
- Window management beyond grid placement (no tiling automation, no window tracking, no drag-to-edge snapping)
- Mouse-first workflows; the mouse works in the grid panel, but keyboard is the primary interface

## Core Features

### F1. Global hotkey → grid panel

A single user-configurable global hotkey summons the **grid panel**, targeting whichever window currently has focus.

- The panel appears on the screen containing the focused window
- The panel displays the focused app's icon and name (as Divvy does), so it is unambiguous which window will move
- The panel shows an N×M grid of cells (default 6×6, configurable), shaped like the screen's visible area so each cell has the screen's proportions
- **Click-drag** across cells selects a rectangular region; on mouse-up, the focused window is moved/resized to that region and the panel dismisses
- While dragging, a translucent live preview shows the target frame on the actual screen behind the panel
- **Escape** or clicking outside the grid dismisses the panel without acting
- The panel must not steal focus from the target window (non-activating panel), so the "focused window" remains well-defined

### F2. Grid doubling

While the grid panel is open, a toggle (keypress, e.g. `space`) doubles the grid resolution in both dimensions (6×6 → 12×12) for finer placement. Toggling again returns to the base grid. The doubled state is transient — the panel always opens at the base grid size.

### F3. Preset layouts

Up to twelve **saved grid regions**, kept in the grid panel so each common layout is one keypress after the summon hotkey.

- A saved layout is a grid region (e.g. "columns 1–3 of 6, all 6 rows"), **not** absolute pixels. Layouts are resolution-independent and apply correctly on any monitor
- The panel shows presets under the grid as two rows of six thumbnails, lined up with the grid's six columns. Each thumbnail shows its region
- Slots are keyed `1`–`9`, `0`, `-`, `=` in order. With the panel open, pressing a slot's key or clicking its thumbnail moves the window and dismisses the panel
- **Add Preset** at the bottom of the panel puts the grid in define mode: the next painted region is saved to the next free slot instead of moving the window. Escape backs out of define mode
- Dragging a thumbnail reorders the presets, which renumbers their keys. Hovering one previews its region on screen and reveals an × to delete it
- Built in: with the panel open, the arrow keys apply the top, bottom, left, and right halves of the screen
- A preset can optionally get its own global shortcut (F4) that applies it instantly with no UI shown

### F4. Configuration window

Opened from the menu bar icon. Contains:

- **Presets list**: one row per preset in slot order, with its panel key, a thumbnail of its region, an optional global shortcut recorder, and a delete button. Adding and reordering happen in the panel (F3)
- **General settings** — the summon hotkey (F1), base grid dimensions (rows × columns), launch at login

### F5. Menu bar presence

- Status item in the menu bar; no Dock icon (`LSUIElement`)
- Menu: open grid panel, open settings, launch-at-login toggle, quit

## Functional Requirements

- **FR1** Window placement uses the target screen's *visible frame* (excludes menu bar, Dock, notch inset)
- **FR2** Multi-monitor: grid math is per-screen; the target screen is the one containing the focused window
- **FR3** Coordinate conversion between Accessibility (top-left origin) and AppKit (bottom-left origin) must be correct across all monitor arrangements
- **FR4** Apps that clamp or resist resizing (Electron apps, fixed-min-size windows) get the set-size → set-position → set-size retry dance; failures are silent but non-destructive
- **FR5** First launch detects missing Accessibility permission and walks the user to System Settings (`AXIsProcessTrustedWithOptions` with prompt); all features degrade gracefully until granted
- **FR6** Presets and settings persist across launches (Codable structs in `UserDefaults`; no database)
- **FR7** Shortcut conflicts (two presets, or a preset vs. the summon key) are prevented or clearly surfaced in the config UI

## Technical Requirements

- **Language/UI:** Swift 6, SwiftUI where practical (`MenuBarExtra`, settings window), AppKit for the overlay panel (`NSPanel`, non-activating, borderless)
- **Window control:** Accessibility API (`AXUIElement` — `AXFocusedWindow`, `AXPosition`, `AXSize`). No private APIs
- **Hotkeys:** Carbon `RegisterEventHotKey` via the [`KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts) SPM package (also provides the recorder UI control). No Input Monitoring permission required
- **Target:** macOS 15+, Apple Silicon native (universal binary optional)
- **Dependencies:** `KeyboardShortcuts` only
- **Distribution:** build in Xcode, copy the `.app` to `/Applications`. Local signing is fine for personal use; ad-hoc or Developer ID signing only if shared with the team. Not sandboxed, not notarized, no update mechanism

## Architecture Sketch

| Module | Responsibility | Est. size |
|---|---|---|
| `WindowManager` | AX wrapper: focused window, set frame, coordinate conversion | ~150 lines |
| `GridPanel` | Overlay panel: grid render, drag-select, double toggle, preset slots, preview, dismiss | ~450 lines |
| `ShortcutStore` | Codable presets, hotkey registration/dispatch | ~100 lines |
| `SettingsView` | Config window: summon hotkey, presets list with recorder controls | ~100 lines |
| `App` | `MenuBarExtra` glue, permission onboarding, launch at login | ~50 lines |

## Milestones

1. **Spike** — one hardcoded hotkey snaps the focused window to the left half of its screen. Validates permissions, AX, and coordinate math end to end
2. **MVP** — grid panel with drag-select placement (F1)
3. **Full grid UX** — double toggle, app icon/name, multi-monitor correctness (F2, FR1–FR3)
4. **Presets**: saved layouts in the grid panel, optional global shortcuts, config UI (F3, F4)
5. **Polish** — permission onboarding, launch at login, stubborn-app retries, animations (F5, FR4, FR5)

## Open Questions

- Should a second press of the summon hotkey while the panel is open dismiss it? (Assumed: yes)
