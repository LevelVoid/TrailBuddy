import SwiftUI

struct GreetingView: View {
    @Environment(AppViewModel.self) private var appViewModel
    @State private var showDog = false
    @State private var showTitle = false
    @State private var showFeatures = false
    @State private var showButton = false
    @State private var dogFloat = false

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.height < 700

            ZStack {
                Theme.nearBlack.ignoresSafeArea()

                // Warm radial glow behind the dog
                RadialGradient(
                    colors: [Theme.rustTan.opacity(0.12), Color.clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 260
                )
                .offset(y: isCompact ? -40 : -80)
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer(minLength: isCompact ? 20 : 44)

                        // Logo hero with gentle floating animation
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: isCompact ? 270 : 300,
                                   height: isCompact ? 270 : 300)
                            .shadow(color: Theme.rustTan.opacity(0.5),
                                    radius: 40, y: 12)
                            .scaleEffect(showDog ? 1.0 : 0.4)
                            .opacity(showDog ? 1 : 0)
                            .offset(y: dogFloat ? -6 : 6)
                            .accessibilityLabel("TrailBuddy Logo")

                        // Title & subtitle
                        VStack(spacing: 8) {
                            Text("TrailBuddy")
                                .font(Theme.title(isCompact ? 32 : 42))
                                .foregroundStyle(Theme.warmWhite)

                            Text("I'll remember every step.\nIf you get lost, follow me home.")
                                .font(Theme.body(isCompact ? 15 : 17))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.warmGray)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)
                        .padding(.horizontal, 24)

                        Spacer(minLength: isCompact ? 20 : 32)

                        // Feature rows
                        VStack(spacing: 14) {
                            featureRow(icon: "location.fill",
                                       text: "Records your path — 100% offline")
                            featureRow(icon: "pawprint.fill",
                                       text: "AR companion walks you home")
                            featureRow(icon: "heart.fill",
                                       text: "Watches over you on every trail")
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Theme.darkSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(Theme.subtleBorder,
                                                      lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 24)
                        .opacity(showFeatures ? 1 : 0)
                        .offset(y: showFeatures ? 0 : 24)

                        Spacer(minLength: isCompact ? 24 : 40)

                        // CTA
                        Button {
                            appViewModel.advance()
                        } label: {
                            Text("Meet Your Buddy →")
                                .font(Theme.heading(17))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(Theme.rustTan)
                                        .shadow(color: Theme.rustTan.opacity(0.4),
                                                radius: 12, y: 4)
                                )
                                .foregroundStyle(.white)
                                .padding(.horizontal, 28)
                        }
                        .opacity(showButton ? 1 : 0)
                        .offset(y: showButton ? 0 : 16)
                        .accessibilityLabel("Meet Your Buddy")
                        .accessibilityHint("Proceed to permissions")

                        Spacer(minLength: 32)
                    }
                    .frame(minHeight: geo.size.height)
                }
            }
        }
        .onAppear { animateEntrance() }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.rustTan.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .foregroundStyle(Theme.rustTan)
                    .font(.system(size: 14, weight: .semibold))
            }
            Text(text)
                .foregroundStyle(Theme.warmWhite)
                .font(Theme.body(14))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            showDog = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
            showTitle = true
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.65)) {
            showFeatures = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.95)) {
            showButton = true
        }
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
            .delay(1.2)
        ) {
            dogFloat = true
        }
    }
}
