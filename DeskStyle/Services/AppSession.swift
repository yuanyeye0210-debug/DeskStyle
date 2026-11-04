import UIKit

@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var plan: LayoutPlan
    @Published private(set) var wallpaperImage: UIImage?

    private let store = LayoutStore()

    init() {
        if let stored = store.load() {
            plan = stored
        } else {
            plan = LayoutPlan.empty(styleId: StylePreset.defaultID)
            store.save(plan)
        }
        wallpaperImage = store.loadWallpaper()
    }

    var style: StylePreset {
        StylePreset.preset(id: plan.styleId)
    }

    var suggestions: [OrgSuggestion] {
        OrganizationEngine.suggestions(for: plan.library)
    }

    var planFileURL: URL {
        store.planURL
    }

    func selectStyle(_ id: String) {
        update { $0.styleId = id }
    }

    func useSample() {
        update { LayoutEditing.replaceLibrary(&$0, with: AppCatalog.sampleLibrary(), mode: .screenshot) }
    }

    func replaceFromAnalysis(_ apps: [LibraryApp]) {
        guard !apps.isEmpty else { return }
        update { LayoutEditing.replaceLibrary(&$0, with: apps, mode: .screenshot) }
    }

    func addApp(name: String) {
        update { LayoutEditing.addApp(&$0, name: name) }
    }

    func removeApp(id: UUID) {
        update { LayoutEditing.removeApp(&$0, id: id) }
    }

    func arrange(_ mode: ArrangeMode) {
        update { LayoutEditing.rebuild(&$0, mode: mode) }
    }

    @discardableResult
    func addWidget(kind: String, name: String, symbol: String, columnSpan: Int, rowSpan: Int) -> Bool {
        var placed = false
        update { placed = LayoutEditing.addWidget(&$0, kind: kind, name: name, symbol: symbol, columnSpan: columnSpan, rowSpan: rowSpan) }
        return placed
    }

    func deleteItem(id: UUID) {
        update { LayoutEditing.deleteItem(&$0, id: id) }
    }

    @discardableResult
    func move(id: UUID, toPage page: Int, column: Int, row: Int) -> Bool {
        var moved = false
        update { moved = LayoutEditing.move(&$0, id: id, toPage: page, column: column, row: row) }
        return moved
    }

    @discardableResult
    func nudge(id: UUID, columnDelta: Int, rowDelta: Int) -> Bool {
        var moved = false
        update { moved = LayoutEditing.nudge(&$0, id: id, columnDelta: columnDelta, rowDelta: rowDelta) }
        return moved
    }

    @discardableResult
    func movePage(id: UUID, delta: Int) -> Bool {
        var moved = false
        update { moved = LayoutEditing.moveToAdjacentPage(&$0, id: id, delta: delta) }
        return moved
    }

    @discardableResult
    func toggleDock(id: UUID) -> Bool {
        var moved = false
        update { moved = LayoutEditing.toggleDock(&$0, id: id) }
        return moved
    }

    @discardableResult
    func addPage() -> Bool {
        var added = false
        update { added = LayoutEditing.addPage(&$0) }
        return added
    }

    @discardableResult
    func removePageIfEmpty(_ index: Int) -> Bool {
        var removed = false
        update { removed = LayoutEditing.removePageIfEmpty(&$0, index: index) }
        return removed
    }

    func clearPlan() {
        update { LayoutEditing.clear(&$0) }
    }

    func setWallpaper(_ image: UIImage) {
        wallpaperImage = image
        store.saveWallpaper(image)
    }

    private func update(_ body: (inout LayoutPlan) -> Void) {
        var copy = plan
        body(&copy)
        guard copy != plan else { return }
        copy.updatedAt = Date()
        copy.note = LayoutPlan.placementNote
        copy.schema = LayoutPlan.currentSchema
        copy.coordinateSystem = LayoutPlan.currentCoordinateSystem
        copy.screen = ScreenMetrics.snapshot()
        plan = copy
        store.save(copy)
    }
}
