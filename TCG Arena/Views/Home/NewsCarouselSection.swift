//
//  NewsCarouselSection.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI

struct NewsCarouselSection: View {
    @EnvironmentObject var homeDashboard: HomeDashboardService
    @State private var currentIndex = 0
    
    // Get news from dashboard data or use default fallback
    private var newsItems: [NewsItemDisplay] {
        if let newsData = homeDashboard.dashboardData?.news, !newsData.isEmpty {
            return newsData.map { NewsItemDisplay(from: $0) }
        } else {
            // Fallback to static news if no data available
            return [
                NewsItemDisplay(
                    id: "fallback-1",
                    title: "Benvenuto in TCG Arena",
                    subtitle: "Gestisci le tue carte, partecipa ai tornei e scopri negozi vicini",
                    source: "BROADCAST",
                    shopName: nil
                ),
                NewsItemDisplay(
                    id: "fallback-2",
                    title: "Scala la classifica",
                    subtitle: "Guadagna badge partecipando ai tornei",
                    source: "BROADCAST",
                    shopName: nil
                ),
                NewsItemDisplay(
                    id: "fallback-3",
                    title: "Trova tornei vicini",
                    subtitle: "Cerca eventi nei negozi della tua zona",
                    source: "BROADCAST",
                    shopName: nil
                )
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with dots
            HStack {
                Text("Notizie")
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
            if newsItems.isEmpty {
                // Empty state
                Text("Nessuna notizia al momento")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(newsItems.enumerated()), id: \.offset) { index, item in
                        NewsCard(item: item)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 120)
            }
        }
    }
}

struct NewsCard: View {
    let item: NewsItemDisplay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Source badge if from shop
            if item.source == "SHOP", let shopName = item.shopName {
                HStack(spacing: 4) {
                    SwiftUI.Image(systemName: "storefront.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.blue)
                    Text(shopName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.12))
                .clipShape(Capsule())
            }
            
            Text(item.title)
                .font(.system(size: 22, weight: .heavy))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(item.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}

// Display model for news items
struct NewsItemDisplay: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let source: String
    let shopName: String?
    
    init(id: String, title: String, subtitle: String, source: String, shopName: String?) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.source = source
        self.shopName = shopName
    }
    
    init(from newsData: NewsItemData) {
        // Create unique ID by combining source and id to avoid conflicts
        // between broadcast news and shop news with same ID
        self.id = "\(newsData.source)-\(newsData.id)"
        self.title = newsData.title
        self.subtitle = newsData.content
        self.source = newsData.source
        self.shopName = newsData.shopName
    }
}
