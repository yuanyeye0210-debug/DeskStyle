import SwiftUI
import UIKit

struct HomeScreenPreview: View {
    @EnvironmentObject private var session: AppSession
    let pageIndex: Int
    @Binding var selectedID: UUID?

    var body: some View {
        VStack(spacing: 8) {
            Text("第 \(pageIndex + 1) 页 · \(session.style.name)")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.black.opacity(0.28), in: Capsule())
                .foregroundStyle(.white)
            GeometryReader { geo in
                grid(in: geo.size)
            }
            .frame(minHeight: 280)
            dock
        }
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [session.style.backgroundColor, session.style.secondaryColor],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            if let wallpaper = session.wallpaperImage {
                Image(uiImage: wallpaper)
                    .resizable()
                    .scaledToFill()
            }
        }
    }

    private var pageItems: [LayoutItem] {
        guard session.plan.pages.indices.contains(pageIndex) else { return [] }
        return session.plan.pages[pageIndex].items
    }

    private func grid(in size: CGSize) -> some View {
        let columns = session.plan.grid.columns
        let rows = session.plan.grid.dockRow
        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = size.height / CGFloat(max(rows, 1))
        return ZStack(alignment: .topLeading) {
            ForEach(0..<rows, id: \.self) { row in
                ForEach(0..<columns, id: \.self) { column in
                    GridDropCell(pageIndex: pageIndex, column: column, row: row)
                        .frame(width: cellWidth - 6, height: cellHeight - 6)
                        .position(
                            x: cellWidth * (CGFloat(column) + 0.5),
                            y: cellHeight * (CGFloat(row) + 0.5)
                        )
                }
            }
            ForEach(pageItems) { item in
                PlacedLayoutItem(item: item, pageIndex: pageIndex, selectedID: $selectedID)
                    .frame(
                        width: cellWidth * CGFloat(item.columnSpan) - 8,
                        height: cellHeight * CGFloat(item.rowSpan) - 8
                    )
                    .position(
                        x: cellWidth * (CGFloat(item.column) + CGFloat(item.columnSpan) / 2),
                        y: cellHeight * (CGFloat(item.row) + CGFloat(item.rowSpan) / 2)
                    )
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private var dock: some View {
        HStack(spacing: 8) {
            ForEach(0..<session.plan.grid.columns, id: \.self) { column in
                dockSlot(column)
            }
        }
        .padding(8)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder
    private func dockSlot(_ column: Int) -> some View {
        if let item = session.plan.dock.first(where: { $0.column == column }) {
            PlacedLayoutItem(item: item, pageIndex: 0, selectedID: $selectedID)
                .frame(maxWidth: .infinity, minHeight: 58)
        } else {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(maxWidth: .infinity, minHeight: 58)
                .contentShape(Rectangle())
                .dropDestination(for: String.self) { items, _ in
                    guard let id = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                    return session.move(id: id, toPage: 0, column: column, row: session.plan.grid.dockRow)
                }
        }
    }
}

private struct GridDropCell: View {
    @EnvironmentObject private var session: AppSession
    let pageIndex: Int
    let column: Int
    let row: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(Color.white.opacity(0.18), lineWidth: 1)
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { items, _ in
                guard let id = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                return session.move(id: id, toPage: pageIndex, column: column, row: row)
            }
    }
}

private struct PlacedLayoutItem: View {
    @EnvironmentObject private var session: AppSession
    let item: LayoutItem
    let pageIndex: Int
    @Binding var selectedID: UUID?

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { selectedID = item.id }
            .draggable(item.id.uuidString)
            .dropDestination(for: String.self) { items, _ in
                guard let id = items.first.flatMap(UUID.init(uuidString:)) else { return false }
                return session.move(id: id, toPage: pageIndex, column: item.column, row: item.row)
            }
            .overlay {
                if selectedID == item.id {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white, lineWidth: 2)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .app:
            VStack(spacing: 2) {
                iconSquare(title: String(item.name.prefix(1)), symbol: item.symbolName, hex: IconPalette.hex(name: item.name, style: session.style))
                Text(item.name)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
        case .folder:
            VStack(spacing: 2) {
                folderFace
                Text(item.name)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .foregroundStyle(.white)
            }
        case .widget:
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(session.style.secondaryColor.opacity(0.9))
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: item.symbolName ?? "square.dashed")
                        Text(item.name)
                            .font(.headline)
                        Text("小组件")
                            .font(.caption)
                    }
                    .foregroundStyle(session.style.textColor)
                    .padding(10)
                }
        }
    }

    private var folderFace: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.22))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                let children = item.children ?? []
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        mini(children, 0)
                        mini(children, 1)
                    }
                    HStack(spacing: 2) {
                        mini(children, 2)
                        mini(children, 3)
                    }
                }
                .padding(4)
            }
    }

    private func mini(_ children: [String], _ index: Int) -> some View {
        Text(index < children.count ? String(children[index].prefix(1)) : "")
            .font(.system(size: 8, weight: .bold))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.white)
    }

    private func iconSquare(title: String, symbol: String?, hex: String) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(hex: hex))
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Group {
                    if let symbol {
                        Image(systemName: symbol)
                    } else {
                        Text(title)
                    }
                }
                .font(.system(size: 16, weight: .semibold, design: session.style.fontDesign.swiftUI))
                .foregroundStyle(Color(hex: hex).isLight ? Color.black : Color.white)
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
