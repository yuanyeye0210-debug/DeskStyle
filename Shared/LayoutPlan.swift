import Foundation

/// DeskStyle layout file.
///
/// Phase 2 desktop automation should place icons from `pages` and `dock`.
/// Coordinates are zero-based cell indexes, origin at the top-left of the icon grid.
/// `dock` is stored once because the iOS dock is shared by every home-screen page.
/// `library` is the recognition list, not the final placement.
struct LayoutPlan: Codable, Equatable {
    static let currentVersion = 1
    static let currentSchema = "deskstyle.layout.v1"
    static let currentCoordinateSystem = "column-row-top-left"
    static let placementNote = "执行摆放时以 pages 与 dock 的格子坐标为准（左上角为 column 0、row 0）。dock 在所有主屏页共享，只存一份。library 是识别清单，不是最终位置。iOS 不能代为移动图标，本文件供预览和后续桌面自动化使用。bundleHint 本版留空，因为系统不允许读取已安装 App 的 Bundle ID。"

    var version: Int
    var schema: String
    var note: String
    var styleId: String
    var createdAt: Date
    var updatedAt: Date
    var coordinateSystem: String
    var grid: GridSpec
    var screen: ScreenSnapshot?
    var library: [LibraryApp]
    var dock: [LayoutItem]
    var pages: [LayoutPage]

    static func empty(styleId: String) -> LayoutPlan {
        LayoutPlan(
            version: currentVersion,
            schema: currentSchema,
            note: placementNote,
            styleId: styleId,
            createdAt: Date(),
            updatedAt: Date(),
            coordinateSystem: currentCoordinateSystem,
            grid: GridSpec(columns: 4, rows: 6, dockRow: 5),
            screen: nil,
            library: [],
            dock: [],
            pages: [LayoutPage(id: UUID(), index: 0, items: [])]
        )
    }

    func containsItem(_ id: UUID) -> Bool {
        if dock.contains(where: { $0.id == id }) {
            return true
        }
        return pages.contains { page in page.items.contains { $0.id == id } }
    }

    var placedNames: Set<String> {
        var names = Set(dock.filter { $0.kind == .app }.map { $0.name.lowercased() })
        for page in pages {
            for item in page.items {
                if item.kind == .app {
                    names.insert(item.name.lowercased())
                }
                for child in item.children ?? [] {
                    names.insert(child.lowercased())
                }
            }
        }
        return names
    }
}

struct GridSpec: Codable, Equatable {
    /// Home-screen columns. iPhone portrait is 4.
    var columns: Int
    /// Visual rows including the dock row.
    var rows: Int
    /// Dock row index. Content cells use `0 ..< dockRow`.
    var dockRow: Int
}

struct ScreenSnapshot: Codable, Equatable {
    var widthPoints: Double
    var heightPoints: Double
    var scale: Double
}

struct LibraryApp: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var name: String
    var category: String
    var colorHex: String
    /// Rough column inferred from a screenshot. Not the committed layout.
    var column: Int?
    /// Rough content-row inferred from a screenshot. Not the committed layout.
    var row: Int?
    var zone: LayoutZone?
    var confidence: Double?
    /// `vision`, `manual`, or `sample`.
    var source: String
}

struct LayoutPage: Codable, Equatable, Identifiable {
    var id: UUID
    var index: Int
    var items: [LayoutItem]
}

struct LayoutItem: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var kind: LayoutItemKind
    var name: String
    /// Widget preset id: clock, calendar, photo, countdown, quote.
    var widgetKind: String?
    var category: String?
    var colorHex: String?
    var symbolName: String?
    /// Reserved for a later tool that knows real bundle identifiers. Always nil in phase 1.
    var bundleHint: String?
    /// `-1` for dock items. Otherwise the page index.
    var pageIndex: Int
    var column: Int
    var row: Int
    var columnSpan: Int
    var rowSpan: Int
    var zone: LayoutZone
    /// App display names inside a folder placeholder.
    var children: [String]?
}

enum LayoutItemKind: String, Codable, Equatable, Sendable {
    case app
    case widget
    case folder
}

enum LayoutZone: String, Codable, Equatable, Sendable {
    case grid
    case dock
}
