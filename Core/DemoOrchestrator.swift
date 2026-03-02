import Foundation
import Observation

@MainActor
@Observable
final class DemoOrchestrator {
    static let shared = DemoOrchestrator()

    private(set) var currentFrameIndex: Int = 0
    private(set) var companionMessage: String?
    private(set) var isReadyForLost: Bool = false
    private var frameTimer: Timer?
    private var messageTimer: Timer?

    private init() {}

    // MARK: - Public

    func start() {
        currentFrameIndex = 0
        isReadyForLost = false
        companionMessage = nil
        frameTimer?.invalidate()
        messageTimer?.invalidate()
        scheduleNextFrame()
    }

    func stop() {
        frameTimer?.invalidate()
        messageTimer?.invalidate()
        frameTimer = nil
        messageTimer = nil
    }

    // MARK: - Private

    private func scheduleNextFrame() {
        let frames = DemoDataProvider.simulatedFrames
        guard currentFrameIndex < frames.count else {
            isReadyForLost = true
            return
        }

        applyFrame(frames[currentFrameIndex])

        if currentFrameIndex == frames.count - 1 {
            isReadyForLost = true
        }

        currentFrameIndex += 1

        // Timer runs on main RunLoop → callback is already on MainActor.
        // Use DispatchQueue.main.async instead of Task to avoid capturing
        // non-Sendable self across an actor boundary.
        frameTimer = Timer.scheduledTimer(
            withTimeInterval: 3.0,
            repeats: false
        ) { _ in
            MainActor.assumeIsolated {
                self.scheduleNextFrame()
            }
        }
    }

    private func applyFrame(_ frame: DemoDataProvider.SimulatedFrame) {
        let vm = JourneyViewModel.shared
        vm.updateSteps(frame.steps)
        vm.updateActivityType(frame.activityType)
        vm.updateHeading(frame.heading)
        vm.stats.distanceMeters = frame.distanceMeters
        vm.stats.altitudeMeters = frame.altitudeMeters
        vm.stats.elapsedSeconds += 3

        guard let message = frame.companionMessage else { return }

        companionMessage = message

        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(
            withTimeInterval: 4.0,
            repeats: false
        ) { _ in
            MainActor.assumeIsolated {
                self.companionMessage = nil
            }
        }
    }
}
