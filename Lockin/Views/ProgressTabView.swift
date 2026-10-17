import Charts
import SwiftUI

/// The "You" tab: goal, weekly hours, streak calendar, subjects and records.
struct ProgressTabView: View {
    @Environment(Store.self) private var store
    @State private var range = 4
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    GoalCard()
                    weeklyChart
                    StreakCalendar()
                    subjects
                    records
                }
                .padding(16)
            }
            .background(Color.surface)
            .navigationDestination(for: StudySession.self) { SessionDetailView(sessionID: $0.id) }
            .toolbar {
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
            }
            .toolbarBackground(Color.surface, for: .navigationBar)
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Avatar(name: store.profile?.name ?? "You", size: 62)
            VStack(alignment: .leading, spacing: 4) {
                Text(store.profile?.name ?? "You").font(.wide(24, .black))
                Text(store.profile?.focus ?? "").font(.system(size: 14, weight: .semibold)).foregroundStyle(Color.muted)
            }
            Spacer()
        }
    }

    private var weeklyChart: some View {
        let weeks = store.weeklySeconds(weeks: range)
        let goal = store.profile?.weeklyGoalHours ?? 6
        let average = Double(weeks.reduce(0) { $0 + $1.seconds }) / Double(weeks.count) / 3600
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Hours a week").font(.wide(17))
                Spacer()
                Picker("Range", selection: $range) {
                    Text("4W").tag(4)
                    Text("3M").tag(13)
                    Text("6M").tag(26)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            Text("Avg \(String(format: "%.1f", average))h · goal \(Int(goal))h")
                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.muted)
            Chart {
                ForEach(weeks, id: \.start) { week in
                    BarMark(x: .value("Week", week.start, unit: .weekOfYear),
                            y: .value("Hours", Double(week.seconds) / 3600))
                        .foregroundStyle(Double(week.seconds) / 3600 >= goal ? Color.cobalt : Color.ink.opacity(0.8))
                        .cornerRadius(3)
                }
                RuleMark(y: .value("Goal", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Color.cobalt)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: range == 4 ? 1 : 4)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 170)
            .animation(.snappy, value: range)
        }
        .card(padding: 18)
    }

    private var subjects: some View {
        let rows = store.subjectSeconds()
        let total = max(store.totalSeconds, 1)
        return VStack(alignment: .leading, spacing: 12) {
            Text("Subjects").font(.wide(17))
            if rows.isEmpty {
                Text("Lock in once to see where your time goes.").font(.system(size: 14)).foregroundStyle(Color.muted)
            }
            ForEach(rows, id: \.subject) { row in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(row.subject).font(.system(size: 14, weight: .semibold))
                        Spacer()
                        Text(Fmt.duration(row.seconds)).font(.system(size: 14, weight: .bold)).monospacedDigit()
                    }
                    GeometryReader { geo in
                        Capsule().fill(Color.cobalt)
                            .frame(width: max(6, geo.size.width * Double(row.seconds) / Double(total)))
                    }
                    .frame(height: 6)
                }
            }
        }
        .card(padding: 18)
    }

    private var records: some View {
        let bests = store.bests
        return VStack(alignment: .leading, spacing: 4) {
            Text("Personal records").font(.wide(17)).padding(.bottom, 8)
            recordRow("Longest focus", bests.longest, value: bests.longest.map { Fmt.duration($0.focusSeconds) })
            recordRow("Fastest pace", bests.fastest, value: bests.fastest.map { Fmt.pace($0.pace) + " /q" })
            recordRow("Most questions", bests.mostQuestions, value: bests.mostQuestions.map { "\($0.questions)" })
        }
        .card(padding: 18)
    }

    @ViewBuilder
    private func recordRow(_ title: String, _ session: StudySession?, value: String?) -> some View {
        let row = HStack {
            Image(systemName: "trophy.fill").foregroundStyle(session == nil ? Color.hairline : Color.cobalt)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.system(size: 15, weight: .semibold))
                if let session {
                    Text(session.title).font(.system(size: 12)).foregroundStyle(Color.muted).lineLimit(1)
                }
            }
            Spacer()
            Text(value ?? "–").font(.wide(16))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        if let session {
            NavigationLink(value: session) { row }.buttonStyle(.plain)
        } else {
            row
        }
    }
}

private struct GoalCard: View {
    @Environment(Store.self) private var store

    var body: some View {
        let profile = store.profile
        let isExam = profile?.track == .exam
        let done = isExam ? store.totalSeconds : store.weekSeconds()
        let target = (isExam ? profile?.targetHours : profile?.weeklyGoalHours) ?? 6
        let progress = min(1, Double(done) / 3600 / target)
        HStack(spacing: 20) {
            ZStack {
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 12)
                Circle().trim(from: 0, to: progress)
                    .stroke(Color.lime, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(Fmt.hours(done)).font(.wide(26, .black))
                    Text("of \(Int(target))h").font(.system(size: 11, weight: .semibold)).foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 112, height: 112)
            VStack(alignment: .leading, spacing: 6) {
                if isExam, let exam = profile?.examDate {
                    let days = max(0, Calendar.current.dateComponents([.day], from: .now, to: exam).day ?? 0)
                    Text("\(days) days").font(.wide(28, .black))
                    Text("to \(profile?.focus ?? "your exam"), \(exam.formatted(.dateTime.month(.abbreviated).year()))")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
                    let left = max(0, target - Double(done) / 3600)
                    let perWeek = days > 0 ? left / (Double(days) / 7) : left
                    Text("\(String(format: "%.1f", perWeek))h a week to get there")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.lime)
                } else {
                    Text("This week").font(.wide(24, .black))
                    Text("\(Int(progress * 100))% of your weekly goal")
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white.opacity(0.6))
                    Label("\(store.streak()) day streak", systemImage: "flame.fill")
                        .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.lime)
                }
            }
            .foregroundStyle(.white)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Color.ink, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

/// The last 17 weeks, a square a day, darker for more focus.
private struct StreakCalendar: View {
    @Environment(Store.self) private var store
    private let weeks = 17

    var body: some View {
        let calendar = Calendar.current
        let daily = store.dailySeconds
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: .now)!.start
        let first = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: thisWeek)!
        let today = calendar.startOfDay(for: .now)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Streak").font(.wide(17))
                Spacer()
                Label(store.streak() == 1 ? "1 day" : "\(store.streak()) days", systemImage: "flame.fill")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Color.cobalt)
            }
            HStack(spacing: 3) {
                ForEach(0..<weeks, id: \.self) { column in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { row in
                            let day = calendar.date(byAdding: .day, value: column * 7 + row, to: first)!
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color(daily[day] ?? 0, future: day > today))
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            HStack(spacing: 4) {
                Text("Less").font(.system(size: 11)).foregroundStyle(Color.muted)
                ForEach([0, 900, 2700, 5400], id: \.self) { seconds in
                    RoundedRectangle(cornerRadius: 2).fill(color(seconds, future: false)).frame(width: 10, height: 10)
                }
                Text("More").font(.system(size: 11)).foregroundStyle(Color.muted)
            }
        }
        .card(padding: 18)
    }

    private func color(_ seconds: Int, future: Bool) -> Color {
        if future { return .clear }
        switch seconds {
        case 0: return Color.ink.opacity(0.06)
        case ..<1800: return Color.cobalt.opacity(0.3)
        case ..<3600: return Color.cobalt.opacity(0.6)
        default: return Color.cobalt
        }
    }
}

private struct SettingsView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        @Bindable var store = store
        NavigationStack {
            Form {
                if let profile = Binding($store.profile) {
                    Section("You") {
                        TextField("Name", text: profile.name)
                        LabeledContent("Studying for", value: profile.wrappedValue.focus)
                    }
                    Section("Goals") {
                        Stepper("Weekly goal: \(Int(profile.wrappedValue.weeklyGoalHours))h",
                                value: profile.weeklyGoalHours, in: 1...60)
                        if profile.wrappedValue.track == .exam {
                            Stepper("Hours before the exam: \(Int(profile.wrappedValue.targetHours))",
                                    value: profile.targetHours, in: 10...1000, step: 10)
                            DatePicker("Exam day", selection: Binding(
                                get: { profile.wrappedValue.examDate ?? .now },
                                set: { profile.wrappedValue.examDate = $0 }), displayedComponents: .date)
                        }
                    }
                }
                Section {
                    Button("Start over", role: .destructive) { confirmReset = true }
                } footer: {
                    Text("Deletes your sessions and photos from this phone and goes back to the start.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .confirmationDialog("Delete everything?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    dismiss()
                    store.reset()
                }
            }
        }
    }
}
