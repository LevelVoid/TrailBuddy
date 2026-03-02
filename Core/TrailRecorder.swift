//
//  TrailRecorder.swift
//  TrailBuddy
//
//  Created by SDC-USER on 26/02/26.
//


import CoreLocation
import Foundation

@MainActor
final class TrailRecorder {
    static let shared = TrailRecorder()
    private(set) var trail: [TrailPoint] = []
    private let saveKey = "savedTrail"

    /// Set to false during guidance to stop recording new points.
    var isRecording: Bool = true

    /// Minimum distance (metres) between consecutive trail points.
    private let minRecordDistance: Double = 5.0

    func record(location: CLLocation) {
        guard isRecording else { return }

        // Distance-gate: skip if too close to the last recorded point
        if let last = trail.last {
            if location.distance(from: last.clLocation) < minRecordDistance {
                return
            }
        }

        let point = TrailPoint(from: location)
        trail.append(point)
        persist()
    }

    func clearTrail() {
        trail.removeAll()
        UserDefaults.standard.removeObject(forKey: saveKey)
    }

    func loadPersistedTrail() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([TrailPoint].self, from: data)
        else { return }
        trail = decoded
    }

    var reversedTrail: [TrailPoint] {
        trail.reversed()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(trail) else { return }
        UserDefaults.standard.set(data, forKey: saveKey)
    }
}
