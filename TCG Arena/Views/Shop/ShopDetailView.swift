//
//  ShopDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import SwiftUI
import MapKit

enum ShopServiceType {
    case cardSales
    case buyCards
    case tournaments
    case playArea
    case grading
    case accessories
    case preorders
    case onlineStore
}



struct ShopDetailView: View {
    let shop: Shop
    @EnvironmentObject var shopService: ShopService
    @State private var selectedTab = 0
    @State private var showingSubscribeAlert = false
    
    private var alertTitle: String {
        shopService.isSubscribed(to: shop.id.description) ? "Subscribed!" : "Unsubscribed"
    }
    
    private var alertMessage: String {
        shopService.isSubscribed(to: shop.id.description)
        ? "You'll receive notifications about new products, events, and tournaments from \(shop.name)."
        : "You won't receive notifications from \(shop.name) anymore."
    }
    
    private var newsSection: some View {
        if !shopService.getNews(for: shop.id.description).isEmpty {
            return AnyView(
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            SwiftUI.Image(systemName: "newspaper.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                            
                            Text("News & Updates")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Subscribe Bell Icon
                            Button(action: {
                                shopService.toggleSubscription(for: String(shop.id))
                                showingSubscribeAlert = true
                            }) {
                                SwiftUI.Image(systemName: shopService.isSubscribed(to: String(shop.id)) ? "bell.fill" : "bell")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(shopService.isSubscribed(to: String(shop.id)) ? .green : .gray)
                            }
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(shopService.getNews(for: shop.id.description)) { newsItem in
                                NewsCardView(news: newsItem)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                }
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Image Placeholder
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                    
                    HStack(spacing: 8) {
                        Text(shop.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        if shop.isVerified {
                            SwiftUI.Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                }
                
                // Subscribe Button (removed from here)
                
                // Info Section
                VStack(spacing: 24) {
                    newsSection
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(shop.description ?? "")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Opening Hours
                VStack(alignment: .leading, spacing: 12) {
                    Text("Opening Hours")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        if let openingDays = shop.openingDays {
                            HStack(alignment: .top) {
                                SwiftUI.Image(systemName: "calendar")
                                    .font(.system(size: 16))
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Days")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text(openingDays)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        if let openingHours = shop.openingHours {
                            HStack(alignment: .top) {
                                SwiftUI.Image(systemName: "clock")
                                    .font(.system(size: 16))
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hours")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    Text(openingHours)
                                        .font(.system(size: 15))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        if shop.openingHours == nil && shop.openingDays == nil {
                            Text("Hours not available")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Location
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            SwiftUI.Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(shop.address)
                                    .font(.system(size: 15))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        // Map Preview
                        if let latitude = shop.latitude, let longitude = shop.longitude {
                            Map(coordinateRegion: .constant(MKCoordinateRegion(
                                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )), annotationItems: [shop]) { shop in
                                MapMarker(coordinate: CLLocationCoordinate2D(latitude: shop.latitude ?? 0, longitude: shop.longitude ?? 0), tint: .red)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                            .disabled(true)
                        }
                        
                        // Navigate Button
                        Button(action: {
                            openInMaps()
                        }) {
                            HStack(spacing: 8) {
                                SwiftUI.Image(systemName: "location.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("Open in Maps")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                
                // Contact
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        if let phone = shop.phoneNumber {
                            ContactRow(icon: "phone.fill", text: phone, color: .green)
                        }
                        
                        if let email = shop.email {
                            ContactRow(icon: "envelope.fill", text: email, color: .orange)
                        }
                        
                        if let website = shop.websiteUrl {
                            ContactRow(icon: "globe", text: website, color: .purple)
                        }
                        
                        if let instagram = shop.instagramUrl {
                            ContactRow(icon: "camera.fill", text: instagram, color: .pink)
                        }
                        
                        if let facebook = shop.facebookUrl {
                            ContactRow(icon: "f.circle.fill", text: facebook, color: .blue)
                        }
                        
                        if let twitter = shop.twitterUrl {
                            ContactRow(icon: "bird.fill", text: twitter, color: .cyan)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showingSubscribeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func openInMaps() {
        guard let latitude = shop.latitude, let longitude = shop.longitude else { return }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let address = shop.address
        
        // Try to open in Apple Maps
        let urlString = "http://maps.apple.com/?daddr=\(coordinate.latitude),\(coordinate.longitude)&dirflg=d"
        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to Google Maps
        let googleMapsString = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"
        if let googleUrl = URL(string: googleMapsString) {
            if UIApplication.shared.canOpenURL(googleUrl) {
                UIApplication.shared.open(googleUrl)
                return
            }
        }
        
        // Last fallback: open in browser
        if let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
           let webUrl = URL(string: "https://maps.google.com/?q=\(encodedAddress)") {
            UIApplication.shared.open(webUrl)
        }
    }
    
    private func iconForService(_ service: ShopServiceType) -> String {
        switch service {
        case .cardSales: return "cart.fill"
        case .buyCards: return "dollarsign.circle.fill"
        case .tournaments: return "trophy.fill"
        case .playArea: return "gamecontroller.fill"
        case .grading: return "checkmark.seal.fill"
        case .accessories: return "bag.fill"
        case .preorders: return "calendar.badge.clock"
        case .onlineStore: return "laptopcomputer"
        }
    }
    
    
    
    
    
    
    // MARK: - News Card View
    struct NewsCardView: View {
        let news: ShopNews
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(newsTypeColor.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        SwiftUI.Image(systemName: news.newsType.icon)
                            .font(.system(size: 16))
                            .foregroundColor(newsTypeColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // Title with pinned indicator
                        HStack(spacing: 6) {
                            if news.isPinned {
                                SwiftUI.Image(systemName: "pin.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.orange)
                            }
                            
                            Text(news.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                        
                        // Content
                        Text(news.content)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                        
                        // Footer
                        HStack {
                            // News Type Badge
                            Text(news.newsType.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(newsTypeColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(newsTypeColor.opacity(0.15))
                                )
                            
                            Spacer()
                            
                            // Date
                            Text(timeAgo(from: news.publishedDate))
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(news.isPinned ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        
        private var newsTypeColor: Color {
            switch news.newsType {
            case .announcement: return .blue
            case .newStock: return .green
            case .tournament: return .orange
            case .sale: return .red
            case .event: return .purple
            case .general: return .gray
            default: return .gray
            }
        }
        
        private func timeAgo(from date: Date) -> String {
            let calendar = Calendar.current
            let now = Date()
            let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)
            
            if let days = components.day, days > 0 {
                return days == 1 ? "1 day ago" : "\(days) days ago"
            } else if let hours = components.hour, hours > 0 {
                return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
            } else if let minutes = components.minute, minutes > 0 {
                return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
            } else {
                return "Just now"
            }
        }
    }
    
    // MARK: - Contact Row
    struct ContactRow: View {
        let icon: String
        let text: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
    }
}
