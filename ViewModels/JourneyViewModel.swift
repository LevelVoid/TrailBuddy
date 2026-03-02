import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class JourneyViewModel {
    static let shared = JourneyViewModel()

    var stats = JourneyStats()
    var startDate: Date?

    // Companion message system — works for both real and demo hikes
    var companionMessage: String?

    // Contextual alert flags
    var showFallAlert = false

    private var lastLocation: CLLocation?
    private var timer: Timer?
    private var messageDismissTimer: Timer?
    private var stationarySeconds: TimeInterval = 0
    private var hasShownHydration30 = false
    private var hasShownHydration60 = false
    private var hasShownAltitudeWarn = false
    private var hasShownStationaryWarn = false

    private init() {}

    func startJourney() {
        startDate = Date()
        stats = JourneyStats()
        companionMessage = nil
        stationarySeconds = 0
        hasShownHydration30 = false
        hasShownHydration60 = false
        hasShownAltitudeWarn = false
        hasShownStationaryWarn = false
        startTimer()
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func stopJourney() {
        stopTimer()
        messageDismissTimer?.invalidate()
        messageDismissTimer = nil
        lastLocation = nil
        stationarySeconds = 0
    }

    func update(location: CLLocation) {
        if let last = lastLocation {
            stats.distanceMeters += location.distance(from: last)
        }
        stats.altitudeMeters = location.altitude
        lastLocation = location
        checkContextualAlerts()
    }

    func updateHeading(_ heading: Double) {
        stats.heading = heading
    }

    func updateSteps(_ steps: Int) {
        stats.steps = steps
    }

    func updateActivityType(_ type: String) {
        stats.activityType = type
        if type == "Stationary" {
            stationarySeconds += 3
            if stationarySeconds >= 600 && !hasShownStationaryWarn {
                hasShownStationaryWarn = true
                showCompanionMessage(
                    "You've been still for a while. Everything okay? 🐾"
                )
            }
        } else {
            stationarySeconds = 0
            hasShownStationaryWarn = false
        }
    }

    func handlePotentialFall() {
        showFallAlert = true
        showCompanionMessage(
            "I felt a jolt! Are you okay? Please check yourself. 🐾"
        )
    }

    func showCompanionMessage(_ message: String) {
        companionMessage = message
        messageDismissTimer?.invalidate()
        // Timer fires on main RunLoop = main thread = already MainActor.
        // No need for Task wrapper — avoids Sendable warnings.
        messageDismissTimer = Timer.scheduledTimer(
            withTimeInterval: 5.0,
            repeats: false
        ) { _ in
            MainActor.assumeIsolated {
                self.companionMessage = nil
            }
        }
    }

    private func startTimer() {
        // Timer fires on main RunLoop = main thread = already MainActor.
        timer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { _ in
            MainActor.assumeIsolated {
                self.stats.elapsedSeconds += 1

                if Int(self.stats.elapsedSeconds) == 1800
                    && !self.hasShownHydration30 {
                    self.hasShownHydration30 = true
                    self.showCompanionMessage(
                        "30 minutes in! Time for a water break. 💧"
                    )
                }
                if Int(self.stats.elapsedSeconds) == 3600
                    && !self.hasShownHydration60 {
                    self.hasShownHydration60 = true
                    self.showCompanionMessage(
                        "One hour trekking! Stay hydrated. 💧"
                    )
                }
            }
        }
    }

    private func checkContextualAlerts() {
        if stats.altitudeMeters > 1200 && !hasShownAltitudeWarn {
            hasShownAltitudeWarn = true
            showCompanionMessage(
                "Above 1200 m now. Watch for dizziness or nausea. ⛰️"
            )
        }
    }
}
