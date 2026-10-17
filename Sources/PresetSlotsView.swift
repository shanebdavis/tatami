import SwiftUI

/// The preset slots under the grid: two rows of six that line up with the
/// base grid's columns, keyed 1–9, 0, -, = in order. Click a preset to
/// apply it, hover to preview it and reveal its delete button, drag to
/// reorder.
struct PresetSlotsView: View {
    let slotSize: CGSize
    let spacing: CGFloat
    /// Highlights the empty slot the next added preset lands in.
    let highlightsNextSlot: Bool
    let onHover: (Preset?) -> Void
    let onApply: (Preset) -> Void

    @ObservedObject private var store = PresetStore.shared
    @State private var hoveredID: UUID?
    @State private var drag: SlotDrag?

    private struct SlotDrag {
        let id: UUID
        let startOrigin: CGPoint
        var translation: CGSize

        var origin: CGPoint {
            CGPoint(x: startOrigin.x + translation.width, y: startOrigin.y + translation.height)
        }
    }

    private let keys = PresetStore.slotKeys
    private let perRow = Slot.perRow
    private let space = NamedCoordinateSpace.named("slots")

    var body: some View {
        let presets = Array(store.presets.prefix(keys.count))
        let rowCount = (keys.count + perRow - 1) / perRow

        ZStack(alignment: .topLeading) {
            ForEach(presets.count..<keys.count, id: \.self) { slot in
                emptySlot(slot, highlighted: highlightsNextSlot && slot == presets.count)
            }
            ForEach(Array(presets.enumerated()), id: \.element.id) { slot, preset in
                tile(preset, slot: slot)
            }
        }
        .frame(
            width: CGFloat(perRow) * (slotSize.width + spacing) - spacing,
            height: CGFloat(rowCount) * (slotSize.height + spacing) - spacing,
            alignment: .topLeading
        )
        .coordinateSpace(space)
        .onChange(of: hoveredID) {
            onHover(store.presets.first { $0.id == hoveredID })
        }
    }

    private func emptySlot(_ slot: Int, highlighted: Bool) -> some View {
        let color = highlighted ? Color.accentColor : Color.primary.opacity(0.2)
        return SlotLayout(key: keys[slot]) {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(color, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
        }
        .opacity(highlighted ? 1 : 0.6)
        .frame(width: slotSize.width, height: slotSize.height)
        .offset(origin(of: slot))
    }

    private func tile(_ preset: Preset, slot: Int) -> some View {
        let isHovered = hoveredID == preset.id
        let dragOrigin = drag?.id == preset.id ? drag?.origin : nil

        return SlotLayout(key: keys[slot]) {
            PresetThumbnail(preset: preset)
        }
        .frame(width: slotSize.width, height: slotSize.height)
        .slotBackground(highlighted: isHovered)
        .shadow(radius: dragOrigin == nil ? 0 : 6)
        // Gesture before the overlay so clicks on the delete button never
        // reach it; hover after, so the button keeps the tile hovered.
        .gesture(dragGesture(for: preset))
        .overlay(alignment: .topTrailing) {
            if isHovered && drag == nil {
                Button {
                    delete(preset)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .secondary)
                }
                .buttonStyle(.plain)
                .padding(2)
            }
        }
        .onHover { hovering in
            if hovering {
                hoveredID = preset.id
            } else if hoveredID == preset.id {
                hoveredID = nil
            }
        }
        .offset(dragOrigin ?? origin(of: slot))
        .zIndex(dragOrigin == nil ? 0 : 1)
    }

    /// A click (no movement) applies the preset; a drag picks it up and
    /// reorders the list live as it passes over other slots.
    private func dragGesture(for preset: Preset) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: space)
            .onChanged { value in
                guard let slot = store.presets.firstIndex(where: { $0.id == preset.id }) else { return }
                if drag == nil {
                    guard hypot(value.translation.width, value.translation.height) > 3 else { return }
                    drag = SlotDrag(id: preset.id, startOrigin: origin(of: slot), translation: .zero)
                }
                drag?.translation = value.translation
                let target = min(self.slot(at: value.location), store.presets.count - 1)
                if target != slot {
                    withAnimation(.snappy(duration: 0.2)) { store.move(preset, to: target) }
                }
            }
            .onEnded { _ in
                if drag == nil {
                    onApply(preset)
                } else {
                    withAnimation(.snappy(duration: 0.2)) { drag = nil }
                }
            }
    }

    private func delete(_ preset: Preset) {
        hoveredID = nil
        withAnimation(.snappy(duration: 0.2)) { store.delete(preset) }
    }

    private func origin(of slot: Int) -> CGPoint {
        CGPoint(
            x: CGFloat(slot % perRow) * (slotSize.width + spacing),
            y: CGFloat(slot / perRow) * (slotSize.height + spacing)
        )
    }

    private func slot(at point: CGPoint) -> Int {
        let col = min(max(Int(point.x / (slotSize.width + spacing)), 0), perRow - 1)
        let row = min(max(Int(point.y / (slotSize.height + spacing)), 0), keys.count / perRow - 1)
        return row * perRow + col
    }
}

private extension View {
    func offset(_ point: CGPoint) -> some View {
        offset(x: point.x, y: point.y)
    }
}
