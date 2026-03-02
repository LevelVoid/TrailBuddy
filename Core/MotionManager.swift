import CoreMotion
import Foundation

/// MotionManager must NOT be @MainActor because CoreMotion
/// delivers callbacks on private background queues (CMPedometerUpdateQueue,
/// accelerometer OperationQueue). Swift 6 strict concurrency enforces
/// actor isolation at runtime.
final class MotionManager: @unchecked Sendable {
    static let shared = MotionManager()
    private let pedometer = CMPedometer()
    private let activityManager = CMMotionActivityManager()
    private let motionManager = CMMotionManager()
    private var lastFallAlertDate: Date?

    func requestPermissionsIfNeeded() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        activityManager.startActivityUpdates(to: .main) { activity in
            guard let activity else { return }
            // Extract Sendable values BEFORE crossing actor boundary
            let type: String
            if activity.walking { type = "Walking" }
            else if activity.running { type = "Running" }
            else if activity.stationary { type = "Stationary" }
            else { type = "Moving" }
            Task { @MainActor in
                JourneyViewModel.shared.updateActivityType(type)
            }
        }
    }

    func startTracking(from date: Date) {
        guard CMPedometer.isStepCountingAvailable() else {
            startFallDetection()
            return
        }
        pedometer.startUpdates(from: date) { data, _ in
            guard let data else { return }
            // Extract Sendable Int BEFORE crossing actor boundary
            let steps = data.numberOfSteps.intValue
            Task { @MainActor in
                JourneyViewModel.shared.updateSteps(steps)
            }
        }
        startFallDetection()
    }

    func stopTracking() {
        pedometer.stopUpdates()
        activityManager.stopActivityUpdates()
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - Fall Detection

    private func startFallDetection() {
        guard motionManager.isAccelerometerAvailable else { return }
        motionManager.accelerometerUpdateInterval = 0.1 // 10 Hz

        let queue = OperationQueue()
        queue.name = "com.trailbuddy.accelerometer"
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self, let data else { return }
            // Extract Sendable Doubles BEFORE any boundary
            let accel = data.acceleration
            let magnitude = sqrt(
                accel.x * accel.x + accel.y * accel.y + accel.z * accel.z
            )

            if magnitude > 3.0 {
                let now = Date()
                if let last = self.lastFallAlertDate,
                   now.timeIntervalSince(last) < 30 {
                    return
                }
                self.lastFallAlertDate = now
                Task { @MainActor in
                    JourneyViewModel.shared.handlePotentialFall()
                }
            }
        }
    }
}
