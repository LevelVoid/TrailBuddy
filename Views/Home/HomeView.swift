import SwiftUI

struct HomeView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var showContent = false

    private let tips: [SafetyTip] = [
        SafetyTip(icon: "drop.fill", title: "Stay Hydrated",
                  description: "Carry at least 500 ml per hour of trekking."),
        SafetyTip(icon: "cross.fill", title: "Basic First Aid",
                  description: "Carry bandages, antiseptic, and ORS packets."),
        SafetyTip(icon: "battery.100", title: "Charged Battery",
                  description: "Carry a power bank. TrailBuddy uses minimal power."),
        SafetyTip(icon: "sun.max.fill", title: "Smart Timing",
                  description: "Start early. Never begin a descent after 4 PM."),
        SafetyTip(icon: "person.2.fill", title: "Tell Someone",
                  description: "Share your plan with a friend before you leave."),
        SafetyTip(icon: "shoe.fill", title: "Proper Footwear",
                  description: "Wear ankle-support trekking shoes on rocky terrain.")
    ]

    var body: some View {
        ZStack {
            Theme.nearBlack.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Theme.rustTan.opacity(0.15))
                                .frame(width: 52, height: 52)
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 58, height: 58)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text("TrailBuddy")
                                .font(Theme.title(26))
                                .foregroundStyle(Theme.warmWhite)
                            Text("Ready when you are.")
                                .font(Theme.caption())
                                .foregroundStyle(Theme.warmGray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Section heading
                    HStack(spacing: 8) {
                        Rectangle()
                            .fill(Theme.rustTan)
                            .frame(width: 3, height: 18)
                            .clipShape(Capsule())
                        Text("Before You Trek")
                            .font(Theme.heading(18))
                            .foregroundStyle(Theme.mutedGold)
                    }
                    .padding(.horizontal, 20)

                    // Safety tips grid
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12),
                                  GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(tips) { tip in
                            TipCard(tip: tip)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button {
                            TrailRecorder.shared.clearTrail()
                            appViewModel.startJourney(demo: false)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "figure.hiking")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Start Real Hike")
                                    .font(Theme.heading(16))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Theme.rustTan)
                                    .shadow(color: Theme.rustTan.opacity(0.35), radius: 10, y: 4)
                            )
                            .foregroundStyle(.white)
                        }
                        .accessibilityLabel("Start Real Hike")
                        .accessibilityHint("Begins recording your trail offline")

                        Button {
                            appViewModel.startJourney(demo: true)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Run Demo  (Judge Mode)")
                                    .font(Theme.heading(16))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(Theme.darkSurface)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(Theme.mutedGold.opacity(0.35), lineWidth: 1)
                                    )
                            )
                            .foregroundStyle(Theme.mutedGold)
                        }
                        .accessibilityLabel("Run Demo in Judge Mode")
                        .accessibilityHint("Simulates a complete trek indoors")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
                .padding(.top, 4)
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { showContent = true }
        }
    }
}

struct TipCard: View {
    let tip: SafetyTip

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Theme.rustTan.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: tip.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.rustTan)
            }
            Text(tip.title)
                .font(Theme.heading(14))
                .foregroundStyle(Theme.warmWhite)
            Text(tip.description)
                .font(Theme.caption())
                .foregroundStyle(Theme.warmGray)
                .lineSpacing(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.subtleBorder, lineWidth: 1)
                )
        )
    }
}
