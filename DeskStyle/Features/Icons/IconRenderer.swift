import UIKit

enum IconPalette {
    static func hex(name: String, style: StylePreset) -> String {
        let amount = Double(AppCatalog.stableHash(name) % 100) / 100
        return mix(style.accentHex, style.secondaryHex, amount)
    }

    static func mix(_ left: String, _ right: String, _ amount: Double) -> String {
        let start = rgb(left)
        let end = rgb(right)
        let ratio = min(max(amount, 0), 1)
        let red = Int(Double(start.0) + (Double(end.0) - Double(start.0)) * ratio)
        let green = Int(Double(start.1) + (Double(end.1) - Double(start.1)) * ratio)
        let blue = Int(Double(start.2) + (Double(end.2) - Double(start.2)) * ratio)
        return String(format: "%02X%02X%02X", clamp(red), clamp(green), clamp(blue))
    }

    private static func clamp(_ value: Int) -> Int {
        min(255, max(0, value))
    }

    private static func rgb(_ hex: String) -> (Int, Int, Int) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        guard cleaned.count == 6 else { return (128, 128, 128) }
        return (Int((value >> 16) & 0xFF), Int((value >> 8) & 0xFF), Int(value & 0xFF))
    }
}

enum IconRenderer {
    static func card(name: String, style: StylePreset) -> UIImage {
        let size = CGSize(width: 512, height: 640)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            UIColor(hex: style.backgroundHex).setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let iconRect = CGRect(x: 56, y: 48, width: 400, height: 400)
            drawIcon(name: name, style: style, in: iconRect)
            drawCentered(
                name,
                in: CGRect(x: 24, y: 468, width: 464, height: 140),
                font: font(size: 54, style: style, weight: .semibold),
                color: UIColor(hex: style.textHex)
            )
        }
    }

    static func overview(names: [String], style: StylePreset) -> UIImage {
        let columns = 3
        let cell = CGSize(width: 320, height: 390)
        let padding: CGFloat = 28
        let rows = max(1, Int(ceil(Double(names.count) / Double(columns))))
        let size = CGSize(
            width: padding * 2 + cell.width * CGFloat(columns),
            height: padding * 2 + 80 + cell.height * CGFloat(rows)
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            UIColor(hex: style.backgroundHex).setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            drawCentered(
                "图标总览 · \(style.name)",
                in: CGRect(x: padding, y: 16, width: size.width - padding * 2, height: 52),
                font: font(size: 36, style: style, weight: .semibold),
                color: UIColor(hex: style.textHex)
            )
            for (index, name) in names.enumerated() {
                let column = index % columns
                let row = index / columns
                let origin = CGPoint(
                    x: padding + CGFloat(column) * cell.width,
                    y: 80 + padding + CGFloat(row) * cell.height
                )
                let iconSide: CGFloat = 220
                let iconRect = CGRect(
                    x: origin.x + (cell.width - iconSide) / 2,
                    y: origin.y,
                    width: iconSide,
                    height: iconSide
                )
                drawIcon(name: name, style: style, in: iconRect)
                drawCentered(
                    name,
                    in: CGRect(x: origin.x + 8, y: origin.y + iconSide + 12, width: cell.width - 16, height: 80),
                    font: font(size: 32, style: style, weight: .medium),
                    color: UIColor(hex: style.textHex)
                )
            }
        }
    }

    static func drawIcon(name: String, style: StylePreset, in rect: CGRect) {
        let fill = UIColor(hex: IconPalette.hex(name: name, style: style))
        let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width * CGFloat(style.iconCornerRatio))
        fill.setFill()
        path.fill()
        UIColor.black.withAlphaComponent(0.1).setStroke()
        path.lineWidth = max(1, rect.width * 0.015)
        path.stroke()
        let glyph = fill.relativeLuminance > 0.58 ? UIColor(white: 0.12, alpha: 1) : UIColor.white
        if let symbolName = AppCatalog.symbolName(for: name),
           let symbol = UIImage(
            systemName: symbolName,
            withConfiguration: UIImage.SymbolConfiguration(pointSize: rect.width * 0.42, weight: .medium)
           )?.withTintColor(glyph, renderingMode: .alwaysOriginal) {
            let symbolRect = CGRect(
                x: rect.midX - symbol.size.width / 2,
                y: rect.midY - symbol.size.height / 2,
                width: symbol.size.width,
                height: symbol.size.height
            )
            symbol.draw(in: symbolRect)
        } else {
            let initial = String(name.prefix(1))
            drawCentered(
                initial,
                in: rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.18),
                font: font(size: rect.width * 0.42, style: style, weight: .semibold),
                color: glyph
            )
        }
    }

    private static func font(size: CGFloat, style: StylePreset, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let design: UIFontDescriptor.SystemDesign
        switch style.fontDesign {
        case .rounded:
            design = .rounded
        case .serif:
            design = .serif
        case .monospaced:
            design = .monospaced
        case .standard:
            design = .default
        }
        let descriptor = base.fontDescriptor.withDesign(design) ?? base.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }

    private static func drawCentered(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let string = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
        let bounds = string.boundingRect(
            with: CGSize(width: rect.width, height: rect.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let target = CGRect(
            x: rect.minX,
            y: rect.midY - bounds.height / 2,
            width: rect.width,
            height: bounds.height
        )
        string.draw(with: target, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
}
