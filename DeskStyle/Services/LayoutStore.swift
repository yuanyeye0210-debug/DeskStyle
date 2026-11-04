import UIKit

struct LayoutStore {
    private let fileManager = FileManager.default

    var planURL: URL {
        documents.appendingPathComponent("layout-plan.json")
    }

    private var backupURL: URL {
        documents.appendingPathComponent("layout-plan.backup.json")
    }

    private var wallpaperURL: URL {
        support.appendingPathComponent("wallpaper.jpg")
    }

    private var documents: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var support: URL {
        let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func load() -> LayoutPlan? {
        guard let data = try? Data(contentsOf: planURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(LayoutPlan.self, from: data)
    }

    func save(_ plan: LayoutPlan) {
        if fileManager.fileExists(atPath: planURL.path) {
            try? fileManager.removeItem(at: backupURL)
            try? fileManager.copyItem(at: planURL, to: backupURL)
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(plan) else { return }
        try? data.write(to: planURL, options: .atomic)
    }

    func loadWallpaper() -> UIImage? {
        guard let data = try? Data(contentsOf: wallpaperURL) else { return nil }
        return UIImage(data: data)
    }

    func saveWallpaper(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: wallpaperURL, options: .atomic)
    }
}
