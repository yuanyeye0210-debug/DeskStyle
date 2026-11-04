import SwiftUI
import UIKit

struct IconPackView: View {
    @EnvironmentObject private var session: AppSession
    @State private var manualName = ""
    @State private var isSaving = false
    @State private var notice: String?

    private var names: [String] {
        session.plan.library.map(\.name)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("按当前风格给名单里的每个名字画一张图标：能对上的用符号，对不上的用首字。保存到照片后，按教程用快捷指令换到主屏幕。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("再加一个名字", text: $manualName)
                            .textFieldStyle(.roundedBorder)
                        Button("添加") {
                            let name = manualName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty else { return }
                            session.addApp(name: name)
                            manualName = ""
                        }
                        .buttonStyle(.bordered)
                    }

                    if names.isEmpty {
                        ContentUnavailableView(
                            "没有可生成的图标",
                            systemImage: "app",
                            description: Text("先在「分析」里识别截图、使用示例，或在这里输入名字。")
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 12)], spacing: 14) {
                            ForEach(names, id: \.self) { name in
                                StyleIconBadge(name: name, style: session.style)
                            }
                        }
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().frame(maxWidth: .infinity)
                        } else {
                            Text("保存图标到照片")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(names.isEmpty || isSaving)

                    NavigationLink {
                        ShortcutTutorialView()
                    } label: {
                        Label("查看换图标步骤", systemImage: "list.number")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(16)
            }
            .navigationTitle("图标")
            .noticeAlert($notice)
        }
    }

    private func save() async {
        isSaving = true
        var images = names.map { IconRenderer.card(name: $0, style: session.style) }
        images.append(IconRenderer.overview(names: names, style: session.style))
        do {
            try await PhotoLibrarySaver.save(images)
            notice = "已保存 \(names.count) 张图标，以及最后一张带名字的总览。换图标时以总览为对照。"
        } catch {
            notice = error.localizedDescription
        }
        isSaving = false
    }
}

struct StyleIconBadge: View {
    let name: String
    let style: StylePreset

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: IconPalette.hex(name: name, style: style)))
                glyph
                    .foregroundStyle(Color(hex: IconPalette.hex(name: name, style: style)).isLight ? Color.black : Color.white)
                    .font(.system(size: 26, weight: .semibold, design: style.fontDesign.swiftUI))
            }
            .frame(width: 64, height: 64)
            Text(name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 76)
        }
    }

    @ViewBuilder
    private var glyph: some View {
        if let symbol = AppCatalog.symbolName(for: name) {
            Image(systemName: symbol)
        } else {
            Text(String(name.prefix(1)))
        }
    }
}

private extension Color {
    var isLight: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (0.2126 * red + 0.7152 * green + 0.0722 * blue) > 0.62
    }
}
