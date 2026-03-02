import SwiftUI

struct JourneySummaryView: View {
    @Environment(AppViewModel.self) private var appViewModel
    private let stats: JourneyStats
    private let trailPointCount: Int
    @State private var showContent = false
    @State private var confetti: [SummaryConfetti] = []

    let emojis = ["🎉", "🐾", "⭐️", "🎊", "🥳", "✨", "🏔️"]

    init() {
        self.stats = JourneyViewModel.shared.stats
        // In demo mode TrailRecorder has no points — estimate from distance
        let recorded = TrailRecorder.shared.trail.count
        if recorded > 0 {
            self.trailPointCount = recorded
        } else {
            // ~1 point per 5m of distance
            self.trailPointCount = max(1, Int(JourneyViewModel.shared.stats.distanceMeters / 5.0))
        }
    }

    var body: some View {
        ZStack {
            Theme.nearBlack.ignoresSafeArea()

            // Falling confetti behind content
            ForEach(confetti) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .position(p.position)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(p.rotation))
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Theme.rustTan.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image("confetti")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                        }

                        Text("Journey Complete")
                            .font(Theme.title(28))
                            .foregroundStyle(Theme.warmWhite)

                        Text("Great work out there! Here's your summary.")
                            .font(Theme.body(15))
                            .foregroundStyle(Theme.warmGray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)

                    // Stats grid
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12),
                                  GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        SummaryCard(icon: "timer",
                                    label: "Duration",
                                    value: stats.formattedDuration,
                                    accent: Theme.rustTan)
                        SummaryCard(icon: "figure.walk",
                                    label: "Steps",
                                    value: "\(stats.steps)",
                                    accent: Theme.mutedGold)
                        SummaryCard(icon: "arrow.triangle.swap",
                                    label: "Distance",
                                    value: stats.formattedDistance,
                                    accent: Theme.forestGreen)
                        SummaryCard(icon: "mountain.2.fill",
                                    label: "Altitude",
                                    value: stats.formattedAltitude,
                                    accent: Theme.rustTan)
                        SummaryCard(icon: "speedometer",
                                    label: "Avg Speed",
                                    value: speedValue,
                                    accent: Theme.mutedGold)
                        SummaryCard(icon: "mappin.and.ellipse",
                                    label: "Trail Points",
                                    value: "\(trailPointCount)",
                                    accent: Theme.forestGreen)
                    }
                    .padding(.horizontal, 20)

                    // Return home button
                    Button {
                        appViewModel.returnHome()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Return Home")
                                .font(Theme.heading(16))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Theme.rustTan)
                                .shadow(color: Theme.rustTan.opacity(0.35),
                                        radius: 10, y: 4)
                        )
                        .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .opacity(showContent ? 1 : 0)
        }
        .onAppear {
            spawnConfetti()
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showContent = true
            }
        }
    }

    private var speedValue: String {
        let km = stats.distanceMeters / 1000.0
        let hours = stats.elapsedSeconds / 3600.0
        guard km > 0.01, hours > 0.001 else { return "—" }
        return String(format: "%.1f km/h", km / hours)
    }

    // MARK: - Confetti animation

    private func spawnConfetti() {
        let sw = UIScreen.main.bounds.width
        let sh = UIScreen.main.bounds.height

        for i in 0..<30 {
            let startX = CGFloat.random(in: 0...sw)
            let startY = CGFloat.random(in: -80...(-10))
            let emoji = emojis[i % emojis.count]
            let size = CGFloat.random(in: 16...28)

            let p = SummaryConfetti(
                id: i, emoji: emoji, size: size,
                position: CGPoint(x: startX, y: startY),
                rotation: .random(in: 0...360), opacity: 1
            )
            confetti.append(p)

            let endY = sh + 40
            let delay = Double.random(in: 0...1.2)
            let dur = Double.random(in: 2.5...4.0)
            let drift = CGFloat.random(in: -50...50)

            withAnimation(.easeIn(duration: dur).delay(delay)) {
                confetti[i].position = CGPoint(
                    x: startX + drift, y: endY
                )
                confetti[i].rotation += .random(in: 180...720)
            }
            withAnimation(.easeIn(duration: 0.6).delay(delay + dur - 0.6)) {
                confetti[i].opacity = 0
            }
        }
    }
}

struct SummaryConfetti: Identifiable {
    let id: Int
    let emoji: String
    let size: CGFloat
    var position: CGPoint
    var rotation: Double
    var opacity: Double
}

struct SummaryCard: View {
    let icon: String
    let label: String
    let value: String
    let accent: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
            }
            Text(value)
                .font(Theme.mono(22))
                .foregroundStyle(Theme.warmWhite)
            Text(label)
                .font(Theme.caption())
                .foregroundStyle(Theme.warmGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.elevatedCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Theme.subtleBorder, lineWidth: 1)
                )
        )
    }
}
