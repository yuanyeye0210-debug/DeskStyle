import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red: Double
        let green: Double
        let blue: Double
        if cleaned.count == 6 {
            red = Double((value >> 16) & 0xFF) / 255
            green = Double((value >> 8) & 0xFF) / 255
            blue = Double(value & 0xFF) / 255
        } else {
            red = 0.5
            green = 0.5
            blue = 0.5
        }
        self.init(red: red, green: green, blue: blue)
    }
}

enum ColorMath {
    static func hue(of hex: String) -> Double {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        guard cleaned.count == 6 else { return 0 }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        let maxChannel = max(red, green, blue)
        let minChannel = min(red, green, blue)
        let delta = maxChannel - minChannel
        guard delta > 0.08 else { return 400 }
        let hue: Double
        if maxChannel == red {
            hue = 60 * ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        } else if maxChannel == green {
            hue = 60 * (((blue - red) / delta) + 2)
        } else {
            hue = 60 * (((red - green) / delta) + 4)
        }
        return hue < 0 ? hue + 360 : hue
    }

    static func bucketName(for hex: String) -> String {
        let hue = hue(of: hex)
        switch hue {
        case 0..<15, 345..<360:
            return "红色系"
        case 15..<45:
            return "橙色系"
        case 45..<70:
            return "黄色系"
        case 70..<170:
            return "绿色系"
        case 170..<200:
            return "青色系"
        case 200..<255:
            return "蓝色系"
        case 255..<345:
            return "紫色系"
        default:
            return "中性色"
        }
    }
}
