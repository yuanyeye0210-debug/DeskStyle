import SwiftUI
import WidgetKit

struct CountdownEntry: TimelineEntry {
    let date: Date
    let style: WidgetStyleChoice
    let title: String
    let targetDate: Date?
}

struct CountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, style: .sunset, title: "纪念日", targetDate: nil)
    }

    func snapshot(for configuration: CountdownWidgetIntent, in context: Context) async -> CountdownEntry {
        CountdownEntry(date: .now, style: configuration.style, title: configuration.eventTitle, targetDate: configuration.targetDate)
    }

    func timeline(for configuration: CountdownWidgetIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let now = Date()
        let entries = (0..<24).compactMap { hour -> CountdownEntry? in
            guard let date = Calendar.current.date(byAdding: .hour, value: hour, to: now) else { return nil }
            return CountdownEntry(date: date, style: configuration.style, title: configuration.eventTitle, targetDate: configuration.targetDate)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "deskstyle.countdown", intent: CountdownWidgetIntent.self, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("倒数日")
        .description("编辑小组件里填写标题和日期。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    private var preset: StylePreset { entry.style.preset }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.title.isEmpty ? "倒数日" : entry.title)
                .font(.headline)
                .lineLimit(1)
            if let target = entry.targetDate {
                Text(headline(from: entry.date, to: target))
                    .font(.system(size: family == .systemSmall ? 28 : 40, weight: .semibold, design: preset.fontDesign.swiftUI))
                    .foregroundStyle(preset.accentColor)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if family != .systemSmall {
                    Text(ZHFormat.fullDate(target))
                        .font(.subheadline)
                }
            } else {
                Text("未设置日期")
                    .font(.title3)
                if family != .systemSmall {
                    Text("长按小组件，点编辑小组件，选择日期。")
                        .font(.caption)
                        .opacity(0.75)
                }
            }
            if family == .systemLarge {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .foregroundStyle(preset.textColor)
        .containerBackground(for: .widget) {
            WidgetBackdrop(preset: preset)
        }
    }

    private func headline(from date: Date, to target: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: target)
        let days = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        if days > 0 {
            return "还有 \(days) 天"
        }
        if days == 0 {
            return "就是今天"
        }
        return "已经 \(-days) 天"
    }
}
