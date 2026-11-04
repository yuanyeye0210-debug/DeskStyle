import CoreImage
import UIKit

enum WallpaperMode: String, CaseIterable, Identifiable {
    case solid
    case gradient
    case blur

    var id: String { rawValue }

    var title: String {
        switch self {
        case .solid:
            return "纯色"
        case .gradient:
            return "渐变"
        case .blur:
            return "模糊照片"
        }
    }
}

enum WallpaperRenderer {
    static func render(
        style: StylePreset,
        mode: WallpaperMode,
        photo: UIImage?,
        reserveWidgetSpace: Bool,
        pointSize: CGSize,
        scale: CGFloat
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: pointSize, format: format)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: pointSize)
            switch mode {
            case .solid:
                UIColor(hex: style.backgroundHex).setFill()
                context.fill(rect)
            case .gradient:
                drawGradient(style, in: rect, context: context.cgContext)
            case .blur:
                if let photo {
                    let filled = aspectFill(photo, pointSize: pointSize, scale: scale)
                    let blurred = gaussianBlur(filled, radius: max(pointSize.width, pointSize.height) * 0.05) ?? filled
                    blurred.draw(in: rect)
                } else {
                    drawGradient(style, in: rect, context: context.cgContext)
                }
            }
            guard reserveWidgetSpace else { return }
            let panel = CGRect(
                x: pointSize.width * 0.06,
                y: pointSize.height * 0.11,
                width: pointSize.width * 0.88,
                height: pointSize.height * 0.30
            )
            let path = UIBezierPath(roundedRect: panel, cornerRadius: min(36, pointSize.width * 0.07))
            let dark = UIColor(hex: style.backgroundHex).relativeLuminance < 0.4
            UIColor(white: dark ? 1 : 0, alpha: 0.12).setFill()
            path.fill()
        }
    }

    private static func drawGradient(_ style: StylePreset, in rect: CGRect, context: CGContext) {
        let space = CGColorSpaceCreateDeviceRGB()
        let colors = [
            UIColor(hex: style.backgroundHex).cgColor,
            UIColor(hex: style.secondaryHex).cgColor,
            UIColor(hex: style.backgroundHex).cgColor
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.62, 1]) {
            context.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: rect.maxX, y: rect.maxY),
                options: []
            )
        }
        let blob = [
            UIColor(hex: style.accentHex).withAlphaComponent(0.5).cgColor,
            UIColor(hex: style.accentHex).withAlphaComponent(0).cgColor
        ] as CFArray
        guard let radial = CGGradient(colorsSpace: space, colors: blob, locations: [0, 1]) else { return }
        let center = CGPoint(x: rect.width * 0.82, y: rect.height * 0.14)
        context.drawRadialGradient(
            radial,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: rect.width * 0.58,
            options: []
        )
    }

    private static func aspectFill(_ image: UIImage, pointSize: CGSize, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: pointSize, format: format)
        return renderer.image { _ in
            let scaleFactor = max(pointSize.width / max(image.size.width, 1), pointSize.height / max(image.size.height, 1))
            let drawSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
            let origin = CGPoint(x: (pointSize.width - drawSize.width) / 2, y: (pointSize.height - drawSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }

    private static func gaussianBlur(_ image: UIImage, radius: CGFloat) -> UIImage? {
        guard let source = CIImage(image: image) else { return nil }
        guard let filter = CIFilter(name: "CIGaussianBlur") else { return nil }
        filter.setValue(source, forKey: kCIInputImageKey)
        filter.setValue(radius * image.scale, forKey: kCIInputRadiusKey)
        guard let output = filter.outputImage?.cropped(to: source.extent) else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
}
