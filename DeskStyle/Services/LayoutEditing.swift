import Foundation

enum ArrangeMode: String, CaseIterable, Identifiable {
    case screenshot
    case category
    case color
    case folders

    var id: String { rawValue }

    var title: String {
        switch self {
        case .screenshot:
            return "按截图位置"
        case .category:
            return "按类别排列"
        case .color:
            return "按颜色排列"
        case .folders:
            return "按类别收成文件夹"
        }
    }
}

struct GridCell: Hashable {
    var column: Int
    var row: Int
}

enum LayoutEditing {
    static func replaceLibrary(_ plan: inout LayoutPlan, with apps: [LibraryApp], mode: ArrangeMode) {
        plan.library = apps
        rebuild(&plan, mode: mode)
    }

    static func addApp(_ plan: inout LayoutPlan, name rawName: String) {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard !plan.library.contains(where: { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }) else {
            return
        }
        let app = LibraryApp(
            id: UUID(),
            name: name,
            category: AppCatalog.category(for: name),
            colorHex: AppCatalog.colorHex(for: name),
            column: nil,
            row: nil,
            zone: nil,
            confidence: nil,
            source: "manual"
        )
        plan.library.append(app)
        if AppCatalog.isDockPreferred(name), let column = firstFreeDockColumn(plan) {
            plan.dock.append(makeAppItem(app, pageIndex: -1, column: column, row: plan.grid.dockRow, zone: .dock))
            plan.dock.sort { $0.column < $1.column }
        } else if let slot = firstFreeOrigin(plan, columnSpan: 1, rowSpan: 1) {
            ensurePage(&plan, slot.page)
            plan.pages[slot.page].items.append(makeAppItem(app, pageIndex: slot.page, column: slot.column, row: slot.row, zone: .grid))
        }
        reindex(&plan)
    }

    static func removeApp(_ plan: inout LayoutPlan, id: UUID) {
        guard let app = plan.library.first(where: { $0.id == id }) else { return }
        let name = app.name.lowercased()
        plan.library.removeAll { $0.id == id }
        plan.dock.removeAll { $0.kind == .app && $0.name.lowercased() == name }
        for pageIndex in plan.pages.indices {
            plan.pages[pageIndex].items.removeAll { $0.kind == .app && $0.name.lowercased() == name }
            for itemIndex in plan.pages[pageIndex].items.indices {
                guard plan.pages[pageIndex].items[itemIndex].kind == .folder else { continue }
                plan.pages[pageIndex].items[itemIndex].children?.removeAll { $0.lowercased() == name }
            }
            plan.pages[pageIndex].items = explodeTinyFolders(plan.pages[pageIndex].items)
        }
        reindex(&plan)
    }

    static func rebuild(_ plan: inout LayoutPlan, mode: ArrangeMode) {
        let library = plan.library
        plan.dock = []
        plan.pages = [LayoutPage(id: UUID(), index: 0, items: [])]
        switch mode {
        case .screenshot:
            placeByScreenshot(&plan, apps: library)
        case .category:
            let peeled = peelDock(library)
            placeDock(&plan, apps: peeled.dock)
            placeSequentially(&plan, items: peeled.rest.sorted(by: categorySort).map { .app($0) })
        case .color:
            let peeled = peelDock(library)
            placeDock(&plan, apps: peeled.dock)
            placeSequentially(&plan, items: peeled.rest.sorted(by: colorSort).map { .app($0) })
        case .folders:
            let peeled = peelDock(library)
            placeDock(&plan, apps: peeled.dock)
            placeSequentially(&plan, items: folderItems(from: peeled.rest))
        }
        trimEmptyTrailingPages(&plan)
        reindex(&plan)
    }

    static func addWidget(_ plan: inout LayoutPlan, kind: String, name: String, symbol: String, columnSpan: Int, rowSpan: Int) -> Bool {
        guard let slot = firstFreeOrigin(plan, columnSpan: columnSpan, rowSpan: rowSpan) else { return false }
        ensurePage(&plan, slot.page)
        let item = LayoutItem(
            id: UUID(),
            kind: .widget,
            name: name,
            widgetKind: kind,
            category: nil,
            colorHex: nil,
            symbolName: symbol,
            bundleHint: nil,
            pageIndex: slot.page,
            column: slot.column,
            row: slot.row,
            columnSpan: columnSpan,
            rowSpan: rowSpan,
            zone: .grid,
            children: nil
        )
        plan.pages[slot.page].items.append(item)
        reindex(&plan)
        return true
    }

    static func deleteItem(_ plan: inout LayoutPlan, id: UUID) {
        if let dockIndex = plan.dock.firstIndex(where: { $0.id == id }) {
            let name = plan.dock[dockIndex].name
            plan.dock.remove(at: dockIndex)
            plan.library.removeAll { $0.name.compare(name, options: .caseInsensitive) == .orderedSame }
            reindex(&plan)
            return
        }
        for pageIndex in plan.pages.indices {
            guard let itemIndex = plan.pages[pageIndex].items.firstIndex(where: { $0.id == id }) else { continue }
            let item = plan.pages[pageIndex].items.remove(at: itemIndex)
            if item.kind == .app {
                plan.library.removeAll { $0.name.compare(item.name, options: .caseInsensitive) == .orderedSame }
            } else if item.kind == .folder {
                let children = Set((item.children ?? []).map { $0.lowercased() })
                plan.library.removeAll { children.contains($0.name.lowercased()) }
            }
            reindex(&plan)
            return
        }
    }

    static func move(_ plan: inout LayoutPlan, id: UUID, toPage page: Int, column: Int, row: Int) -> Bool {
        guard let moving = item(plan, id: id) else { return false }
        if row >= plan.grid.dockRow {
            return moveToDock(&plan, id: id, column: column)
        }
        guard moving.zone == .grid || moving.columnSpan == 1 else { return false }
        var candidate = moving
        if candidate.zone == .dock {
            candidate.columnSpan = 1
            candidate.rowSpan = 1
            candidate.zone = .grid
        }
        let targetPage = min(max(0, page), 9)
        ensurePage(&plan, targetPage)
        let originColumn = min(column, plan.grid.columns - candidate.columnSpan)
        let originRow = min(max(0, row), plan.grid.dockRow - candidate.rowSpan)
        if let other = itemCovering(plan, page: targetPage, column: originColumn, row: originRow),
           other.id != id,
           other.columnSpan == 1, other.rowSpan == 1,
           candidate.columnSpan == 1, candidate.rowSpan == 1 {
            return swap(&plan, first: id, second: other.id)
        }
        guard fits(plan, page: targetPage, column: originColumn, row: originRow, columnSpan: candidate.columnSpan, rowSpan: candidate.rowSpan, ignoring: id) else {
            return false
        }
        removeItemOnly(&plan, id: id)
        candidate.pageIndex = targetPage
        candidate.column = originColumn
        candidate.row = originRow
        candidate.zone = .grid
        ensurePage(&plan, targetPage)
        plan.pages[targetPage].items.append(candidate)
        reindex(&plan)
        return true
    }

    static func nudge(_ plan: inout LayoutPlan, id: UUID, columnDelta: Int, rowDelta: Int) -> Bool {
        guard let moving = item(plan, id: id) else { return false }
        if moving.zone == .dock {
            if rowDelta < 0 {
                return moveOutOfDock(&plan, id: id)
            }
            if columnDelta == 0 {
                return false
            }
            return moveToDock(&plan, id: id, column: moving.column + columnDelta)
        }
        let targetRow = moving.row + rowDelta
        if targetRow >= plan.grid.dockRow {
            return false
        }
        return move(&plan, id: id, toPage: moving.pageIndex, column: moving.column + columnDelta, row: targetRow)
    }

    static func moveToAdjacentPage(_ plan: inout LayoutPlan, id: UUID, delta: Int) -> Bool {
        guard let moving = item(plan, id: id), moving.zone == .grid else { return false }
        let target = moving.pageIndex + delta
        guard target >= 0, target <= 9 else { return false }
        ensurePage(&plan, target)
        if fits(plan, page: target, column: moving.column, row: moving.row, columnSpan: moving.columnSpan, rowSpan: moving.rowSpan, ignoring: id) {
            return move(&plan, id: id, toPage: target, column: moving.column, row: moving.row)
        }
        guard let slot = firstFreeOrigin(on: target, plan: plan, columnSpan: moving.columnSpan, rowSpan: moving.rowSpan, ignoring: id) else {
            return false
        }
        return move(&plan, id: id, toPage: slot.page, column: slot.column, row: slot.row)
    }

    static func toggleDock(_ plan: inout LayoutPlan, id: UUID) -> Bool {
        guard let moving = item(plan, id: id) else { return false }
        if moving.zone == .dock {
            return moveOutOfDock(&plan, id: id)
        }
        guard moving.kind == .app, moving.columnSpan == 1, moving.rowSpan == 1 else { return false }
        guard let column = firstFreeDockColumn(plan) else { return false }
        return moveToDock(&plan, id: id, column: column)
    }

    static func addPage(_ plan: inout LayoutPlan) -> Bool {
        guard plan.pages.count < 10 else { return false }
        plan.pages.append(LayoutPage(id: UUID(), index: plan.pages.count, items: []))
        reindex(&plan)
        return true
    }

    static func removePageIfEmpty(_ plan: inout LayoutPlan, index: Int) -> Bool {
        guard plan.pages.count > 1, plan.pages.indices.contains(index), plan.pages[index].items.isEmpty else {
            return false
        }
        plan.pages.remove(at: index)
        reindex(&plan)
        return true
    }

    static func clear(_ plan: inout LayoutPlan) {
        let styleId = plan.styleId
        let created = plan.createdAt
        plan = LayoutPlan.empty(styleId: styleId)
        plan.createdAt = created
    }
}

private extension LayoutEditing {
    enum Placeable {
        case app(LibraryApp)
        case folder(name: String, category: String, children: [LibraryApp])
    }

    static func placeByScreenshot(_ plan: inout LayoutPlan, apps: [LibraryApp]) {
        let dockApps = apps.filter { $0.zone == .dock }.sorted(by: { ($0.column ?? 0) < ($1.column ?? 0) })
        let positioned = apps.filter { $0.zone != .dock && $0.column != nil && $0.row != nil }
            .sorted(by: { left, right in
                if (left.row ?? 0) == (right.row ?? 0) { return (left.column ?? 0) < (right.column ?? 0) }
                return (left.row ?? 0) < (right.row ?? 0)
            })
        let leftovers = apps.filter { app in
            app.zone != .dock && (app.column == nil || app.row == nil)
        }
        for app in dockApps {
            let preferred = min(max(0, app.column ?? 0), plan.grid.columns - 1)
            let resolved: Int?
            if plan.dock.contains(where: { $0.column == preferred }) {
                resolved = firstFreeDockColumn(plan)
            } else {
                resolved = preferred
            }
            guard let column = resolved else { continue }
            plan.dock.append(makeAppItem(app, pageIndex: -1, column: column, row: plan.grid.dockRow, zone: .dock))
        }
        for app in positioned {
            let column = min(max(0, app.column ?? 0), plan.grid.columns - 1)
            let row = min(max(0, app.row ?? 0), plan.grid.dockRow - 1)
            if fits(plan, page: 0, column: column, row: row, columnSpan: 1, rowSpan: 1, ignoring: nil) {
                plan.pages[0].items.append(makeAppItem(app, pageIndex: 0, column: column, row: row, zone: .grid))
            } else if let slot = firstFreeOrigin(plan, columnSpan: 1, rowSpan: 1) {
                ensurePage(&plan, slot.page)
                plan.pages[slot.page].items.append(makeAppItem(app, pageIndex: slot.page, column: slot.column, row: slot.row, zone: .grid))
            }
        }
        placeSequentially(&plan, items: leftovers.map { .app($0) })
    }

    static func peelDock(_ apps: [LibraryApp]) -> (dock: [LibraryApp], rest: [LibraryApp]) {
        var dock: [LibraryApp] = []
        var rest: [LibraryApp] = []
        for app in apps {
            if AppCatalog.isDockPreferred(app.name), dock.count < 4 {
                dock.append(app)
            } else {
                rest.append(app)
            }
        }
        dock.sort { AppCatalog.dockRank($0.name) < AppCatalog.dockRank($1.name) }
        return (dock, rest)
    }

    static func placeDock(_ plan: inout LayoutPlan, apps: [LibraryApp]) {
        for (index, app) in apps.prefix(plan.grid.columns).enumerated() {
            plan.dock.append(makeAppItem(app, pageIndex: -1, column: index, row: plan.grid.dockRow, zone: .dock))
        }
    }

    static func folderItems(from apps: [LibraryApp]) -> [Placeable] {
        let groups = Dictionary(grouping: apps, by: \.category)
        let categories = groups.keys.sorted(by: { AppCatalog.categoryRank($0) < AppCatalog.categoryRank($1) })
        var items: [Placeable] = []
        for category in categories {
            let members = (groups[category] ?? []).sorted(by: { $0.name.localizedStandardCompare($1.name) == .orderedAscending })
            if members.count >= 2 {
                items.append(.folder(name: category, category: category, children: members))
            } else if let only = members.first {
                items.append(.app(only))
            }
        }
        return items
    }

    static func placeSequentially(_ plan: inout LayoutPlan, items: [Placeable]) {
        for item in items {
            switch item {
            case .app(let app):
                guard let slot = firstFreeOrigin(plan, columnSpan: 1, rowSpan: 1) else { continue }
                ensurePage(&plan, slot.page)
                plan.pages[slot.page].items.append(makeAppItem(app, pageIndex: slot.page, column: slot.column, row: slot.row, zone: .grid))
            case .folder(let name, let category, let children):
                guard let slot = firstFreeOrigin(plan, columnSpan: 1, rowSpan: 1) else { continue }
                ensurePage(&plan, slot.page)
                let folder = LayoutItem(
                    id: UUID(),
                    kind: .folder,
                    name: name,
                    widgetKind: nil,
                    category: category,
                    colorHex: children.first?.colorHex,
                    symbolName: "folder.fill",
                    bundleHint: nil,
                    pageIndex: slot.page,
                    column: slot.column,
                    row: slot.row,
                    columnSpan: 1,
                    rowSpan: 1,
                    zone: .grid,
                    children: children.map(\.name)
                )
                plan.pages[slot.page].items.append(folder)
            }
        }
    }

    static func makeAppItem(_ app: LibraryApp, pageIndex: Int, column: Int, row: Int, zone: LayoutZone) -> LayoutItem {
        LayoutItem(
            id: UUID(),
            kind: .app,
            name: app.name,
            widgetKind: nil,
            category: app.category,
            colorHex: app.colorHex,
            symbolName: AppCatalog.symbolName(for: app.name),
            bundleHint: nil,
            pageIndex: pageIndex,
            column: column,
            row: row,
            columnSpan: 1,
            rowSpan: 1,
            zone: zone,
            children: nil
        )
    }

    static func categorySort(_ lhs: LibraryApp, _ rhs: LibraryApp) -> Bool {
        let left = AppCatalog.categoryRank(lhs.category)
        let right = AppCatalog.categoryRank(rhs.category)
        if left == right {
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        return left < right
    }

    static func colorSort(_ lhs: LibraryApp, _ rhs: LibraryApp) -> Bool {
        let left = ColorMath.hue(of: lhs.colorHex)
        let right = ColorMath.hue(of: rhs.colorHex)
        if abs(left - right) < 0.1 {
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        return left < right
    }

    static func explodeTinyFolders(_ items: [LayoutItem]) -> [LayoutItem] {
        items.flatMap { item -> [LayoutItem] in
            guard item.kind == .folder else { return [item] }
            let children = item.children ?? []
            if children.isEmpty {
                return []
            }
            if children.count == 1, let only = children.first {
                var single = item
                single.id = UUID()
                single.kind = .app
                single.name = only
                single.children = nil
                single.symbolName = AppCatalog.symbolName(for: only)
                single.category = AppCatalog.category(for: only)
                single.colorHex = AppCatalog.colorHex(for: only)
                return [single]
            }
            return [item]
        }
    }

    static func item(_ plan: LayoutPlan, id: UUID) -> LayoutItem? {
        if let docked = plan.dock.first(where: { $0.id == id }) {
            return docked
        }
        for page in plan.pages {
            if let found = page.items.first(where: { $0.id == id }) {
                return found
            }
        }
        return nil
    }

    static func removeItemOnly(_ plan: inout LayoutPlan, id: UUID) {
        plan.dock.removeAll { $0.id == id }
        for pageIndex in plan.pages.indices {
            plan.pages[pageIndex].items.removeAll { $0.id == id }
        }
    }

    static func moveToDock(_ plan: inout LayoutPlan, id: UUID, column requested: Int) -> Bool {
        guard let moving = item(plan, id: id), moving.kind == .app else { return false }
        let column = min(max(0, requested), plan.grid.columns - 1)
        if let other = plan.dock.first(where: { $0.column == column && $0.id != id }) {
            return swap(&plan, first: id, second: other.id)
        }
        if plan.dock.contains(where: { $0.column == column }) {
            return false
        }
        if moving.zone != .dock, plan.dock.count >= plan.grid.columns {
            return false
        }
        removeItemOnly(&plan, id: id)
        var placed = moving
        placed.zone = .dock
        placed.pageIndex = -1
        placed.column = column
        placed.row = plan.grid.dockRow
        placed.columnSpan = 1
        placed.rowSpan = 1
        plan.dock.append(placed)
        plan.dock.sort { $0.column < $1.column }
        reindex(&plan)
        return true
    }

    static func moveOutOfDock(_ plan: inout LayoutPlan, id: UUID) -> Bool {
        guard let moving = item(plan, id: id), moving.zone == .dock else { return false }
        guard let slot = firstFreeOrigin(plan, columnSpan: 1, rowSpan: 1) else { return false }
        ensurePage(&plan, slot.page)
        removeItemOnly(&plan, id: id)
        var placed = moving
        placed.zone = .grid
        placed.pageIndex = slot.page
        placed.column = slot.column
        placed.row = slot.row
        plan.pages[slot.page].items.append(placed)
        reindex(&plan)
        return true
    }

    static func swap(_ plan: inout LayoutPlan, first: UUID, second: UUID) -> Bool {
        guard var left = item(plan, id: first), var right = item(plan, id: second) else { return false }
        if (left.zone == .dock || right.zone == .dock) && (left.kind != .app || right.kind != .app) {
            return false
        }
        let leftPlace = (left.pageIndex, left.column, left.row, left.zone)
        left.pageIndex = right.pageIndex
        left.column = right.column
        left.row = right.row
        left.zone = right.zone
        right.pageIndex = leftPlace.0
        right.column = leftPlace.1
        right.row = leftPlace.2
        right.zone = leftPlace.3
        removeItemOnly(&plan, id: first)
        removeItemOnly(&plan, id: second)
        insert(&plan, left)
        insert(&plan, right)
        reindex(&plan)
        return true
    }

    static func insert(_ plan: inout LayoutPlan, _ item: LayoutItem) {
        if item.zone == .dock {
            plan.dock.append(item)
            plan.dock.sort { $0.column < $1.column }
            return
        }
        let page = min(max(0, item.pageIndex), 9)
        ensurePage(&plan, page)
        plan.pages[page].items.append(item)
    }

    static func itemCovering(_ plan: LayoutPlan, page: Int, column: Int, row: Int) -> LayoutItem? {
        guard plan.pages.indices.contains(page) else { return nil }
        return plan.pages[page].items.first { item in
            (item.column..<(item.column + item.columnSpan)).contains(column)
                && (item.row..<(item.row + item.rowSpan)).contains(row)
        }
    }

    static func fits(
        _ plan: LayoutPlan,
        page: Int,
        column: Int,
        row: Int,
        columnSpan: Int,
        rowSpan: Int,
        ignoring: UUID?
    ) -> Bool {
        guard column >= 0, row >= 0,
              column + columnSpan <= plan.grid.columns,
              row + rowSpan <= plan.grid.dockRow,
              plan.pages.indices.contains(page) else {
            return false
        }
        let occupied = occupiedCells(plan, page: page, ignoring: ignoring)
        for rowIndex in row..<(row + rowSpan) {
            for columnIndex in column..<(column + columnSpan) where occupied.contains(GridCell(column: columnIndex, row: rowIndex)) {
                return false
            }
        }
        return true
    }

    static func occupiedCells(_ plan: LayoutPlan, page: Int, ignoring: UUID?) -> Set<GridCell> {
        guard plan.pages.indices.contains(page) else { return [] }
        var cells = Set<GridCell>()
        for item in plan.pages[page].items where item.id != ignoring {
            for row in item.row..<(item.row + item.rowSpan) {
                for column in item.column..<(item.column + item.columnSpan) {
                    cells.insert(GridCell(column: column, row: row))
                }
            }
        }
        return cells
    }

    static func firstFreeDockColumn(_ plan: LayoutPlan) -> Int? {
        let used = Set(plan.dock.map(\.column))
        return (0..<plan.grid.columns).first { !used.contains($0) }
    }

    static func firstFreeOrigin(_ plan: LayoutPlan, columnSpan: Int, rowSpan: Int) -> (page: Int, column: Int, row: Int)? {
        var page = 0
        while page < 10 {
            if let slot = firstFreeOrigin(on: page, plan: plan, columnSpan: columnSpan, rowSpan: rowSpan, ignoring: nil) {
                return slot
            }
            page += 1
        }
        return nil
    }

    static func firstFreeOrigin(
        on page: Int,
        plan: LayoutPlan,
        columnSpan: Int,
        rowSpan: Int,
        ignoring: UUID?
    ) -> (page: Int, column: Int, row: Int)? {
        guard page < 10 else { return nil }
        var mutable = plan
        ensurePage(&mutable, page)
        for row in 0...(mutable.grid.dockRow - rowSpan) {
            for column in 0...(mutable.grid.columns - columnSpan) {
                if fits(mutable, page: page, column: column, row: row, columnSpan: columnSpan, rowSpan: rowSpan, ignoring: ignoring) {
                    return (page, column, row)
                }
            }
        }
        return nil
    }

    static func ensurePage(_ plan: inout LayoutPlan, _ index: Int) {
        while plan.pages.count <= index && plan.pages.count < 10 {
            plan.pages.append(LayoutPage(id: UUID(), index: plan.pages.count, items: []))
        }
    }

    static func trimEmptyTrailingPages(_ plan: inout LayoutPlan) {
        while plan.pages.count > 1, plan.pages.last?.items.isEmpty == true {
            plan.pages.removeLast()
        }
    }

    static func reindex(_ plan: inout LayoutPlan) {
        for pageIndex in plan.pages.indices {
            plan.pages[pageIndex].index = pageIndex
            for itemIndex in plan.pages[pageIndex].items.indices {
                plan.pages[pageIndex].items[itemIndex].pageIndex = pageIndex
                plan.pages[pageIndex].items[itemIndex].zone = .grid
            }
        }
        for index in plan.dock.indices {
            plan.dock[index].pageIndex = -1
            plan.dock[index].row = plan.grid.dockRow
            plan.dock[index].zone = .dock
            plan.dock[index].columnSpan = 1
            plan.dock[index].rowSpan = 1
        }
    }
}
