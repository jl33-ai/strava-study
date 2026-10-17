import SwiftUI

@main
struct LockinApp: App {
    @State private var store = Store()
    @State private var recorder = Recorder()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(recorder)
                .preferredColorScheme(.light)
                .tint(.cobalt)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { recorder.noteLeftApp() }
        }
    }
}

struct RootView: View {
    @Environment(Store.self) private var store

    var body: some View {
        if store.profile == nil {
            OnboardingView()
        } else {
            MainView()
        }
    }
}

enum Tab: Hashable { case home, clubs, you }

struct MainView: View {
    @Environment(Recorder.self) private var recorder
    @State private var tab: Tab = .home

    var body: some View {
        @Bindable var recorder = recorder
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .home: FeedView()
                case .clubs: ClubsView()
                case .you: ProgressTabView()
                }
            }
            .frame(maxHeight: .infinity)
            if recorder.isActive && !recorder.isPresented {
                LiveBanner { recorder.isPresented = true }
            }
            TabBar(tab: $tab) {
                Haptics.thud()
                recorder.isPresented = true
            }
        }
        .background(Color.surface)
        .fullScreenCover(isPresented: $recorder.isPresented) {
            RecordFlow { tab = .home }
        }
    }
}

struct TabBar: View {
    @Binding var tab: Tab
    let onRecord: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.home, "Home", "house.fill")
            item(.clubs, "Clubs", "person.3.fill")
            Button(action: onRecord) {
                VStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.ink)
                        .frame(width: 52, height: 40)
                        .background(Color.lime, in: Capsule())
                    Text("Lock in").font(.system(size: 10, weight: .semibold)).foregroundStyle(Color.ink)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            item(.you, "You", "person.crop.circle.fill")
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Color.hairline).frame(height: 0.5) }
    }

    private func item(_ value: Tab, _ title: String, _ symbol: String) -> some View {
        Button {
            Haptics.tap()
            tab = value
        } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 20)).frame(height: 40)
                Text(title).font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(tab == value ? Color.ink : Color.ink.opacity(0.35))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

/// Shown above the tab bar while a session runs with the record screen minimised.
struct LiveBanner: View {
    @Environment(Recorder.self) private var recorder
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: 10) {
                Circle().fill(recorder.isRunning ? Color.lime : Color.orange).frame(width: 8, height: 8)
                Text(recorder.isRunning ? "Locked in" : "Paused").font(.system(size: 14, weight: .bold))
                Text(recorder.live?.subject ?? "").font(.system(size: 14)).foregroundStyle(.white.opacity(0.6))
                Spacer()
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(Fmt.clock(Int(recorder.elapsed(at: context.date)))).font(.wide(16)).monospacedDigit()
                }
                Image(systemName: "chevron.up")
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.ink)
        }
        .buttonStyle(.plain)
    }
}
