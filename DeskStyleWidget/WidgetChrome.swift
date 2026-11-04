import SwiftUI
import WidgetKit

struct WidgetBackdrop: View {
    let preset: StylePreset

    var body: some View {
        LinearGradient(
            colors: [preset.backgroundColor, preset.secondaryColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

enum ZHFormat {
    static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    static func monthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    static func weekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    static func yearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: date)
    }
}

enum ZHCalendar {
    static var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.locale = Locale(identifier: "zh_CN")
        value.firstWeekday = 2
        return value
    }

    static func monthCells(for date: Date) -> [Int?] {
        let calendar = calendar
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let range = calendar.range(of: .day, in: .month, for: start) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: start)
        let leading = (weekday + 5) % 7
        var cells: [Int?] = Array(repeating: nil, count: leading)
        cells.append(contentsOf: range.map { Optional($0) })
        while cells.count % 7 != 0 {
            cells.append(nil)
        }
        return cells
    }

    static func dayNumber(_ date: Date) -> Int {
        calendar.component(.day, from: date)
    }
}
