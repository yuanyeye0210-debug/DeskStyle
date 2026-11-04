import Foundation

enum AppCatalog {
    struct Rule {
        let category: String
        let keywords: [String]
    }

    static let categoryOrder = [
        "系统", "社交", "支付", "购物", "视频", "音乐", "地图出行",
        "摄影", "浏览", "效率", "健康", "教育", "游戏", "其他"
    ]

    static let dockPreferred = ["电话", "信息", "safari", "音乐"]

    private static let rules: [Rule] = [
        Rule(category: "支付", keywords: ["支付宝", "alipay", "云闪付", "paypal", "钱包"]),
        Rule(category: "购物", keywords: ["淘宝", "天猫", "京东", "拼多多", "美团", "饿了么", "闲鱼", "唯品会", "得物", "亚马逊", "amazon", "盒马"]),
        Rule(category: "视频", keywords: ["哔哩哔哩", "bilibili", "腾讯视频", "爱奇艺", "优酷", "youtube", "netflix", "抖音", "快手", "影视"]),
        Rule(category: "音乐", keywords: ["网易云音乐", "qq音乐", "酷狗", "酷我", "spotify", "喜马拉雅", "播客", "podcasts", "音乐", "music"]),
        Rule(category: "地图出行", keywords: ["高德地图", "高德", "百度地图", "滴滴", "12306", "铁路", "航旅", "uber", "地图", "maps"]),
        Rule(category: "摄影", keywords: ["相机", "camera", "照片", "photos", "美图", "醒图", "lightroom", "snapseed"]),
        Rule(category: "浏览", keywords: ["safari", "chrome", "edge", "firefox", "浏览器"]),
        Rule(category: "社交", keywords: ["微信", "wechat", "qq", "微博", "weibo", "小红书", "telegram", "whatsapp", "instagram", "facebook", "messenger", "discord", "钉钉", "飞书", "soul", "陌陌", "line"]),
        Rule(category: "系统", keywords: ["电话", "phone", "信息", "messages", "设置", "settings", "日历", "calendar", "备忘录", "notes", "邮件", "mail", "时钟", "clock", "文件", "files", "天气", "weather", "计算器", "calculator", "快捷指令", "shortcuts", "app store", "提醒事项", "reminders"]),
        Rule(category: "健康", keywords: ["健康", "keep", "运动", "fitness", "睡眠"]),
        Rule(category: "教育", keywords: ["多邻国", "duolingo", "百词斩", "词典", "课堂", "学习"]),
        Rule(category: "游戏", keywords: ["王者", "原神", "和平精英", "游戏", "game"]),
        Rule(category: "效率", keywords: ["翻译", "translate", "扫描", "语音备忘录"])
    ]

    private static let flattened: [(keyword: String, category: String)] = {
        var pairs: [(keyword: String, category: String)] = []
        for rule in rules {
            for keyword in rule.keywords {
                pairs.append((keyword: keyword.lowercased(), category: rule.category))
            }
        }
        return pairs.sorted(by: { left, right in
            left.keyword.count > right.keyword.count
        })
    }()

    private static let knownColors: [String: String] = [
        "微信": "07C160",
        "支付宝": "1677FF",
        "淘宝": "FF5000",
        "美团": "FFC300",
        "高德地图": "00B386",
        "哔哩哔哩": "FB7299",
        "网易云音乐": "E60026",
        "小红书": "FF2442",
        "抖音": "111111",
        "qq": "12B7F5",
        "微博": "E6162D",
        "京东": "E1251B",
        "拼多多": "E02E24",
        "safari": "0A84FF",
        "音乐": "FF2D55",
        "照片": "FF9F0A",
        "相机": "8E8E93",
        "日历": "FF3B30",
        "备忘录": "FFD60A",
        "设置": "8E8E93",
        "邮件": "0A84FF",
        "时钟": "FF9500",
        "文件": "007AFF",
        "健康": "FF2D55",
        "电话": "34C759",
        "信息": "34C759",
        "天气": "0A84FF",
        "app store": "0A84FF"
    ]

    private static let symbols: [String: String] = [
        "微信": "message.fill",
        "qq": "bubble.left.and.bubble.right.fill",
        "微博": "text.bubble.fill",
        "电话": "phone.fill",
        "信息": "message.fill",
        "safari": "safari.fill",
        "音乐": "music.note",
        "网易云音乐": "music.note.list",
        "qq音乐": "music.note.list",
        "照片": "photo.fill",
        "相机": "camera.fill",
        "日历": "calendar",
        "备忘录": "note.text",
        "设置": "gearshape.fill",
        "支付宝": "creditcard.fill",
        "淘宝": "bag.fill",
        "京东": "bag.fill",
        "美团": "fork.knife",
        "饿了么": "fork.knife",
        "高德地图": "map.fill",
        "地图": "map.fill",
        "哔哩哔哩": "play.rectangle.fill",
        "抖音": "video.fill",
        "小红书": "book.fill",
        "邮件": "envelope.fill",
        "时钟": "clock.fill",
        "文件": "folder.fill",
        "健康": "heart.fill",
        "天气": "cloud.sun.fill",
        "计算器": "plus.forwardslash.minus",
        "快捷指令": "square.stack.3d.up.fill",
        "app store": "bag.fill"
    ]

    static var recognitionWords: [String] {
        var words: [String] = []
        var seen = Set<String>()
        for pair in flattened {
            if pair.keyword.count >= 2, seen.insert(pair.keyword).inserted {
                words.append(pair.keyword)
            }
        }
        for name in knownColors.keys where seen.insert(name.lowercased()).inserted {
            words.append(name)
        }
        return Array(words.prefix(80))
    }

    static func category(for name: String) -> String {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for pair in flattened where key.contains(pair.keyword) {
            return pair.category
        }
        return "其他"
    }

    static func knownColorHex(for name: String) -> String? {
        knownColors[name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()]
    }

    static func colorHex(for name: String) -> String {
        if let known = knownColorHex(for: name) {
            return known
        }
        let palette = ["5B7C99", "C17B6B", "7D8B6A", "C2A15B", "8E6B8A", "6A8F8B", "B08968", "6E7F99"]
        return palette[stableHash(name) % palette.count]
    }

    static func symbolName(for name: String) -> String? {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let exact = symbols[key] {
            return exact
        }
        for pair in symbols.sorted(by: { $0.key.count > $1.key.count }) where key.contains(pair.key) {
            return pair.value
        }
        return nil
    }

    static func categoryRank(_ category: String) -> Int {
        categoryOrder.firstIndex(of: category) ?? categoryOrder.count
    }

    static func isDockPreferred(_ name: String) -> Bool {
        dockRank(name) < dockPreferred.count
    }

    static func dockRank(_ name: String) -> Int {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return dockPreferred.firstIndex(of: key) ?? dockPreferred.count
    }

    static func stableHash(_ text: String) -> Int {
        var hash = 5381
        for byte in text.utf8 {
            hash = ((hash << 5) &+ hash) &+ Int(byte)
        }
        return abs(hash)
    }

    static func sampleLibrary() -> [LibraryApp] {
        let specs: [(String, Int, Int, LayoutZone)] = [
            ("微信", 0, 0, .grid),
            ("支付宝", 1, 0, .grid),
            ("淘宝", 2, 0, .grid),
            ("美团", 3, 0, .grid),
            ("高德地图", 0, 1, .grid),
            ("哔哩哔哩", 1, 1, .grid),
            ("网易云音乐", 2, 1, .grid),
            ("小红书", 3, 1, .grid),
            ("抖音", 0, 2, .grid),
            ("日历", 1, 2, .grid),
            ("邮件", 2, 2, .grid),
            ("文件", 3, 2, .grid),
            ("照片", 0, 3, .grid),
            ("相机", 1, 3, .grid),
            ("时钟", 2, 3, .grid),
            ("天气", 3, 3, .grid),
            ("备忘录", 0, 4, .grid),
            ("健康", 1, 4, .grid),
            ("设置", 2, 4, .grid),
            ("电话", 0, 5, .dock),
            ("信息", 1, 5, .dock),
            ("Safari", 2, 5, .dock),
            ("音乐", 3, 5, .dock)
        ]
        return specs.map { name, column, row, zone in
            LibraryApp(
                id: UUID(),
                name: name,
                category: category(for: name),
                colorHex: colorHex(for: name),
                column: column,
                row: zone == .dock ? nil : row,
                zone: zone,
                confidence: nil,
                source: "sample"
            )
        }
    }
}
