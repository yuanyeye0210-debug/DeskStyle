import SwiftUI
import WidgetKit

struct PhotoEntry: TimelineEntry {
    let date: Date
    let style: WidgetStyleChoice
    let sample: PhotoSample
}

struct PhotoProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PhotoEntry {
        PhotoEntry(date: .now, style: .ocean, sample: .landscape)
    }

    func snapshot(for configuration: PhotoWidgetIntent, in context: Context) async -> PhotoEntry {
        PhotoEntry(date: .now, style: configuration.style, sample: configuration.sample)
    }

    func timeline(for configuration: PhotoWidgetIntent, in context: Context) async -> Timeline<PhotoEntry> {
        let entry = PhotoEntry(date: .now, style: configuration.style, sample: configuration.sample)
        return Timeline(entries: [entry], policy: .never)
    }
}

struct PhotoWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "deskstyle.photo", intent: PhotoWidgetIntent.self, provider: PhotoProvider()) { entry in
            PhotoWidgetView(entry: entry)
        }
        .configurationDisplayName("照片")
        .description("内置画面。不能读取主 App 或相册，因为免费 Apple ID 没有 App Groups。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct PhotoWidgetView: View {
    let entry: PhotoEntry

    private var preset: StylePreset { entry.style.preset }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            artwork(preset)
            Text(entry.sample.title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.black.opacity(0.25), in: Capsule())
                .foregroundStyle(.white)
                .padding(8)
        }
        .containerBackground(for: .widget) {
            WidgetBackdrop(preset: preset)
        }
    }

    private func artwork(_ preset: StylePreset) -> some View {
        ZStack {
            LinearGradient(
                colors: [preset.secondaryColor, preset.backgroundColor],
                startPoint: .top,
                endPoint: .bottom
            )
            Circle()
                .fill(preset.accentColor.opacity(0.9))
                .frame(width: entry.sample == .abstract ? 130 : 78, height: entry.sample == .abstract ? 130 : 78)
                .offset(primaryOffset)
            Circle()
                .fill(preset.textColor.opacity(0.18))
                .frame(width: 160, height: 160)
                .offset(secondaryOffset)
            if entry.sample == .landscape {
                Rectangle()
                    .fill(preset.accentColor.opacity(0.35))
                    .frame(height: 28)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    private var primaryOffset: CGSize {
        switch entry.sample {
        case .landscape:
            return CGSize(width: 70, height: -36)
        case .abstract:
            return CGSize(width: -30, height: -20)
        case .dusk:
            return CGSize(width: 10, height: -50)
        }
    }

    private var secondaryOffset: CGSize {
        switch entry.sample {
        case .landscape:
            return CGSize(width: -80, height: 40)
        case .abstract:
            return CGSize(width: 50, height: 36)
        case .dusk:
            return CGSize(width: -40, height: 48)
        }
    }
}
