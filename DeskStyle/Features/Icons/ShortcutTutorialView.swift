import SwiftUI

struct ShortcutTutorialView: View {
    private let steps = [
        "打开系统自带的「快捷指令」。",
        "点右上角加号，新建一条空白快捷指令。",
        "搜索并添加操作「打开 App」。",
        "在这个操作里选中你要换图标的 App，例如「微信」。每条快捷指令只对应一个 App。",
        "点顶部名称，改成这个 App 的名字，方便以后辨认。",
        "点分享按钮，选择「添加到主屏幕」。",
        "点图标，选「选取照片」，从相册里找到刚保存的图。单张图下方有名字；最后一张「图标总览」可以当对照表。",
        "用双指把取景框缩到圆角图标上，不要把下面的名字裁进去。",
        "点「添加」。新图标会出现在主屏幕最后。",
        "长按主屏幕进入编辑，把它拖到「布局」页导出的预览图对应的位置。原来的官方图标可以放进 App 资源库。",
        "这个图标实际打开的是快捷指令，会先闪一下再进入 App。这是 iOS 允许的换图标方式。不要删掉那条快捷指令，删了图标就会失效。"
    ]

    var body: some View {
        List {
            Section {
                Text("DeskStyle 不能改其他 App 的图标。下面是用「快捷指令 → 添加到主屏幕」逐个替换的步骤。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Section("步骤") {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .frame(width: 28, height: 28)
                            .background(Color.secondary.opacity(0.15), in: Circle())
                        Text(step)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("换图标步骤")
        .navigationBarTitleDisplayMode(.inline)
    }
}
