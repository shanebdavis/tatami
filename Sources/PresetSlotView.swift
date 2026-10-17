import SwiftUI

/// One preset slot, labeled with the key that activates it. Filled: click
/// or press the key to apply, hover to preview and reveal a clear button,
/// drag onto another slot to swap. Empty: click or press the key, then
/// paint on the grid to define it.
struct PresetSlotView: View {
    let key: String
    let slotSize: CGSize
    @ObservedObject var controller: GridPanelController
    @ObservedObject var drag: SlotDrag

    @ObservedObject private var store = PresetStore.shared
    @State private var isHovered = false

    private var preset: Preset? { store.slots[key] }

    var body: some View {
        content
            .frame(width: slotSize.width, height: slotSize.height)
            .contentShape(Rectangle())
            .overlay {
                if drag.key != nil && drag.targetKey == key {
                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
            // Gesture before the clear button's overlay so clicks on the
            // button never reach it; hover after, so the button keeps the
            // slot hovered.
            .gesture(gesture)
            .overlay(alignment: .topTrailing) {
                if preset != nil && isHovered && drag.key == nil {
                    clearButton
                }
            }
            .onHover { isHovered = $0 }
            .onChange(of: isHovered) { controller.preview(isHovered ? preset : nil) }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: SlotDrag.space) } action: { drag.frames[key] = $0 }
            .opacity(drag.key == key ? 0.3 : 1)
    }

    /// A filled slot's look, shared with the dragged tile the panel draws.
    static func tile(_ key: String, _ preset: Preset, highlighted: Bool) -> some View {
        SlotLayout(key: key.uppercased()) {
            PresetThumbnail(preset: preset)
        }
        .slotBackground(highlighted: highlighted)
    }

    @ViewBuilder private var content: some View {
        if let preset {
            Self.tile(key, preset, highlighted: isHovered)
        } else {
            let defining = controller.definingSlot == key
            let color = defining ? Color.accentColor : Color.primary.opacity(isHovered ? 0.5 : 0.2)
            SlotLayout(key: key.uppercased()) {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(color, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    .overlay {
                        if defining || isHovered {
                            Image(systemName: "plus").foregroundStyle(color)
                        }
                    }
            }
            .opacity(defining || isHovered ? 1 : 0.6)
        }
    }

    private var clearButton: some View {
        Button {
            controller.preview(nil)
            withAnimation(.snappy(duration: 0.2)) { store.clear(key) }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .secondary)
        }
        .buttonStyle(.plain)
        .padding(2)
    }

    /// A click (no movement) activates the slot; dragging a filled slot
    /// picks its preset up to drop on another slot.
    private var gesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: SlotDrag.space)
            .onChanged { value in
                guard preset != nil else { return }
                if drag.key == nil, hypot(value.translation.width, value.translation.height) <= 3 { return }
                drag.move(key, from: value.startLocation, to: value.location)
            }
            .onEnded { _ in
                if drag.key == key {
                    withAnimation(.snappy(duration: 0.2)) { drag.drop() }
                } else {
                    controller.activate(key)
                }
            }
    }
}

/// Drag-to-swap state shared by every preset slot in the panel, so a preset
/// can be dropped on any other slot. Slots register their frames in the
/// panel's coordinate space; the panel draws the dragged tile.
@MainActor
final class SlotDrag: ObservableObject {
    nonisolated static var space: NamedCoordinateSpace { .named("panel") }

    /// The slot being dragged, if any.
    @Published private(set) var key: String?
    @Published private(set) var location = CGPoint.zero
    private var grabOffset = CGSize.zero
    var frames: [String: CGRect] = [:]

    /// Top-left of the dragged tile as it follows the cursor.
    var tileOrigin: CGPoint {
        CGPoint(x: location.x - grabOffset.width, y: location.y - grabOffset.height)
    }

    /// The slot under the cursor, other than the one being dragged.
    var targetKey: String? {
        frames.first { $0.key != key && $0.value.contains(location) }?.key
    }

    func move(_ key: String, from start: CGPoint, to location: CGPoint) {
        if self.key == nil, let frame = frames[key] {
            grabOffset = CGSize(width: start.x - frame.minX, height: start.y - frame.minY)
        }
        self.key = key
        self.location = location
    }

    func drop() {
        if let key, let targetKey {
            PresetStore.shared.swap(key, targetKey)
        }
        key = nil
    }
}
