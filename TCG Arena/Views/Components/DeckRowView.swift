//
//  DeckRowView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct DeckRowView: View {
    let deck: Deck
    
    // Computed property for cover image
    private var coverImageUrl: String? {
        // Find the first card with an image
        if let firstCardWithImage = deck.cards.first(where: { $0.cardImageUrl != nil }) {
            var url = firstCardWithImage.cardImageUrl
            if let imageUrl = url, !imageUrl.contains("/high.webp") {
                return "\(imageUrl)/high.webp"
            }
            return url
        }
        return nil
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background Image or Gradient
            GeometryReader { geometry in
                if let imageUrl = coverImageUrl {
                    CachedAsyncImage(url: URL(string: imageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        case .failure, .empty:
                            fallbackBackground
                        @unknown default:
                            fallbackBackground
                        }
                    }
                } else {
                    fallbackBackground
                }
            }
            
            // Gradient Overlay for text readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.4),
                    Color.clear
                ]),
                startPoint: .bottom,
                endPoint: .top
            )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // TCG Badge
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                            .font(.system(size: 10, weight: .bold))
                        Text(deck.tcgType.displayName)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Material.thinMaterial)
                    .clipShape(Capsule())
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Card Count Badge
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 10))
                        Text("\(deck.totalCards)")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Capsule())
                    .foregroundColor(.white)
                }
                
                Spacer()
                
                // Deck Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(deck.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(radius: 2)
                    
                    if let description = deck.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .shadow(radius: 1)
                    }
                    
                    // Tags
                    if !deck.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(deck.tags.prefix(3), id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(deck.tcgType.themeColor.opacity(0.8))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .frame(height: 160)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private var fallbackBackground: some View {
        ZStack {
            deck.tcgType.themeColor.opacity(0.15)
            
            SwiftUI.Image(systemName: deck.tcgType.systemIcon)
                .font(.system(size: 60))
                .foregroundColor(deck.tcgType.themeColor.opacity(0.3))
        }
    }
}