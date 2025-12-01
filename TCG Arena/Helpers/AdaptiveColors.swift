//
//  AdaptiveColors.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

struct AdaptiveColors {
    // Primary accent colors that adapt to light/dark mode
    static let primary = Color(hex: "#6B46C1") // Modern purple
    static let accent = Color(hex: "#E53E3E") // Modern red
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    // TCG Theme colors - using system colors that adapt automatically
    static let pokemon = Color.orange
    static let magic = Color.red
    static let onePiece = Color.cyan
    static let yugioh = Color.purple
    
    // Updated modern palette
    static let brandPrimary = Color(hex: "#1E88E5") // Modern blue
    static let brandSecondary = Color(hex: "#FFC107") // Warm yellow
    static let brandTertiary = Color(hex: "#43A047") // Fresh green

    // Neutral tones
    static let neutralLight = Color(hex: "#F5F5F5") // Light neutral
    static let neutralDark = Color(hex: "#424242") // Dark neutral
    static let textSecondary = Color(hex: "#757575") // For secondary text on light backgrounds

    // Backgrounds
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)

    // Status colors
    static let success = Color(hex: "#4CAF50")
    static let warning = Color(hex: "#FB8C00")
    static let error = Color(hex: "#E53935")
    static let info = Color(hex: "#1E88E5")
    
    // Neutral colors
    static let lightGray = Color(.systemGray6)
    static let mediumGray = Color(.systemGray4)
    static let darkGray = Color(.systemGray2)

    // Shadow colors
    static let shadow = Color.black.opacity(0.2) // Colore per ombre morbide
}

extension Color {
    // Custom adaptive colors that work well in both light and dark mode
    static let adaptiveAccent = Color("AccentColor") // This will use the app's accent color
    static let adaptiveBlue = Color.blue
    static let adaptiveCardBackground = Color(.secondarySystemBackground)
    static let adaptiveBorder = Color(.separator)
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}