//
//  ShopDetailView.swift
//  TCG Arena
//
//  Redesigned with Home-style minimal aesthetic
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI
import MapKit

struct ShopDetailView: View {
    let shop: Shop
    @EnvironmentObject var shopService: ShopService
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingInventory = false
    @State private var showingSendRequest = false
    @State private var showingMyRequests = false
    @State private var showingMyShopRequests = false
    @State private var showingTournamentRequest = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var newsLoaded = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // MARK: - Shop Image Header
                        shopImageHeader(width: geometry.size.width)
                        
                        VStack(alignment: .leading, spacing: 32) {
                            // MARK: - Header Section
                            headerSection
                            
                            // MARK: - Quick Stats Grid
                            quickStatsGrid
                            
                            // MARK: - News Carousel (if any)
                            newsSection
                            
                            // MARK: - Quick Actions
                            quickActionsSection
                            
                            // MARK: - Action Buttons
                            actionButtonsSection
                            
                            // MARK: - TCG Types
                            if let tcgTypes = shop.tcgTypes, !tcgTypes.isEmpty {
                                tcgTypesSection
                            }
                            
                            // MARK: - Services
                            if let services = shop.services, !services.isEmpty {
                                servicesSection
                            }
                            
                            // MARK: - About
                            if let description = shop.description, !description.isEmpty {
                                aboutSection(description: description)
                            }
                            
                            // MARK: - Location & Hours
                            if shop.latitude != nil && shop.longitude != nil {
                                locationSection
                            }
                            
                            // MARK: - Social Links
                            if shop.email != nil || shop.instagramUrl != nil || shop.facebookUrl != nil {
                                socialSection
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 24)
                    }
                }
                
                // MARK: - Top Bar
                topBar
                
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
        .navigationBarHidden(true)
        .task {
            // Load subscriptions first, awaiting completion so isSubscribed() works correctly
            if authService.isAuthenticated {
                await withCheckedContinuation { continuation in
                    shopService.loadUserSubscriptions { _ in
                        continuation.resume()
                    }
                }
            }
            await shopService.loadShopNewsFromAPI(shopId: shop.id.description)
            newsLoaded = true
        }
        .sheet(isPresented: $showingInventory) {
            NavigationView {
                ShopInventoryView(shopId: String(shop.id))
                    .environmentObject(inventoryService)
                    .navigationTitle("Inventario")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Chiudi") { showingInventory = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingSendRequest) {
            SendRequestToShopView(shop: shop, onRequestSent: {
                showingSendRequest = false
                toastMessage = "Richiesta inviata con successo!"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showToast = false }
                }
            })
        }
        .sheet(isPresented: $showingMyRequests) {
            NavigationView {
                ShopReservationsView(shopId: String(shop.id))
                    .navigationTitle("Le Mie Prenotazioni")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Chiudi") { showingMyRequests = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingMyShopRequests) {
            NavigationView {
                ShopRequestsView(shopId: String(shop.id), shopName: shop.name)
                    .navigationTitle("Le Mie Richieste")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Chiudi") { showingMyShopRequests = false }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingTournamentRequest) {
            TournamentRequestView(shop: shop)
                .environmentObject(authService)
        }
    }
    
    // MARK: - Shop Image Header
    @ViewBuilder
    private func shopImageHeader(width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Image or placeholder
            if let photoBase64 = shop.photoBase64, let image = base64ToImage(photoBase64) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: 220)
                    .clipped()
            } else {
                // No photo - show minimal placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: width, height: 220)
                    .overlay(
                        SwiftUI.Image(systemName: "storefront.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.3))
                    )
            }
            
            // Subtle gradient at bottom for smooth transition
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.white.opacity(0.5),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
        }
        .frame(width: width, height: 220)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                SwiftUI.Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
            
            Spacer()
            
            // Notification bell
            if authService.isAuthenticated {
                Button(action: toggleSubscription) {
                    SwiftUI.Image(systemName: shopService.isSubscribed(to: String(shop.id)) ? "bell.fill" : "bell")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Shop Name
            HStack(spacing: 10) {
                Text(shop.name)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.primary)
                
                if shop.isVerified {
                    SwiftUI.Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
            }
            
            // Address
            HStack(spacing: 6) {
                SwiftUI.Image(systemName: "mappin")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Text(shop.address)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Open/Closed status
            if let structured = shop.openingHoursStructured {
                HStack(spacing: 8) {
                    Circle()
                        .fill(structured.isOpenNow ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(structured.isOpenNow ? "Aperto ora" : "Chiuso")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(structured.isOpenNow ? .green : .orange)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(structured.todaySchedule.displayString)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
    
    // MARK: - Quick Stats Grid
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let tcgTypes = shop.tcgTypes {
                MinimalStatTile(value: "\(tcgTypes.count)", label: "TCG Supportati")
            }
            
            let news = shopService.getNews(for: shop.id.description)
            MinimalStatTile(value: "\(news.count)", label: "Novità")
            
            if let services = shop.services {
                MinimalStatTile(value: "\(services.count)", label: "Servizi")
            }
            
            if shopService.isSubscribed(to: String(shop.id)) {
                MinimalStatTile(value: "Attivo", label: "Notifiche", isHighlighted: true)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - News Section
    @ViewBuilder
    private var newsSection: some View {
        let news = shopService.getNews(for: shop.id.description)
        
        if !news.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Novità")
                        .font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                    
                    Text("\(news.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(news.prefix(5)) { newsItem in
                            MinimalNewsCard(news: newsItem)
                                .frame(width: 280)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        } else if !newsLoaded {
            HStack {
                Spacer()
                ProgressView()
                Text("Caricamento...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Quick Actions Section
    @ViewBuilder
    private var quickActionsSection: some View {
        let hasPhone = shop.phoneNumber != nil
        let hasLocation = shop.latitude != nil && shop.longitude != nil
        let hasWebsite = shop.websiteUrl != nil
        
        if hasPhone || hasLocation || hasWebsite {
            VStack(alignment: .leading, spacing: 16) {
                Text("Contatta")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.horizontal, 24)
                
                HStack(spacing: 12) {
                    if let phone = shop.phoneNumber {
                        MinimalQuickAction(icon: "phone.fill", label: "Chiama") {
                            if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    
                    if hasLocation {
                        MinimalQuickAction(icon: "location.fill", label: "Naviga") {
                            openInMaps()
                        }
                    }
                    
                    if let website = shop.websiteUrl {
                        MinimalQuickAction(icon: "safari", label: "Sito Web") {
                            if let url = URL(string: website.hasPrefix("http") ? website : "https://\(website)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Azioni")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 24)
            
            if authService.isAuthenticated && authService.currentUserId != nil {
                VStack(spacing: 12) {
                    ShopActionRow(title: "Sfoglia Inventario", subtitle: "Carte e prezzi disponibili", icon: "square.stack.3d.up.fill") {
                        showingInventory = true
                    }
                    
                    ShopActionRow(title: "Le Mie Prenotazioni", subtitle: "Gestisci le tue prenotazioni", icon: "list.bullet.rectangle") {
                        showingMyRequests = true
                    }
                    
                    ShopActionRow(title: "Invia Richiesta", subtitle: "Chiedi informazioni", icon: "envelope") {
                        showingSendRequest = true
                    }
                    
                    ShopActionRow(title: "Richiedi Torneo", subtitle: "Proponi un evento", icon: "trophy") {
                        showingTournamentRequest = true
                    }
                    
                    ShopActionRow(title: "Le Mie Richieste", subtitle: "Storico richieste inviate", icon: "envelope.open") {
                        showingMyShopRequests = true
                    }
                }
                .padding(.horizontal, 24)
            } else {
                // Login prompt
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "person.crop.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Accedi per interagire")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Sfoglia l'inventario, fai prenotazioni e invia richieste.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(20)
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - TCG Types Section
    private var tcgTypesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Giochi Supportati")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(shop.tcgTypes ?? [], id: \.self) { tcgTypeString in
                        MinimalTCGBadge(tcgTypeString: tcgTypeString)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Services Section
    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Servizi")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                ForEach(Array(shop.servicesList.enumerated()), id: \.offset) { index, service in
                    MinimalServiceRow(service: service)
                    
                    if index < shop.servicesList.count - 1 {
                        Divider()
                            .padding(.horizontal, 24)
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - About Section
    private func aboutSection(description: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Info")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 24)
            
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Posizione")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 24)
            
            VStack(alignment: .leading, spacing: 16) {
                // Address
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    Text(shop.address)
                        .font(.system(size: 15, weight: .medium))
                }
                
                // Opening Hours
                if let structured = shop.openingHoursStructured {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            SwiftUI.Image(systemName: "clock.fill")
                                .foregroundColor(structured.isOpenNow ? .green : .orange)
                            Text(structured.isOpenNow ? "Aperto ora" : "Chiuso")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(structured.isOpenNow ? .green : .orange)
                        }
                        
                        DisclosureGroup("Orari Settimanali") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(structured.allDays.enumerated()), id: \.0) { _, day in
                                    HStack {
                                        Text(day.0)
                                            .font(.system(size: 13, weight: .medium))
                                            .frame(width: 80, alignment: .leading)
                                        Text(day.1.displayString)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                        .font(.system(size: 14, weight: .medium))
                    }
                } else if let hours = shop.openingHours {
                    HStack(spacing: 8) {
                        SwiftUI.Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(hours)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Navigate button
                Button(action: openInMaps) {
                    HStack {
                        SwiftUI.Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Ottieni indicazioni")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Social Section
    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social")
                .font(.system(size: 20, weight: .bold))
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                if let email = shop.email {
                    MinimalSocialRow(icon: "envelope.fill", title: "Email", value: email) {
                        if let url = URL(string: "mailto:\(email)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if let instagram = shop.instagramUrl {
                    MinimalSocialRow(icon: "camera.fill", title: "Instagram", value: "@instagram") {
                        if let url = URL(string: instagram.hasPrefix("http") ? instagram : "https://instagram.com/\(instagram)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if let facebook = shop.facebookUrl {
                    MinimalSocialRow(icon: "hand.thumbsup.fill", title: "Facebook", value: "Facebook") {
                        if let url = URL(string: facebook.hasPrefix("http") ? facebook : "https://facebook.com/\(facebook)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Helper Functions
    private func toggleSubscription() {
        if shopService.isSubscribed(to: String(shop.id)) {
            shopService.unsubscribeFromShop(shopId: String(shop.id)) { result in
                if case .success = result {
                    ToastManager.shared.showSuccess("Notifiche disattivate")
                }
            }
        } else {
            shopService.subscribeToShop(shopId: String(shop.id)) { result in
                if case .success = result {
                    ToastManager.shared.showSuccess("Notifiche attivate")
                }
            }
        }
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
    
    private func base64ToImage(_ base64String: String) -> SwiftUI.Image? {
        struct Cache {
            static var images = [String: SwiftUI.Image]()
        }
        
        if let cached = Cache.images[base64String] {
            return cached
        }
        
        let cleanBase64 = base64String.replacingOccurrences(of: "data:image/[^;]+;base64,", with: "", options: .regularExpression)
        
        guard let data = Data(base64Encoded: cleanBase64),
              let uiImage = UIImage(data: data) else {
            return nil
        }
        
        let image = SwiftUI.Image(uiImage: uiImage)
        Cache.images[base64String] = image
        return image
    }
}

// MARK: - Minimal Components

struct MinimalStatTile: View {
    let value: String
    let label: String
    var isHighlighted: Bool = false
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(isHighlighted ? .orange : .primary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
}

struct MinimalNewsCard: View {
    let news: ShopNews
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(news.newsType.displayName.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(1)
            
            Text(news.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(news.content)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            Spacer()
            
            Text(formatDate(news.publishedDate))
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .padding(16)
        .frame(height: 150)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

struct MinimalQuickAction: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShopActionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MinimalTCGBadge: View {
    let tcgTypeString: String
    
    private var tcgType: TCGType? {
        TCGType(rawValue: tcgTypeString)
    }
    
    var body: some View {
        if let tcg = tcgType {
            HStack(spacing: 8) {
                TCGIconView(tcgType: tcg, size: 16)
                Text(tcg.displayName)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.08))
            .cornerRadius(20)
        } else {
            Text(tcgTypeString)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(20)
        }
    }
}

struct MinimalServiceRow: View {
    let service: ShopServiceType
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: service.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 24)
            
            Text(service.displayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

struct MinimalSocialRow: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    Text(value)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                SwiftUI.Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
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
