import CoreLocation
import Foundation
import Observation

enum AppState: Equatable {
    case greeting, permissions, home, journey, arGuidance, journeySummary
}

@MainActor
@Observable
final class AppViewModel {
    static let shared = AppViewModel()

    var appState: AppState = .greeting
    var isDemoMode: Bool = false

    private init() {}

    func advance() {
        switch appState {
        case .greeting:        appState = .permissions
        case .permissions:     appState = .home
        case .home:            appState = .journey
        case .journey:         appState = .arGuidance
        case .arGuidance:      appState = .home
        case .journeySummary:  appState = .home
        }
    }

    func startJourney(demo: Bool) {
        isDemoMode = demo
        appState = .journey
    }

    func activateARGuidance() {
        appState = .arGuidance
    }

    func returnHome() {
        appState = .home
        TrailRecorder.shared.clearTrail()
        JourneyViewModel.shared.stopJourney()
        LocationManager.shared.stopTracking()
        MotionManager.shared.stopTracking()
    }

    /// End the journey and show the summary screen.
    /// Stops tracking but keeps stats alive for display.
    func endJourney() {
        DemoOrchestrator.shared.stop()
        JourneyViewModel.shared.stopTimer()
        LocationManager.shared.stopTracking()
        MotionManager.shared.stopTracking()
        appState = .journeySummary
    }

    // Location auth changes no longer auto-navigate.
    // The user must tap "Continue" on the permissions screen.
    func handleLocationAuthChange(_ status: CLAuthorizationStatus) {
        // No-op. Navigation is manual only.
    }
}
