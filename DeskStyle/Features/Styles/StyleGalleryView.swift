import SwiftUI

struct StyleGalleryView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("风格会用于壁纸、图标和布局预览。小组件读不到这里的选择：免费 Apple ID 不能使用 App Groups。添加小组件后，请长按它，点「编辑小组件」，再选一次同名风格。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }
                Section("六套预设") {
                    ForEach(StylePreset.presets) { preset in
                        Button {
                            session.selectStyle(preset.id)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(preset.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(preset.summary)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.leading)
                                    HStack(spacing: 6) {
                                        swatch(preset.backgroundHex)
                                        swatch(preset.secondaryHex)
                                        swatch(preset.accentHex)
                                        swatch(preset.textHex)
                                    }
                                }
                                Spacer(minLength: 8)
                                if session.plan.styleId == preset.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(preset.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("风格")
        }
    }

    private func swatch(_ hex: String) -> some View {
        Circle()
            .fill(Color(hex: hex))
            .frame(width: 16, height: 16)
            .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
    }
}
