//
//  TCGTheme.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

// MARK: - TCG Arena Visual Identity
struct TCGTheme {
    
    // MARK: - Colors
    struct Colors {
        // Primary palette - Dark gaming theme
        static let primary = Color(red: 0.1, green: 0.1, blue: 0.15)        // Dark navy
        static let secondary = Color(red: 0.15, green: 0.15, blue: 0.2)     // Charcoal
        static let accent = Color(red: 0.3, green: 0.6, blue: 1.0)          // Electric blue
        static let highlight = Color(red: 0.95, green: 0.4, blue: 0.2)      // Orange-red
        
        // Cards & Gaming
        static let cardBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
        static let rareBorder = Color(red: 0.8, green: 0.6, blue: 0.1)      // Gold
        static let epicBorder = Color(red: 0.6, green: 0.2, blue: 0.9)      // Purple
        static let legendaryBorder = Color(red: 0.9, green: 0.3, blue: 0.1) // Orange
        
        // Functional
        static let background = Color(red: 0.98, green: 0.98, blue: 0.99)   // Off-white
        static let surface = Color.white
        static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.15)
        static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.45)
        static let textMuted = Color(red: 0.6, green: 0.6, blue: 0.65)
        
        // Status colors
        static let success = Color(red: 0.2, green: 0.7, blue: 0.3)
        static let warning = Color(red: 0.9, green: 0.6, blue: 0.1)
        static let error = Color(red: 0.85, green: 0.2, blue: 0.2)
    }
    
    // MARK: - Typography
    struct Typography {
        static let titleFont = Font.custom("SF Pro Display", size: 28).weight(.bold)
        static let headingFont = Font.custom("SF Pro Display", size: 20).weight(.semibold)
        static let bodyFont = Font.custom("SF Pro Text", size: 16).weight(.regular)
        static let captionFont = Font.custom("SF Pro Text", size: 14).weight(.medium)
        static let badgeFont = Font.custom("SF Pro Text", size: 12).weight(.semibold)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let card: CGFloat = 20
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let card = Color.black.opacity(0.08)
        static let button = Color.black.opacity(0.12)
        static let modal = Color.black.opacity(0.25)
    }
}

// MARK: - Custom View Modifiers
struct TCGCardStyle: ViewModifier {
    let rarity: Rarity?
    
    func body(content: Content) -> some View {
        content
            .background(TCGTheme.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: TCGTheme.CornerRadius.card)
                    .stroke(borderColor, lineWidth: 2)
            )
            .cornerRadius(TCGTheme.CornerRadius.card)
            .shadow(color: TCGTheme.Shadow.card, radius: 8, x: 0, y: 4)
    }
    
    private var borderColor: Color {
        switch rarity {
        case .rare, .ultraRare:
            return TCGTheme.Colors.rareBorder
        case .secretRare, .superRare, .mythic:
            return TCGTheme.Colors.epicBorder
        case .legendary:
            return TCGTheme.Colors.legendaryBorder
        default:
            return TCGTheme.Colors.textMuted.opacity(0.3)
        }
    }
}

struct TCGSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(TCGTheme.Spacing.md)
            .background(TCGTheme.Colors.surface)
            .cornerRadius(TCGTheme.CornerRadius.medium)
            .shadow(color: TCGTheme.Shadow.card, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Extensions
extension View {
    func tcgCardStyle(rarity: Rarity? = nil) -> some View {
        modifier(TCGCardStyle(rarity: rarity))
    }
    
    func tcgSectionStyle() -> some View {
        modifier(TCGSectionStyle())
    }
}