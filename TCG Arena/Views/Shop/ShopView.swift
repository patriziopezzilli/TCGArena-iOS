//
//  ShopView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import SwiftUI
import MapKit
import CoreLocation
import SkeletonUI

struct ShopView: View {
    @EnvironmentObject var shopService: ShopService
    @EnvironmentObject var tournamentService: TournamentService
    @StateObject private var locationManager = LocationManager()
    @State private var selectedSection = 0
    @State private var showingLocationInput = false
    @AppStorage("userLocationText") private var userLocationText = "Milano, Italy"
    @AppStorage("savedLocationLatitude") private var savedLatitude: Double = 45.4642
    @AppStorage("savedLocationLongitude") private var savedLongitude: Double = 9.1900
    @State private var hasLoadedInitialData = false
    @State private var isLoading = true

    // Custom colors
    private let bgGradient = LinearGradient(
        gradient: Gradient(colors: [Color(.systemBackground), Color(.secondarySystemBackground)]),
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Modern Header
                    VStack(spacing: 16) {
                        // Top Bar with Location
                        HStack {
                            Text("Esplora")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.primary)

                            Spacer()

                            // Location Pill
                            Button(action: { showingLocationInput = true }) {
                                HStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "mappin.and.ellipse")
                                        .font(.system(size: 14))
                                        .foregroundColor(.blue)

                                    Text(userLocationText)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    SwiftUI.Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)

                        // Custom Segmented Control
                        HStack(spacing: 0) {
                            CompactTabButton(
                                icon: "storefront.fill",
                                label: "Negozi",
                                isSelected: selectedSection == 0
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSection = 0
                                }
                            }

                            CompactTabButton(
                                icon: "calendar",
                                label: "Eventi",
                                isSelected: selectedSection == 1
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSection = 1
                                }
                            }
                            
                            CompactTabButton(
                                icon: "list.clipboard.fill",
                                label: "Attività",
                                isSelected: selectedSection == 2
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSection = 2
                                }
                            }
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                    .background(
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    )
                    .zIndex(1)

                    // Content
                    Group {
                        if selectedSection == 0 {
                            ShopListView()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .leading)),
                                    removal: .opacity.combined(with: .move(edge: .trailing))
                                ))
                        } else if selectedSection == 1 {
                            EventListView()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        } else {
                            MyActivityView()
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                                    removal: .opacity.combined(with: .move(edge: .leading))
                                ))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedSection)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                guard !hasLoadedInitialData else { return }
                hasLoadedInitialData = true
                
                // Load tournaments
                await tournamentService.loadTournaments()

                // Use saved location or device location or default
                let locationToUse: CLLocation
                if let userLocation = locationManager.location {
                    locationToUse = userLocation
                } else {
                    // Use saved coordinates from UserDefaults
                    locationToUse = CLLocation(latitude: savedLatitude, longitude: savedLongitude)
                }
                await tournamentService.loadNearbyTournaments(userLocation: locationToUse)

                isLoading = false
            }
            .sheet(isPresented: $showingLocationInput) {
                LocationInputView(locationText: $userLocationText) { newLocation in
                    // Save coordinates to UserDefaults
                    savedLatitude = newLocation.coordinate.latitude
                    savedLongitude = newLocation.coordinate.longitude
                    
                    // Force UI refresh by triggering objectWillChange
                    shopService.objectWillChange.send()
                    tournamentService.objectWillChange.send()
                    
                    // Reload shops and tournaments with new location
                    Task {
                        await shopService.loadAllShops(forceRefresh: true)
                        await tournamentService.loadNearbyTournaments(userLocation: newLocation)
                    }
                }
            }
        }
    }
}

// MARK: - Custom Segment Button


// MARK: - Shop List View
struct ShopListView: View {
    @EnvironmentObject var shopService: ShopService
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var authService: AuthService
    @StateObject private var locationManager = LocationManager()
    @AppStorage("savedLocationLatitude") private var savedLatitude: Double = 45.4642
    @AppStorage("savedLocationLongitude") private var savedLongitude: Double = 9.1900
    
    // MARK: - View Mode (persisted)
    @AppStorage("shopListViewMode") private var isCompactMode: Bool = false
    
    // MARK: - Filter State
    @State private var shopFilters = ShopFilters()
    @State private var showingFilters = false
    
    // MARK: - Filtered Shops
    private var filteredShops: [Shop] {
        // Priority: Use saved location if user has set one (not default Milano), otherwise use LocationManager
        // Default Milano coordinates: 45.4642, 9.1900
        let isDefaultLocation = (savedLatitude == 45.4642 && savedLongitude == 9.1900)
        let userLocation: CLLocation
        
        if !isDefaultLocation {
            // User has set a custom location - use it
            userLocation = CLLocation(latitude: savedLatitude, longitude: savedLongitude)
        } else if let deviceLocation = locationManager.location {
            // Use device GPS location
            userLocation = deviceLocation
        } else {
            // Fallback to saved (default) location
            userLocation = CLLocation(latitude: savedLatitude, longitude: savedLongitude)
        }
        
        var result = shopService.nearbyShops
        
        // Apply 20km distance filter
        if shopFilters.onlyNearby {
            result = result.filter { shop in
                guard let lat = shop.latitude, let lon = shop.longitude else {
                    return true // Include shops without location
                }
                let shopLocation = CLLocation(latitude: lat, longitude: lon)
                let distanceKm = userLocation.distance(from: shopLocation) / 1000
                return distanceKm <= 20
            }
        }
        
        // Apply TCG type filter
        if !shopFilters.selectedTCGTypes.isEmpty {
            result = result.filter { shop in
                // Check if shop's available TCGs intersect with selected filters
                // For now, include all shops since we don't have TCG types on shop model
                return true
            }
        }
        
        // Sort by distance
        result.sort { shop1, shop2 in
            let dist1 = distanceToShop(shop1, from: userLocation)
            let dist2 = distanceToShop(shop2, from: userLocation)
            return dist1 < dist2
        }
        
        return result
    }
    
    private func distanceToShop(_ shop: Shop, from location: CLLocation) -> Double {
        guard let lat = shop.latitude, let lon = shop.longitude else {
            return Double.infinity
        }
        let shopLocation = CLLocation(latitude: lat, longitude: lon)
        return location.distance(from: shopLocation) / 1000
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // MARK: - Premium Toolbar
                    HStack(spacing: 12) {
                        // Store count pill
                        HStack(spacing: 6) {
                            SwiftUI.Image(systemName: "storefront.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text("\(filteredShops.count)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.indigo)
                        )
                        
                        // Nearby badge
                        if shopFilters.onlyNearby {
                            HStack(spacing: 4) {
                                SwiftUI.Image(systemName: "location.fill")
                                    .font(.system(size: 10, weight: .semibold))
                                Text("20km")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.12))
                            )
                        }
                        
                        Spacer()
                        
                        // Loading indicator
                        if shopService.isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        
                        // View Mode Toggle
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isCompactMode.toggle()
                            }
                            HapticManager.shared.selectionChanged()
                        }) {
                            SwiftUI.Image(systemName: isCompactMode ? "square.grid.2x2" : "rectangle.grid.1x2")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(.label))
                                .frame(width: 38, height: 34)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(.secondarySystemFill))
                                )
                        }
                        
                        // Filter button
                        Button(action: {
                            showingFilters = true
                            HapticManager.shared.selectionChanged()
                        }) {
                            ZStack(alignment: .topTrailing) {
                                SwiftUI.Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(shopFilters.isActive ? .white : Color(.label))
                                    .frame(width: 38, height: 34)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(shopFilters.isActive ? Color.indigo : Color(.secondarySystemFill))
                                    )
                                
                                if shopFilters.activeFilterCount > 0 {
                                    Text("\(shopFilters.activeFilterCount)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(width: 15, height: 15)
                                        .background(Circle().fill(Color.red))
                                        .offset(x: 5, y: -5)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    if filteredShops.isEmpty && !shopService.isLoading {
                        // MARK: - Premium Empty State
                        VStack(spacing: 32) {
                            // Animated icon with rings
                            ZStack {
                                // Outer ring
                                Circle()
                                    .stroke(Color(.systemGray5), lineWidth: 2)
                                    .frame(width: 140, height: 140)
                                
                                // Middle ring
                                Circle()
                                    .stroke(Color(.systemGray4), lineWidth: 2)
                                    .frame(width: 110, height: 110)
                                
                                // Inner solid circle with icon
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 80, height: 80)
                                
                                SwiftUI.Image(systemName: shopFilters.onlyNearby ? "mappin.slash" : "storefront")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(Color(.systemGray))
                            }
                            
                            // Text content
                            VStack(spacing: 10) {
                                Text(shopFilters.onlyNearby ? "Nessun negozio nelle vicinanze" : "Nessun negozio trovato")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(shopFilters.onlyNearby 
                                    ? "Non ci sono negozi entro 20km dalla tua posizione. Prova ad ampliare la ricerca."
                                    : "Non sono stati trovati negozi disponibili al momento.")
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(4)
                                    .padding(.horizontal, 24)
                            }
                            
                            // Action buttons
                            VStack(spacing: 14) {
                                if shopFilters.onlyNearby {
                                    // Primary CTA - Show all stores
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            shopFilters.onlyNearby = false
                                        }
                                        HapticManager.shared.selectionChanged()
                                    }) {
                                        HStack(spacing: 8) {
                                            SwiftUI.Image(systemName: "globe")
                                                .font(.system(size: 15, weight: .semibold))
                                            Text("Mostra tutti i negozi")
                                                .font(.system(size: 15, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: 220)
                                        .padding(.vertical, 14)
                                        .background(Color.indigo)
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                    }
                                }
                                
                                // Secondary CTA - Reload
                                Button(action: {
                                    HapticManager.shared.selectionChanged()
                                    Task {
                                        await shopService.loadAllShops(forceRefresh: true)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        SwiftUI.Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 13, weight: .medium))
                                        Text("Aggiorna")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.tertiarySystemFill))
                                    )
                                }
                            }
                            
                            if let errorMessage = shopService.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 13))
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 80)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        )
                        .padding(.top, 20)
                    } else {
                        ForEach(filteredShops) { shop in
                            NavigationLink(destination: ShopDetailView(shop: shop)
                                .environmentObject(shopService)
                                .environmentObject(inventoryService)
                                .environmentObject(authService)) {
                                if isCompactMode {
                                    CompactShopCardView(shop: shop, hasNews: !shopService.getNews(for: shop.id.description).isEmpty)
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                } else {
                                    ShopCardView(shop: shop, hasNews: !shopService.getNews(for: shop.id.description).isEmpty)
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .animation(.easeInOut(duration: 0.3), value: isCompactMode)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .refreshable {
                // Haptic feedback on refresh
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // Force refresh from server
                await shopService.loadAllShops(forceRefresh: true)
            }
            
            // Loading overlay
            if shopService.isLoading && shopService.nearbyShops.isEmpty {
                Color(.systemBackground)
                    .opacity(0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Caricamento negozi vicini...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .task {
            // Load shops when view appears
            if shopService.nearbyShops.isEmpty {
                let locationToUse = locationManager.location ?? CLLocation(latitude: savedLatitude, longitude: savedLongitude)
                await shopService.loadNearbyShops(userLocation: locationToUse)
            }
        }
        .sheet(isPresented: $showingFilters) {
            ShopFiltersView(filters: $shopFilters, isPresented: $showingFilters) {
                // Filters applied - view will update automatically
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Event List View
struct EventListView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @StateObject private var locationManager = LocationManager()
    @AppStorage("savedLocationLatitude") private var savedLatitude: Double = 45.4642
    @AppStorage("savedLocationLongitude") private var savedLongitude: Double = 9.1900
    @State private var showingCreateEvent = false
    @State private var registeringTournamentId: Int64?
    @State private var selectedEventSection = 0 // 0 = Upcoming, 1 = Past, 2 = My Events
    @State private var refreshTrigger = UUID() // Used to force refresh when needed
    
    // MARK: - Filter State
    @State private var eventFilters = EventFilters()
    @State private var showingFilters = false
    
    // MARK: - Date Filtered Tournaments (Frontend Consistency)
    
    /// Filters nearby tournaments to include upcoming and IN_PROGRESS ones
    /// - Upcoming: status is not COMPLETED/CANCELLED, OR startDate >= now
    /// - IN_PROGRESS tournaments should always appear here
    private var upcomingTournaments: [Tournament] {
        let now = Date()
        
        let upcoming = tournamentService.nearbyTournaments.filter { tournament in
            // IN_PROGRESS tournaments should ALWAYS appear in upcoming
            if tournament.status == .inProgress {
                return true
            }
            
            // COMPLETED and CANCELLED tournaments should not appear in upcoming
            if tournament.status == .completed || tournament.status == .cancelled {
                return false
            }
            
            // PENDING_APPROVAL and UPCOMING should always be included
            if tournament.status == .pendingApproval || tournament.status == .upcoming {
                return true
            }
            
            // For other statuses, check if the date is in the future
            guard let tournamentDate = parseTournamentDate(tournament.startDate) else {
                return true // If we can't parse the date, include it by default
            }
            return tournamentDate >= now
        }
        return applyFilters(to: upcoming)
    }
    
    /// Filters past tournaments to only include COMPLETED ones
    private var filteredPastTournaments: [Tournament] {
        // Only show tournaments that are actually COMPLETED
        // Don't rely only on date - check the status too
        return tournamentService.pastTournaments.filter { tournament in
            tournament.status == .completed
        }
    }
    
    /// Filters all tournaments to only include those where the user is registered
    private var myEvents: [Tournament] {
        let allTournaments = upcomingTournaments + filteredPastTournaments
        return allTournaments.filter { isUserRegistered(for: $0) }
    }
    
    // MARK: - Filter Logic
    
    private func applyFilters(to tournaments: [Tournament]) -> [Tournament] {
        var filtered = tournaments
        
        // Date filter
        if eventFilters.dateRange != .all {
            let now = Date()
            let calendar = Calendar.current
            
            filtered = filtered.filter { tournament in
                guard let tournamentDate = parseTournamentDate(tournament.startDate) else {
                    return true
                }
                
                switch eventFilters.dateRange {
                case .today:
                    return calendar.isDateInToday(tournamentDate)
                case .thisWeek:
                    let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) ?? now
                    return tournamentDate >= now && tournamentDate <= weekFromNow
                case .thisMonth:
                    let monthFromNow = calendar.date(byAdding: .month, value: 1, to: now) ?? now
                    return tournamentDate >= now && tournamentDate <= monthFromNow
                case .all:
                    return true
                }
            }
        }
        
        // Price filter
        if eventFilters.priceRange != .all, let range = eventFilters.priceRange.priceRange {
            filtered = filtered.filter { tournament in
                guard let entryFee = tournament.entryFee else { return true }
                return range.contains(entryFee)
            }
        }
        
        // TCG Type filter
        if !eventFilters.selectedTCGTypes.isEmpty {
            filtered = filtered.filter { tournament in
                return eventFilters.selectedTCGTypes.contains(tournament.tcgType)
            }
        }
        
        // Tournament Type filter
        if !eventFilters.selectedTournamentTypes.isEmpty {
            filtered = filtered.filter { tournament in
                guard let type = tournament.type else { return true }
                return eventFilters.selectedTournamentTypes.contains(type)
            }
        }
        
        // Official/Ranked filter
        if eventFilters.onlyRanked {
            filtered = filtered.filter { tournament in
                return tournament.isRanked == true
            }
        }
        
        // Nearby filter (30km)
        if eventFilters.onlyNearby {
            let userLocation = locationManager.location ?? CLLocation(latitude: savedLatitude, longitude: savedLongitude)
            filtered = filtered.filter { tournament in
                guard let location = tournament.location,
                      let lat = location.latitude,
                      let lon = location.longitude else {
                    return true // Include if no location (can't calculate distance)
                }
                let eventLocation = CLLocation(latitude: lat, longitude: lon)
                let distanceKm = userLocation.distance(from: eventLocation) / 1000
                return distanceKm <= 30
            }
        }
        
        return filtered
    }
    
    /// Parses tournament date string to Date object
    private func parseTournamentDate(_ dateString: String) -> Date? {
        // Try multiple date formats that the backend might use
        let formatters: [DateFormatter] = {
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "dd MMM yyyy, HH:mm",
                "yyyy-MM-dd HH:mm:ss"
            ]
            return formats.map { format in
                let formatter = DateFormatter()
                formatter.dateFormat = format
                formatter.locale = Locale(identifier: "en_US_POSIX")
                return formatter
            }
        }()
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // MARK: - Premium Section Tabs & Filter
                HStack(spacing: 12) {
                    // Section Tabs
                    HStack(spacing: 0) {
                        EventSectionTab(title: "In Arrivo", isSelected: selectedEventSection == 0) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedEventSection = 0
                            }
                            HapticManager.shared.selectionChanged()
                        }
                        
                        EventSectionTab(title: "Passati", isSelected: selectedEventSection == 1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedEventSection = 1
                            }
                            HapticManager.shared.selectionChanged()
                        }

                        EventSectionTab(title: "I Miei", isSelected: selectedEventSection == 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedEventSection = 2
                            }
                            HapticManager.shared.selectionChanged()
                        }
                    }
                    .background(
                        Capsule()
                            .fill(Color(.secondarySystemFill))
                    )
                    
                    Spacer()
                    
                    // Loading indicator
                    if tournamentService.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    
                    // Filter Button (only show for Upcoming section)
                    if selectedEventSection == 0 {
                        Button(action: { 
                            showingFilters = true 
                            HapticManager.shared.selectionChanged()
                        }) {
                            ZStack(alignment: .topTrailing) {
                                SwiftUI.Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(eventFilters.isActive ? .white : Color(.label))
                                    .frame(width: 38, height: 34)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(eventFilters.isActive ? Color.orange : Color(.secondarySystemFill))
                                    )
                                
                                // Badge for active filters
                                if eventFilters.activeFilterCount > 0 {
                                    Text("\(eventFilters.activeFilterCount)")
                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .frame(width: 15, height: 15)
                                        .background(Circle().fill(Color.red))
                                        .offset(x: 5, y: -5)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)
                
                // Content based on selected section
                if selectedEventSection == 0 {
                    upcomingEventsView
                } else if selectedEventSection == 1 {
                    pastEventsView
                } else {
                    myEventsView
                }
            }

            // Floating Action Button - Only for merchants
            if authService.currentUser?.isMerchant == true {
                Button(action: { showingCreateEvent = true }) {
                    SwiftUI.Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color.blue)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateTournamentView()
        }
        .sheet(isPresented: $showingFilters) {
            EventFiltersView(filters: $eventFilters, isPresented: $showingFilters) {
                // Filters applied - view will automatically update
                refreshTrigger = UUID()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            // Force refresh when view appears to reflect any registration changes
            refreshTrigger = UUID()
        }
        .task {
            // Load past tournaments when view appears
            await tournamentService.loadPastTournaments()
        }
    }
    
    // MARK: - Upcoming Events View
    private var upcomingEventsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Count Pill
                HStack {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(upcomingTournaments.count) upcoming")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
                    
                    if eventFilters.onlyNearby {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "location.fill")
                                .font(.system(size: 10, weight: .semibold))
                            Text("30km")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.12))
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                if upcomingTournaments.isEmpty {
                    premiumEmptyStateView(
                        icon: "calendar.badge.clock",
                        title: "Nessun evento in arrivo",
                        message: "Non ci sono tornei programmati a breve. Controlla i filtri o torna più tardi.",
                        actionTitle: "Aggiorna",
                        action: {
                            Task {
                                await tournamentService.loadTournaments()
                            }
                        }
                    )
                } else {
                    ForEach(upcomingTournaments) { tournament in
                        // PENDING_APPROVAL tournaments are not clickable
                        if tournament.status == .pendingApproval {
                            TournamentCardView(
                                tournament: tournament,
                                userRegistrationStatus: getUserRegistrationStatus(for: tournament),
                                onRegisterTap: { }
                            )
                            .opacity(0.8)
                        } else {
                            NavigationLink(destination: TournamentDetailView(tournament: tournament)
                                .environmentObject(tournamentService)
                                .environmentObject(authService)) {
                                TournamentCardView(
                                    tournament: tournament,
                                    userRegistrationStatus: getUserRegistrationStatus(for: tournament),
                                    onRegisterTap: {
                                        handleRegisterTap(for: tournament)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .id(refreshTrigger)
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // Space for FAB
        }
        .refreshable {
            await tournamentService.refreshAllData()
        }
    }
    
    // MARK: - Past Events View
    private var pastEventsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Count Pill
                HStack {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(filteredPastTournaments.count) past")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.gray)
                    )
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                if filteredPastTournaments.isEmpty {
                    premiumEmptyStateView(
                        icon: "calendar.badge.checkmark",
                        title: "Nessun evento passato",
                        message: "I tornei completati appariranno qui.",
                        actionTitle: "Aggiorna",
                        action: {
                            Task {
                                await tournamentService.refreshAllData()
                            }
                        }
                    )
                } else {
                    ForEach(filteredPastTournaments) { tournament in
                        PastTournamentCard(tournament: tournament)
                    }
                }
            }
            .id(refreshTrigger)
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // Space for FAB
        }
        .refreshable {
            await tournamentService.refreshAllData() // Load everything just in case status changed
        }
    }

    // MARK: - My Events View
    private var myEventsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Count Pill
                HStack {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "person.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(myEvents.count) my events")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                if myEvents.isEmpty {
                    premiumEmptyStateView(
                        icon: "ticket.fill",
                        title: "Nessuna iscrizione",
                        message: "Iscriviti ai tornei per vederli apparire in questa lista.",
                        actionTitle: "Cerca Eventi",
                        action: {
                            withAnimation {
                                selectedEventSection = 0 // Switch to upcoming
                            }
                        }
                    )
                } else {
                    ForEach(myEvents.sorted(by: { parseTournamentDate($0.startDate) ?? Date() > parseTournamentDate($1.startDate) ?? Date() })) { tournament in
                        // Disable navigation for pending approval or rejected tournaments
                        if tournament.status == .pendingApproval || tournament.status == .rejected {
                            // Show card but without navigation
                            VStack(spacing: 0) {
                                if tournament.status == .completed || tournament.status == .cancelled || tournament.status == .rejected {
                                    PastTournamentCard(tournament: tournament)
                                } else {
                                    TournamentCardView(
                                        tournament: tournament,
                                        userRegistrationStatus: getUserRegistrationStatus(for: tournament),
                                        onRegisterTap: {
                                            // No action for pending tournaments
                                        }
                                    )
                                }
                                
                                // Show message below card
                                if tournament.status == .pendingApproval {
                                    Text("In attesa di approvazione dal negozio")
                                        .font(.system(size: 12))
                                        .foregroundColor(.orange)
                                        .padding(.top, 4)
                                } else if tournament.status == .rejected {
                                    Text("Richiesta rifiutata")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                        .padding(.top, 4)
                                }
                            }
                        } else {
                            // Normal navigation for approved tournaments
                            NavigationLink(destination: TournamentDetailView(tournament: tournament)
                                .environmentObject(tournamentService)
                                .environmentObject(authService)) {
                                // Check status, not just date - IN_PROGRESS should show as "upcoming/active"
                                if tournament.status == .completed || tournament.status == .cancelled {
                                    // Past/completed event
                                    PastTournamentCard(tournament: tournament)
                                } else {
                                    // Upcoming or in-progress event
                                    TournamentCardView(
                                        tournament: tournament,
                                        userRegistrationStatus: getUserRegistrationStatus(for: tournament),
                                        onRegisterTap: {
                                            handleRegisterTap(for: tournament)
                                        }
                                    )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .id(refreshTrigger)
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // Space for FAB
        }
        .refreshable {
            await tournamentService.refreshAllData()
        }
    }
    
    private func premiumEmptyStateView(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        VStack(spacing: 32) {
            // Animated icon with rings
            ZStack {
                // Outer ring
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 2)
                    .frame(width: 140, height: 140)
                
                // Middle ring
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 2)
                    .frame(width: 110, height: 110)
                
                // Inner solid circle with icon
                Circle()
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 80)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color(.systemGray))
            }
            
            // Text content
            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }
            
            // Action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.shared.selectionChanged()
                    action()
                }) {
                    HStack(spacing: 6) {
                        if actionTitle == "Aggiorna" {
                            SwiftUI.Image(systemName: "arrow.clockwise")
                        } else if actionTitle == "Cerca Eventi" {
                            SwiftUI.Image(systemName: "magnifyingglass")
                        }
                        
                        Text(actionTitle)
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemFill))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
        .padding(.horizontal, 20)
    }

    private func getUserRegistrationStatus(for tournament: Tournament) -> ParticipantStatus? {
        guard let currentUserId = authService.currentUser?.id else { return nil }
        return tournament.tournamentParticipants.first { $0.userId == currentUserId }?.status
    }
    
    private func isUserRegistered(for tournament: Tournament) -> Bool {
        return getUserRegistrationStatus(for: tournament) != nil
    }

    private func handleRegisterTap(for tournament: Tournament) {
        guard let tournamentId = tournament.id else { return }

        // Check if already registered
        if isUserRegistered(for: tournament) {
            print("User is already registered for this tournament")
            return
        }

        registeringTournamentId = tournamentId

        Task {
            do {
                let participant = try await tournamentService.registerForTournament(tournamentId: tournamentId)

                // Refresh tournaments to update UI
                await tournamentService.loadTournaments()

                await MainActor.run {
                    registeringTournamentId = nil
                    // Show appropriate message based on status
                    let message = participant.status == .REGISTERED
                        ? "Iscrizione completata!"
                        : "Aggiunto alla lista d'attesa. Ti avviseremo se si libera un posto."
                    // ToastManager.showSuccess(message)
                    print("Registration success: \(message)")
                }
            } catch {
                await MainActor.run {
                    registeringTournamentId = nil
                    // ToastManager.showError("Registration failed: \(error.localizedDescription)")
                    print("Registration failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Event Section Tab
struct EventSectionTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                )
        }
        .padding(2)
    }
}

// MARK: - Shop Card View (Expanded - Modern Design)
struct ShopCardView: View {
    let shop: Shop
    var hasNews: Bool = false
    
    // Reactive location for distance calculation
    @AppStorage("savedLocationLatitude") private var savedLatitude: Double = 45.4642
    @AppStorage("savedLocationLongitude") private var savedLongitude: Double = 9.1900
    
    private func calculateDistance(lat: Double, lng: Double) -> String {
        if savedLatitude == 0 && savedLongitude == 0 {
            return "-- km"
        }
        
        let earthRadius = 6371.0 // km
        let dLat = (lat - savedLatitude) * .pi / 180
        let dLng = (lng - savedLongitude) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(savedLatitude * .pi / 180) * cos(lat * .pi / 180) *
                sin(dLng/2) * sin(dLng/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let distance = earthRadius * c
        
        if distance < 1 {
            return String(format: "%.0f m", distance * 1000)
        } else {
            return String(format: "%.1f km", distance)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Shop Image (square, contained)
            ZStack(alignment: .topLeading) {
                if let photoBase64 = shop.photoBase64, let image = base64ToImage(photoBase64) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 140)
                        .clipped()
                } else {
                    // No photo - show default gradient with icon
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 120, height: 140)
                    .overlay(
                        SwiftUI.Image(systemName: "storefront.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color.blue.opacity(0.4))
                    )
                }
                
                // Badges (top-left on image)
                VStack(alignment: .leading, spacing: 4) {
                    if shop.isVerified {
                        HStack(spacing: 3) {
                            SwiftUI.Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 9))
                            Text("VERIFICATO")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                    
                    if hasNews {
                        HStack(spacing: 3) {
                            SwiftUI.Image(systemName: "newspaper.fill")
                                .font(.system(size: 8))
                            Text("NOVITÀ")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.purple)
                        )
                    }
                }
                .padding(8)
            }
            .clipShape(
                RoundedCorner(radius: 12, corners: [.topLeft, .bottomLeft])
            )
            
            // Right: Shop Info
            VStack(alignment: .leading, spacing: 8) {
                // Shop Name
                Text(shop.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                // City
                HStack(spacing: 4) {
                    SwiftUI.Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                    
                    Text(shop.address)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // TCG Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach((shop.tcgTypes ?? []).prefix(3), id: \.self) { tcg in
                            Text(tcg.uppercased())
                                .font(.system(size: 9, weight: .semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // Footer: Status + Distance
                HStack {
                    // Status
                    HStack(spacing: 4) {
                        Circle()
                            .fill(shop.isOpenNow ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(shop.isOpenNow ? "Aperto" : "Chiuso")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(shop.isOpenNow ? .green : .red)
                    }
                    
                    Spacer()
                    
                    // Distance
                    if let lat = shop.latitude, let lng = shop.longitude {
                        HStack(spacing: 3) {
                            SwiftUI.Image(systemName: "location.fill")
                                .font(.system(size: 9))
                            Text(calculateDistance(lat: lat, lng: lng))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 140)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Compact Shop Card View (No Photo)
struct CompactShopCardView: View {
    let shop: Shop
    var hasNews: Bool = false
    
    // Reactive location for distance calculation
    @AppStorage("savedLocationLatitude") private var savedLatitude: Double = 45.4642
    @AppStorage("savedLocationLongitude") private var savedLongitude: Double = 9.1900
    
    private func calculateDistance(lat: Double, lng: Double) -> String {
        if savedLatitude == 0 && savedLongitude == 0 {
            return "-- km"
        }
        
        let earthRadius = 6371.0 // km
        let dLat = (lat - savedLatitude) * .pi / 180
        let dLng = (lng - savedLongitude) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(savedLatitude * .pi / 180) * cos(lat * .pi / 180) *
                sin(dLng/2) * sin(dLng/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let distance = earthRadius * c
        
        if distance < 1 {
            return String(format: "%.0f m", distance * 1000)
        } else {
            return String(format: "%.1f km", distance)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with initials (no photo)
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text(shop.name.prefix(2).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
                
                // Verified badge
                if shop.isVerified {
                    VStack {
                        HStack {
                            Spacer()
                            SwiftUI.Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                                .background(Circle().fill(.white).frame(width: 14, height: 14))
                        }
                        Spacer()
                    }
                    .frame(width: 50, height: 50)
                }
            }
            
            // Shop Info
            VStack(alignment: .leading, spacing: 4) {
                // Name
                Text(shop.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Address
                Text(shop.address)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Status and TCG badges
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(shop.isOpenNow ? Color.green : Color.red)
                            .frame(width: 6, height: 6)
                        Text(shop.isOpenNow ? "Aperto" : "Chiuso")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(shop.isOpenNow ? .green : .red)
                    }
                    
                    if let tcgTypes = shop.tcgTypes, !tcgTypes.isEmpty {
                        HStack(spacing: 3) {
                            ForEach(tcgTypes.prefix(3), id: \.self) { tcg in
                                Text(tcg.prefix(3).uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color(.tertiarySystemFill))
                                    .cornerRadius(3)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Distance
            if let lat = shop.latitude, let lng = shop.longitude {
                HStack(spacing: 3) {
                    SwiftUI.Image(systemName: "location.fill")
                        .font(.system(size: 9))
                    Text(calculateDistance(lat: lat, lng: lng))
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.secondary)
            }
            
            // Chevron
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.gray.opacity(0.5))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ShopView()
        .environmentObject(ShopService())
        .environmentObject(TournamentService())
        .environmentObject(InventoryService())
        .environmentObject(AuthService())
}

// MARK: - Helper Functions
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

// MARK: - Service Name Formatter
private func formatServiceName(_ service: String) -> String {
    let serviceMap: [String: String] = [
        "WIFI": "Wi-Fi",
        "FREE_WIFI": "Wi-Fi Gratis",
        "PARKING": "Parcheggio",
        "FREE_PARKING": "Parcheggio Gratis",
        "CARD_GRADING": "Grading Carte",
        "CARD_BUYING": "Acquisto Carte",
        "CARD_SELLING": "Vendita Carte",
        "TOURNAMENTS": "Tornei",
        "PLAY_AREA": "Area Gioco",
        "SNACKS": "Snack",
        "DRINKS": "Bevande",
        "FOOD": "Cibo",
        "DELIVERY": "Consegna",
        "PICKUP": "Ritiro",
        "ONLINE_STORE": "Negozio Online",
        "LOYALTY_PROGRAM": "Programma Fedeltà",
        "REPAIR_SERVICE": "Riparazione",
        "TRADE_IN": "Permuta",
        "ACCESSORIES": "Accessori",
        "SLEEVES": "Bustine",
        "BINDERS": "Raccoglitori",
        "MATS": "Tappetini"
    ]
    
    return serviceMap[service] ?? service.replacingOccurrences(of: "_", with: " ").capitalized
}

// MARK: - Distance Formatter
private func formatDistance(lat: Double, lng: Double) -> String {
    // Get saved user location from UserDefaults (matching keys used by location selector)
    let userLat = UserDefaults.standard.double(forKey: "savedLocationLatitude")
    let userLng = UserDefaults.standard.double(forKey: "savedLocationLongitude")
    
    // Debug logging
    print("📍 Distance calc - Shop: (\(lat), \(lng)) | User: (\(userLat), \(userLng))")
    
    // If no user location saved, return placeholder
    if userLat == 0 && userLng == 0 {
        return "-- km"
    }
    
    // Calculate distance using Haversine formula
    let earthRadius = 6371.0 // km
    
    let dLat = (lat - userLat) * .pi / 180
    let dLng = (lng - userLng) * .pi / 180
    
    let a = sin(dLat/2) * sin(dLat/2) +
            cos(userLat * .pi / 180) * cos(lat * .pi / 180) *
            sin(dLng/2) * sin(dLng/2)
    let c = 2 * atan2(sqrt(a), sqrt(1-a))
    let distance = earthRadius * c
    
    print("📍 Calculated distance: \(distance) km")
    
    if distance < 1 {
        return String(format: "%.0f m", distance * 1000)
    } else {
        return String(format: "%.1f km", distance)
    }
}
