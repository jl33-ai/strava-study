import SwiftUI

extension Color {
    static let ink = Color(red: 0x11 / 255, green: 0x11 / 255, blue: 0x11 / 255)
    static let lime = Color(red: 0xD7 / 255, green: 1, blue: 0x3C / 255)
    static let cobalt = Color(red: 0x2B / 255, green: 0x45 / 255, blue: 1)
    static let surface = Color(red: 0xF3 / 255, green: 0xF3 / 255, blue: 0xF0 / 255)
    static let hairline = Color.black.opacity(0.08)
    static let muted = Color.black.opacity(0.5)
}

extension Font {
    /// The wide display face used for numbers and headings.
    static func wide(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight).width(.expanded)
    }
}

enum Fmt {
    /// 1:42:06 or 42:06.
    static func clock(_ seconds: Int) -> String {
        let h = seconds / 3600, m = seconds / 60 % 60, s = seconds % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// 1h 42m or 42m.
    static func duration(_ seconds: Int) -> String {
        let h = seconds / 3600, m = seconds / 60 % 60
        if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
        return seconds < 60 && seconds > 0 ? "\(seconds)s" : "\(m)m"
    }

    static func hours(_ seconds: Int) -> String {
        let h = Double(seconds) / 3600
        return h >= 10 ? String(format: "%.0f", h) : String(format: "%.1f", h)
    }

    /// Seconds per question as m:ss.
    static func pace(_ seconds: Double?) -> String {
        guard let seconds else { return "–" }
        return clock(Int(seconds.rounded()))
    }

    static func percent(_ value: Double?) -> String {
        guard let value else { return "–" }
        return "\(Int((value * 100).rounded()))%"
    }

    static func when(_ date: Date) -> String {
        let calendar = Calendar.current
        let time = date.formatted(date: .omitted, time: .shortened)
        if calendar.isDateInToday(date) { return "Today at \(time)" }
        if calendar.isDateInYesterday(date) { return "Yesterday at \(time)" }
        return date.formatted(.dateTime.month(.abbreviated).day()) + " at \(time)"
    }
}

struct Card: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View { modifier(Card(padding: padding)) }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func thud() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
}
