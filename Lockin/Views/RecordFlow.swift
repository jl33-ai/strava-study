import PhotosUI
import SwiftUI

/// The record screen and, once finished, the save screen.
struct RecordFlow: View {
    let onSaved: () -> Void
    @Environment(Recorder.self) private var recorder
    @State private var draft: StudySession?

    var body: some View {
        NavigationStack {
            RecordView { draft = recorder.draft() }
                .navigationDestination(item: $draft) { draft in
                    SaveSessionView(draft: draft, onSaved: onSaved)
                }
        }
        .preferredColorScheme(draft == nil ? .dark : .light)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
}

struct RecordView: View {
    @Environment(Store.self) private var store
    @Environment(Recorder.self) private var recorder
    let onFinish: () -> Void
    @State private var subject: String?

    private static let blockSeconds = 25 * 60.0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { recorder.isPresented = false } label: {
                    Image(systemName: "chevron.down").font(.system(size: 18, weight: .bold))
                        .frame(width: 40, height: 40).background(Color.white.opacity(0.08), in: Circle())
                }
                Spacer()
                Text(recorder.isActive ? recorder.live!.subject : "Lock in").font(.wide(16))
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)

            if recorder.isActive {
                running
            } else {
                setup
            }
        }
        .padding(.vertical, 8)
        .background(Color.ink.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: Before starting

    private var setup: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("What are you studying?").font(.wide(26, .black)).foregroundStyle(.white)
            FlowLayout {
                ForEach(store.profile?.subjects ?? [], id: \.self) { option in
                    Chip(title: option, selected: subject == option, dark: true) { subject = option }
                }
            }
            Text("The clock runs while you're away from the app, and each time you leave counts as a phone pickup. Tap Got it or Missed as you answer questions to get your pace and splits.")
                .font(.system(size: 14)).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Button {
                guard let subject else { return }
                Haptics.thud()
                withAnimation(.snappy) { recorder.start(subject: subject) }
            } label: {
                Text("Start")
                    .font(.wide(20, .black))
                    .foregroundStyle(Color.ink)
                    .frame(width: 120, height: 120)
                    .background(subject == nil ? Color.white.opacity(0.25) : Color.lime, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(subject == nil)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .onAppear { subject = subject ?? store.profile?.subjects.first }
    }

    // MARK: Running

    private var running: some View {
        let live = recorder.live!
        let correct = live.answers.filter(\.correct).count
        return TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = recorder.elapsed(at: context.date)
            let block = Int(elapsed / Self.blockSeconds) + 1
            let intoBlock = elapsed.truncatingRemainder(dividingBy: Self.blockSeconds)
            VStack(spacing: 22) {
                Spacer(minLength: 0)
                HStack(spacing: 8) {
                    Circle().fill(recorder.isRunning ? Color.lime : Color.orange).frame(width: 8, height: 8)
                    Text(recorder.isRunning ? "DEEP FOCUS" : "PAUSED")
                        .font(.system(size: 12, weight: .bold)).tracking(1.2)
                    if live.pickups > 0 {
                        Text("· \(live.pickups) pickup\(live.pickups == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .foregroundStyle(.white)
                Text(Fmt.clock(Int(elapsed)))
                    .font(.wide(68, .black))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                VStack(spacing: 8) {
                    HStack {
                        Text("Block \(block)").font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text("Break in \(Fmt.clock(Int(Self.blockSeconds - intoBlock)))")
                            .font(.system(size: 13, weight: .semibold)).monospacedDigit()
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.12))
                            Capsule().fill(Color.lime).frame(width: geo.size.width * intoBlock / Self.blockSeconds)
                        }
                    }
                    .frame(height: 6)
                }
                .foregroundStyle(.white)

                HStack {
                    Stat(label: "Questions", value: "\(live.answers.count)", dark: true, size: 24)
                    Stat(label: "Pace /q", value: live.answers.isEmpty ? "–" : Fmt.pace(elapsed / Double(live.answers.count)), dark: true, size: 24)
                    Stat(label: "Accuracy", value: live.answers.isEmpty ? "–" : Fmt.percent(Double(correct) / Double(live.answers.count)), dark: true, size: 24)
                }
                .padding(.top, 6)

                HStack(spacing: 12) {
                    answerButton("Missed", "xmark", correct: false)
                    answerButton("Got it", "checkmark", correct: true)
                }
                .disabled(!recorder.isRunning)
                .opacity(recorder.isRunning ? 1 : 0.4)

                if !live.answers.isEmpty {
                    Button("Undo last answer") { Haptics.tap(); recorder.undoAnswer() }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer(minLength: 0)
                controls
            }
            .padding(20)
        }
    }

    private func answerButton(_ title: String, _ symbol: String, correct: Bool) -> some View {
        Button {
            correct ? Haptics.tap() : Haptics.thud()
            recorder.answer(correct: correct)
        } label: {
            Label(title, systemImage: symbol)
                .font(.wide(16))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .foregroundStyle(correct ? Color.ink : .white)
                .background(correct ? Color.lime : Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var controls: some View {
        HStack(spacing: 28) {
            if recorder.isRunning {
                roundButton("pause.fill", "Pause", fill: .white) {
                    withAnimation(.snappy) { recorder.pause() }
                }
            } else {
                roundButton("play.fill", "Resume", fill: .lime) {
                    withAnimation(.snappy) { recorder.resume() }
                }
                roundButton("flag.checkered", "Finish", fill: .white) { onFinish() }
            }
        }
    }

    private func roundButton(_ symbol: String, _ title: String, fill: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.thud()
            action()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.ink)
                    .frame(width: 78, height: 78)
                    .background(fill, in: Circle())
                Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
    }
}

struct SaveSessionView: View {
    @Environment(Store.self) private var store
    @Environment(Recorder.self) private var recorder
    @State var draft: StudySession
    let onSaved: () -> Void
    @State private var picked: [PhotosPickerItem] = []
    @State private var confirmDiscard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Stat(label: "Focus", value: Fmt.duration(draft.focusSeconds), size: 20)
                    Stat(label: "Questions", value: "\(draft.questions)", size: 20)
                    Stat(label: "Accuracy", value: Fmt.percent(draft.accuracy), size: 20)
                }
                .card()

                let records = store.records(for: draft)
                if !records.isEmpty {
                    FlowLayout(spacing: 6) { ForEach(records, id: \.self) { Badge(text: $0) } }
                }

                VStack(alignment: .leading, spacing: 0) {
                    TextField("Title", text: $draft.title)
                        .font(.wide(18))
                        .padding(16)
                    Divider()
                    TextField("How did it go? Share what you studied.", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.system(size: 16))
                        .padding(16)
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 22))

                VStack(alignment: .leading, spacing: 10) {
                    Text("Photos").font(.wide(15))
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            PhotosPicker(selection: $picked, maxSelectionCount: 4, matching: .images) {
                                VStack(spacing: 6) {
                                    Image(systemName: "camera.fill").font(.system(size: 20))
                                    Text("Add").font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(Color.ink)
                                .frame(width: 90, height: 90)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.hairline, style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                            }
                            ForEach(draft.photoFiles, id: \.self) { file in
                                SessionPhoto(file: file)
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(alignment: .topTrailing) {
                                        Button {
                                            PhotoStore.delete(file)
                                            draft.photoFiles.removeAll { $0 == file }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill").font(.system(size: 20))
                                                .foregroundStyle(.white, Color.ink.opacity(0.7))
                                        }
                                        .padding(4)
                                    }
                            }
                        }
                    }
                }
                .onChange(of: picked) { _, items in
                    Task {
                        for item in items {
                            if let data = try? await item.loadTransferable(type: Data.self), let file = PhotoStore.save(data) {
                                draft.photoFiles.append(file)
                            }
                        }
                        picked = []
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Who can see this").font(.wide(15))
                    Picker("Who can see this", selection: $draft.visibility) {
                        ForEach(Visibility.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Count toward club leaderboards", isOn: $draft.countsForClub)
                        .font(.system(size: 15, weight: .semibold))
                        .tint(.cobalt)
                        .padding(.top, 6)
                }
                .card()

                Button("Discard session", role: .destructive) { confirmDiscard = true }
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
            .padding(16)
            .padding(.bottom, 90)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.surface)
        .navigationTitle("Save session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Save session") {
                Haptics.success()
                var session = draft
                session.title = session.title.trimmingCharacters(in: .whitespaces).isEmpty
                    ? Recorder.defaultTitle(subject: session.subject, at: session.start) : session.title
                store.add(session)
                recorder.discard()
                recorder.isPresented = false
                onSaved()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.surface)
        }
        .confirmationDialog("Discard this session?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                draft.photoFiles.forEach(PhotoStore.delete)
                recorder.discard()
                recorder.isPresented = false
            }
        } message: {
            Text("\(Fmt.duration(draft.focusSeconds)) of focus will be lost.")
        }
    }
}
