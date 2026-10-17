import SwiftUI

struct ClubsView: View {
    @Environment(Store.self) private var store
    @State private var metric = Metric.hours

    enum Metric: String, CaseIterable, Identifiable {
        case hours = "Hours", questions = "Questions", accuracy = "Accuracy"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    challenge
                    moreChallenges
                    leaderboard
                    SectionTitle(text: "Clubs")
                    ForEach(Seed.clubs) { club in clubRow(club) }
                }
                .padding(16)
            }
            .background(Color.surface)
            .navigationTitle("Clubs")
            .toolbarBackground(Color.surface, for: .navigationBar)
        }
    }

    // MARK: Challenges

    private var monthName: String { Date.now.formatted(.dateTime.month(.wide)) }

    private var challenge: some View {
        let id = "month-50-" + Date.now.formatted(.dateTime.year().month(.twoDigits))
        let joined = store.joinedChallenges.contains(id)
        let hours = Double(store.monthSeconds()) / 3600
        let daysLeft = daysLeftInMonth
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("CHALLENGE").font(.system(size: 11, weight: .bold)).tracking(0.8)
                Spacer()
                Text("\(daysLeft) days left").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Color.ink.opacity(0.6))
            Text("\(monthName) 50-Hour Lock-in").font(.wide(26, .black)).fixedSize(horizontal: false, vertical: true)
            Text("Log 50 hours of focus this month. 12,408 people are in.")
                .font(.system(size: 14))
            if joined {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(String(format: "%.1f of 50 h", hours)).font(.wide(16))
                        Spacer()
                        Text("\(Int(min(1, hours / 50) * 100))%").font(.system(size: 14, weight: .bold))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.ink.opacity(0.12))
                            Capsule().fill(Color.ink).frame(width: max(8, geo.size.width * min(1, hours / 50)))
                        }
                    }
                    .frame(height: 8)
                }
            }
            Button {
                Haptics.tap()
                withAnimation(.snappy) { store.toggle(challenge: id) }
            } label: {
                Text(joined ? "Joined ✓" : "Join challenge")
                    .font(.wide(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(joined ? Color.ink : Color.lime)
                    .background(joined ? Color.white.opacity(0.6) : Color.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.ink)
        .padding(20)
        .background(Color.lime, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var daysLeftInMonth: Int {
        let calendar = Calendar.current
        let end = calendar.dateInterval(of: .month, for: .now)!.end
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: .now), to: end).day ?? 0
    }

    private var moreChallenges: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                smallChallenge(id: "streak-7", title: "7-day streak", symbol: "flame.fill",
                               progress: Double(min(store.streak(), 7)) / 7, label: "\(min(store.streak(), 7))/7 days")
                smallChallenge(id: "q-500", title: "500 questions", symbol: "checkmark.circle.fill",
                               progress: min(1, Double(questionsThisMonth) / 500), label: "\(questionsThisMonth)/500")
                smallChallenge(id: "early-10", title: "10 sessions", symbol: "sunrise.fill",
                               progress: min(1, Double(sessionsThisMonth) / 10), label: "\(sessionsThisMonth)/10")
            }
        }
    }

    private var monthSessions: [StudySession] {
        let month = Calendar.current.dateInterval(of: .month, for: .now)!
        return store.sessions.filter { month.contains($0.start) }
    }
    private var questionsThisMonth: Int { monthSessions.reduce(0) { $0 + $1.questions } }
    private var sessionsThisMonth: Int { monthSessions.count }

    private func smallChallenge(id: String, title: String, symbol: String, progress: Double, label: String) -> some View {
        let joined = store.joinedChallenges.contains(id)
        return Button {
            Haptics.tap()
            withAnimation(.snappy) { store.toggle(challenge: id) }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: symbol).font(.system(size: 18))
                    .foregroundStyle(joined ? Color.ink : Color.white)
                    .frame(width: 38, height: 38)
                    .background(joined ? Color.lime : Color.ink, in: Circle())
                Text(title).font(.wide(14))
                if joined {
                    ProgressView(value: progress).tint(.cobalt)
                    Text(label).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.muted)
                } else {
                    Text("Tap to join").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.cobalt)
                }
            }
            .frame(width: 140, alignment: .leading)
            .card(padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: Leaderboard

    private var leaderboard: some View {
        let members = store.leaderboard().sorted { value($0) > value($1) }
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This week").font(.wide(17))
                Spacer()
                Text("CFA Level I · Feb 2027").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.muted)
            }
            Picker("Metric", selection: $metric) {
                ForEach(Metric.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            ForEach(Array(members.enumerated()), id: \.element.id) { rank, member in
                HStack(spacing: 12) {
                    Text("\(rank + 1)").font(.wide(15)).frame(width: 22)
                    Avatar(name: member.name, size: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(member.isYou ? "\(member.name) (you)" : member.name).font(.system(size: 15, weight: .bold))
                        Text(member.tagline).font(.system(size: 12)).foregroundStyle(Color.muted)
                    }
                    Spacer()
                    Text(display(member)).font(.wide(15)).monospacedDigit()
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(member.isYou ? Color.lime.opacity(0.5) : Color.clear, in: RoundedRectangle(cornerRadius: 12))
                .animation(.snappy, value: metric)
            }
        }
        .card(padding: 18)
    }

    private func value(_ member: ClubMember) -> Double {
        switch metric {
        case .hours: Double(member.weekSeconds)
        case .questions: Double(member.questions)
        case .accuracy: member.accuracy
        }
    }

    private func display(_ member: ClubMember) -> String {
        switch metric {
        case .hours: Fmt.duration(member.weekSeconds)
        case .questions: "\(member.questions)"
        case .accuracy: member.questions == 0 ? "–" : Fmt.percent(member.accuracy)
        }
    }

    // MARK: Clubs

    private func clubRow(_ club: Club) -> some View {
        let joined = store.joinedClubs.contains(club.id)
        return HStack(spacing: 12) {
            Image(systemName: club.symbol)
                .font(.system(size: 18))
                .foregroundStyle(club.isClass ? Color.ink : Color.white)
                .frame(width: 48, height: 48)
                .background(club.isClass ? Color.lime : Color.cobalt, in: RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(club.name).font(.system(size: 15, weight: .bold)).lineLimit(1)
                    if club.isClass {
                        Text("CLASS").font(.system(size: 9, weight: .heavy))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.ink.opacity(0.08), in: Capsule())
                    }
                }
                Text(club.detail).font(.system(size: 12)).foregroundStyle(Color.muted).lineLimit(2)
                Text("\(club.members.formatted()) members").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.muted)
            }
            Spacer()
            Button(joined ? "Joined" : "Join") {
                Haptics.tap()
                withAnimation(.snappy) { store.toggle(club: club.id) }
            }
            .font(.system(size: 13, weight: .bold))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .foregroundStyle(joined ? Color.ink : Color.white)
            .background(joined ? Color.ink.opacity(0.08) : Color.ink, in: Capsule())
            .buttonStyle(.plain)
        }
        .card(padding: 14)
    }
}
