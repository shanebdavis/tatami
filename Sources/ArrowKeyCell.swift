import SwiftUI

/// One arrow key in the panel's legend: a thumbnail of the layout it
/// applies with the modifiers held right now. Click to apply, hover to
/// preview.
struct ArrowKeyCell: View {
    let arrow: NSEvent.SpecialKey
    let label: String
    let slotSize: CGSize
    @ObservedObject var controller: GridPanelController

    @State private var isHovered = false

    private var preset: Preset? { Preset.edge(arrow, modifiers: controller.modifiers) }

    var body: some View {
        SlotLayout(key: label) {
            if let preset {
                PresetThumbnail(preset: preset)
            } else {
                Color.clear
            }
        }
        .frame(width: slotSize.width, height: slotSize.height)
        .slotBackground(highlighted: isHovered)
        .contentShape(Rectangle())
        .onTapGesture {
            if let preset { controller.apply(preset) }
        }
        .onHover { isHovered = $0 }
        .onChange(of: isHovered) { controller.preview(isHovered ? preset : nil) }
        .onChange(of: controller.modifiers) {
            if isHovered { controller.preview(preset) }
        }
    }
}

/// A modifier combination (the label) above the fraction it switches the
/// arrow keys to; lit while exactly that combination is held.
struct ModifierCell: View {
    let label: String
    let fraction: String
    let modifiers: NSEvent.ModifierFlags
    let slotSize: CGSize
    @ObservedObject var controller: GridPanelController

    private var held: Bool {
        controller.modifiers.intersection(Preset.edgeModifiers) == modifiers
    }

    var body: some View {
        SlotLayout(key: label) {
            Text(fraction)
                .font(.title2.weight(.semibold))
                .foregroundStyle(held ? Color.accentColor : .secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: slotSize.width, height: slotSize.height)
        .slotBackground(highlighted: held)
    }
}
