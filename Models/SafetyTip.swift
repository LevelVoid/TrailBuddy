//
//  SafetyTip.swift
//  TrailBuddy
//
//  Created by SDC-USER on 26/02/26.
//


import Foundation

struct SafetyTip: Codable, Identifiable, Sendable {
    let id: UUID
    let icon: String
    let title: String
    let description: String

    init(icon: String, title: String, description: String) {
        self.id = UUID()
        self.icon = icon
        self.title = title
        self.description = description
    }
}
