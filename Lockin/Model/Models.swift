import Foundation

/// What the reader is locking in for, picked at onboarding.
enum Track: String, Codable, CaseIterable, Identifiable {
    case school, exam, better
    var id: String { rawValue }

    var title: String {
        switch self {
        case .school: "School"
        case .exam: "A big exam"
        case .better: "Just getting better"
        }
    }

    var subtitle: String {
        switch self {
        case .school: "Homework, tests, finals"
        case .exam: "CFA, CPA, MCAT, the Bar, SAT"
        case .better: "Reading, a language, a skill"
        }
    }

    var symbol: String {
        switch self {
        case .school: "backpack.fill"
        case .exam: "graduationcap.fill"
        case .better: "chart.line.uptrend.xyaxis"
        }
    }

    /// The follow-up chips shown once the track is picked.
    var options: [String] {
        switch self {
        case .school: ["Grade 6–8", "Grade 9", "Grade 10", "Grade 11", "Grade 12", "University"]
        case .exam: ["CFA Level I", "CFA Level II", "CFA Level III", "CPA", "MCAT", "Bar", "SAT"]
        case .better: ["30m a day", "1h a day", "2h a day"]
        }
    }

    var optionsTitle: String {
        switch self {
        case .school: "What year are you in?"
        case .exam: "Which exam?"
        case .better: "How much a day?"
        }
    }
}

struct Profile: Codable, Equatable {
    var name: String
    var track: Track
    var focus: String
    var weeklyGoalHours: Double
    /// Hours to put in before the exam; only for the exam track.
    var targetHours: Double
    var examDate: Date?
    var subjects: [String]

    static func make(name: String, track: Track, focus: String, examDate: Date?) -> Profile {
        var weekly = 6.0
        var target = 0.0
        var subjects = ["Math", "Biology", "Chemistry", "English", "History", "Physics"]
        switch track {
        case .school:
            weekly = focus == "University" ? 12 : 6
        case .exam:
            weekly = 12
            target = ["CPA": 400, "Bar": 400, "SAT": 60, "MCAT": 300][focus] ?? 300
            subjects = focus.hasPrefix("CFA")
                ? ["Ethics", "Quant", "Economics", "FSA", "Corporate Issuers", "Equity", "Fixed Income", "Derivatives", "Alternatives", "Portfolio Mgmt"]
                : ["Practice questions", "Review", "Flashcards", "Mock exam"]
        case .better:
            weekly = (["30m a day": 0.5, "1h a day": 1, "2h a day": 2][focus] ?? 1) * 7
            subjects = ["Reading", "Coding", "Language", "Writing", "Music"]
        }
        return Profile(name: name, track: track, focus: focus, weeklyGoalHours: weekly,
                       targetHours: target, examDate: track == .exam ? examDate : nil, subjects: subjects)
    }
}

enum Visibility: String, Codable, CaseIterable, Identifiable {
    case everyone, followers, onlyMe
    var id: String { rawValue }
    var title: String {
        switch self {
        case .everyone: "Everyone"
        case .followers: "Followers"
        case .onlyMe: "Only me"
        }
    }
}

/// One question answered during a session, `at` seconds of focus in.
struct Answer: Codable, Hashable {
    var correct: Bool
    var at: Int
}

struct Split: Identifiable, Hashable {
    let id: Int
    let questions: Int
    let seconds: Int
    let correct: Int
    var pace: Double { Double(seconds) / Double(max(questions, 1)) }
}

/// A finished, saved study session: the "activity".
struct StudySession: Codable, Identifiable, Hashable {
    var id = UUID()
    var title: String
    var notes: String = ""
    var subject: String
    var start: Date
    var end: Date
    /// Time spent locked in, pauses left out.
    var focusSeconds: Int
    var pauses: Int = 0
    /// Times the app was left while the clock ran.
    var pickups: Int = 0
    var answers: [Answer] = []
    var photoFiles: [String] = []
    var visibility: Visibility = .everyone
    var countsForClub = true

    var elapsedSeconds: Int { Int(end.timeIntervalSince(start)) }
    var questions: Int { answers.count }
    var correct: Int { answers.filter(\.correct).count }
    var accuracy: Double? { questions == 0 ? nil : Double(correct) / Double(questions) }
    /// Seconds per question.
    var pace: Double? { questions == 0 ? nil : Double(focusSeconds) / Double(questions) }

    /// Every 10 questions, like a runner's kilometre splits.
    var splits: [Split] {
        var result: [Split] = []
        var previous = 0
        for (index, chunkStart) in stride(from: 0, to: answers.count, by: 10).enumerated() {
            let chunk = answers[chunkStart..<min(chunkStart + 10, answers.count)]
            let endAt = chunk.last!.at
            result.append(Split(id: index + 1, questions: chunk.count, seconds: max(endAt - previous, 0),
                                correct: chunk.filter(\.correct).count))
            previous = endAt
        }
        return result
    }
}

/// A friend's session in the feed. There is no backend yet, so these are seeded on device.
struct FriendPost: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var tagline: String
    var title: String
    var note: String
    var subject: String
    var date: Date
    var focusSeconds: Int
    var questions: Int
    var correct: Int
    var pickups: Int
    var kudos: Int
    var kudoed = false
    var accuracy: Double? { questions == 0 ? nil : Double(correct) / Double(questions) }
}

struct LiveFriend: Identifiable {
    let name: String
    let subject: String
    let since: Date
    var id: String { name }
}

struct ClubMember: Identifiable {
    let name: String
    let tagline: String
    let weekSeconds: Int
    let questions: Int
    let accuracy: Double
    var isYou = false
    var id: String { name }
}

struct Club: Identifiable {
    let id: String
    let name: String
    let detail: String
    let members: Int
    let symbol: String
    var isClass = false
}
