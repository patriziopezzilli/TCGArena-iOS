//
//  NewsCarouselSection.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI

struct NewsCarouselSection: View {
    @State private var currentIndex = 0
    
    // Static news items for now (can be fetched from API later)
    private let newsItems: [NewsItem] = [
        NewsItem(
            id: "1",
            title: "Riscatta i tuoi punti",
            subtitle: "Scopri i premi esclusivi nella sezione Premi"
        ),
        NewsItem(
            id: "2",
            title: "Scala la classifica",
            subtitle: "Guadagna badge partecipando ai tornei"
        ),
        NewsItem(
            id: "3",
            title: "Trova tornei vicini",
            subtitle: "Cerca eventi nei negozi della tua zona"
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with dots
            HStack {
                Text("Novità")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                // Page indicator dots
                HStack(spacing: 6) {
                    ForEach(0..<newsItems.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.primary : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(newsItems.enumerated()), id: \.element.id) { index, item in
                    NewsCard(item: item)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 100)
        }
    }
}

struct NewsCard: View {
    let item: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.primary)
            
            Text(item.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}

struct NewsItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
}

