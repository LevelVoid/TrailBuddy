import SwiftUI

/// Fullscreen confetti celebration overlay
struct ConfettiView: View {
    let onDismiss: () -> Void

    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    let emojis = ["🎉", "🐾", "⭐️", "🎊", "🥳", "✨", "🏔️"]

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            // Falling particles
            ForEach(particles) { p in
                Text(p.emoji)
                    .font(.system(size: p.size))
                    .position(p.position)
                    .opacity(p.opacity)
                    .rotationEffect(.degrees(p.rotation))
            }

            // Center message + button
            VStack(spacing: 20) {
                Image("confetti")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .shadow(color: Theme.rustTan.opacity(0.6), radius: 20)

                Text("You Made It!")
                    .font(Theme.title(34))
                    .foregroundStyle(Theme.warmWhite)

                Text("Your buddy guided you safely\nback to the start!")
                    .font(Theme.body(16))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.warmGray)
                    .lineSpacing(3)

                Button {
                    onDismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Return Home")
                            .font(.headline)
                    }
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .fill(Theme.rustTan)
                            .shadow(color: Theme.rustTan.opacity(0.5),
                                    radius: 10, y: 3)
                    )
                    .foregroundStyle(.white)
                }
                .padding(.top, 8)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.3)
            .opacity(isAnimating ? 1 : 0)
        }
        .onAppear {
            spawnConfetti()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }

    private func spawnConfetti() {
        let sw = UIScreen.main.bounds.width
        let sh = UIScreen.main.bounds.height

        for i in 0..<40 {
            let startX = CGFloat.random(in: 0...sw)
            let startY = CGFloat.random(in: -100...(-20))
            let emoji = emojis[i % emojis.count]
            let size = CGFloat.random(in: 18...32)

            let p = ConfettiParticle(
                id: i, emoji: emoji, size: size,
                position: CGPoint(x: startX, y: startY),
                rotation: .random(in: 0...360), opacity: 1
            )
            particles.append(p)

            let endY = sh + 50
            let delay = Double.random(in: 0...1.5)
            let dur = Double.random(in: 2.0...3.5)
            let drift = CGFloat.random(in: -60...60)

            withAnimation(.easeIn(duration: dur).delay(delay)) {
                particles[i].position = CGPoint(
                    x: startX + drift, y: endY
                )
                particles[i].rotation += .random(in: 180...720)
            }
            withAnimation(.easeIn(duration: 0.5).delay(delay + dur - 0.5)) {
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let emoji: String
    let size: CGFloat
    var position: CGPoint
    var rotation: Double
    var opacity: Double
}
