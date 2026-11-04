import PhotosUI
import SwiftUI

struct WallpaperStudioView: View {
    @EnvironmentObject private var session: AppSession
    @State private var mode: WallpaperMode = .gradient
    @State private var followsStyle = true
    @State private var reserveWidgetSpace = true
    @State private var pickerItem: PhotosPickerItem?
    @State private var photo: UIImage?
    @State private var preview: UIImage?
    @State private var isSaving = false
    @State private var notice: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("样式", selection: $mode) {
                        ForEach(WallpaperMode.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: mode) { _, _ in
                        followsStyle = false
                        refreshPreview()
                    }

                    Toggle("跟随当前风格的建议", isOn: $followsStyle)
                    Toggle("上方留出小组件区域", isOn: $reserveWidgetSpace)
                        .onChange(of: reserveWidgetSpace) { _, _ in refreshPreview() }

                    if mode == .blur {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label(photo == nil ? "选择要模糊的照片" : "更换照片", systemImage: "photo")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .onChange(of: pickerItem) { _, item in
                            guard let item else { return }
                            Task { await load(item) }
                        }
                        Text("没选照片时，会退回当前风格的渐变。模糊使用 Core Image 的高斯模糊。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if let preview {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                            }
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("保存到照片（按本机分辨率）")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving)

                    Text("保存后到「设置 → 墙纸」里选用。布局页导出的预览也会用最近一次生成的壁纸当底图。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .navigationTitle("壁纸")
            .noticeAlert($notice)
            .onAppear {
                if followsStyle {
                    mode = suggestedMode
                }
                refreshPreview()
            }
            .onChange(of: session.plan.styleId) { _, _ in
                if followsStyle {
                    mode = suggestedMode
                }
                refreshPreview()
            }
        }
    }

    private var suggestedMode: WallpaperMode {
        switch session.style.wallpaper {
        case .solid:
            return .solid
        case .gradient:
            return .gradient
        case .blur:
            return .blur
        }
    }

    private func refreshPreview() {
        let size = ScreenMetrics.pointSize
        let previewSize = CGSize(width: 280, height: max(280, 280 * size.height / max(size.width, 1)))
        preview = WallpaperRenderer.render(
            style: session.style,
            mode: mode,
            photo: photo,
            reserveWidgetSpace: reserveWidgetSpace,
            pointSize: previewSize,
            scale: 2
        )
    }

    private func load(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            notice = "这张照片读不出来。"
            return
        }
        photo = image
        refreshPreview()
    }

    private func save() async {
        isSaving = true
        let image = WallpaperRenderer.render(
            style: session.style,
            mode: mode,
            photo: photo,
            reserveWidgetSpace: reserveWidgetSpace,
            pointSize: ScreenMetrics.pointSize,
            scale: ScreenMetrics.scale
        )
        session.setWallpaper(image)
        do {
            try await PhotoLibrarySaver.save([image])
            notice = "壁纸已保存到照片。到系统「墙纸」里选用即可。"
        } catch {
            notice = error.localizedDescription
        }
        isSaving = false
    }
}
