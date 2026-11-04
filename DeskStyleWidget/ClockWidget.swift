import SwiftUI
import WidgetKit

struct ClockEntry: TimelineEntry {
    let date: Date
    let style: WidgetStyleChoice
}

struct ClockProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: .now, style: .minimal)
    }

    func snapshot(for configuration: ClockWidgetIntent, in context: Context) async -> ClockEntry {
        ClockEntry(date: .now, style: configuration.style)
    }

    func timeline(for configuration: ClockWidgetIntent, in context: Context) async -> Timeline<ClockEntry> {
        let now = Date()
        let entries = (0..<60).compactMap { minute -> ClockEntry? in
            guard let date = Calendar.current.date(byAdding: .minute, value: minute, to: now) else { return nil }
            return ClockEntry(date: date, style: configuration.style)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct ClockWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "deskstyle.clock", intent: ClockWidgetIntent.self, provider: ClockProvider()) { entry in
            ClockWidgetView(entry: entry)
        }
        .configurationDisplayName("时钟")
        .description("显示当前时间。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ClockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ClockEntry

    private var preset: StylePreset { entry.style.preset }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(ZHFormat.time(entry.date))
                .font(family == .systemSmall ? .system(size: 36, weight: .semibold, design: preset.fontDesign.swiftUI) : .system(size: 54, weight: .semibold, design: preset.fontDesign.swiftUI))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
            if family != .systemSmall {
                Text("\(ZHFormat.monthDay(entry.date)) \(ZHFormat.weekday(entry.date))")
                    .font(.title3)
            }
            if family == .systemLarge {
                Spacer()
                Text(preset.name)
                    .font(.footnote)
                    .opacity(0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: family == .systemSmall ? .center : .leading)
        .foregroundStyle(preset.textColor)
        .containerBackground(for: .widget) {
            WidgetBackdrop(preset: preset)
        }
    }
}
