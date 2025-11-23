//
//  ViewHelpers.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

// MARK: - TCG Type Helpers
extension TCGType {
    var icon: String {
        switch self {
        case .pokemon: return "bolt.fill"
        case .onePiece: return "sailboat.fill"
        case .magic: return "sparkles"
        case .yugioh: return "eye.fill"
        case .digimon: return "shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .pokemon: return Color(red: 1.0, green: 0.7, blue: 0.0) // Darker Yellow #FFB300
        case .onePiece: return Color(red: 0.0, green: 0.7, blue: 1.0) // Bright Blue #00B3FF
        case .magic: return Color(red: 1.0, green: 0.5, blue: 0.0) // Bright Orange #FF8000
        case .yugioh: return Color(red: 0.8, green: 0.0, blue: 1.0) // Bright Purple #CC00FF
        case .digimon: return Color.cyan // Cyan
        }
    }
}

// MARK: - Card Rarity Helpers
extension Rarity {
    var starCount: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 3
        case .ultraRare: return 4
        case .holographic: return 4
        case .promo: return 3
        case .mythic: return 5
        case .legendary: return 6
        case .secretRare: return 5
        }
    }
}

// MARK: - Card Condition Helpers
extension Card.CardCondition {
    var color: Color {
        switch self {
        case .mint, .nearMint: return .green
        case .lightlyPlayed, .moderatelyPlayed: return .orange
        case .heavilyPlayed, .damaged: return .red
        }
    }
    
    var shortName: String {
        switch self {
        case .mint: return "M"
        case .nearMint: return "NM"
        case .lightlyPlayed: return "LP"
        case .moderatelyPlayed: return "MP"
        case .heavilyPlayed: return "HP"
        case .damaged: return "D"
        }
    }
}

// MARK: - Global Helper Functions
func tcgIcon(_ tcgType: TCGType) -> String {
    return tcgType.systemIcon
}

func tcgColor(_ tcgType: TCGType) -> Color {
    return tcgType.themeColor
}

func rarityStars(_ rarity: Rarity) -> Int {
    return rarity.starCount
}

func rarityColor(_ rarity: Rarity) -> Color {
    return rarity.color
}

func conditionColor(_ condition: Card.CardCondition) -> Color {
    return condition.color
}

// MARK: - Common UI Constants
struct UIConstants {
    static let headerFontSize: CGFloat = 28
    static let subheaderFontSize: CGFloat = 14
    static let sectionTitleFontSize: CGFloat = 20
    static let captionFontSize: CGFloat = 12
    
    static let cornerRadius: CGFloat = 12
    static let capsuleRadius: CGFloat = 16
    
    static let shadowRadius: CGFloat = 6
    static let shadowOpacity: Double = 0.1
    
    static let spacing: CGFloat = 16
    static let padding: CGFloat = 20
}

// MARK: - Common UI Components
struct InfoRow: View {
    let icon: String?
    let label: String?
    let title: String?
    let value: String
    let color: Color?
    
    // Initializer for TournamentDetailView style (icon + title)
    init(icon: String, title: String, value: String) {
        self.icon = icon
        self.title = title
        self.label = nil
        self.value = value
        self.color = nil
    }
    
    // Initializer for CardDetailView style (label + color)
    init(label: String, value: String, color: Color) {
        self.icon = nil
        self.title = nil
        self.label = label
        self.value = value
        self.color = color
    }
    
    // Initializer for simple label + value style
    init(label: String, value: String) {
        self.icon = nil
        self.title = nil
        self.label = label
        self.value = value
        self.color = nil
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                SwiftUI.Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 20)
            }
            
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else if let label = label {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(title != nil ? .subheadline : .system(size: 16, weight: .semibold))
                .fontWeight(title != nil ? .medium : .semibold)
                .foregroundColor(color ?? .primary)
        }
    }
}

struct InfoCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: UIConstants.sectionTitleFontSize, weight: .semibold))
                .foregroundColor(.primary)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(UIConstants.shadowOpacity),
                    radius: UIConstants.shadowRadius,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
    }
}
