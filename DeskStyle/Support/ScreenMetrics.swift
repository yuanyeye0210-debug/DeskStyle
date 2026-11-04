import UIKit

@MainActor
enum ScreenMetrics {
    static var pointSize: CGSize {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen.bounds.size ?? CGSize(width: 390, height: 844)
    }

    static var scale: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen.scale ?? 3
    }

    static func snapshot() -> ScreenSnapshot {
        let size = pointSize
        return ScreenSnapshot(widthPoints: size.width, heightPoints: size.height, scale: scale)
    }
}
