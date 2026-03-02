//
//  JourneyStats.swift
//  TrailBuddy
//
//  Created by SDC-USER on 26/02/26.
//


import Foundation

struct JourneyStats: Sendable {
    var steps: Int = 0
    var distanceMeters: Double = 0.0
    var altitudeMeters: Double = 0.0
    var elapsedSeconds: TimeInterval = 0.0
    var heading: Double = 0.0
    var activityType: String = "Walking"

    var formattedDistance: String {
        distanceMeters >= 1000
            ? String(format: "%.2f km", distanceMeters / 1000)
            : String(format: "%.0f m", distanceMeters)
    }

    var formattedDuration: String {
        let minutes = Int(elapsedSeconds) / 60
        let seconds = Int(elapsedSeconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedAltitude: String {
        String(format: "%.0f m", altitudeMeters)
    }
}
