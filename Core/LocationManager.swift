import CoreLocation
import Foundation

extension Notification.Name {
    static let locationAuthorizationChanged = Notification.Name("locationAuthorizationChanged")
}

@MainActor
final class LocationManager: NSObject {
    static let shared = LocationManager()

    /// Latest GPS fix that passed accuracy filtering.
    private(set) var currentLocation: CLLocation?

    private let manager = CLLocationManager()

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5

        let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String]
        if backgroundModes?.contains("location") == true {
            manager.allowsBackgroundLocationUpdates = true
            manager.pausesLocationUpdatesAutomatically = false
        }
    }

    func requestPermissions() {
        manager.requestAlwaysAuthorization()
    }

    func startTracking() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }

    func switchToBatteryMode() {
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 20
    }

    func switchToFullMode() {
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        guard location.horizontalAccuracy > 0,
              location.horizontalAccuracy <= 20 else { return }

        // Extract all Sendable value types BEFORE crossing actor boundary.
        // CLLocation is Sendable on iOS 17+, but extracting primitives
        // guarantees zero warnings on every Swift 6 compiler version.
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let alt = location.altitude
        let hAcc = location.horizontalAccuracy
        let ts = location.timestamp

        Task { @MainActor in
            let reconstructed = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                altitude: alt,
                horizontalAccuracy: hAcc,
                verticalAccuracy: -1,
                timestamp: ts
            )
            self.currentLocation = reconstructed
            TrailRecorder.shared.record(location: reconstructed)
            JourneyViewModel.shared.update(location: reconstructed)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateHeading newHeading: CLHeading
    ) {
        let trueHeading = newHeading.trueHeading
        Task { @MainActor in
            JourneyViewModel.shared.updateHeading(trueHeading)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            AppViewModel.shared.handleLocationAuthChange(status)
            NotificationCenter.default.post(name: .locationAuthorizationChanged, object: nil)
        }
    }
}
