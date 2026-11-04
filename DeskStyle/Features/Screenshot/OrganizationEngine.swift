import Foundation

struct OrgSuggestion: Identifiable {
    let id: String
    let title: String
    let detail: String
}

enum OrganizationEngine {
    static func suggestions(for apps: [LibraryApp]) -> [OrgSuggestion] {
        guard !apps.isEmpty else { return [] }
        var result = [
            OrgSuggestion(
                id: "count",
                title: "名单里有 \(apps.count) 个",
                detail: "截图位置只是按文字框估算的。iOS 不允许 App 读取已安装列表，也不能直接改主屏幕。"
            )
        ]
        let groups = Dictionary(grouping: apps, by: \.category)
        let categories = groups.keys.sorted { AppCatalog.categoryRank($0) < AppCatalog.categoryRank($1) }
        for category in categories {
            let names = groups[category] ?? []
            guard names.count >= 2 else { continue }
            let listed = names.prefix(6).map(\.name).joined(separator: "、")
            let extra = names.count > 6 ? " 等" : ""
            result.append(
                OrgSuggestion(
                    id: "cat-\(category)",
                    title: "\(category) · \(names.count) 个",
                    detail: "\(listed)\(extra)。可以放在同一页，或收成一个文件夹占位。"
                )
            )
        }
        let colors = Dictionary(grouping: apps, by: { ColorMath.bucketName(for: $0.colorHex) })
        for bucket in colors.keys.sorted() {
            let names = colors[bucket] ?? []
            guard names.count >= 2 else { continue }
            let listed = names.prefix(6).map(\.name).joined(separator: "、")
            result.append(
                OrgSuggestion(
                    id: "color-\(bucket)",
                    title: bucket,
                    detail: "\(listed)。把接近的颜色排成一行，主屏幕会整齐一些。"
                )
            )
        }
        return result
    }
}
