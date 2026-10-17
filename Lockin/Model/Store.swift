import Foundation
import Observation

/// Everything the app keeps, saved as one JSON file in Documents.
@Observable
final class Store {
    var profile: Profile? { didSet { save() } }
    var sessions: [StudySession] = [] { didSet { save() } }
    var friends: [FriendPost] = [] { didSet { save() } }
    var joinedClubs: Set<String> = [] { didSet { save() } }
    var joinedChallenges: Set<String> = [] { didSet { save() } }

    /// Friends studying right now, started a few minutes before launch.
    let liveNow: [LiveFriend]

    @ObservationIgnored private let fileURL: URL?
    @ObservationIgnored private var loading = false

    private struct Saved: Codable {
        var profile: Profile?
        var sessions: [StudySession]
        var friends: [FriendPost]
        var joinedClubs: Set<String>
        var joinedChallenges: Set<String>
    }

    /// `fileURL` nil keeps everything in memory (tests and previews).
    init(fileURL: URL? = Store.defaultURL, now: Date = .now) {
        self.fileURL = fileURL
        liveNow = [
            LiveFriend(name: "Dev Patel", subject: "Fixed Income", since: now.addingTimeInterval(-62 * 60)),
            LiveFriend(name: "Hana Kim", subject: "FSA", since: now.addingTimeInterval(-24 * 60)),
            LiveFriend(name: "Jordan Lee", subject: "AP Bio", since: now.addingTimeInterval(-41 * 60)),
            LiveFriend(name: "Priya Shah", subject: "Ethics", since: now.addingTimeInterval(-9 * 60)),
            LiveFriend(name: "Theo Brooks", subject: "Calculus", since: now.addingTimeInterval(-77 * 60)),
        ]
        load(now: now)
    }

    static var defaultURL: URL {
        URL.documentsDirectory.appending(path: "lockin.json")
    }

    private func load(now: Date) {
        loading = true
        defer { loading = false }
        if let fileURL, let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(Saved.self, from: data) {
            profile = saved.profile
            sessions = saved.sessions
            friends = saved.friends
            joinedClubs = saved.joinedClubs
            joinedChallenges = saved.joinedChallenges
        } else {
            friends = Seed.friendPosts(now: now)
            joinedClubs = ["cfa-feb", "5am"]
        }
    }

    private func save() {
        guard !loading, let fileURL else { return }
        let saved = Saved(profile: profile, sessions: sessions, friends: friends,
                          joinedClubs: joinedClubs, joinedChallenges: joinedChallenges)
        try? JSONEncoder().encode(saved).write(to: fileURL, options: .atomic)
    }

    // MARK: Changes

    func add(_ session: StudySession) {
        sessions.append(session)
        sessions.sort { $0.start > $1.start }
    }

    func delete(_ session: StudySession) {
        session.photoFiles.forEach(PhotoStore.delete)
        sessions.removeAll { $0.id == session.id }
    }

    func toggleKudos(_ post: FriendPost) {
        guard let index = friends.firstIndex(where: { $0.id == post.id }) else { return }
        friends[index].kudoed.toggle()
        friends[index].kudos += friends[index].kudoed ? 1 : -1
    }

    func toggle(club id: String) {
        if joinedClubs.contains(id) { joinedClubs.remove(id) } else { joinedClubs.insert(id) }
    }

    func toggle(challenge id: String) {
        if joinedChallenges.contains(id) { joinedChallenges.remove(id) } else { joinedChallenges.insert(id) }
    }

    func reset() {
        sessions.forEach { $0.photoFiles.forEach(PhotoStore.delete) }
        sessions = []
        friends = Seed.friendPosts(now: .now)
        joinedChallenges = []
        joinedClubs = ["cfa-feb", "5am"]
        profile = nil
    }

    // MARK: Stats

    private var calendar: Calendar { .current }

    var totalSeconds: Int { sessions.reduce(0) { $0 + $1.focusSeconds } }

    func seconds(in interval: DateInterval) -> Int {
        sessions.filter { interval.contains($0.start) }.reduce(0) { $0 + $1.focusSeconds }
    }

    func weekSeconds(now: Date = .now) -> Int {
        seconds(in: calendar.dateInterval(of: .weekOfYear, for: now)!)
    }

    func monthSeconds(now: Date = .now) -> Int {
        seconds(in: calendar.dateInterval(of: .month, for: now)!)
    }

    /// Focus seconds for each of the last `weeks` weeks, oldest first.
    func weeklySeconds(weeks: Int, now: Date = .now) -> [(start: Date, seconds: Int)] {
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)!.start
        return (0..<weeks).reversed().map { back in
            let start = calendar.date(byAdding: .weekOfYear, value: -back, to: thisWeek)!
            let interval = DateInterval(start: start, duration: 7 * 86_400)
            return (start, seconds(in: interval))
        }
    }

    /// Focus seconds per day, keyed by the start of the day.
    var dailySeconds: [Date: Int] {
        sessions.reduce(into: [:]) { $0[calendar.startOfDay(for: $1.start), default: 0] += $1.focusSeconds }
    }

    /// Days in a row with a session, counting today or, if nothing yet today, yesterday.
    func streak(now: Date = .now) -> Int {
        let days = Set(sessions.map { calendar.startOfDay(for: $0.start) })
        var day = calendar.startOfDay(for: now)
        if !days.contains(day) { day = calendar.date(byAdding: .day, value: -1, to: day)! }
        var count = 0
        while days.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    func subjectSeconds() -> [(subject: String, seconds: Int)] {
        let totals = sessions.reduce(into: [String: Int]()) { $0[$1.subject, default: 0] += $1.focusSeconds }
        return totals.map { ($0.key, $0.value) }.sorted { $0.seconds > $1.seconds }
    }

    struct Bests {
        var longest: StudySession?
        var fastest: StudySession?
        var mostQuestions: StudySession?
    }

    var bests: Bests {
        let paced = sessions.filter { $0.questions >= 10 }
        return Bests(longest: sessions.max { $0.focusSeconds < $1.focusSeconds },
                     fastest: paced.min { $0.pace! < $1.pace! },
                     mostQuestions: paced.max { $0.questions < $1.questions })
    }

    /// Personal records this session set against everything before it.
    func records(for session: StudySession) -> [String] {
        let prior = sessions.filter { $0.id != session.id && $0.start < session.start }
        if prior.isEmpty { return ["First lock-in"] }
        var records: [String] = []
        if session.focusSeconds >= 600, session.focusSeconds > prior.map(\.focusSeconds).max()! {
            records.append("Longest focus")
        }
        if session.questions >= 10, let pace = session.pace {
            let best = prior.filter { $0.questions >= 10 }.compactMap(\.pace).min()
            if best.map({ pace < $0 }) ?? true { records.append("Fastest pace") }
        }
        if session.questions >= 10, session.questions > (prior.map(\.questions).max() ?? 0) {
            records.append("Most questions")
        }
        return records
    }

    /// The leaderboard: seeded club members plus you, this week.
    func leaderboard(now: Date = .now) -> [ClubMember] {
        let week = calendar.dateInterval(of: .weekOfYear, for: now)!
        let mine = sessions.filter { week.contains($0.start) && $0.countsForClub }
        let questions = mine.reduce(0) { $0 + $1.questions }
        let correct = mine.reduce(0) { $0 + $1.correct }
        let you = ClubMember(name: profile?.name ?? "You", tagline: profile?.focus ?? "",
                             weekSeconds: mine.reduce(0) { $0 + $1.focusSeconds }, questions: questions,
                             accuracy: questions == 0 ? 0 : Double(correct) / Double(questions), isYou: true)
        return Seed.members + [you]
    }
}
