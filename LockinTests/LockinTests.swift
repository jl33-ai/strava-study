import XCTest
@testable import Lockin

final class LockinTests: XCTestCase {
    private let day: TimeInterval = 86_400

    private func session(at start: Date, focus: Int = 1800, answers: [Answer] = []) -> StudySession {
        StudySession(title: "t", subject: "Quant", start: start, end: start.addingTimeInterval(TimeInterval(focus)),
                     focusSeconds: focus, answers: answers)
    }

    func testSplitsEveryTenQuestions() {
        let answers = (1...25).map { Answer(correct: $0 % 2 == 0, at: $0 * 60) }
        let splits = session(at: .now, answers: answers).splits
        XCTAssertEqual(splits.map(\.questions), [10, 10, 5])
        XCTAssertEqual(splits.map(\.seconds), [600, 600, 300])
        XCTAssertEqual(splits[0].correct, 5)
    }

    func testStreakCountsFromYesterdayWhenNothingToday() {
        let store = Store(fileURL: nil)
        let now = Date.now
        store.add(session(at: now.addingTimeInterval(-day)))
        store.add(session(at: now.addingTimeInterval(-2 * day)))
        store.add(session(at: now.addingTimeInterval(-4 * day)))
        XCTAssertEqual(store.streak(now: now), 2)
        store.add(session(at: now))
        XCTAssertEqual(store.streak(now: now), 3)
    }

    func testRecords() {
        let store = Store(fileURL: nil)
        let first = session(at: .now.addingTimeInterval(-day), focus: 1200)
        XCTAssertEqual(store.records(for: first), ["First lock-in"])
        store.add(first)
        let longer = session(at: .now, focus: 3000)
        XCTAssertEqual(store.records(for: longer), ["Longest focus"])
    }

    func testRecorderLeavesPausesOutOfFocus() {
        let recorder = Recorder(defaults: nil)
        let start = Date.now
        recorder.start(subject: "Ethics", now: start)
        recorder.answer(correct: true, now: start.addingTimeInterval(90))
        recorder.pause(now: start.addingTimeInterval(600))
        recorder.resume(now: start.addingTimeInterval(900))
        recorder.noteLeftApp()
        let draft = recorder.draft(now: start.addingTimeInterval(1200))!
        XCTAssertEqual(draft.focusSeconds, 900)
        XCTAssertEqual(draft.elapsedSeconds, 1200)
        XCTAssertEqual(draft.pauses, 1)
        XCTAssertEqual(draft.pickups, 1)
        XCTAssertEqual(draft.answers, [Answer(correct: true, at: 90)])
    }
}
