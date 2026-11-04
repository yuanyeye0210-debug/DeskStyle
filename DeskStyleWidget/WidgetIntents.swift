import AppIntents
import WidgetKit

enum WidgetStyleChoice: String, AppEnum {
    case minimal
    case dark
    case morandi
    case cute
    case ocean
    case sunset

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "风格"

    static var caseDisplayRepresentations: [WidgetStyleChoice: DisplayRepresentation] = [
        .minimal: "极简",
        .dark: "暗黑",
        .morandi: "莫兰迪",
        .cute: "可爱风",
        .ocean: "海洋",
        .sunset: "暖阳"
    ]

    var preset: StylePreset {
        StylePreset.preset(id: rawValue)
    }
}

enum PhotoSample: String, AppEnum {
    case landscape
    case abstract
    case dusk

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "画面"

    static var caseDisplayRepresentations: [PhotoSample: DisplayRepresentation] = [
        .landscape: "海平线",
        .abstract: "色块",
        .dusk: "暮色"
    ]

    var title: String {
        switch self {
        case .landscape:
            return "海平线"
        case .abstract:
            return "色块"
        case .dusk:
            return "暮色"
        }
    }
}

struct ClockWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "时钟"
    static var description = IntentDescription("显示当前时间。风格在编辑小组件里选择。")

    @Parameter(title: "风格", default: WidgetStyleChoice.minimal)
    var style: WidgetStyleChoice
}

struct CalendarWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "日历"
    static var description = IntentDescription("显示今天和本月。风格在编辑小组件里选择。")

    @Parameter(title: "风格", default: WidgetStyleChoice.morandi)
    var style: WidgetStyleChoice
}

struct PhotoWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "照片"
    static var description = IntentDescription("内置画面。免费 Apple ID 不能使用 App Groups，所以这里不能选相册照片。")

    @Parameter(title: "画面", default: PhotoSample.landscape)
    var sample: PhotoSample

    @Parameter(title: "风格", default: WidgetStyleChoice.ocean)
    var style: WidgetStyleChoice
}

struct CountdownWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "倒数日"
    static var description = IntentDescription("显示距离某一天还有多少天。")

    @Parameter(title: "标题", default: "纪念日")
    var eventTitle: String

    @Parameter(title: "日期")
    var targetDate: Date?

    @Parameter(title: "风格", default: WidgetStyleChoice.sunset)
    var style: WidgetStyleChoice
}

struct QuoteWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "一句话"
    static var description = IntentDescription("每天换一句短句。风格在编辑小组件里选择。")

    @Parameter(title: "风格", default: WidgetStyleChoice.cute)
    var style: WidgetStyleChoice
}
