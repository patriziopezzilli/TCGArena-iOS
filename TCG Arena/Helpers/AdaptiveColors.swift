//
//  AdaptiveColors.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

struct AdaptiveColors {
    // Primary accent colors that adapt to light/dark mode
    static let primary = Color.primary
    static let secondary = Color.secondary
    static let accent = Color.blue
    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    
    // TCG Theme colors - using system colors that adapt automatically
    static let pokemon = Color.orange
    static let magic = Color.red
    static let onePiece = Color.cyan
    static let yugioh = Color.purple
    
    // Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // Neutral colors
    static let lightGray = Color(.systemGray6)
    static let mediumGray = Color(.systemGray4)
    static let darkGray = Color(.systemGray2)
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