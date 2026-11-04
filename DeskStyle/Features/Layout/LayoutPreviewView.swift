import SwiftUI

struct LayoutPreviewView: View {
    @EnvironmentObject private var session: AppSession
    @State private var pageIndex = 0
    @State private var selectedID: UUID?
    @State private var isSaving = false
    @State private var notice: String?
    @State private var confirmClear = false

    private let widgetChoices: [(id: String, name: String, symbol: String)] = [
        ("clock", "时钟", "clock.fill"),
        ("calendar", "日历", "calendar"),
        ("photo", "照片", "photo.fill"),
        ("countdown", "倒数日", "hourglass"),
        ("quote", "一句话", "quote.opening")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    pagePicker
                    HomeScreenPreview(pageIndex: safePage, selectedID: $selectedID)
                        .frame(maxWidth: 420)
                        .frame(maxWidth: .infinity)
                    Text("点选一个格子后再用下面的按钮微调，也可以直接拖到别的空位。程序坞在每一页看起来一样，JSON 里只存一份。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    nudgeBar
                    pageButtons
                    widgetMenu
                    exportButtons
                    Text("布局文件在「文件」App 的「桌面美化」文件夹，文件名是 layout-plan.json。后续桌面自动化应读取 pages 和 dock，不要用 library 里的估算坐标。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .navigationTitle("布局")
            .noticeAlert($notice)
            .confirmationDialog("清空名单和布局？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清空", role: .destructive) {
                    selectedID = nil
                    session.clearPlan()
                }
                Button("取消", role: .cancel) {}
            }
            .onChange(of: session.plan.pages.count) { _, count in
                pageIndex = min(pageIndex, max(0, count - 1))
            }
            .onChange(of: session.plan) { _, plan in
                if let selectedID, !plan.containsItem(selectedID) {
                    self.selectedID = nil
                }
            }
        }
    }

    private var safePage: Int {
        min(pageIndex, max(0, session.plan.pages.count - 1))
    }

    private var pagePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(session.plan.pages) { page in
                    Button("第 \(page.index + 1) 页") {
                        pageIndex = page.index
                    }
                    .buttonStyle(.bordered)
                    .tint(page.index == safePage ? Color.accentColor : Color.secondary)
                }
            }
        }
    }

    private var nudgeBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                nudgeButton("左移", column: -1, row: 0)
                nudgeButton("右移", column: 1, row: 0)
                nudgeButton("上移", column: 0, row: -1)
                nudgeButton("下移", column: 0, row: 1)
                Button("程序坞") { nudgeDock() }
                    .buttonStyle(.bordered)
                Button("上页") { nudgePage(-1) }
                    .buttonStyle(.bordered)
                Button("下页") { nudgePage(1) }
                    .buttonStyle(.bordered)
                Button("删除", role: .destructive) {
                    guard let selectedID else { return }
                    session.deleteItem(id: selectedID)
                }
                .buttonStyle(.bordered)
            }
        }
        .disabled(selectedID == nil)
    }

    private var pageButtons: some View {
        HStack {
            Button("新增一页") {
                if session.addPage() {
                    pageIndex = session.plan.pages.count - 1
                } else {
                    notice = "最多 10 页。"
                }
            }
            .buttonStyle(.bordered)
            Button("删除空页") {
                if !session.removePageIfEmpty(safePage) {
                    notice = "只能删除没有图标的页，而且至少留一页。"
                }
            }
            .buttonStyle(.bordered)
            Button("清空", role: .destructive) {
                confirmClear = true
            }
            .buttonStyle(.bordered)
        }
    }

    private var widgetMenu: some View {
        Menu {
            ForEach(widgetChoices, id: \.id) { choice in
                Menu(choice.name) {
                    Button("小号 2×2") { placeWidget(choice, columns: 2, rows: 2) }
                    Button("中号 4×2") { placeWidget(choice, columns: 4, rows: 2) }
                    Button("大号 4×4") { placeWidget(choice, columns: 4, rows: 4) }
                }
            }
        } label: {
            Label("添加小组件占位", systemImage: "plus.rectangle.on.rectangle")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }

    private var exportButtons: some View {
        VStack(spacing: 8) {
            Button {
                Task { await export(currentOnly: true) }
            } label: {
                if isSaving {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("导出当前页到照片")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)

            Button("导出全部页面") {
                Task { await export(currentOnly: false) }
            }
            .buttonStyle(.bordered)
            .disabled(isSaving)

            ShareLink(item: session.planFileURL) {
                Label("分享布局 JSON", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func nudgeButton(_ title: String, column: Int, row: Int) -> some View {
        Button(title) {
            guard let selectedID else { return }
            if !session.nudge(id: selectedID, columnDelta: column, rowDelta: row) {
                notice = "这个方向没有空位。"
            }
        }
        .buttonStyle(.bordered)
    }

    private func nudgeDock() {
        guard let selectedID else { return }
        if !session.toggleDock(id: selectedID) {
            notice = "程序坞只放单个 App，而且最多 4 个。"
        }
    }

    private func nudgePage(_ delta: Int) {
        guard let selectedID else { return }
        if session.movePage(id: selectedID, delta: delta) {
            if let item = findItem(selectedID), item.pageIndex >= 0 {
                pageIndex = item.pageIndex
            }
        } else {
            notice = "旁边那一页放不下。"
        }
    }

    private func placeWidget(_ choice: (id: String, name: String, symbol: String), columns: Int, rows: Int) {
        if !session.addWidget(kind: choice.id, name: choice.name, symbol: choice.symbol, columnSpan: columns, rowSpan: rows) {
            notice = "没有够大的空位了。可以新开一页，或先挪走几个图标。"
        }
    }

    private func findItem(_ id: UUID) -> LayoutItem? {
        if let docked = session.plan.dock.first(where: { $0.id == id }) {
            return docked
        }
        for page in session.plan.pages {
            if let item = page.items.first(where: { $0.id == id }) {
                return item
            }
        }
        return nil
    }

    private func export(currentOnly: Bool) async {
        isSaving = true
        let image: UIImage
        if currentOnly {
            image = LayoutImageExporter.pageImage(
                plan: session.plan,
                style: session.style,
                wallpaper: session.wallpaperImage,
                pageIndex: safePage,
                pointSize: ScreenMetrics.pointSize,
                scale: ScreenMetrics.scale
            )
        } else {
            image = LayoutImageExporter.allPagesImage(
                plan: session.plan,
                style: session.style,
                wallpaper: session.wallpaperImage,
                pointSize: ScreenMetrics.pointSize,
                scale: ScreenMetrics.scale
            )
        }
        do {
            try await PhotoLibrarySaver.save([image])
            notice = "预览图已保存到照片，可以打开相册对照着摆主屏幕。"
        } catch {
            notice = error.localizedDescription
        }
        isSaving = false
    }
}
