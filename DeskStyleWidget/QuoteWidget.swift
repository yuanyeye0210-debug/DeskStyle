import SwiftUI
import WidgetKit

struct QuoteLine {
    let text: String
    let author: String
}

enum QuoteLibrary {
    static let lines: [QuoteLine] = [
        QuoteLine(text: "把常用的留下，把吵的收起来。", author: "桌面美化"),
        QuoteLine(text: "留白是为了让重要的事情被看见。", author: "桌面美化"),
        QuoteLine(text: "颜色靠近的放在一行，眼睛会轻一点。", author: "桌面美化"),
        QuoteLine(text: "主屏幕是每天的第一眼。", author: "桌面美化"),
        QuoteLine(text: "少放一个图标，就多一块安静。", author: "桌面美化"),
        QuoteLine(text: "先摆整齐，再决定要不要更漂亮。", author: "桌面美化"),
        QuoteLine(text: "今天只留下真正会打开的。", author: "桌面美化"),
        QuoteLine(text: "文件夹不是藏起来，是分好类。", author: "桌面美化"),
        QuoteLine(text: "壁纸淡一点，图标才站得住。", author: "桌面美化"),
        QuoteLine(text: "程序坞只放每天都要碰到的。", author: "桌面美化"),
        QuoteLine(text: "慢慢排，比一次排满更耐久。", author: "桌面美化"),
        QuoteLine(text: "桌面干净的时候，开始一件小事。", author: "桌面美化")
    ]

    static func line(for date: Date) -> QuoteLine {
        let day = Calendar(identifier: .gregorian).ordinality(of: .day, in: .year, for: date) ?? 1
        return lines[(day - 1) % lines.count]
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let style: WidgetStyleChoice
    let line: QuoteLine
}

struct QuoteProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: .now, style: .cute, line: QuoteLibrary.lines[0])
    }

    func snapshot(for configuration: QuoteWidgetIntent, in context: Context) async -> QuoteEntry {
        QuoteEntry(date: .now, style: configuration.style, line: QuoteLibrary.line(for: .now))
    }

    func timeline(for configuration: QuoteWidgetIntent, in context: Context) async -> Timeline<QuoteEntry> {
        let now = Date()
        let line = QuoteLibrary.line(for: now)
        let next = ZHCalendar.calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(24 * 3600)
        let entry = QuoteEntry(date: now, style: configuration.style, line: line)
        return Timeline(entries: [entry], policy: .after(next))
    }
}

struct QuoteWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "deskstyle.quote", intent: QuoteWidgetIntent.self, provider: QuoteProvider()) { entry in
            QuoteWidgetView(entry: entry)
        }
        .configurationDisplayName("一句话")
        .description("每天换一句短句。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct QuoteWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: QuoteEntry

    private var preset: StylePreset { entry.style.preset }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.line.text)
                .font(.system(family == .systemSmall ? .subheadline : .title3, design: preset.fontDesign.swiftUI))
                .minimumScaleFactor(0.7)
                .lineLimit(family == .systemSmall ? 4 : 6)
            Spacer(minLength: 0)
            Text(entry.line.author)
                .font(.caption)
                .opacity(0.7)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(preset.textColor)
        .containerBackground(for: .widget) {
            WidgetBackdrop(preset: preset)
        }
    }
}
