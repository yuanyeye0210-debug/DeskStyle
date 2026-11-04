import SwiftUI
import WidgetKit

struct CalendarEntry: TimelineEntry {
    let date: Date
    let style: WidgetStyleChoice
}

struct CalendarProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CalendarEntry {
        CalendarEntry(date: .now, style: .morandi)
    }

    func snapshot(for configuration: CalendarWidgetIntent, in context: Context) async -> CalendarEntry {
        CalendarEntry(date: .now, style: configuration.style)
    }

    func timeline(for configuration: CalendarWidgetIntent, in context: Context) async -> Timeline<CalendarEntry> {
        let now = Date()
        let next = ZHCalendar.calendar.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(6 * 3600)
        return Timeline(entries: [CalendarEntry(date: now, style: configuration.style)], policy: .after(next))
    }
}

struct CalendarWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "deskstyle.calendar", intent: CalendarWidgetIntent.self, provider: CalendarProvider()) { entry in
            CalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("日历")
        .description("显示日期，大号会画出本月。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CalendarWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CalendarEntry

    private var preset: StylePreset { entry.style.preset }

    var body: some View {
        Group {
            if family == .systemLarge {
                month(preset)
            } else if family == .systemMedium {
                medium(preset)
            } else {
                small(preset)
            }
        }
        .foregroundStyle(preset.textColor)
        .containerBackground(for: .widget) {
            WidgetBackdrop(preset: preset)
        }
    }

    private func small(_ preset: StylePreset) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ZHFormat.weekday(entry.date))
                .font(.caption)
            Text("\(ZHCalendar.dayNumber(entry.date))")
                .font(.system(size: 48, weight: .semibold, design: preset.fontDesign.swiftUI))
                .minimumScaleFactor(0.6)
            Text(ZHFormat.monthDay(entry.date))
                .font(.footnote)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func medium(_ preset: StylePreset) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(ZHFormat.weekday(entry.date))
                    .font(.headline)
                Text(ZHFormat.fullDate(entry.date))
                    .font(.subheadline)
            }
            Spacer()
            Text("\(ZHCalendar.dayNumber(entry.date))")
                .font(.system(size: 56, weight: .semibold, design: preset.fontDesign.swiftUI))
                .foregroundStyle(preset.accentColor)
        }
    }

    private func month(_ preset: StylePreset) -> some View {
        let cells = ZHCalendar.monthCells(for: entry.date)
        let today = ZHCalendar.dayNumber(entry.date)
        let symbols = ["一", "二", "三", "四", "五", "六", "日"]
        let rows = max(cells.count / 7, 0)
        return VStack(alignment: .leading, spacing: 6) {
            Text(ZHFormat.yearMonth(entry.date))
                .font(.headline)
            HStack {
                ForEach(symbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .opacity(0.65)
                }
            }
            ForEach(0..<rows, id: \.self) { row in
                HStack {
                    ForEach(0..<7, id: \.self) { column in
                        dayCell(cells[row * 7 + column], today: today, preset: preset)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Int?, today: Int, preset: StylePreset) -> some View {
        Text(day.map(String.init) ?? "")
            .font(.caption)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .background {
                if day == today {
                    Circle().fill(preset.accentColor.opacity(0.85))
                }
            }
            .foregroundStyle(day == today ? Color.white : preset.textColor)
    }
}
