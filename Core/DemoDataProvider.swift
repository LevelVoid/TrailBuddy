import Foundation
import RealityKit

struct DemoDataProvider {

    struct SimulatedFrame {
        let steps: Int
        let distanceMeters: Double
        let altitudeMeters: Double
        let heading: Double
        let activityType: String
        let companionMessage: String?
    }

    static let simulatedFrames: [SimulatedFrame] = [
        SimulatedFrame(steps: 0,    distanceMeters: 0,    altitudeMeters: 650,
                       heading: 45,
                       activityType: "Walking",
                       companionMessage: "Trek started! I'm recording your path. 🐾"),
        SimulatedFrame(steps: 420,  distanceMeters: 280,  altitudeMeters: 670,
                       heading: 62,
                       activityType: "Walking",    companionMessage: nil),
        SimulatedFrame(steps: 890,  distanceMeters: 590,  altitudeMeters: 698,
                       heading: 98,
                       activityType: "Walking",
                       companionMessage: "Good pace! Stay hydrated. 💧"),
        SimulatedFrame(steps: 1340, distanceMeters: 900,  altitudeMeters: 720,
                       heading: 135,
                       activityType: "Walking",    companionMessage: nil),
        SimulatedFrame(steps: 1780, distanceMeters: 1180, altitudeMeters: 748,
                       heading: 135,
                       activityType: "Stationary",
                       companionMessage: "You've stopped. Taking a rest? 😊"),
        SimulatedFrame(steps: 2100, distanceMeters: 1390, altitudeMeters: 771,
                       heading: 180,
                       activityType: "Walking",    companionMessage: nil),
        SimulatedFrame(steps: 2560, distanceMeters: 1700, altitudeMeters: 800,
                       heading: 220,
                       activityType: "Walking",
                       companionMessage: "Above 800m! Stunning view ahead. ⛰️"),
        SimulatedFrame(steps: 3020, distanceMeters: 2010, altitudeMeters: 830,
                       heading: 275,
                       activityType: "Walking",    companionMessage: nil),
        SimulatedFrame(steps: 3480, distanceMeters: 2310, altitudeMeters: 847,
                       heading: 310,
                       activityType: "Walking",
                       companionMessage: "You've trekked 2.3 km! 🎉"),
        SimulatedFrame(steps: 3847, distanceMeters: 2560, altitudeMeters: 847,
                       heading: 310,
                       activityType: "Stationary",
                       companionMessage: "Hmm... all paths look the same here. Tap below if you need me. 🐾")
    ]

    // Room-scale AR waypoints — local offsets in metres from pet spawn position
    // Designed to fit inside a ~3x3m indoor space (judge's desk area)
    static let arWaypoints: [SIMD3<Float>] = [
        SIMD3(0,    0,  0),
        SIMD3(0,    0, -1.0),
        SIMD3(0.6,  0, -1.8),
        SIMD3(1.2,  0, -1.4),
        SIMD3(1.4,  0, -0.5),
        SIMD3(1.0,  0,  0.4),
        SIMD3(0.4,  0,  0.6),
        SIMD3(0,    0,  0)
    ]
}
