import Foundation

/// Friends, clubs and members shown until there is a backend.
enum Seed {
    static func friendPosts(now: Date) -> [FriendPost] {
        func ago(_ hours: Double) -> Date { now.addingTimeInterval(-hours * 3600) }
        return [
            FriendPost(id: "dev-1", name: "Dev Patel", tagline: "CFA Level I · Feb 2027",
                       title: "Ethics + Quant mock, no phone", note: "Finally under 1:30 a question.",
                       subject: "Quant", date: ago(2.5), focusSeconds: 6120, questions: 80, correct: 62,
                       pickups: 0, kudos: 23),
            FriendPost(id: "jordan-1", name: "Jordan Lee", tagline: "Grade 11 · Lincoln High",
                       title: "AP Bio unit 4 before the test", note: "Cell signalling makes sense now??",
                       subject: "Biology", date: ago(5), focusSeconds: 3300, questions: 30, correct: 24,
                       pickups: 2, kudos: 17),
            FriendPost(id: "hana-1", name: "Hana Kim", tagline: "CFA Level II · May 2027",
                       title: "Library group, FSA all afternoon", note: "Three of us, four hours, one coffee each.",
                       subject: "FSA", date: ago(20), focusSeconds: 7800, questions: 0, correct: 0,
                       pickups: 1, kudos: 41),
            FriendPost(id: "marcus-1", name: "Marcus Webb", tagline: "Bar exam · July 2027",
                       title: "5am contracts outline", note: "",
                       subject: "Contracts", date: ago(29), focusSeconds: 5400, questions: 45, correct: 31,
                       pickups: 0, kudos: 12),
            FriendPost(id: "lily-1", name: "Lily Chen", tagline: "Grade 9",
                       title: "Spanish vocab streak day 30", note: "30 days!!",
                       subject: "Spanish", date: ago(46), focusSeconds: 1800, questions: 60, correct: 55,
                       pickups: 1, kudos: 35),
        ]
    }

    static let members: [ClubMember] = [
        ClubMember(name: "Dev Patel", tagline: "CFA Level I", weekSeconds: 15 * 3600 + 20 * 60, questions: 412, accuracy: 0.76),
        ClubMember(name: "Hana Kim", tagline: "CFA Level II", weekSeconds: 13 * 3600 + 5 * 60, questions: 188, accuracy: 0.81),
        ClubMember(name: "Noor Haddad", tagline: "CFA Level I", weekSeconds: 11 * 3600 + 40 * 60, questions: 365, accuracy: 0.72),
        ClubMember(name: "Marcus Webb", tagline: "Bar exam", weekSeconds: 9 * 3600 + 50 * 60, questions: 240, accuracy: 0.69),
        ClubMember(name: "Sofia Ruiz", tagline: "CFA Level I", weekSeconds: 7 * 3600 + 15 * 60, questions: 290, accuracy: 0.83),
        ClubMember(name: "Theo Brooks", tagline: "Grade 12", weekSeconds: 5 * 3600 + 30 * 60, questions: 120, accuracy: 0.64),
    ]

    static let clubs: [Club] = [
        Club(id: "cfa-feb", name: "CFA Level I · Feb 2027", detail: "Everyone sitting the February window", members: 2814, symbol: "chart.bar.fill"),
        Club(id: "5am", name: "5am Lock-in Club", detail: "Study before the world wakes up", members: 9120, symbol: "sunrise.fill"),
        Club(id: "lincoln-bio", name: "Lincoln High · AP Bio", detail: "Ms. Alvarez's class · minutes only, never grades", members: 28, symbol: "leaf.fill", isClass: true),
        Club(id: "library", name: "Library Mondays", detail: "Meet at the main library, 6–9pm", members: 340, symbol: "books.vertical.fill"),
    ]
}
