import SwiftUI

struct Avatar: View {
    let name: String
    var size: CGFloat = 40
    var ring = false

    private static let palette: [Color] = [
        .cobalt, Color(red: 0.95, green: 0.42, blue: 0.25), Color(red: 0.1, green: 0.58, blue: 0.44),
        Color(red: 0.55, green: 0.35, blue: 0.9), Color(red: 0.88, green: 0.28, blue: 0.52), .ink,
    ]

    var body: some View {
        let index = name.unicodeScalars.reduce(0) { $0 + Int($1.value) } % Self.palette.count
        Text(initials)
            .font(.wide(size * 0.36, .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Self.palette[index], in: Circle())
            .overlay {
                if ring { Circle().stroke(Color.lime, lineWidth: 3).padding(-4) }
            }
    }

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
}

struct Stat: View {
    let label: String
    let value: String
    var dark = false
    var size: CGFloat = 18

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(dark ? Color.white.opacity(0.5) : Color.muted)
            Text(value)
                .font(.wide(size))
                .foregroundStyle(dark ? Color.white : Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Chip: View {
    let title: String
    let selected: Bool
    var dark = false
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .foregroundStyle(selected ? Color.ink : (dark ? Color.white : Color.ink))
                .background(selected ? Color.lime : (dark ? Color.white.opacity(0.08) : Color.white), in: Capsule())
                .overlay(Capsule().stroke(selected ? Color.clear : (dark ? Color.white.opacity(0.15) : Color.hairline)))
        }
        .buttonStyle(.plain)
    }
}

struct SectionTitle: View {
    let text: String
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text).font(.wide(17))
            Spacer()
            if let trailing {
                Text(trailing).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.muted)
            }
        }
        .padding(.top, 8)
    }
}

struct Badge: View {
    let text: String
    var body: some View {
        Label(text, systemImage: "trophy.fill")
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(Color.ink)
            .background(Color.lime, in: Capsule())
    }
}

struct PrimaryButton: View {
    let title: String
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.wide(16))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .foregroundStyle(enabled ? Color.lime : Color.white.opacity(0.6))
                .background(enabled ? Color.ink : Color.ink.opacity(0.3), in: Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Lays children out left to right, wrapping onto new rows.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            widest = max(widest, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Seconds per question in each split, as small bars.
struct SplitBars: View {
    let splits: [Split]
    var height: CGFloat = 36

    var body: some View {
        let slowest = splits.map(\.pace).max() ?? 1
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(splits) { split in
                RoundedRectangle(cornerRadius: 3)
                    .fill(split == fastest ? Color.cobalt : Color.ink.opacity(0.18))
                    .frame(maxWidth: 22)
                    .frame(height: max(4, height * split.pace / slowest))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: height, alignment: .bottom)
    }

    private var fastest: Split? { splits.min { $0.pace < $1.pace } }
}

struct SessionPhoto: View {
    let file: String
    var body: some View {
        if let image = PhotoStore.image(file) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Color.surface
        }
    }
}
