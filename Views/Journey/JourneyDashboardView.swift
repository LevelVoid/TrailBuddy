import CoreLocation
import SwiftUI

struct JourneyDashboardView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var journeyVM = JourneyViewModel.shared
    @State private var demoOrchestrator = DemoOrchestrator.shared
    @State private var selectedTab = 0

    private var activeCompanionMessage: String? {
        demoOrchestrator.companionMessage ?? journeyVM.companionMessage
    }

    var body: some View {
        ZStack {
            Theme.nearBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Status bar
                HStack {
                    HStack(spacing: 8) {
                        Text("🐕")
                            .font(.system(size: 16))
                        Text("Buddy is with you")
                            .font(.caption.bold())
                            .foregroundStyle(Theme.rustTan)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.mutedGold)
                            .frame(width: 6, height: 6)
                            .shadow(color: Theme.mutedGold, radius: 3)
                        Text(appViewModel.isDemoMode
                             ? "Demo Mode" : "Recording Offline")
                            .font(.caption)
                            .foregroundStyle(Theme.warmGray)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.darkSurface)

                // Native TabView with buttons injected above tab bar
                TabView(selection: $selectedTab) {
                    JourneyStatsView()
                        .safeAreaInset(edge: .bottom) { actionButtons }
                        .tag(0)
                        .tabItem {
                            Label("Journey", systemImage: "map.fill")
                        }

                    SafetyGuideView()
                        .safeAreaInset(edge: .bottom) { actionButtons }
                        .tag(1)
                        .tabItem {
                            Label("If Unwell",
                                  systemImage: "cross.circle.fill")
                        }
                }
                .tint(Theme.rustTan)
            }

            // Companion message — floats above everything
            if let message = activeCompanionMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Text("🐕")
                            .font(.system(size: 20))
                        Text(message)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Theme.rustTan.opacity(0.92))
                            .shadow(color: Theme.rustTan.opacity(0.3),
                                    radius: 10, y: 4)
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 180)
                    .transition(.move(edge: .bottom)
                        .combined(with: .opacity))
                    .animation(.spring(response: 0.4),
                               value: message)
                }
            }
        }
        // Fall detection alert
        .alert("Are You Okay? 🐾",
               isPresented: Binding(
                get: { journeyVM.showFallAlert },
                set: { journeyVM.showFallAlert = $0 }
               )) {
            Button("I'm Fine!") {
                journeyVM.showFallAlert = false
                journeyVM.showCompanionMessage(
                    "Glad you're okay! Stay safe. 🐾"
                )
            }
            Button("I Need Help", role: .destructive) {
                journeyVM.showFallAlert = false
                journeyVM.showCompanionMessage(
                    "Try tapping \"I'm Lost\" to navigate back. 🐾"
                )
            }
        } message: {
            Text("Your buddy detected a sudden jolt. Are you alright?")
        }
        .onAppear { startJourney() }
        .onDisappear { DemoOrchestrator.shared.stop() }
    }

    // MARK: - Action buttons (injected above tab bar)

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // End Journey
            Button {
                appViewModel.endJourney()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 18, weight: .semibold))
                    Text("End Journey")
                        .font(Theme.heading(16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Theme.darkSurface)
                        .overlay(
                            Capsule()
                                .strokeBorder(Theme.mutedGold.opacity(0.35),
                                              lineWidth: 1)
                        )
                )
                .foregroundStyle(Theme.mutedGold)
                .padding(.horizontal, 16)
            }
            .accessibilityLabel("End journey and view summary")

            // I'm Lost
            Button {
                DemoOrchestrator.shared.stop()
                ARViewModel.shared.loadWaypoints(
                    demo: appViewModel.isDemoMode
                )
                appViewModel.activateARGuidance()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName:
                            "exclamationmark.triangle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("I'm Lost – Guide Me Back")
                        .font(Theme.heading(16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Theme.bloodRed)
                        .shadow(color: Theme.bloodRed.opacity(0.4),
                                radius: 10, y: 3)
                )
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
            }
            .accessibilityLabel("I am lost, guide me back")
        }
        .padding(.vertical, 8)
        .background(Theme.nearBlack)
    }

    // MARK: - Helpers

    private func startJourney() {
        journeyVM.startJourney()

        if appViewModel.isDemoMode {
            journeyVM.stopTimer()
            demoOrchestrator.start()
        } else {
            TrailRecorder.shared.isRecording = true
            LocationManager.shared.startTracking()
            MotionManager.shared.startTracking(from: Date())
        }
    }
}
