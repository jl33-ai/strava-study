import Charts
import SwiftUI

struct SessionDetailView: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss
    let sessionID: UUID
    @State private var confirmDelete = false

    var body: some View {
        if let session = store.sessions.first(where: { $0.id == sessionID }) {
            content(session)
        } else {
            ContentUnavailableView("Session deleted", systemImage: "trash")
        }
    }

    private func content(_ session: StudySession) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !session.photoFiles.isEmpty {
                    TabView {
                        ForEach(session.photoFiles, id: \.self) { file in
                            SessionPhoto(file: file).clipped()
                        }
                    }
                    .tabViewStyle(.page)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Avatar(name: store.profile?.name ?? "You", size: 36)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(store.profile?.name ?? "You").font(.system(size: 14, weight: .bold))
                            Text(Fmt.when(session.start)).font(.system(size: 12)).foregroundStyle(Color.muted)
                        }
                    }
                    Text(session.title).font(.wide(26, .black)).fixedSize(horizontal: false, vertical: true)
                    if !session.notes.isEmpty {
                        Text(session.notes).font(.system(size: 16))
                    }
                }

                let records = store.records(for: session)
                if !records.isEmpty {
                    FlowLayout(spacing: 6) { ForEach(records, id: \.self) { Badge(text: $0) } }
                }

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 18) {
                    GridRow {
                        Stat(label: "Focus time", value: Fmt.clock(session.focusSeconds), size: 22)
                        Stat(label: "Elapsed", value: Fmt.clock(session.elapsedSeconds), size: 22)
                    }
                    GridRow {
                        Stat(label: "Questions", value: "\(session.questions)", size: 22)
                        Stat(label: "Accuracy", value: Fmt.percent(session.accuracy), size: 22)
                    }
                    GridRow {
                        Stat(label: "Pace /q", value: Fmt.pace(session.pace), size: 22)
                        Stat(label: "Pickups · pauses", value: "\(session.pickups) · \(session.pauses)", size: 22)
                    }
                }
                .card(padding: 18)

                if !session.splits.isEmpty {
                    SplitsCard(splits: session.splits, average: session.pace)
                }

                HStack {
                    Label(session.subject, systemImage: "book.closed.fill")
                    Spacer()
                    Label(session.visibility.title, systemImage: session.visibility == .onlyMe ? "lock.fill" : "eye")
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.muted)
                .padding(.horizontal, 4)
            }
            .padding(16)
        }
        .background(Color.surface)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Menu {
                Button("Delete session", systemImage: "trash", role: .destructive) { confirmDelete = true }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .confirmationDialog("Delete this session?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                dismiss()
                store.delete(session)
            }
        }
    }
}

private struct SplitsCard: View {
    let splits: [Split]
    let average: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Splits").font(.wide(17))
            Text("Seconds per question, every 10 questions").font(.system(size: 13)).foregroundStyle(Color.muted)
            Chart {
                ForEach(splits) { split in
                    BarMark(x: .value("Split", "\(split.id)"), y: .value("Pace", split.pace))
                        .foregroundStyle(split == fastest ? Color.cobalt : Color.ink.opacity(0.75))
                        .cornerRadius(4)
                }
                if let average {
                    RuleMark(y: .value("Average", average))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .foregroundStyle(Color.muted)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel { Text(Fmt.pace(value.as(Double.self))) }
                }
            }
            .frame(height: 150)

            VStack(spacing: 0) {
                HStack {
                    Text("Qs").frame(width: 50, alignment: .leading)
                    Text("Time").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Pace").frame(maxWidth: .infinity, alignment: .leading)
                    Text("Correct").frame(width: 60, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.muted)
                .padding(.vertical, 8)
                ForEach(splits) { split in
                    let first = splits.prefix(split.id - 1).reduce(0) { $0 + $1.questions } + 1
                    HStack {
                        Text("\(first)–\(first + split.questions - 1)").frame(width: 50, alignment: .leading)
                        Text(Fmt.clock(split.seconds)).frame(maxWidth: .infinity, alignment: .leading)
                        Text(Fmt.pace(split.pace)).frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(split == fastest ? Color.cobalt : Color.ink)
                        Text("\(split.correct)/\(split.questions)").frame(width: 60, alignment: .trailing)
                    }
                    .font(.system(size: 14, weight: .semibold)).monospacedDigit()
                    .padding(.vertical, 9)
                    .overlay(alignment: .top) { Rectangle().fill(Color.hairline).frame(height: 0.5) }
                }
            }
        }
        .card(padding: 18)
    }

    private var fastest: Split? { splits.count > 1 ? splits.min { $0.pace < $1.pace } : nil }
}
