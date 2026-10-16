# Build Plan

Phased so each phase ends with something Shane runs and validates by hand before the next phase starts. The three risky integrations — menu-bar app lifecycle, global hotkey interception, and Accessibility-driven window positioning — each get their own early phase so they're validated in isolation. Everything after that is pure logic and UI.

## Phase 1: Menu bar skeleton

A buildable, runnable app that proves the project setup and app lifecycle.

- Opens in Xcode, builds with ⌘R, no configuration needed
- Appears as an icon in the menu bar (no Dock icon, no windows)
- Menu contains Quit, which works

**Validate:** build & run from Xcode; icon appears top-right; Quit exits cleanly.

## Phase 2: Global hotkey

Prove we can intercept a system-wide key combination — the thing that rotted in Divvy.

- Hardcoded hotkey (⌃⌥⌘Space to start) registered via the KeyboardShortcuts package
- Pressing it from *any* app (while our app has no focus at all) shows a visible reaction: a small floating "hotkey works!" HUD for ~1 second
- No permissions should be required for this — that's the point of the Carbon hotkey API

**Validate:** press the hotkey while in Safari, iTerm, etc.; HUD appears every time; no permission prompts.

## Phase 3: Accessibility + window positioning

Prove we can move other apps' windows — the other risky integration.

- First run: detects missing Accessibility permission, prompts, and guides to System Settings
- The Phase 2 hotkey now snaps the **focused window to the left half of its screen** (hardcoded action)
- Correct across multiple monitors and with the Dock/menu bar/notch (uses visible frame)

**Validate:** grant permission once; hotkey snaps iTerm, Safari, Finder, an Electron app (e.g. Slack/VS Code) to the left half; try on both the MacBook screen and an external display.

## Phase 4: Grid panel (the core UX)

The Divvy experience: hotkey summons a grid, paint a region, window moves there.

- Hotkey opens a floating grid panel (6×5) centered on the screen containing the focused window
- Panel shows the focused app's icon and name
- Click-drag paints a cell region with a live translucent preview of the target frame
- Mouse-up moves/resizes the window and dismisses; Escape cancels
- Panel never steals focus from the target window

**Validate:** full daily-driver loop — summon, paint, window lands exactly on the painted region; Escape cancels; repeat rapid-fire.

## Phase 5: Grid doubling + multi-monitor polish

- `Space` while the panel is open toggles 6×5 ↔ 12×10 (always reopens at base size)
- Panel appears on the correct screen in all monitor arrangements
- Stubborn-app handling (set-size → set-position → set-size retry)

**Validate:** doubling toggle feels right; correct behavior on external display above/beside the MacBook.

## Phase 6: Preset layout shortcuts + settings

- Settings window (opened from menu bar): list of presets, each with a shortcut recorder and a grid-region picker (same grid UX in "define region" mode)
- Pressing a preset's shortcut instantly lays out the focused window — no UI shown
- Summon hotkey is user-configurable; presets persist across launches
- Shortcut conflicts surfaced in the UI

**Validate:** define "left ⅔", "right ⅓", "full screen" presets; hammer them all day; restart the app and they survive.

## Phase 7: Presets in the grid panel

Presets move into the panel, so every common layout is one keypress after the summon hotkey.

- Two rows of six preset thumbnails under the grid, keyed `1`–`9`, `0`, `-`, `=`
- **Add Preset** button: paint a region on the grid to save it to the next free slot
- Click a thumbnail or press its key to apply; drag to reorder; hover for a live preview and a delete ×
- Arrow keys apply built-in halves: top, bottom, left, right
- Base grid becomes 6×6 (12×12 doubled)
- Settings keeps the summon hotkey plus optional per-preset global shortcuts

**Validate:** add "left ⅔", "right ⅓", "full screen" from the panel; apply each by key and by click; drag to reorder and confirm the keys follow; delete one; each arrow key lands the window on the matching half; restart the app and the presets survive.

## Phase 8: Polish & daily-driver hardening

- Launch at login toggle
- Base grid dimensions configurable
- Permission onboarding flow refined (first-run experience)
- App icon, animations, edge cases found during real use

**Validate:** a week of real use replaces Divvy entirely.
