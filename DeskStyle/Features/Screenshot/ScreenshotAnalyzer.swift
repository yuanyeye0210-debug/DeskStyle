import UIKit
import Vision

enum ScreenshotAnalyzer {
    static func analyze(_ image: UIImage) async -> [LibraryApp] {
        guard let data = normalizedJPEG(from: image) else { return [] }
        return await Task.detached(priority: .userInitiated) {
            guard let decoded = UIImage(data: data), let cgImage = decoded.cgImage else { return [] }
            return recognize(cgImage)
        }.value
    }

    private static func normalizedJPEG(from image: UIImage) -> Data? {
        let maxSide: CGFloat = 1400
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let size = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let upright = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return upright.jpegData(compressionQuality: 0.86)
    }

    private static func recognize(_ cgImage: CGImage) -> [LibraryApp] {
        let observations = performRequest(on: cgImage)
        var candidates: [Candidate] = []
        for observation in observations {
            guard let top = observation.topCandidates(1).first else { continue }
            let text = top.string
                .replacingOccurrences(of: "\n", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let box = observation.boundingBox
            let width = box.width
            let height = box.height
            let midX = box.midX
            let midY = 1 - box.midY
            guard accept(text, width: width, height: height, midY: midY) else { continue }
            let color = AppCatalog.knownColorHex(for: text) ?? sampleColor(cgImage, above: box)
            candidates.append(
                Candidate(text: text, midX: midX, midY: midY, confidence: Double(top.confidence), colorHex: color)
            )
        }
        let unique = dedupe(candidates)
        return layout(unique)
    }

    private static func performRequest(on cgImage: CGImage) -> [VNRecognizedTextObservation] {
        let request = makeRequest(languages: ["zh-Hans", "en-US"])
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        if (try? handler.perform([request])) != nil {
            return request.results ?? []
        }
        let retry = makeRequest(languages: [])
        let retryHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? retryHandler.perform([retry])
        return retry.results ?? []
    }

    private static func makeRequest(languages: [String]) -> VNRecognizeTextRequest {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.customWords = AppCatalog.recognitionWords
        if !languages.isEmpty {
            request.recognitionLanguages = languages
        }
        return request
    }

    private static func accept(_ text: String, width: CGFloat, height: CGFloat, midY: CGFloat) -> Bool {
        guard text.count <= 12 else { return false }
        if text.count == 1 && text.caseInsensitiveCompare("X") != .orderedSame { return false }
        guard height >= 0.008, height <= 0.05, width <= 0.34 else { return false }
        guard midY >= 0.045, midY <= 0.98 else { return false }
        let lowered = text.lowercased()
        if ["搜索", "search", "编辑", "完成"].contains(lowered) { return false }
        if lowered.range(of: #"^\d{1,2}:\d{2}$"#, options: .regularExpression) != nil { return false }
        if lowered.range(of: #"^\d{1,3}%$"#, options: .regularExpression) != nil { return false }
        let meaningful = text.unicodeScalars.contains {
            CharacterSet.letters.contains($0) || CharacterSet.decimalDigits.contains($0)
        }
        return meaningful
    }

    private static func sampleColor(_ cgImage: CGImage, above box: CGRect) -> String {
        let aspect = CGFloat(cgImage.width) / CGFloat(max(cgImage.height, 1))
        let iconWidth = min(0.2, max(0.08, box.width * 1.45))
        let iconHeight = min(0.16, iconWidth * aspect)
        let midX = box.midX
        let top = 1 - box.maxY
        var rect = CGRect(
            x: midX - iconWidth / 2,
            y: top - iconHeight - box.height * 0.35,
            width: iconWidth,
            height: iconHeight
        ).insetBy(dx: iconWidth * 0.18, dy: iconHeight * 0.18)
        rect.origin.x = min(max(0, rect.origin.x), 1)
        rect.origin.y = min(max(0, rect.origin.y), 1)
        rect.size.width = min(rect.width, 1 - rect.origin.x)
        rect.size.height = min(rect.height, 1 - rect.origin.y)
        guard rect.width > 0.01, rect.height > 0.01 else { return "888888" }
        return averageHex(cgImage, normalizedTopLeft: rect)
    }

    private static func averageHex(_ cgImage: CGImage, normalizedTopLeft rect: CGRect) -> String {
        let sample = 16
        var pixels = [UInt8](repeating: 0, count: sample * sample * 4)
        let drew = pixels.withUnsafeMutableBytes { raw -> Bool in
            guard let context = CGContext(
                data: raw.baseAddress,
                width: sample,
                height: sample,
                bitsPerComponent: 8,
                bytesPerRow: sample * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            let pixelWidth = CGFloat(cgImage.width)
            let pixelHeight = CGFloat(cgImage.height)
            let crop = CGRect(
                x: rect.minX * pixelWidth,
                y: (1 - rect.maxY) * pixelHeight,
                width: rect.width * pixelWidth,
                height: rect.height * pixelHeight
            )
            guard let cropped = cgImage.cropping(to: crop.integral) else { return false }
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: sample, height: sample))
            return true
        }
        guard drew else { return "888888" }
        var red = 0
        var green = 0
        var blue = 0
        var count = 0
        for index in stride(from: 0, to: pixels.count, by: 4) {
            guard pixels[index + 3] > 16 else { continue }
            red += Int(pixels[index])
            green += Int(pixels[index + 1])
            blue += Int(pixels[index + 2])
            count += 1
        }
        guard count > 0 else { return "888888" }
        return String(format: "%02X%02X%02X", red / count, green / count, blue / count)
    }

    private static func dedupe(_ candidates: [Candidate]) -> [Candidate] {
        var best: [String: Candidate] = [:]
        for candidate in candidates {
            let key = candidate.text.lowercased()
            if let existing = best[key], existing.confidence >= candidate.confidence {
                continue
            }
            best[key] = candidate
        }
        return Array(best.values)
    }

    private static func layout(_ candidates: [Candidate]) -> [LibraryApp] {
        let dock = candidates.filter { $0.midY >= 0.86 }.sorted { $0.midX < $1.midX }
        let grid = candidates.filter { $0.midY < 0.86 }.sorted { $0.midY < $1.midY }
        var rows: [[Candidate]] = []
        for candidate in grid {
            if let lastY = rows.last?.map(\.midY).max(), abs(candidate.midY - lastY) < 0.05 {
                rows[rows.count - 1].append(candidate)
            } else {
                rows.append([candidate])
            }
        }
        var apps: [LibraryApp] = []
        for (rowIndex, row) in rows.enumerated() {
            let mappedRow: Int
            if rows.count <= 5 {
                mappedRow = rowIndex
            } else {
                mappedRow = min(4, rowIndex * 5 / rows.count)
            }
            let ordered = row.sorted { $0.midX < $1.midX }
            var used = Set<Int>()
            for (index, candidate) in ordered.enumerated() {
                var column = columnIndex(midX: candidate.midX, count: ordered.count, index: index)
                while used.contains(column), column < 3 {
                    column += 1
                }
                used.insert(column)
                apps.append(makeApp(candidate, column: column, row: mappedRow, zone: .grid))
            }
        }
        var usedDock = Set<Int>()
        for (index, candidate) in dock.enumerated() {
            var column = columnIndex(midX: candidate.midX, count: dock.count, index: index)
            while usedDock.contains(column), column < 3 {
                column += 1
            }
            usedDock.insert(column)
            apps.append(makeApp(candidate, column: column, row: nil, zone: .dock))
        }
        return apps
    }

    private static func columnIndex(midX: CGFloat, count: Int, index: Int) -> Int {
        if count >= 4 {
            return min(3, index)
        }
        return min(3, max(0, Int(midX * 4)))
    }

    private static func makeApp(_ candidate: Candidate, column: Int, row: Int?, zone: LayoutZone) -> LibraryApp {
        LibraryApp(
            id: UUID(),
            name: candidate.text,
            category: AppCatalog.category(for: candidate.text),
            colorHex: candidate.colorHex,
            column: column,
            row: row,
            zone: zone,
            confidence: candidate.confidence,
            source: "vision"
        )
    }

    private struct Candidate {
        var text: String
        var midX: CGFloat
        var midY: CGFloat
        var confidence: Double
        var colorHex: String
    }
}
