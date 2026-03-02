import SwiftUI

struct OffScreenArrowView: View {
    let angle: Double
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Pulsing outer ring
                Circle()
                    .fill(Theme.mutedGold.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulse ? 1.15 : 1.0)
                    .opacity(pulse ? 0.3 : 0.6)

                // Main circle
                Circle()
                    .fill(Theme.rustTan)
                    .frame(width: 60, height: 60)
                    .shadow(color: Theme.rustTan.opacity(0.5), radius: 12)

                // Arrow
                Image(systemName: "arrow.up")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(angle))
            }

            Text("Turn to find buddy")
                .font(.system(size: 12, weight: .semibold,
                              design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(.ultraThinMaterial))
        }
        .accessibilityLabel("Your buddy is off screen")
        .accessibilityHint(
            "Rotate your device in the direction of the arrow"
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true)
            ) {
                pulse = true
            }
        }
    }
}
