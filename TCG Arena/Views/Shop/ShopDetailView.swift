//
//  ShopDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import SwiftUI
import MapKit

struct ShopDetailView: View {
    let shop: Shop
    @EnvironmentObject var shopService: ShopService
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var showingSubscribeAlert = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showingInventory = false
    @State private var showingSendRequest = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    private var alertTitle: String {
        shopService.isSubscribed(to: shop.id.description) ? "Subscribed!" : "Unsubscribed"
    }
    
    private var alertMessage: String {
        shopService.isSubscribed(to: shop.id.description)
        ? "You'll receive notifications about new products, events, and tournaments from \(shop.name)."
        : "You won't receive notifications from \(shop.name) anymore."
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    GeometryReader { geometry in
                        let offset = geometry.frame(in: .global).minY
                        
                        ZStack(alignment: .bottomLeading) {
                            // Background Gradient
                            LinearGradient(
                                gradient: Gradient(colors: [Color.indigo, Color.purple.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .overlay(
                                SwiftUI.Image(systemName: "storefront.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.white.opacity(0.15))
                                    .offset(x: 20, y: -20)
                            )
                            .frame(height: max(250, 250 + offset))
                            .clipped()
                            
                            // Gradient Overlay
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                            .offset(y: min(0, -offset))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text(shop.name)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(radius: 4)
                                    
                                    if shop.isVerified {
                                        SwiftUI.Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                HStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 13))
                                    Text(shop.address)
                                        .font(.system(size: 13, weight: .medium))
                                        .lineLimit(1)
                                }
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(radius: 2)
                            }
                            .padding(20)
                            .offset(y: min(0, -offset))
                        }
                    }
                    .frame(height: 250)
                    
                    VStack(spacing: 24) {
                        // Subscription Status/Button
                        VStack(spacing: 16) {
                            if authService.isAuthenticated && authService.currentUserId != nil {
                                // User is authenticated - show subscription functionality
                                if shopService.isSubscribed(to: String(shop.id)) {
                                    // Subscribed Status Card
                                    HStack {
                                        SwiftUI.Image(systemName: "bell.badge.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.orange)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Notifications Active")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.primary)
                                            
                                            Text("You'll receive updates from this store")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(20)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                                    
                                    // Unsubscribe Button
                                    Button(action: {
                                        shopService.unsubscribeFromShop(shopId: String(shop.id)) { result in
                                            DispatchQueue.main.async {
                                                switch result {
                                                case .success:
                                                    shopService.subscribedShops.remove(String(shop.id))
                                                    showingSubscribeAlert = true
                                                case .failure(let error):
                                                    print("Error unsubscribing: \(error.localizedDescription)")
                                                    // TODO: Show error alert
                                                }
                                            }
                                        }
                                    }) {
                                        HStack {
                                            SwiftUI.Image(systemName: "bell.slash.fill")
                                                .font(.system(size: 16))
                                            Text("Unsubscribe")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(.orange)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.orange, lineWidth: 2)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                } else {
                                    // Subscribe Button
                                    Button(action: {
                                        shopService.subscribeToShop(shopId: String(shop.id)) { result in
                                            DispatchQueue.main.async {
                                                switch result {
                                                case .success:
                                                    shopService.subscribedShops.insert(String(shop.id))
                                                    showingSubscribeAlert = true
                                                case .failure(let error):
                                                    print("Error subscribing: \(error.localizedDescription)")
                                                    // TODO: Show error alert
                                                }
                                            }
                                        }
                                    }) {
                                        HStack {
                                            SwiftUI.Image(systemName: "bell.fill")
                                                .font(.system(size: 16))
                                            Text("Subscribe for Updates")
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.orange)
                                                .shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            } else {
                                // User is not authenticated - show disabled subscription button
                                ZStack {
                                    HStack {
                                        SwiftUI.Image(systemName: "bell.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                        Text("Subscribe for Updates")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.gray.opacity(0.2))
                                    )
                                    
                                    // Login Required Badge
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            Text("Registrati o fai login")
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.orange)
                                                .cornerRadius(8)
                                                .shadow(radius: 2)
                                        }
                                        .padding(8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Quick Info Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            if let phone = shop.phoneNumber {
                                QuickInfoCard(icon: "phone.fill", title: "Phone", value: phone, color: .green) {
                                    if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                            
                            if shop.latitude != nil && shop.longitude != nil {
                                QuickInfoCard(icon: "mappin.circle.fill", title: "Navigate", value: "Directions", color: .red) {
                                    openInMaps()
                                }
                            }
                            
                            if let website = shop.websiteUrl {
                                QuickInfoCard(icon: "globe", title: "Website", value: "Visit", color: .blue) {
                                    if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Action Buttons - Inventory & Request
                        actionButtonsSection
                        
                        // TCG Types Section
                        if let tcgTypes = shop.tcgTypes, !tcgTypes.isEmpty {
                            tcgTypesSection
                        }
                        
                        // Services Section (Enhanced)
                        if let services = shop.services, !services.isEmpty {
                            servicesSection
                        }
                        
                        // News Section
                        if !shopService.getNews(for: shop.id.description).isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Latest News", icon: "newspaper.fill", color: .purple)
                                    .padding(.horizontal, 20)
                                
                                VStack(spacing: 12) {
                                    ForEach(shopService.getNews(for: shop.id.description).prefix(3)) { newsItem in
                                        CompactNewsCard(news: newsItem)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "About", icon: "info.circle.fill", color: .blue)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text(shop.description ?? "No description available.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Location Section
                        if shop.latitude != nil && shop.longitude != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Location", icon: "mappin.circle.fill", color: .red)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(shop.address)
                                        .font(.system(size: 15, weight: .medium))
                                    
                                    HStack(alignment: .top, spacing: 8) {
                                        SwiftUI.Image(systemName: "clock.fill")
                                            .foregroundColor(.orange)
                                            .font(.system(size: 14))
                                        
                                        if let hours = shop.openingHours {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Open Today")
                                                    .font(.system(size: 14, weight: .medium))
                                                Text(hours)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.secondary)
                                            }
                                        } else {
                                            Text("Hours not available")
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Button(action: openInMaps) {
                                        Text("Get Directions")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Contact Section
                        if shop.email != nil || shop.instagramUrl != nil || shop.facebookUrl != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Social", icon: "at.circle.fill", color: .pink)
                                
                                VStack(spacing: 12) {
                                    if let email = shop.email {
                                        SocialButton(icon: "envelope.fill", title: "Email", color: .blue) {
                                            if let url = URL(string: "mailto:\(email)") {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    }
                                    
                                    if let instagram = shop.instagramUrl {
                                        SocialButton(icon: "camera.fill", title: "Instagram", color: .pink) {
                                            if let url = URL(string: instagram.hasPrefix("http") ? instagram : "https://instagram.com/\(instagram)") {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    }
                                    
                                    if let facebook = shop.facebookUrl {
                                        SocialButton(icon: "f.square.fill", title: "Facebook", color: .blue) {
                                            if let url = URL(string: facebook.hasPrefix("http") ? facebook : "https://facebook.com/\(facebook)") {
                                                UIApplication.shared.open(url)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 24)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            // Custom Navigation Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    SwiftUI.Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 50) // Adjust for safe area
        }
        .navigationBarHidden(true)
        .alert(alertTitle, isPresented: $showingSubscribeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingInventory) {
            NavigationView {
                ShopInventoryView(shopId: String(shop.id))
                    .environmentObject(inventoryService)
                    .navigationTitle("Inventory")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { showingInventory = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSendRequest) {
            SendRequestToShopView(shop: shop, onRequestSent: {
                showingSendRequest = false
                toastMessage = "Request sent to \(shop.name)!"
                withAnimation {
                    showToast = true
                }
                // Hide toast after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showToast = false
                    }
                }
            })
        }
        .toast(message: toastMessage, isPresented: showToast)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if authService.isAuthenticated && authService.currentUserId != nil {
                // User is logged in - show active buttons
                // View Inventory Button
                Button(action: { showingInventory = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Browse Inventory")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("View available cards and prices")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        SwiftUI.Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Send Request Button
                Button(action: { showingSendRequest = true }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            SwiftUI.Image(systemName: "envelope.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Send Request")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Text("Ask about availability, prices, or more")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        SwiftUI.Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                // User is not logged in - show disabled buttons with login prompt
                // View Inventory Button (Disabled)
                ZStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Browse Inventory")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            Text("View available cards and prices")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        SwiftUI.Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    
                    // Login Required Badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Registrati o fai login")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
                }
                
                // Send Request Button (Disabled)
                ZStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            SwiftUI.Image(systemName: "envelope.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Send Request")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            Text("Ask about availability, prices, or more")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        SwiftUI.Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                    
                    // Login Required Badge
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Registrati o fai login")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                        }
                        .padding(8)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - TCG Types Section
    private var tcgTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Supported Games", icon: "gamecontroller.fill", color: .purple)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(shop.tcgTypes ?? [], id: \.self) { tcgType in
                        ShopTCGTypeBadge(tcgTypeString: tcgType)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Services Section
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Services", icon: "star.fill", color: .orange)
            
            VStack(spacing: 0) {
                ForEach(Array((shop.services ?? []).enumerated()), id: \.offset) { index, service in
                    ServiceRow(serviceName: service)
                    
                    if index < (shop.services?.count ?? 0) - 1 {
                        Divider()
                            .padding(.leading, 52)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }
    
    private func openInMaps() {
        guard let latitude = shop.latitude, let longitude = shop.longitude else { return }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = shop.name
        mapItem.openInMaps()
    }
    
    // MARK: - Subviews
    
    struct QuickInfoCard: View {
        let icon: String
        let title: String
        let value: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SwiftUI.Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundColor(color)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(value)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    struct SectionHeader: View {
        let title: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 8) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }
    
    struct SocialButton: View {
        let icon: String
        let title: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                        .frame(width: 24)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    SwiftUI.Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    struct CompactNewsCard: View {
        let news: ShopNews
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                SwiftUI.Image(systemName: news.newsType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.purple))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(news.newsType.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        Text(timeAgo(from: news.publishedDate))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(news.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(news.content)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        
        private func timeAgo(from date: Date) -> String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
    
    // FlowLayout helper for services
    struct FlowLayout: Layout {
        var spacing: CGFloat = 8
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let rows = computeRows(proposal: proposal, subviews: subviews)
            let height = rows.reduce(0) { $0 + $1.maxHeight } + CGFloat(max(0, rows.count - 1)) * spacing
            return CGSize(width: proposal.width ?? 0, height: height)
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let rows = computeRows(proposal: proposal, subviews: subviews)
            var y = bounds.minY
            
            for row in rows {
                var x = bounds.minX
                for index in row.indices {
                    let size = subviews[index].sizeThatFits(.unspecified)
                    subviews[index].place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                    x += size.width + spacing
                }
                y += row.maxHeight + spacing
            }
        }
        
        private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
            var rows: [[Int]] = [[]]
            var currentRowWidth: CGFloat = 0
            let maxWidth = proposal.width ?? .infinity
            
            for (index, subview) in subviews.enumerated() {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentRowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                    rows.append([index])
                    currentRowWidth = size.width + spacing
                } else {
                    rows[rows.count - 1].append(index)
                    currentRowWidth += size.width + spacing
                }
            }
            
            return rows
        }
    }
    
    // MARK: - Shop TCG Type Badge (local styled version)
    struct ShopTCGTypeBadge: View {
        let tcgTypeString: String
        
        private var tcgType: TCGType? {
            TCGType(rawValue: tcgTypeString)
        }
        
        var body: some View {
            if let tcg = tcgType {
                HStack(spacing: 8) {
                    SwiftUI.Image(systemName: tcg.systemIcon)
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(tcg.displayName)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tcg.themeColor)
                        .shadow(color: tcg.themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            } else {
                // Fallback for unknown TCG types
                HStack(spacing: 8) {
                    SwiftUI.Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text(tcgTypeString)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray)
                        .shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
        }
    }
    
    // MARK: - Service Row
    struct ServiceRow: View {
        let serviceName: String
        
        private var serviceInfo: (icon: String, color: Color) {
            switch serviceName.lowercased() {
            case let s where s.contains("card sales"), let s where s.contains("vendita"):
                return ("creditcard.fill", .green)
            case let s where s.contains("buy"), let s where s.contains("acquisto"):
                return ("dollarsign.circle.fill", .blue)
            case let s where s.contains("tournament"), let s where s.contains("torneo"):
                return ("trophy.fill", .orange)
            case let s where s.contains("play area"), let s where s.contains("area gioco"):
                return ("gamecontroller.fill", .purple)
            case let s where s.contains("grading"), let s where s.contains("valutazione"):
                return ("star.fill", .yellow)
            case let s where s.contains("accessories"), let s where s.contains("accessori"):
                return ("bag.fill", .pink)
            case let s where s.contains("pre-order"), let s where s.contains("prenotazione"):
                return ("calendar.badge.plus", .cyan)
            case let s where s.contains("online"):
                return ("globe", .indigo)
            default:
                return ("checkmark.circle.fill", .gray)
            }
        }
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(serviceInfo.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    SwiftUI.Image(systemName: serviceInfo.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(serviceInfo.color)
                }
                
                Text(serviceName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

extension Array where Element == Int {
    var maxHeight: CGFloat { 20 }
}

// MARK: - Toast Components
struct ToastView: View {
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.bottom, 40)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct ToastModifier: ViewModifier {
    let message: String
    let icon: String
    let color: Color
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresented {
                    ToastView(message: message, icon: icon, color: color)
                }
            }
    }
}

extension View {
    func toast(message: String, icon: String = "checkmark.circle.fill", color: Color = .green, isPresented: Bool) -> some View {
        self.modifier(ToastModifier(message: message, icon: icon, color: color, isPresented: isPresented))
    }
}

