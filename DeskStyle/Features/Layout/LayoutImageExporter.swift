import UIKit

enum LayoutImageExporter {
    static func pageImage(
        plan: LayoutPlan,
        style: StylePreset,
        wallpaper: UIImage?,
        pageIndex: Int,
        pointSize: CGSize,
        scale: CGFloat
    ) -> UIImage {
        renderPages(
            plan: plan,
            style: style,
            wallpaper: wallpaper,
            pageIndexes: [min(pageIndex, max(0, plan.pages.count - 1))],
            pointSize: pointSize,
            scale: scale
        )
    }

    static func allPagesImage(
        plan: LayoutPlan,
        style: StylePreset,
        wallpaper: UIImage?,
        pointSize: CGSize,
        scale: CGFloat
    ) -> UIImage {
        let indexes = plan.pages.isEmpty ? [0] : Array(plan.pages.indices)
        return renderPages(
            plan: plan,
            style: style,
            wallpaper: wallpaper,
            pageIndexes: indexes,
            pointSize: pointSize,
            scale: scale
        )
    }

    private static func renderPages(
        plan: LayoutPlan,
        style: StylePreset,
        wallpaper: UIImage?,
        pageIndexes: [Int],
        pointSize: CGSize,
        scale: CGFloat
    ) -> UIImage {
        let gap: CGFloat = 28
        let height = pointSize.height * CGFloat(pageIndexes.count) + gap * CGFloat(max(0, pageIndexes.count - 1))
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: pointSize.width, height: height), format: format)
        return renderer.image { _ in
            for (offset, pageIndex) in pageIndexes.enumerated() {
                let origin = CGPoint(x: 0, y: CGFloat(offset) * (pointSize.height + gap))
                drawPage(
                    plan: plan,
                    style: style,
                    wallpaper: wallpaper,
                    pageIndex: pageIndex,
                    in: CGRect(origin: origin, size: pointSize)
                )
            }
        }
    }

    private static func drawPage(
        plan: LayoutPlan,
        style: StylePreset,
        wallpaper: UIImage?,
        pageIndex: Int,
        in rect: CGRect
    ) {
        if let wallpaper {
            wallpaper.draw(in: rect)
        } else {
            UIColor(hex: style.backgroundHex).setFill()
            UIRectFill(rect)
            let colors = [UIColor(hex: style.secondaryHex).withAlphaComponent(0.85).cgColor, UIColor.clear.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                UIGraphicsGetCurrentContext()?.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: rect.minX, y: rect.minY),
                    end: CGPoint(x: rect.maxX, y: rect.maxY),
                    options: []
                )
            }
        }

        let title = "第 \(pageIndex + 1) 页 · \(style.name)"
        let titleRect = CGRect(x: rect.minX + 24, y: rect.minY + rect.height * 0.055, width: rect.width - 48, height: 44)
        let pill = UIBezierPath(roundedRect: titleRect, cornerRadius: 14)
        UIColor(white: 0, alpha: 0.28).setFill()
        pill.fill()
        drawLabel(title, in: titleRect, size: 20, color: .white, weight: .semibold)

        let columns = CGFloat(plan.grid.columns)
        let contentRows = CGFloat(max(plan.grid.dockRow, 1))
        let marginX = rect.width * 0.045
        let top = rect.minY + rect.height * 0.14
        let dockHeight = rect.height * 0.11
        let bottom = rect.maxY - rect.height * 0.035
        let gridHeight = bottom - dockHeight - 16 - top
        let cellWidth = (rect.width - marginX * 2) / columns
        let cellHeight = gridHeight / contentRows
        let page = plan.pages.indices.contains(pageIndex) ? plan.pages[pageIndex] : nil

        for row in 0..<plan.grid.dockRow {
            for column in 0..<plan.grid.columns {
                let cell = CGRect(
                    x: rect.minX + marginX + CGFloat(column) * cellWidth + 4,
                    y: top + CGFloat(row) * cellHeight + 4,
                    width: cellWidth - 8,
                    height: cellHeight - 8
                )
                let slot = UIBezierPath(roundedRect: cell, cornerRadius: 10)
                UIColor(white: 1, alpha: 0.08).setStroke()
                slot.lineWidth = 1
                slot.stroke()
            }
        }

        for item in page?.items ?? [] {
            let frame = CGRect(
                x: rect.minX + marginX + CGFloat(item.column) * cellWidth + 5,
                y: top + CGFloat(item.row) * cellHeight + 5,
                width: cellWidth * CGFloat(item.columnSpan) - 10,
                height: cellHeight * CGFloat(item.rowSpan) - 10
            )
            draw(item, style: style, in: frame)
        }

        let dockY = top + gridHeight + 16
        for column in 0..<plan.grid.columns {
            let frame = CGRect(
                x: rect.minX + marginX + CGFloat(column) * cellWidth + 5,
                y: dockY,
                width: cellWidth - 10,
                height: dockHeight - 8
            )
            if let item = plan.dock.first(where: { $0.column == column }) {
                draw(item, style: style, in: frame)
            }
        }
    }

    private static func draw(_ item: LayoutItem, style: StylePreset, in rect: CGRect) {
        switch item.kind {
        case .app:
            let side = min(rect.width, rect.height * 0.72)
            let iconRect = CGRect(x: rect.midX - side / 2, y: rect.minY, width: side, height: side)
            IconRenderer.drawIcon(name: item.name, style: style, in: iconRect)
            drawLabel(
                item.name,
                in: CGRect(x: rect.minX, y: iconRect.maxY + 2, width: rect.width, height: rect.maxY - iconRect.maxY - 2),
                size: max(9, min(13, rect.width * 0.16)),
                color: .white,
                weight: .medium
            )
        case .folder:
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 16)
            UIColor(white: 1, alpha: 0.2).setFill()
            path.fill()
            let children = item.children ?? []
            for index in children.prefix(4).indices {
                let child = children[index]
                let column = index % 2
                let row = index / 2
                let mini = CGRect(
                    x: rect.minX + 10 + CGFloat(column) * (rect.width * 0.42),
                    y: rect.minY + 8 + CGFloat(row) * (rect.height * 0.34),
                    width: rect.width * 0.34,
                    height: rect.height * 0.28
                )
                drawLabel(String(child.prefix(1)), in: mini, size: 12, color: .white, weight: .bold)
            }
            drawLabel(item.name, in: CGRect(x: rect.minX, y: rect.maxY - 18, width: rect.width, height: 16), size: 11, color: .white, weight: .semibold)
        case .widget:
            let path = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 18)
            UIColor(hex: style.secondaryHex).withAlphaComponent(0.88).setFill()
            path.fill()
            drawLabel(item.name, in: rect.insetBy(dx: 10, dy: 8), size: max(13, min(22, rect.width * 0.12)), color: UIColor(hex: style.textHex), weight: .semibold)
            drawLabel(
                "小组件",
                in: CGRect(x: rect.minX + 10, y: rect.maxY - 28, width: rect.width - 20, height: 18),
                size: 12,
                color: UIColor(hex: style.textHex).withAlphaComponent(0.7),
                weight: .regular
            )
        }
    }

    private static func drawLabel(_ text: String, in rect: CGRect, size: CGFloat, color: UIColor, weight: UIFont.Weight) {
        guard rect.width > 2, rect.height > 2 else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let string = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: size, weight: weight),
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )
        string.draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine],
            context: nil
        )
    }
}
