import AVFoundation
import CoreLocation
import CoreMotion
import SwiftUI

struct PermissionsView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var locationGranted = false
    @State private var motionGranted = false
    @State private var cameraGranted = false
    @State private var animateIn = false

    var allGranted: Bool { locationGranted && cameraGranted }

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.height < 700

            ZStack {
                Theme.nearBlack.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.rustTan.opacity(0.12))
                                    .frame(width: isCompact ? 60 : 80,
                                           height: isCompact ? 60 : 80)
                                Text("🐾")
                                    .font(.system(size: isCompact ? 28 : 40))
                            }

                            Text("Before We Head Out")
                                .font(Theme.title(isCompact ? 24 : 28))
                                .foregroundStyle(Theme.warmWhite)

                            Text("Your buddy needs a few things\nto keep you safe. Everything\nstays on your device.")
                                .font(Theme.body(isCompact ? 13 : 15))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.warmGray)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, isCompact ? 24 : 44)
                        .padding(.bottom, isCompact ? 16 : 28)

                        // Permission cards
                        VStack(spacing: 12) {
                            permissionCard(
                                icon: "location.fill",
                                color: Theme.rustTan,
                                title: "Location",
                                reason: "Records your trail so your buddy can guide you back.",
                                isGranted: locationGranted
                            ) {
                                LocationManager.shared.requestPermissions()
                            }

                            permissionCard(
                                icon: "figure.walk",
                                color: Theme.mutedGold,
                                title: "Motion & Fitness",
                                reason: "Counts your steps and detects falls.",
                                isGranted: motionGranted
                            ) {
                                MotionManager.shared.requestPermissionsIfNeeded()
                                withAnimation(.spring(response: 0.3)) {
                                    motionGranted = true
                                }
                            }

                            permissionCard(
                                icon: "camera.fill",
                                color: Theme.mutedGold,
                                title: "Camera",
                                reason: "Your buddy appears in AR when you're lost.",
                                isGranted: cameraGranted
                            ) {
                                AVCaptureDevice.requestAccess(for: .video) { granted in
                                    DispatchQueue.main.async {
                                        withAnimation(.spring(response: 0.3)) {
                                            cameraGranted = granted
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : 20)

                        Spacer(minLength: isCompact ? 20 : 32)

                        // Continue button — ONLY way to navigate forward
                        Button {
                            appViewModel.advance()
                        } label: {
                            Text(allGranted
                                ? "All Set — Let's Go →"
                                : "Continue →")
                                .font(Theme.heading(16))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    Capsule()
                                        .fill(allGranted
                                            ? Theme.rustTan
                                            : Theme.darkSurface)
                                        .shadow(
                                            color: allGranted
                                                ? Theme.rustTan.opacity(0.3)
                                                : .clear,
                                            radius: 8, y: 3
                                        )
                                )
                                .overlay(
                                    allGranted ? nil :
                                        Capsule()
                                        .strokeBorder(
                                            Theme.warmGray.opacity(0.3),
                                            lineWidth: 1
                                        )
                                )
                                .foregroundStyle(allGranted
                                    ? .white : Theme.warmGray)
                                .padding(.horizontal, 24)
                        }
                        .animation(.spring(response: 0.3), value: allGranted)
                        .accessibilityLabel(allGranted
                            ? "All permissions granted, continue"
                            : "Continue without all permissions")

                        Spacer(minLength: 36)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .locationAuthorizationChanged)
        ) { _ in
            checkStatuses()
        }
        .onAppear {
            checkStatuses()
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                animateIn = true
            }
        }
    }

    private func checkStatuses() {
        let locStatus = LocationManager.shared.authorizationStatus
        withAnimation(.spring(response: 0.3)) {
            locationGranted = (locStatus == .authorizedAlways
                || locStatus == .authorizedWhenInUse)
        }

        let camStatus = AVCaptureDevice.authorizationStatus(for: .video)
        withAnimation(.spring(response: 0.3)) {
            cameraGranted = (camStatus == .authorized)
        }
    }

    private func permissionCard(
        icon: String,
        color: Color,
        title: String,
        reason: String,
        isGranted: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            if !isGranted { action() }
        }) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(title)
                            .font(Theme.heading(15))
                            .foregroundStyle(Theme.warmWhite)
                        Spacer()
                        Image(systemName: isGranted
                              ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isGranted
                                ? Theme.mutedGold
                                : Theme.warmGray.opacity(0.5))
                            .font(.system(size: 18))
                    }
                    Text(reason)
                        .font(Theme.caption())
                        .foregroundStyle(Theme.warmGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.darkSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isGranted ? color.opacity(0.35) : Theme.subtleBorder,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
