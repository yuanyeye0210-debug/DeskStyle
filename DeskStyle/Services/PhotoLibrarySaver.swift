import Photos
import UIKit

enum PhotoSaveError: LocalizedError {
    case denied

    var errorDescription: String? {
        "没有获得添加照片的权限。请到系统设置里允许「桌面美化」添加照片。"
    }
}

enum PhotoLibrarySaver {
    static func save(_ images: [UIImage]) async throws {
        let allowed = await authorize()
        guard allowed else { throw PhotoSaveError.denied }
        try await PHPhotoLibrary.shared().performChanges {
            for image in images {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
        }
    }

    private static func authorize() async -> Bool {
        let current = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch current {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let updated = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return updated == .authorized || updated == .limited
        default:
            return false
        }
    }
}
