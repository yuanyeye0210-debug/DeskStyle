import PhotosUI
import SwiftUI

struct ScreenshotAnalysisView: View {
    @EnvironmentObject private var session: AppSession
    @State private var pickerItem: PhotosPickerItem?
    @State private var screenshot: UIImage?
    @State private var manualName = ""
    @State private var isAnalyzing = false
    @State private var notice: String?
    @State private var confirmSample = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    intro
                    screenshotSection
                    nameField
                    if session.plan.library.isEmpty {
                        ContentUnavailableView(
                            "还没有应用名单",
                            systemImage: "square.grid.2x2",
                            description: Text("选一张主屏幕截图，或先用示例名单试试后面的壁纸、图标和布局。")
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        libraryList
                        suggestionList
                        arrangeSection
                    }
                }
                .padding(16)
            }
            .navigationTitle("分析")
            .noticeAlert($notice)
            .confirmationDialog("用示例名单替换当前内容？", isPresented: $confirmSample, titleVisibility: .visible) {
                Button("替换", role: .destructive) { session.useSample() }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private var intro: some View {
        Text("iOS 不允许第三方 App 改主屏幕，也不能读取你装了哪些 App。这里只根据截图上的文字做估算，再生成壁纸、图标和一份你可以照着摆的布局。")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private var screenshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label(screenshot == nil ? "选择主屏幕截图" : "换一张截图", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task { await load(item) }
            }

            if let screenshot {
                Image(uiImage: screenshot)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            HStack {
                Button {
                    guard let screenshot else {
                        notice = "先选一张主屏幕截图。"
                        return
                    }
                    Task { await analyze(screenshot) }
                } label: {
                    if isAnalyzing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("开始识别")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzing)

                Button("示例名单") {
                    if session.plan.library.isEmpty {
                        session.useSample()
                    } else {
                        confirmSample = true
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var nameField: some View {
        HStack {
            TextField("手动加上应用名", text: $manualName)
                .textFieldStyle(.roundedBorder)
            Button("添加") {
                let name = manualName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { return }
                session.addApp(name: name)
                manualName = ""
            }
            .buttonStyle(.bordered)
        }
    }

    private var libraryList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("识别结果")
                .font(.headline)
            ForEach(session.plan.library) { app in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(hex: app.colorHex))
                        .frame(width: 14, height: 14)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name)
                        Text(positionText(app))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(app.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                    Button {
                        session.removeApp(id: app.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("整理建议")
                .font(.headline)
            ForEach(session.suggestions) { suggestion in
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.subheadline.weight(.semibold))
                    Text(suggestion.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var arrangeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("重排布局")
                .font(.headline)
            Text("会按当前名单重做格子，并清掉已经摆上的小组件占位。程序坞默认只留电话、信息、Safari、音乐。")
                .font(.footnote)
                .foregroundStyle(.secondary)
            ForEach(ArrangeMode.allCases) { mode in
                Button(mode.title) {
                    session.arrange(mode)
                    notice = "已按「\(mode.title)」重排。到「布局」页可以继续拖动。"
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func positionText(_ app: LibraryApp) -> String {
        if app.zone == .dock {
            return "估算在程序坞"
        }
        if let row = app.row, let column = app.column {
            return "估算在第 \(row + 1) 行第 \(column + 1) 列"
        }
        if app.source == "manual" {
            return "手动添加"
        }
        return "未估计位置"
    }

    private func load(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            notice = "这张图片读不出来，请换一张。"
            return
        }
        screenshot = image
    }

    private func analyze(_ image: UIImage) async {
        isAnalyzing = true
        let found = await ScreenshotAnalyzer.analyze(image)
        isAnalyzing = false
        if found.isEmpty {
            notice = "没有识别到应用名。可以换一张更清晰的截图，或直接添加名称、使用示例名单。"
            return
        }
        session.replaceFromAnalysis(found)
        notice = "识别到 \(found.count) 个名称，并按估算位置放进了布局。左滑可以删掉认错的。"
    }
}
