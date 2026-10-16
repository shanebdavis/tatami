import SwiftUI

/// Miniature rendering of a preset's grid with its region filled in. Fills
/// whatever frame it's given.
struct PresetThumbnail: View {
    let preset: Preset

    var body: some View {
        Canvas { context, size in
            let cellWidth = size.width / CGFloat(preset.columns)
            let cellHeight = size.height / CGFloat(preset.rows)

            context.fill(
                Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 4),
                with: .color(.primary.opacity(0.08))
            )
            let region = preset.region
            let regionRect = CGRect(
                x: CGFloat(region.minCol) * cellWidth,
                y: CGFloat(region.minRow) * cellHeight,
                width: CGFloat(region.maxCol - region.minCol + 1) * cellWidth,
                height: CGFloat(region.maxRow - region.minRow + 1) * cellHeight
            )
            context.fill(
                Path(roundedRect: regionRect, cornerRadius: 2),
                with: .color(.accentColor.opacity(0.8))
            )
            var lines = Path()
            for col in 1..<preset.columns {
                lines.move(to: CGPoint(x: CGFloat(col) * cellWidth, y: 0))
                lines.addLine(to: CGPoint(x: CGFloat(col) * cellWidth, y: size.height))
            }
            for row in 1..<preset.rows {
                lines.move(to: CGPoint(x: 0, y: CGFloat(row) * cellHeight))
                lines.addLine(to: CGPoint(x: size.width, y: CGFloat(row) * cellHeight))
            }
            context.stroke(lines, with: .color(.primary.opacity(0.15)), lineWidth: 0.5)
        }
    }
}
