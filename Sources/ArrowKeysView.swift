import SwiftUI

/// Legend for the arrow-key layouts, laid out like the keyboard's arrow
/// cluster. Each arrow shows the layout it applies with the modifiers held
/// right now; the ⌘ and ⇧ cells beside ↑ light up while held. Click an
/// arrow to apply its layout, hover to preview it.
struct ArrowKeysView: View {
    let slotSize: CGSize
    let spacing: CGFloat
    let modifiers: NSEvent.ModifierFlags
    let onHover: (Preset?) -> Void
    let onApply: (Preset) -> Void

    @State private var hovered: NSEvent.SpecialKey?

    var body: some View {
        Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            GridRow {
                modifierCell("⌘", gives: "⅓", held: modifiers.contains(.command))
                arrowCell(.upArrow, label: "↑")
                modifierCell("⇧", gives: "⅔", held: modifiers.contains(.shift))
            }
            GridRow {
                arrowCell(.leftArrow, label: "←")
                arrowCell(.downArrow, label: "↓")
                arrowCell(.rightArrow, label: "→")
            }
        }
        .onChange(of: hovered) { reportHover() }
        .onChange(of: modifiers) { reportHover() }
    }

    private func arrowCell(_ arrow: NSEvent.SpecialKey, label: String) -> some View {
        let preset = Preset.edge(arrow, modifiers: modifiers)
        return SlotLayout(key: label) {
            if let preset {
                PresetThumbnail(preset: preset)
            } else {
                Color.clear
            }
        }
        .frame(width: slotSize.width, height: slotSize.height)
        .slotBackground(highlighted: hovered == arrow)
        .contentShape(Rectangle())
        .onTapGesture {
            if let preset { onApply(preset) }
        }
        .onHover { hovering in
            if hovering {
                hovered = arrow
            } else if hovered == arrow {
                hovered = nil
            }
        }
    }

    /// A modifier key (the label) above the fraction it switches the
    /// arrows to.
    private func modifierCell(_ key: String, gives fraction: String, held: Bool) -> some View {
        SlotLayout(key: key) {
            Text(fraction)
                .font(.title2.weight(.semibold))
                .foregroundStyle(held ? Color.accentColor : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: slotSize.width, height: slotSize.height)
        .slotBackground(highlighted: held)
    }

    private func reportHover() {
        onHover(hovered.flatMap { Preset.edge($0, modifiers: modifiers) })
    }
}
