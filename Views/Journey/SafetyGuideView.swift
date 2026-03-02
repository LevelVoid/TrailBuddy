import SwiftUI

struct SafetyGuideView: View {
    private let emergencies: [(icon: String, title: String, steps: [String])] = [
        ("bolt.heart.fill", "Leg Cramp", [
            "Stop and sit down immediately.",
            "Stretch the cramped muscle gently.",
            "Drink water and eat a salty snack if available.",
            "Rest for 10 minutes before continuing."
        ]),
        ("brain.head.profile", "Headache / Dizziness", [
            "Stop and sit in shade.",
            "Drink water slowly.",
            "If above 1200 m, descend immediately.",
            "Rest until symptoms fully pass."
        ]),
        ("thermometer.sun.fill", "Heat Exhaustion", [
            "Move to shade immediately.",
            "Loosen clothing, cool neck and wrists.",
            "Drink water or ORS if available.",
            "Do not continue trekking that day."
        ]),
        ("location.slash.fill", "Completely Lost", [
            "Stay calm. Panic wastes energy.",
            "Tap \"I'm Lost\" — your buddy will guide you back.",
            "If no phone: stay put, signal rescuers.",
            "Do NOT walk randomly in dense forest."
        ])
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Theme.rustTan)
                        .frame(width: 3, height: 18)
                        .clipShape(Capsule())
                    Text("If Something Goes Wrong")
                        .font(Theme.heading(20))
                        .foregroundStyle(Theme.warmWhite)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 12)

                ForEach(emergencies, id: \.title) { emergency in
                    EmergencyCard(
                        icon: emergency.icon,
                        title: emergency.title,
                        steps: emergency.steps
                    )
                }
            }
            .padding(.bottom, 32)
        }
        .background(Theme.nearBlack)
    }
}

struct EmergencyCard: View {
    let icon: String
    let title: String
    let steps: [String]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.rustTan.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.rustTan)
                    }
                    Text(title)
                        .font(Theme.heading(16))
                        .foregroundStyle(Theme.warmWhite)
                    Spacer()
                    Image(systemName: isExpanded
                          ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.warmGray)
                }
                .padding(14)
            }

            if isExpanded {
                Divider()
                    .background(Theme.warmGray.opacity(0.15))
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.rustTan.opacity(0.15))
                                    .frame(width: 22, height: 22)
                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.rustTan)
                            }
                            Text(step)
                                .font(Theme.body(14))
                                .foregroundStyle(Theme.warmWhite.opacity(0.85))
                        }
                    }
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.darkSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Theme.subtleBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}
