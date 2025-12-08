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
    @State private var scrollOffset: CGFloat = 0
    @State private var showingInventory = false
    @State private var showingSendRequest = false
    @State private var showingMyRequests = false
    @State private var showingMyShopRequests = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var newsLoaded = false
    
    var body: some View {
        GeometryReader { geometry in
            mainContent(geometry: geometry)
        }
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.top)
        .task {
            // Load user subscriptions when view appears to check notification status
            if authService.isAuthenticated {
                shopService.loadUserSubscriptions { result in
                    // Handle result if needed
                    switch result {
                    case .success:
                        print("User subscriptions loaded successfully")
                    case .failure(let error):
                        print("Failed to load user subscriptions: \(error.localizedDescription)")
                    }
                }
            }
            
            // Load shop news from API
            await shopService.loadShopNewsFromAPI(shopId: shop.id.description)
            newsLoaded = true
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
                toastMessage = "Request sent successfully!"
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
        .sheet(isPresented: $showingMyRequests) {
            NavigationView {
                ShopReservationsView(shopId: String(shop.id))
                    .navigationTitle("My Reservations")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { showingMyRequests = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingMyShopRequests) {
            NavigationView {
                ShopRequestsView(shopId: String(shop.id), shopName: shop.name)
                    .navigationTitle("My Requests")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Close") { showingMyShopRequests = false }
                        }
                    }
            }
        }
        .withToastSupport()
    }
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header - Simplified for better performance
                    ZStack(alignment: .topLeading) {
                        // Background - Shop Photo or Gradient (Static, no parallax)
                        ZStack {
                            if let photoBase64 = shop.photoBase64, let image = base64ToImage(photoBase64) {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: geometry.size.width, height: 280)
                                    .clipped()
                                    .overlay(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.clear, .black.opacity(0.5), .black]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            } else {
                                // No photo - show default gradient
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.indigo, Color.purple.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(width: geometry.size.width, height: 280)
                                .overlay(
                                    SwiftUI.Image(systemName: "storefront.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.white.opacity(0.2))
                                        .offset(x: 30, y: -30)
                                )
                            }
                        }
                        
                        // Back Button - Only one, positioned at top-left
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            SwiftUI.Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                                .shadow(radius: 4)
                        }
                        .padding(.top, 50) // Safe area adjustment
                        .padding(.leading, 20)
                        
                        // Shop Info Overlay
                        VStack(alignment: .leading, spacing: 8) {
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Text(shop.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(radius: 4)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                if shop.isVerified {
                                    SwiftUI.Image(systemName: "checkmark.seal.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
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
                        .padding(.bottom, 20)
                    }
                    .frame(width: geometry.size.width, height: 280)
                
                VStack(spacing: 24) {
                    // MARK: - Updates Section (News + Subscribe Combined)
                    updatesSection
                    
                    // MARK: - Quick Actions (Phone, Navigate, Website) - Compact Row
                    quickActionsRow
                    
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
                .frame(width: geometry.size.width)
            }
            
            
            // Toast overlay
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage, icon: "checkmark.circle.fill", color: .green)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showToast)
            }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if authService.isAuthenticated && authService.currentUserId != nil {
                // User is logged in - show active buttons
                
                // Card 1: Inventory & Reservations
                VStack(spacing: 0) {
                    // Browse Inventory Button
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
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Divider()
                        .padding(.leading, 72)
                    
                    // My Reservations Button
                    Button(action: { showingMyRequests = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                SwiftUI.Image(systemName: "list.bullet.rectangle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("My Reservations")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("View your reservations with this shop")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            SwiftUI.Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                
                // Card 2: Requests
                VStack(spacing: 0) {
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
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Divider()
                        .padding(.leading, 72)
                    
                    // My Requests Button
                    Button(action: { showingMyShopRequests = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                SwiftUI.Image(systemName: "envelope.open.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("My Requests")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("View your requests to this shop")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            SwiftUI.Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            } else {
                // User is not logged in - show login prompt
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Sign in to interact with this shop")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Create an account or log in to browse inventory, make reservations, and send requests.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        // Navigate to login/register
                    }) {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
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
                ForEach(Array((shop.servicesList).enumerated()), id: \.offset) { index, service in
                    ServiceRow(service: service)
                    
                    if index < (shop.servicesList.count) - 1 {
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
    
    // MARK: - Updates Section (News + Subscribe Combined)
    @ViewBuilder
    private var updatesSection: some View {
        let news = shopService.getNews(for: shop.id.description)
        let hasNews = !news.isEmpty
        
        VStack(spacing: 0) {
            // Card container with rounded corners
            VStack(spacing: 0) {
                // News Section (if news exist)
                if hasNews {
                    VStack(alignment: .leading, spacing: 12) {
                        // Header
                        HStack {
                            SwiftUI.Image(systemName: "newspaper.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.purple)
                            Text("Latest News")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text("\(news.count) \(news.count == 1 ? "update" : "updates")")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // Horizontal scroll with fade effect
                        ZStack(alignment: .trailing) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(news.prefix(5)) { newsItem in
                                        CompactHorizontalNewsCard(news: newsItem)
                                            .frame(width: 220)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                            
                            // Fade effect on the right side
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(.systemBackground).opacity(0),
                                    Color(.systemBackground)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 30)
                            .allowsHitTesting(false)
                        }
                    }
                    
                    Divider()
                        .padding(.horizontal, 16)
                } else if !newsLoaded {
                    // Loading state
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Loading news...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    
                    Divider()
                        .padding(.horizontal, 16)
                }
                
                // Subscribe/Notification Section
                subscriptionSection
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Subscription Section (inside updates card)
    @ViewBuilder
    private var subscriptionSection: some View {
        VStack(spacing: 12) {
            if authService.isAuthenticated && authService.currentUserId != nil {
                if shopService.isSubscribed(to: String(shop.id)) {
                    // Subscribed state - compact
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 44, height: 44)
                            SwiftUI.Image(systemName: "bell.badge.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications Active")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("You'll receive updates from this store")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            shopService.unsubscribeFromShop(shopId: String(shop.id)) { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success:
                                        shopService.subscribedShops.remove(String(shop.id))
                                        ToastManager.shared.showSuccess("You won't receive notifications from this shop anymore.")
                                    case .failure(let error):
                                        print("Error unsubscribing: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }) {
                            SwiftUI.Image(systemName: "bell.slash")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.orange)
                                .padding(8)
                                .background(Circle().stroke(Color.orange, lineWidth: 1.5))
                        }
                    }
                    .padding(16)
                } else {
                    // Not subscribed - show subscribe button
                    Button(action: {
                        shopService.subscribeToShop(shopId: String(shop.id)) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    shopService.subscribedShops.insert(String(shop.id))
                                    ToastManager.shared.showSuccess("You'll receive notifications from this shop.")
                                case .failure(let error):
                                    print("Error subscribing: \(error.localizedDescription)")
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            SwiftUI.Image(systemName: "bell.fill")
                                .font(.system(size: 14))
                            Text("Subscribe for Updates")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(16)
                }
            } else {
                // Not authenticated
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 44, height: 44)
                        SwiftUI.Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Get Notified")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("Sign in to receive store updates")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Login")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange, lineWidth: 1.5)
                        )
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Quick Actions Row (Phone, Navigate, Website)
    @ViewBuilder
    private var quickActionsRow: some View {
        let hasPhone = shop.phoneNumber != nil
        let hasLocation = shop.latitude != nil && shop.longitude != nil
        let hasWebsite = shop.websiteUrl != nil
        
        if hasPhone || hasLocation || hasWebsite {
            HStack(spacing: 12) {
                if let phone = shop.phoneNumber {
                    QuickActionButton(icon: "phone.fill", label: "Call", color: .green) {
                        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if hasLocation {
                    QuickActionButton(icon: "location.fill", label: "Navigate", color: .blue) {
                        openInMaps()
                    }
                }
                
                if let website = shop.websiteUrl {
                    QuickActionButton(icon: "safari", label: "Website", color: .purple) {
                        if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func base64ToImage(_ base64String: String) -> SwiftUI.Image? {
        // Simple cache to avoid repeated conversions
        struct Cache {
            static var images = [String: SwiftUI.Image]()
        }
        
        if let cached = Cache.images[base64String] {
            return cached
        }
        
        // Remove data:image/jpeg;base64, prefix if present
        let cleanBase64 = base64String.replacingOccurrences(of: "data:image/[^;]+;base64,", with: "", options: .regularExpression)
        
        guard let data = Data(base64Encoded: cleanBase64),
              let uiImage = UIImage(data: data) else {
            return nil
        }
        
        let image = SwiftUI.Image(uiImage: uiImage)
        Cache.images[base64String] = image
        return image
    }
    
    private func openInMaps() {
        guard let latitude = shop.latitude, let longitude = shop.longitude else { return }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = shop.name
        
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
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
    
    // Horizontal News Card for scrolling section
    struct HorizontalNewsCard: View {
        let news: ShopNews
        
        private var newsColor: Color {
            switch news.newsType {
            case .announcement: return .blue
            case .newStock: return .green
            case .tournament: return .orange
            case .sale: return .red
            case .event: return .purple
            case .general: return .gray
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header with type badge and date
                HStack {
                    // Type badge
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: news.newsType.icon)
                            .font(.system(size: 10))
                        Text(news.newsType.displayName)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(newsColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(newsColor.opacity(0.12))
                    .cornerRadius(6)
                    
                    Spacer()
                    
                    // Pinned indicator
                    if news.isPinned {
                        SwiftUI.Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    
                    // Date
                    Text(formatDate(news.publishedDate))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                // Title
                Text(news.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Content preview
                Text(news.content)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
                
                // Expiry date if available
                if let expiryDate = news.expiryDate {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text("Expires \(formatDate(expiryDate))")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(height: 180)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM"
            return formatter.string(from: date)
        }
    }
    
    // Compact Horizontal News Card for Updates section
    struct CompactHorizontalNewsCard: View {
        let news: ShopNews
        
        private var newsColor: Color {
            switch news.newsType {
            case .announcement: return .blue
            case .newStock: return .green
            case .tournament: return .orange
            case .sale: return .red
            case .event: return .purple
            case .general: return .gray
            }
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                // Type badge + pinned
                HStack {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: news.newsType.icon)
                            .font(.system(size: 9))
                        Text(news.newsType.displayName)
                            .font(.system(size: 9, weight: .semibold))
                    }
                    .foregroundColor(newsColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(newsColor.opacity(0.12))
                    .cornerRadius(4)
                    
                    if news.isPinned {
                        SwiftUI.Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text(timeAgo(from: news.publishedDate))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                // Title
                Text(news.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Content preview
                Text(news.content)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(12)
            .frame(height: 110)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        
        private func timeAgo(from date: Date) -> String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
    
    // Quick Action Button for compact contact row
    struct QuickActionButton: View {
        let icon: String
        let label: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.12))
                            .frame(width: 48, height: 48)
                        SwiftUI.Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(color)
                    }
                    
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // FlowLayout helper for services
    struct FlowLayout: Layout {
        var spacing: CGFloat = 8
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let rows = computeRows(proposal: proposal, subviews: subviews)
            let rowHeight = 20
            let totalRowHeight = rows.count * rowHeight
            let spacingHeight = max(0, rows.count - 1) * Int(spacing)
            let height = totalRowHeight + spacingHeight
            return CGSize(width: proposal.width ?? 0, height: CGFloat(height))
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
                y += 20 + spacing
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
                    TCGIconView(tcgType: tcg, size: 16, color: .white)
                    
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
        let service: ShopServiceType
        
        var body: some View {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    SwiftUI.Image(systemName: service.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)
                }
                
                Text(service.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

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
