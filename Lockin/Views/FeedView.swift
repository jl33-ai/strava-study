import SwiftUI

struct FeedView: View {
    @Environment(Store.self) private var store

    private enum Item: Identifiable {
        case mine(StudySession)
        case friend(FriendPost)
        var id: String {
            switch self {
            case .mine(let session): session.id.uuidString
            case .friend(let post): post.id
            }
        }
        var date: Date {
            switch self {
            case .mine(let session): session.start
            case .friend(let post): post.date
            }
        }
    }

    private var items: [Item] {
        (store.sessions.map(Item.mine) + store.friends.map(Item.friend)).sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill").font(.system(size: 13, weight: .bold))
                            .frame(width: 28, height: 28).background(Color.lime, in: Circle())
                        Text("LOCKIN").font(.wide(19, .black)).tracking(1)
                    }
                    LiveNowRow()
                    WeekCard()
                    ForEach(items) { item in
                        switch item {
                        case .mine(let session):
                            NavigationLink(value: session) { MySessionCard(session: session) }
                                .buttonStyle(.plain)
                        case .friend(let post):
                            FriendCard(post: post)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.surface)
            .navigationDestination(for: StudySession.self) { SessionDetailView(sessionID: $0.id) }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct LiveNowRow: View {
    @Environment(Store.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Circle().fill(Color.red).frame(width: 7, height: 7)
                Text("Locked in right now").font(.system(size: 13, weight: .bold))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    HStack(spacing: 16) {
                        ForEach(store.liveNow) { friend in
                            VStack(spacing: 6) {
                                Avatar(name: friend.name, size: 54, ring: true)
                                Text(friend.name.split(separator: " ").first.map(String.init) ?? "")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(Fmt.clock(Int(context.date.timeIntervalSince(friend.since))))
                                    .font(.system(size: 11, weight: .semibold)).monospacedDigit()
                                    .foregroundStyle(Color.muted)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                }
            }
        }
    }
}

private struct WeekCard: View {
    @Environment(Store.self) private var store

    var body: some View {
        let week = store.weekSeconds()
        let goal = (store.profile?.weeklyGoalHours ?? 6) * 3600
        let days = lastSevenDays
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("THIS WEEK").font(.system(size: 11, weight: .bold)).tracking(0.8).foregroundStyle(.white.opacity(0.5))
                Spacer()
                Label("\(store.streak()) day streak", systemImage: "flame.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.lime, in: Capsule())
            }
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(Fmt.duration(week)).font(.wide(36, .black)).foregroundStyle(.white)
                Text("of \(Int(goal / 3600))h goal").font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule().fill(Color.lime).frame(width: geo.size.width * min(1, Double(week) / goal))
                }
            }
            .frame(height: 6)
            HStack(alignment: .bottom, spacing: 8) {
                let most = max(days.map(\.seconds).max() ?? 0, 1800)
                ForEach(days, id: \.day) { entry in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(entry.seconds > 0 ? Color.lime : Color.white.opacity(0.12))
                            .frame(height: max(4, 44 * Double(entry.seconds) / Double(most)))
                        Text(entry.day.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 10, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 64, alignment: .bottom)
        }
        .padding(18)
        .background(Color.ink, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var lastSevenDays: [(day: Date, seconds: Int)] {
        let today = Calendar.current.startOfDay(for: .now)
        let daily = store.dailySeconds
        return (0..<7).reversed().map { back in
            let day = Calendar.current.date(byAdding: .day, value: -back, to: today)!
            return (day, daily[day] ?? 0)
        }
    }
}

struct MySessionCard: View {
    @Environment(Store.self) private var store
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PostHeader(name: store.profile?.name ?? "You", detail: "\(Fmt.when(session.start)) · \(session.subject)",
                       visibility: session.visibility)
            Text(session.title).font(.wide(20)).fixedSize(horizontal: false, vertical: true)
            if !session.notes.isEmpty {
                Text(session.notes).font(.system(size: 15)).foregroundStyle(Color.ink.opacity(0.8)).lineLimit(3)
            }
            HStack {
                Stat(label: "Focus", value: Fmt.duration(session.focusSeconds))
                Stat(label: "Questions", value: "\(session.questions)")
                Stat(label: session.questions > 0 ? "Pace /q" : "Pickups",
                     value: session.questions > 0 ? Fmt.pace(session.pace) : "\(session.pickups)")
            }
            if session.splits.count > 1 {
                SplitBars(splits: session.splits)
            }
            if let first = session.photoFiles.first {
                SessionPhoto(file: first)
                    .frame(height: 220).frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            let records = store.records(for: session)
            if !records.isEmpty {
                FlowLayout(spacing: 6) { ForEach(records, id: \.self) { Badge(text: $0) } }
            }
        }
        .card()
        .contentShape(Rectangle())
    }
}

struct FriendCard: View {
    @Environment(Store.self) private var store
    let post: FriendPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PostHeader(name: post.name, detail: "\(Fmt.when(post.date)) · \(post.tagline)", visibility: nil)
            Text(post.title).font(.wide(20)).fixedSize(horizontal: false, vertical: true)
            if !post.note.isEmpty {
                Text(post.note).font(.system(size: 15)).foregroundStyle(Color.ink.opacity(0.8))
            }
            HStack {
                Stat(label: "Focus", value: Fmt.duration(post.focusSeconds))
                if post.questions > 0 {
                    Stat(label: "Questions", value: "\(post.questions)")
                    Stat(label: "Accuracy", value: Fmt.percent(post.accuracy))
                } else {
                    Stat(label: "Subject", value: post.subject)
                    Stat(label: "Pickups", value: "\(post.pickups)")
                }
            }
            Divider()
            HStack {
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { store.toggleKudos(post) }
                } label: {
                    Image(systemName: post.kudoed ? "hands.clap.fill" : "hands.clap")
                        .font(.system(size: 18))
                        .foregroundStyle(post.kudoed ? Color.cobalt : Color.ink)
                        .symbolEffect(.bounce, value: post.kudoed)
                }
                .buttonStyle(.plain)
                Text(post.kudoed ? "\(post.kudos) kudos, including yours" : "\(post.kudos) kudos")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.muted)
                    .contentTransition(.numericText())
                Spacer()
            }
        }
        .card()
    }
}

private struct PostHeader: View {
    let name: String
    let detail: String
    let visibility: Visibility?

    var body: some View {
        HStack(spacing: 10) {
            Avatar(name: name, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.system(size: 15, weight: .bold))
                Text(detail).font(.system(size: 12)).foregroundStyle(Color.muted).lineLimit(1)
            }
            Spacer()
            if let visibility, visibility != .everyone {
                Image(systemName: visibility == .onlyMe ? "lock.fill" : "person.2.fill")
                    .font(.system(size: 12)).foregroundStyle(Color.muted)
            }
        }
    }
}
