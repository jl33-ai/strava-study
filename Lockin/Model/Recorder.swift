import Foundation
import Observation

/// The session being recorded. Kept in UserDefaults so a killed app picks it back up.
@Observable
final class Recorder {
    struct Live: Codable {
        var subject: String
        var startedAt: Date
        /// Focus time banked before the current run.
        var banked: TimeInterval = 0
        /// When the clock last started; nil while paused.
        var runningSince: Date?
        var answers: [Answer] = []
        var pauses = 0
        var pickups = 0
    }

    var live: Live? { didSet { persist() } }
    /// Whether the record screen is up (the session keeps going while it's minimised).
    var isPresented = false

    @ObservationIgnored private let defaults: UserDefaults?
    private static let key = "lockin.live"

    init(defaults: UserDefaults? = .standard) {
        self.defaults = defaults
        if let data = defaults?.data(forKey: Self.key) {
            live = try? JSONDecoder().decode(Live.self, from: data)
        }
    }

    private func persist() {
        if let live, let data = try? JSONEncoder().encode(live) {
            defaults?.set(data, forKey: Self.key)
        } else {
            defaults?.removeObject(forKey: Self.key)
        }
    }

    var isActive: Bool { live != nil }
    var isRunning: Bool { live?.runningSince != nil }

    func elapsed(at now: Date = .now) -> TimeInterval {
        guard let live else { return 0 }
        return live.banked + (live.runningSince.map { now.timeIntervalSince($0) } ?? 0)
    }

    func start(subject: String, now: Date = .now) {
        live = Live(subject: subject, startedAt: now, runningSince: now)
    }

    func pause(now: Date = .now) {
        guard var current = live, let since = current.runningSince else { return }
        current.banked += now.timeIntervalSince(since)
        current.runningSince = nil
        current.pauses += 1
        live = current
    }

    func resume(now: Date = .now) {
        guard live != nil, !isRunning else { return }
        live?.runningSince = now
    }

    func answer(correct: Bool, now: Date = .now) {
        guard live != nil else { return }
        let at = Int(elapsed(at: now))
        live?.answers.append(Answer(correct: correct, at: at))
    }

    func undoAnswer() {
        guard live?.answers.isEmpty == false else { return }
        live?.answers.removeLast()
    }

    /// The app went to the background while the clock ran: a phone pickup.
    func noteLeftApp() {
        if isRunning { live?.pickups += 1 }
    }

    /// Stops the clock and returns the session to save.
    func draft(now: Date = .now) -> StudySession? {
        if isRunning { pause(now: now); live?.pauses -= 1 }
        guard let live else { return nil }
        return StudySession(title: Self.defaultTitle(subject: live.subject, at: live.startedAt),
                            subject: live.subject, start: live.startedAt, end: now,
                            focusSeconds: Int(live.banked), pauses: live.pauses, pickups: live.pickups,
                            answers: live.answers)
    }

    func discard() {
        live = nil
    }

    static func defaultTitle(subject: String, at date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let part = switch hour {
        case 4..<12: "Morning"
        case 12..<17: "Afternoon"
        case 17..<21: "Evening"
        default: "Late-night"
        }
        return "\(part) \(subject) lock-in"
    }
}
