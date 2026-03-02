import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(AppViewModel.shared)
        }
    }
}

struct RootView: View {
    @Environment(AppViewModel.self) private var appViewModel

    var body: some View {
        ZStack {
            switch appViewModel.appState {
            case .greeting:
                GreetingView()
                    .transition(.opacity)
            case .permissions:
                PermissionsView()
                    .transition(.opacity)
            case .home:
                HomeView()
                    .transition(.opacity)
            case .journey:
                JourneyDashboardView()
                    .transition(.opacity)
            case .arGuidance:
                ARCompanionView()
                    .transition(.opacity)
            case .journeySummary:
                JourneySummaryView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appViewModel.appState)
        .onAppear {
            TrailRecorder.shared.loadPersistedTrail()
        }
    }
}
