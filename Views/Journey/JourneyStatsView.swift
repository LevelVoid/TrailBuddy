import SwiftUI

struct JourneyStatsView: View {
    @State private var journeyVM = JourneyViewModel.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Activity strip — compact top bar
                HStack(spacing: 16) {
                    miniStat(icon: "timer", value: journeyVM.stats.formattedDuration)
                    Divider().frame(height: 16).background(Theme.warmGray.opacity(0.3))
                    miniStat(icon: "location.north.fill",
                             value: String(format: "%.0f°", journeyVM.stats.heading))
                    Divider().frame(height: 16).background(Theme.warmGray.opacity(0.3))
                    miniStat(icon: "person.fill", value: journeyVM.stats.activityType)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.darkSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Theme.subtleBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal)

                // Main stat cards
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12),
                              GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    StatCard(icon: "figure.walk",
                             label: "Steps",
                             value: "\(journeyVM.stats.steps)",
                             accent: Theme.rustTan)
                    StatCard(icon: "arrow.triangle.swap",
                             label: "Distance",
                             value: journeyVM.stats.formattedDistance,
                             accent: Theme.mutedGold)
                    StatCard(icon: "mountain.2.fill",
                             label: "Altitude",
                             value: journeyVM.stats.formattedAltitude,
                             accent: Theme.forestGreen)
                    StatCard(icon: "shoeprints.fill",
                             label: "Pace",
                             value: paceValue,
                             accent: Theme.rustTan)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
        }
        .background(Theme.nearBlack)
    }

    private var paceValue: String {
        let km = journeyVM.stats.distanceMeters / 1000.0
        let mins = journeyVM.stats.elapsedSeconds / 60.0
        guard km > 0.01, mins > 0 else { return "—" }
        return String(format: "%.2f km/min", km / mins)
    }

    private func miniStat(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.rustTan)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.warmWhite)
        }
    }
}

struct StatCard: View {
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
