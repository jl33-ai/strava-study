import SwiftUI

struct OnboardingView: View {
    @Environment(Store.self) private var store
    @State private var track: Track?
    @State private var focus: String?
    @State private var name = ""
    @State private var examDate = Calendar.current.date(byAdding: .month, value: 4, to: .now)!
    @FocusState private var nameFocused: Bool

    private var ready: Bool {
        track != nil && focus != nil && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill").foregroundStyle(Color.ink)
                            .frame(width: 30, height: 30).background(Color.lime, in: Circle())
                        Text("LOCKIN").font(.wide(16, .black)).tracking(1)
                    }
                    Text("What are you locking in for?")
                        .font(.wide(32, .black))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Track every study session like a run. Streaks, splits, kudos from friends.")
                        .font(.system(size: 16)).foregroundStyle(Color.muted)

                    VStack(spacing: 10) {
                        ForEach(Track.allCases) { option in
                            trackRow(option)
                        }
                    }

                    if let track {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(track.optionsTitle).font(.wide(17))
                            FlowLayout {
                                ForEach(track.options, id: \.self) { option in
                                    Chip(title: option, selected: focus == option) {
                                        withAnimation(.snappy) { focus = option }
                                    }
                                }
                            }
                            if track == .exam {
                                DatePicker("Exam day", selection: $examDate, in: Date.now..., displayedComponents: .date)
                                    .font(.system(size: 15, weight: .semibold))
                                    .padding(.top, 4)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    if focus != nil {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What should friends call you?").font(.wide(17))
                            TextField("Your name", text: $name)
                                .textContentType(.givenName)
                                .submitLabel(.done)
                                .focused($nameFocused)
                                .font(.system(size: 17, weight: .semibold))
                                .padding(16)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
                        }
                        .id("name")
                        .transition(.opacity)
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
            .onChange(of: focus) { _, _ in
                withAnimation { proxy.scrollTo("name", anchor: .center) }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.surface)
        .safeAreaInset(edge: .top, spacing: 0) { Color.surface.frame(height: 0) }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Continue", enabled: ready) {
                guard let track, let focus else { return }
                Haptics.success()
                store.profile = .make(name: name.trimmingCharacters(in: .whitespaces), track: track,
                                      focus: focus, examDate: examDate)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.surface)
        }
    }

    private func trackRow(_ option: Track) -> some View {
        let selected = track == option
        return Button {
            Haptics.tap()
            withAnimation(.snappy) {
                if track != option { focus = nil }
                track = option
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: option.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 46, height: 46)
                    .foregroundStyle(selected ? Color.ink : Color.white)
                    .background(selected ? Color.lime : Color.ink, in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title).font(.wide(17))
                    Text(option.subtitle).font(.system(size: 14)).foregroundStyle(Color.muted)
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Color.cobalt : Color.hairline)
            }
            .foregroundStyle(Color.ink)
            .card(padding: 14)
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(selected ? Color.ink : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }
}
