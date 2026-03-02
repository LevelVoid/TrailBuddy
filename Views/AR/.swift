//
//  OffScreenArrowView 2.swift
//  TrailBuddy
//
//  Created by SDC-USER on 26/02/26.
//


import SwiftUI

struct OffScreenArrowView: View {
    let angle: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.85))
                .frame(width: 52, height: 52)
            Image(systemName: "arrow.up")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .rotationEffect(.degrees(angle))
        }
        .shadow(radius: 6)
        .accessibilityLabel("Your buddy is off screen")
        .accessibilityHint(
            "Rotate your device toward the arrow direction to find your companion"
        )
    }
}
