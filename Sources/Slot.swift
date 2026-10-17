import SwiftUI

/// The tile shape shared by the preset slots and the arrow-key legend: a
/// picture shaped like the screen above a short key label.
enum Slot {
    /// Slots per row; a full row lines up with the base grid's six columns.
    static let perRow = 6
    fileprivate static let padding: CGFloat = 4
    fileprivate static let labelHeight: CGFloat = 16

    /// Size of one slot when a full row of them spans `rowWidth`.
    static func size(rowWidth: CGFloat, spacing: CGFloat, screenAspect: CGFloat) -> CGSize {
        let width = (rowWidth - CGFloat(perRow - 1) * spacing) / CGFloat(perRow)
        let pictureHeight = (width - 2 * padding) / screenAspect
        return CGSize(width: width, height: pictureHeight + labelHeight + 2 * padding)
    }
}

/// A slot's picture above its key. The picture fills whatever height the
/// label and padding leave it.
struct SlotLayout<Picture: View>: View {
    let key: String
    @ViewBuilder let picture: Picture

    var body: some View {
        VStack(spacing: 0) {
            picture
            Text(key)
                .font(.caption.monospaced().weight(.medium))
                .foregroundStyle(.secondary)
                .frame(height: Slot.labelHeight)
        }
        .padding(Slot.padding)
    }
}

extension View {
    /// The filled tile behind a slot, brighter while highlighted.
    func slotBackground(highlighted: Bool) -> some View {
        background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(highlighted ? 0.16 : 0.06))
        )
    }
}
