import ARKit
import RealityKit
import SwiftUI

// MARK: - UIViewRepresentable for iOS camera AR

struct ARViewContainer: UIViewRepresentable {
    let arView = ARView(frame: .zero)

    func makeUIView(context: Context) -> ARView {
        arView.automaticallyConfigureSession = false
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}

// MARK: - AR Companion View

struct ARCompanionView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var arVM = ARViewModel.shared
    @State private var petEntity: ModelEntity?
    @State private var petAnchor: AnchorEntity?
    @State private var isLoading = true
    @State private var arContainer = ARViewContainer()
    @State private var guidanceTimer: Timer?
    @State private var visibilityTimer: Timer?
    @State private var isDogWalking = false
    @State private var showConfetti = false
    @State private var isDogMoving = false

    var body: some View {
        ZStack {
            arContainer.ignoresSafeArea()

            // HUD
            VStack(spacing: 0) {
                // Progress bar + status
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "pawprint.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.rustTan)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.15))
                                    .frame(height: 8)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.rustTan,
                                                     Theme.mutedGold],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: max(8,
                                            geo.size.width * arVM.progress),
                                        height: 8
                                    )
                                    .animation(.easeInOut(duration: 0.5),
                                               value: arVM.progress)
                            }
                        }
                        .frame(height: 8)

                        Text("\(Int(arVM.progress * 100))%")
                            .font(.system(size: 12, weight: .bold,
                                          design: .monospaced))
                            .foregroundStyle(Theme.mutedGold)
                            .frame(width: 36, alignment: .trailing)
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(arVM.isGuidanceComplete
                                  ? Theme.mutedGold : Theme.rustTan)
                            .frame(width: 6, height: 6)
                        Text(statusText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.25),
                                radius: 6, y: 2)
                )
                .padding(.horizontal, 16)
                .padding(.top, 56)

                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("Point camera at the floor…")
                            .font(Theme.caption())
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .padding(.top, 12)
                }

                Spacer()

                // Off-screen arrow
                if arVM.isPetOffScreen && petEntity != nil
                    && !arVM.isGuidanceComplete && !showConfetti {
                    OffScreenArrowView(angle: arVM.offScreenAngle)
                        .transition(.scale.combined(with: .opacity))
                        .padding(.bottom, 8)
                }

                if !showConfetti {
                    Button {
                        cleanup()
                        appViewModel.returnHome()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("End Guidance")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal, 22).padding(.vertical, 12)
                        .background(
                            Capsule().fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.2),
                                        radius: 6, y: 2)
                        )
                        .foregroundStyle(.white)
                    }
                    .padding(.bottom, 44)
                }
            }

            // Confetti
            if showConfetti {
                ConfettiView {
                    cleanup()
                    appViewModel.returnHome()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            Task { await spawnOnFloor() }
        }
        .onDisappear { cleanup() }
    }

    private var statusText: String {
        if arVM.isGuidanceComplete {
            return "🎉 You're back at the start!"
        }
        if arVM.isDogWaiting {
            return "Buddy is waiting — walk toward him!"
        }
        return "Follow your buddy  •  \(arVM.formattedDistanceToStart) to go"
    }

    // MARK: - Spawn on FLOOR (lowest detected horizontal plane)

    private func spawnOnFloor() async {
        let arView = arContainer.arView
        let dog = await PetEntityLoader.load()

        // Strategy: cast many rays across the screen, collect ALL
        // horizontal plane hits, and pick the one with the LOWEST
        // Y position — that is almost certainly the floor, not a table.
        var placed = false
        for _ in 0..<30 {   // poll up to 6 seconds
            try? await Task.sleep(for: .milliseconds(200))
            guard arView.bounds.width > 0 else { continue }

            var lowestHit: ARRaycastResult?
            var lowestY: Float = .greatestFiniteMagnitude

            // Cast from multiple vertical positions on screen
            let xMid = arView.bounds.midX
            for yFraction in stride(from: 0.5, through: 0.9, by: 0.1) {
                let pt = CGPoint(
                    x: xMid,
                    y: arView.bounds.height * yFraction
                )
                if let q = arView.makeRaycastQuery(
                    from: pt,
                    allowing: .existingPlaneGeometry,
                    alignment: .horizontal
                ) {
                    for hit in arView.session.raycast(q) {
                        let y = hit.worldTransform.columns.3.y
                        if y < lowestY {
                            lowestY = y
                            lowestHit = hit
                        }
                    }
                }
            }

            if let hit = lowestHit {
                let anchor = AnchorEntity(world: hit.worldTransform)
                anchor.addChild(dog)
                arView.scene.addAnchor(anchor)
                petEntity = dog
                petAnchor = anchor
                placed = true
                break
            }
        }

        if !placed {
            let anchor = AnchorEntity(
                plane: .horizontal, minimumBounds: [0.3, 0.3]
            )
            anchor.addChild(dog)
            arView.scene.addAnchor(anchor)
            petEntity = dog
            petAnchor = anchor
        }

        isLoading = false
        arVM.resetGuidance()

        // Build fixed AR waypoints from GPS trail once,
        // using current device heading so the path is relative
        // to the direction the user is facing now.
        let heading = JourneyViewModel.shared.stats.heading
        arVM.buildARWaypoints(deviceHeading: heading)

        // Face the dog toward the camera (user)
        if let frame = arView.session.currentFrame,
           let anchor = petAnchor {
            let cam = frame.camera.transform
            let camWorld = SIMD3<Float>(
                cam.columns.3.x, cam.columns.3.y, cam.columns.3.z
            )
            let anchorWorld = anchor.position(relativeTo: nil)
            let toUser = camWorld - anchorWorld
            if simd_length(SIMD2(toUser.x, toUser.z)) > 0.01 {
                let angle = atan2(toUser.x, toUser.z)
                let faceUser = simd_quatf(
                    angle: angle, axis: SIMD3(0, 1, 0)
                )
                dog.transform.rotation =
                    faceUser * PetEntityLoader.baseCorrection
            }
        }

        // Stop recording trail during guidance
        TrailRecorder.shared.isRecording = false

        startVisibilityTracking()

        // Pause facing the user, then start guidance
        try? await Task.sleep(for: .milliseconds(1500))
        startGuidanceLoop()
    }

    // MARK: - Main guidance loop

    private func startGuidanceLoop() {
        guidanceTimer?.invalidate()
        guidanceTimer = Timer.scheduledTimer(
            withTimeInterval: 1.5, repeats: true
        ) { _ in
            MainActor.assumeIsolated {
                self.tick()
            }
        }
        tick()
    }

    private func tick() {
        if arVM.isGuidanceComplete {
            guidanceTimer?.invalidate()
            stopDog()
            triggerConfetti()
            return
        }

        if arVM.isDemo {
            demoTick()
        } else {
            realTick()
        }
    }

    // MARK: - Demo tick: smooth continuous walk

    private func demoTick() {
        guard let entity = petEntity,
              let anchor = petAnchor else { return }
        guard !isDogMoving else { return }

        if arVM.canDogAdvance {
            arVM.advanceDog()

            guard let target = arVM.demoTarget(
                at: arVM.dogWaypointIndex
            ) else { return }

            // Keep Y = 0 (ground level relative to anchor)
            let dest = SIMD3<Float>(target.x, 0, target.z)
            let current = entity.position(relativeTo: anchor)
            let dist = simd_distance(current, dest)

            if dist < 0.02 {
                arVM.advanceUser()
                return
            }

            let duration = max(0.4, Double(dist) / 0.8)

            // Combine rotation + translation into ONE move() call
            // so the animations don't conflict with each other.
            var xform = entity.transform
            xform.translation = dest
            let dir = dest - current
            if simd_length(dir) > 0.01 {
                let angle = atan2(dir.x, dir.z)
                let heading = simd_quatf(
                    angle: angle, axis: SIMD3(0, 1, 0)
                )
                xform.rotation = heading * PetEntityLoader.baseCorrection
            }

            startDog()
            isDogMoving = true

            entity.move(to: xform, relativeTo: anchor,
                        duration: duration, timingFunction: .linear)

            DispatchQueue.main.asyncAfter(
                deadline: .now() + duration
            ) {
                MainActor.assumeIsolated {
                    isDogMoving = false
                    arVM.advanceUser()
                }
            }
        } else {
            // Dog can't advance yet — keep idle but stay visible.
            arVM.dogWait()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                MainActor.assumeIsolated {
                    if arVM.isDogWaiting && !arVM.isGuidanceComplete {
                        arVM.advanceUser()
                    }
                }
            }
        }
    }

    // MARK: - Real mode tick: walk pre-computed AR waypoints

    private func realTick() {
        guard let entity = petEntity,
              let anchor = petAnchor else { return }

        // 1. Update user progress from GPS
        arVM.checkUserProgressRealMode()

        if arVM.isGuidanceComplete {
            stopDog()
            triggerConfetti()
            return
        }

        guard !isDogMoving else { return }

        // 2. Advance dog to next waypoint if allowed
        if arVM.canDogAdvance {
            arVM.advanceDog()

            guard let target = arVM.realTarget(
                at: arVM.dogWaypointIndex
            ) else { return }

            // Keep Y = 0 (ground level relative to anchor)
            let dest = SIMD3<Float>(target.x, 0, target.z)
            let current = entity.position(relativeTo: anchor)
            let dist = simd_distance(current, dest)

            if dist < 0.02 {
                arVM.advanceUser()
                return
            }

            let duration = max(0.4, Double(dist) / 0.8)

            // Combine rotation + translation into ONE move() call
            var xform = entity.transform
            xform.translation = dest
            let dir = dest - current
            if simd_length(dir) > 0.01 {
                let angle = atan2(dir.x, dir.z)
                let heading = simd_quatf(
                    angle: angle, axis: SIMD3(0, 1, 0)
                )
                xform.rotation = heading * PetEntityLoader.baseCorrection
            }

            startDog()
            isDogMoving = true

            entity.move(to: xform, relativeTo: anchor,
                        duration: duration, timingFunction: .linear)

            DispatchQueue.main.asyncAfter(
                deadline: .now() + duration
            ) {
                MainActor.assumeIsolated {
                    isDogMoving = false
                    entity.position.y = 0  // ground clamp
                    arVM.advanceUser()
                }
            }
        } else {
            // Dog can't advance — wait for user to catch up.
            if !arVM.isDogWaiting {
                arVM.dogWait()
                stopDog()
            }
        }
    }

    // MARK: - Off-screen tracking

    private func startVisibilityTracking() {
        visibilityTimer?.invalidate()
        visibilityTimer = Timer.scheduledTimer(
            withTimeInterval: 0.2, repeats: true
        ) { _ in
            MainActor.assumeIsolated {
                guard let entity = petEntity else { return }
                let arView = arContainer.arView
                let bounds = arView.bounds
                guard bounds.width > 0 else { return }

                let worldPos = entity.position(relativeTo: nil)
                guard let proj = arView.project(worldPos) else {
                    arVM.updateOffScreenState(
                        isPetVisible: false, angleTowardPet: 0)
                    return
                }

                let padded = bounds.insetBy(dx: -30, dy: -30)
                if padded.contains(proj) {
                    arVM.updateOffScreenState(
                        isPetVisible: true, angleTowardPet: 0)
                } else {
                    let angle = atan2(
                        proj.x - bounds.midX,
                        -(proj.y - bounds.midY)
                    ) * 180 / .pi
                    arVM.updateOffScreenState(
                        isPetVisible: false, angleTowardPet: angle)
                }
            }
        }
    }

    // MARK: - Animation control

    private func startDog() {
        guard !isDogWalking, let e = petEntity else { return }
        isDogWalking = true
        PetEntityLoader.startWalking(e)
    }

    private func stopDog() {
        guard isDogWalking, let e = petEntity else { return }
        isDogWalking = false
        PetEntityLoader.stopWalking(e)
    }

    // MARK: - Confetti

    private func triggerConfetti() {
        guard !showConfetti else { return }
        withAnimation(.easeIn(duration: 0.3)) {
            showConfetti = true
        }
    }

    // MARK: - Cleanup

    private func cleanup() {
        // Restore trail recording
        TrailRecorder.shared.isRecording = true

        guidanceTimer?.invalidate()
        guidanceTimer = nil
        visibilityTimer?.invalidate()
        visibilityTimer = nil
        if isDogWalking, let e = petEntity {
            PetEntityLoader.stopWalking(e)
        }
        petEntity?.removeFromParent()
        petEntity = nil
        petAnchor = nil
        arContainer.arView.session.pause()
    }
}
