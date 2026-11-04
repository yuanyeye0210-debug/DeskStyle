import SwiftUI

enum FontDesignToken: String, Codable, Hashable {
    case standard
    case rounded
    case serif
    case monospaced

    var swiftUI: Font.Design {
        switch self {
        case .standard:
            return .default
        case .rounded:
            return .rounded
        case .serif:
            return .serif
        case .monospaced:
            return .monospaced
        }
    }
}

enum WallpaperSuggestion: String, Codable, Hashable {
    case solid
    case gradient
    case blur
}

struct StylePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let backgroundHex: String
    let secondaryHex: String
    let accentHex: String
    let textHex: String
    let fontDesign: FontDesignToken
    let iconCornerRatio: Double
    let wallpaper: WallpaperSuggestion

    var backgroundColor: Color { Color(hex: backgroundHex) }
    var secondaryColor: Color { Color(hex: secondaryHex) }
    var accentColor: Color { Color(hex: accentHex) }
    var textColor: Color { Color(hex: textHex) }

    var font: Font {
        .system(.body, design: fontDesign.swiftUI)
    }

    static let defaultID = "minimal"

    static func preset(id: String) -> StylePreset {
        presets.first { $0.id == id } ?? presets[0]
    }

    static let presets: [StylePreset] = [
        StylePreset(
            id: "minimal",
            name: "极简",
            summary: "大留白、细字、低对比。适合把主屏幕收成一张安静的清单。",
            backgroundHex: "F4F1EB",
            secondaryHex: "FFFFFF",
            accentHex: "1C1C1E",
            textHex: "1C1C1E",
            fontDesign: .standard,
            iconCornerRatio: 0.22,
            wallpaper: .solid
        ),
        StylePreset(
            id: "dark",
            name: "暗黑",
            summary: "深色底和一点冷色光。适合晚上，也适合把彩色图标压下去。",
            backgroundHex: "101114",
            secondaryHex: "1E2430",
            accentHex: "8EB4FF",
            textHex: "F3F5F8",
            fontDesign: .standard,
            iconCornerRatio: 0.22,
            wallpaper: .gradient
        ),
        StylePreset(
            id: "morandi",
            name: "莫兰迪",
            summary: "灰调的驼、米和雾蓝。图标靠得很近时也不会互相吵。",
            backgroundHex: "E6DDD2",
            secondaryHex: "CDBFB0",
            accentHex: "8C7464",
            textHex: "3C342E",
            fontDesign: .serif,
            iconCornerRatio: 0.26,
            wallpaper: .gradient
        ),
        StylePreset(
            id: "cute",
            name: "可爱风",
            summary: "粉米色和圆角。适合用首字母图标换掉原来的品牌色块。",
            backgroundHex: "FFF1F4",
            secondaryHex: "FFD6E0",
            accentHex: "E9899D",
            textHex: "5C3140",
            fontDesign: .rounded,
            iconCornerRatio: 0.34,
            wallpaper: .gradient
        ),
        StylePreset(
            id: "ocean",
            name: "海洋",
            summary: "薄雾蓝和深青。壁纸可以是纯色，也可以拿一张照片做模糊底。",
            backgroundHex: "E5F3F6",
            secondaryHex: "B7D8E2",
            accentHex: "1F6F8B",
            textHex: "12343D",
            fontDesign: .standard,
            iconCornerRatio: 0.24,
            wallpaper: .blur
        ),
        StylePreset(
            id: "sunset",
            name: "暖阳",
            summary: "杏子色和焦糖色。倒数日、日历用这套会比较暖。",
            backgroundHex: "F8E6D4",
            secondaryHex: "F3C39A",
            accentHex: "D76B32",
            textHex: "4A2A16",
            fontDesign: .serif,
            iconCornerRatio: 0.24,
            wallpaper: .gradient
        )
    ]
}
