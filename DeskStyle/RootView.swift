import SwiftUI

struct RootView: View {
    @StateObject private var session = AppSession()

    var body: some View {
        TabView {
            ScreenshotAnalysisView()
                .tabItem { Label("分析", systemImage: "viewfinder") }
            StyleGalleryView()
                .tabItem { Label("风格", systemImage: "paintpalette") }
            WallpaperStudioView()
                .tabItem { Label("壁纸", systemImage: "photo.on.rectangle.angled") }
            IconPackView()
                .tabItem { Label("图标", systemImage: "square.grid.2x2") }
            LayoutPreviewView()
                .tabItem { Label("布局", systemImage: "square.grid.3x3") }
        }
        .environmentObject(session)
        .tint(session.style.accentColor)
    }
}
