import CoreLocation
import Foundation
import Observation
import RealityKit

@MainActor
@Observable
final class ARViewModel {
    static let shared = ARViewModel()

    /// Which waypoint the dog is currently at / heading toward
    private(set) var dogWaypointIndex: Int = 0
    /// The user's confirmed waypoint (progress bar is based on this)
    private(set) var userWaypointIndex: Int = 0

    private(set) var isGuidanceComplete: Bool = false
    private(set) var isDogWaiting: Bool = false
    private(set) var isPetOffScreen: Bool = false
    private(set) var offScreenAngle: Double = 0
    var distanceToStart: Double = 0

    private(set) var isDemo: Bool = false
    private var realWaypoints: [TrailPoint] = []

    /// Pre-computed AR-local waypoints (built once at spawn time)
    private(set) var arLocalWaypoints: [SIMD3<Float>] = []

    /// Max waypoints the dog can be ahead of the user
    private let maxLeadWaypoints = 2

    /// GPS proximity (metres) to consider a waypoint "reached"
    private let waypointReachedDistance: Double = 20.0

    private init() {}

    // MARK: - Progress (user-based)

    var progress: Double {
        if isGuidanceComplete { return 1.0 }
        let total = max(1, totalWaypointCount - 1)
        return min(1.0, Double(userWaypointIndex) / Double(total))
    }

    var formattedDistanceToStart: String {
        let remaining = distanceToStart * max(0, 1.0 - progress)
        return remaining >= 1000
            ? String(format: "%.1f km", remaining / 1000)
            : String(format: "%.0f m", remaining)
    }

    var totalWaypointCount: Int {
        isDemo
            ? DemoDataProvider.arWaypoints.count
            : arLocalWaypoints.count
    }

    func resetGuidance() {
        dogWaypointIndex = 0
        userWaypointIndex = 0
        isGuidanceComplete = false
        isDogWaiting = false
        isPetOffScreen = false
        arLocalWaypoints = []
    }

    func loadWaypoints(demo: Bool) {
        isDemo = demo
        resetGuidance()

        if demo {
            distanceToStart = Double(
                DemoDataProvider.arWaypoints.count - 1
            ) * 0.9
        } else {
            realWaypoints = TrailRecorder.shared.reversedTrail
            distanceToStart = calculateRealDistance()
        }
    }

    // MARK: - Waypoint targets

    func demoTarget(at index: Int) -> SIMD3<Float>? {
        guard isDemo, index < DemoDataProvider.arWaypoints.count
        else { return nil }
        return DemoDataProvider.arWaypoints[index]
    }

    /// Target for real mode — pre-computed AR-local position.
    func realTarget(at index: Int) -> SIMD3<Float>? {
        guard !isDemo, index < arLocalWaypoints.count
        else { return nil }
        return arLocalWaypoints[index]
    }

    /// Build fixed AR-local waypoints from GPS trail.
    /// Called once at spawn time with the device heading so the path
    /// is anchored relative to where the user is facing.
    /// GPS distances are scaled down so the trail fits in walkable
    /// AR space (1 AR metre per arScale real metres).
    func buildARWaypoints(deviceHeading: Double) {
        guard !isDemo, realWaypoints.count >= 2 else {
            arLocalWaypoints = [SIMD3(0, 0, 0)]
            return
        }

        // Scale: how many real metres = 1 AR metre.
        // With 5m recording distance, scale of 5 means waypoints
        // are ~1m apart in AR — very walkable indoors.
        let arScale: Double = 5.0

        var points: [SIMD3<Float>] = [SIMD3(0, 0, 0)]

        for i in 1..<realWaypoints.count {
            let prev = realWaypoints[i - 1]
            let curr = realWaypoints[i]

            let bearing = bearingBetween(
                lat1: prev.latitude, lon1: prev.longitude,
                lat2: curr.latitude, lon2: curr.longitude
            )
            let dist = prev.clLocation.distance(from: curr.clLocation)

            // Convert GPS bearing to AR-local angle.
            // Subtract device heading so the path is relative to
            // where the user was facing at spawn.
            let relAngle = (bearing - deviceHeading) * .pi / 180.0

            let arDist = Float(dist / arScale)
            let dx = Float(sin(relAngle)) * arDist
            let dz = -Float(cos(relAngle)) * arDist

            let lastPt = points[points.count - 1]
            points.append(SIMD3(lastPt.x + dx, 0, lastPt.z + dz))
        }

        arLocalWaypoints = points
    }

    // MARK: - Dog movement

    var canDogAdvance: Bool {
        guard !isGuidanceComplete else { return false }
        let total = totalWaypointCount
        guard dogWaypointIndex < total - 1 else { return false }
        return (dogWaypointIndex - userWaypointIndex) < maxLeadWaypoints
    }

    func advanceDog() {
        if dogWaypointIndex < totalWaypointCount - 1 {
            dogWaypointIndex += 1
            isDogWaiting = false
        }
    }

    func dogWait() { isDogWaiting = true }
    func resumeDog() { isDogWaiting = false }

    // MARK: - User progress

    func advanceUser() {
        // User can't advance past the dog
        if !isDemo && userWaypointIndex >= dogWaypointIndex {
            return
        }
        if userWaypointIndex < totalWaypointCount - 1 {
            userWaypointIndex += 1
        }
        if userWaypointIndex >= totalWaypointCount - 1 {
            isGuidanceComplete = true
        }
    }

    /// Real mode: advance user if GPS is near the current waypoint
    /// up to the dog's current index.
    func checkUserProgressRealMode() {
        guard !isDemo, !isGuidanceComplete else { return }
        guard let userLoc = LocationManager.shared.currentLocation
        else { return }

        while userWaypointIndex <= dogWaypointIndex,
              userWaypointIndex < realWaypoints.count
        {
            let wp = realWaypoints[userWaypointIndex]
            let wpLoc = CLLocation(
                latitude: wp.latitude, longitude: wp.longitude
            )
            if userLoc.distance(from: wpLoc) < waypointReachedDistance {
                userWaypointIndex += 1
                if userWaypointIndex >= realWaypoints.count {
                    isGuidanceComplete = true
                    return
                }
            } else {
                break
            }
        }
    }

    func updateOffScreenState(
        isPetVisible: Bool, angleTowardPet: Double
    ) {
        isPetOffScreen = !isPetVisible
        offScreenAngle = angleTowardPet
    }

    // MARK: - Private

    private func bearingBetween(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let dLon = (lon2 - lon1) * .pi / 180
        let y = sin(dLon) * cos(lat2 * .pi / 180)
        let x = cos(lat1 * .pi / 180) * sin(lat2 * .pi / 180)
            - sin(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * cos(dLon)
        return ((atan2(y, x) * 180 / .pi) + 360)
            .truncatingRemainder(dividingBy: 360)
    }

    /// Cumulative trail distance along all waypoints.
    private func calculateRealDistance() -> Double {
        guard realWaypoints.count >= 2 else { return 0 }
        var total: Double = 0
        for i in 1..<realWaypoints.count {
            total += realWaypoints[i - 1].clLocation
                .distance(from: realWaypoints[i].clLocation)
        }
        return max(total, 1)
    }
}
