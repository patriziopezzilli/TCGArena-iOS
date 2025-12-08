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
                            Text("Discover")
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
                        HStack(spacing: 12) {
                            PremiumTabButton(
                                title: "Stores",
                                icon: "storefront.fill",
                                isSelected: selectedSection == 0
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSection = 0
                                }
                            }

                            PremiumTabButton(
                                title: "Events",
                                icon: "calendar",
                                isSelected: selectedSection == 1
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSection = 1
                                }
                            }
                        }
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
                    if selectedSection == 0 {
                        ShopListView()
                            .transition(.opacity)
                    } else {
                        EventListView()
                            .transition(.opacity)
                    }
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
                    
                    // Reload shops and tournaments with new location
                    Task {
                        await shopService.loadNearbyShops(userLocation: newLocation)
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

    var body: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Summary Text
                    HStack {
                        Text("\(shopService.nearbyShops.count) stores nearby")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        
                        if shopService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    if shopService.nearbyShops.isEmpty && !shopService.isLoading {
                        // Empty state
                        VStack(spacing: 16) {
                            SwiftUI.Image(systemName: "storefront")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("No stores found nearby")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if let errorMessage = shopService.errorMessage {
                                Text(errorMessage)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                            
                            Button(action: {
                                let locationToUse = locationManager.location ?? CLLocation(latitude: savedLatitude, longitude: savedLongitude)
                                Task {
                                    await shopService.loadNearbyShops(userLocation: locationToUse)
                                }
                            }) {
                                Text("Try Again")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.blue, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        ForEach(shopService.nearbyShops) { shop in
                            NavigationLink(destination: ShopDetailView(shop: shop)
                                .environmentObject(shopService)
                                .environmentObject(inventoryService)
                                .environmentObject(authService)) {
                                ShopCardView(shop: shop, hasNews: !shopService.getNews(for: shop.id.description).isEmpty)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .refreshable {
                // Haptic feedback on refresh
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                let locationToUse = locationManager.location ?? CLLocation(latitude: savedLatitude, longitude: savedLongitude)
                await shopService.loadNearbyShops(userLocation: locationToUse)
            }
            
            // Loading overlay
            if shopService.isLoading && shopService.nearbyShops.isEmpty {
                Color(.systemBackground)
                    .opacity(0.8)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Loading nearby stores...")
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
                return range.contains(tournament.entryFee)
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
                return eventFilters.selectedTournamentTypes.contains(tournament.type)
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
                // Section Tabs with Filter Button
                HStack(spacing: 12) {
                    // Section Tabs
                    HStack(spacing: 0) {
                        EventSectionTab(title: "Upcoming", isSelected: selectedEventSection == 0) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedEventSection = 0
                            }
                        }
                        
                        EventSectionTab(title: "Past", isSelected: selectedEventSection == 1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedEventSection = 1
                            }
                        }

                        EventSectionTab(title: "My Events", isSelected: selectedEventSection == 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedEventSection = 2
                            }
                        }
                    }
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                    )
                    
                    // Filter Button (only show for Upcoming section)
                    if selectedEventSection == 0 {
                        Button(action: { showingFilters = true }) {
                            ZStack(alignment: .topTrailing) {
                                SwiftUI.Image(systemName: eventFilters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(eventFilters.isActive ? .blue : .secondary)
                                
                                // Badge for active filters
                                if eventFilters.activeFilterCount > 0 {
                                    Text("\(eventFilters.activeFilterCount)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Circle().fill(Color.red))
                                        .offset(x: 6, y: -6)
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
            LazyVStack(spacing: 20) {
                // Summary Text with filter indicator
                HStack {
                    Text("\(upcomingTournaments.count) upcoming events")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    if eventFilters.isActive {
                        Text("• Filtered")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)


                if upcomingTournaments.isEmpty {
                    emptyStateView(
                        icon: "calendar.badge.clock",
                        title: "No Upcoming Events",
                        message: "Check back later for new events in your area"
                    )
                } else {
                    ForEach(upcomingTournaments) { tournament in
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
            .id(refreshTrigger)
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // Space for FAB
        }
        .refreshable {
            await tournamentService.loadTournaments()
            await tournamentService.loadPastTournaments()

            let locationToUse = locationManager.location ?? CLLocation(latitude: savedLatitude, longitude: savedLongitude)
            await tournamentService.loadNearbyTournaments(userLocation: locationToUse)
        }
    }
    
    // MARK: - Past Events View
    private var pastEventsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary Text
                HStack {
                    Text("\(filteredPastTournaments.count) past events")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if filteredPastTournaments.isEmpty {
                    emptyStateView(
                        icon: "calendar.badge.checkmark",
                        title: "No Past Events",
                        message: "Your completed events will appear here"
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
            await tournamentService.loadPastTournaments()
        }
    }

    // MARK: - My Events View
    private var myEventsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Summary Text
                HStack {
                    Text("\(myEvents.count) my events")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if myEvents.isEmpty {
                    emptyStateView(
                        icon: "person.circle",
                        title: "No Events Yet",
                        message: "Events you're registered for will appear here"
                    )
                } else {
                    ForEach(myEvents.sorted(by: { parseTournamentDate($0.startDate) ?? Date() > parseTournamentDate($1.startDate) ?? Date() })) { tournament in
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
            .id(refreshTrigger)
            .padding(.horizontal, 20)
            .padding(.bottom, 80) // Space for FAB
        }
        .refreshable {
            await tournamentService.loadTournaments()
            await tournamentService.loadPastTournaments()

            let locationToUse = locationManager.location ?? CLLocation(latitude: savedLatitude, longitude: savedLongitude)
            await tournamentService.loadNearbyTournaments(userLocation: locationToUse)
        }
    }
    private func emptyStateView(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 16) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 40)
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
                        ? "Successfully registered for the tournament!"
                        : "Added to waiting list. You'll be notified if a spot opens up."
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

// MARK: - Shop Card View
struct ShopCardView: View {
    let shop: Shop
    var hasNews: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Image / Placeholder
            ZStack(alignment: .topTrailing) {
                // Shop Image or Placeholder
                if let photoBase64 = shop.photoBase64, let image = base64ToImage(photoBase64) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    // No photo - show default gradient
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 200)
                    .overlay(
                        SwiftUI.Image(systemName: "storefront.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.blue.opacity(0.3))
                    )
                }
                
                // Badges Stack (top-right corner)
                VStack(alignment: .trailing, spacing: 6) {
                    // Verified Badge
                    if shop.isVerified {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                            Text("VERIFIED")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                    }
                    
                    // News Badge
                    if hasNews {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "newspaper.fill")
                                .font(.system(size: 10))
                            Text("NEWS")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.purple)
                        )
                    }
                }
                .padding(12)
            }

            // Content below image
            VStack(alignment: .leading, spacing: 12) {
                // Shop Name
                Text(shop.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Address
                HStack(spacing: 4) {
                    SwiftUI.Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(shop.address)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(shop.tcgTypes ?? [], id: \.self) { tcg in
                            TCGTypeBadge(tcgTypeString: tcg)
                        }

                        ForEach((shop.services ?? []).prefix(3), id: \.self) { service in
                            Text(formatServiceName(service))
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(6)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                // Footer Info
                HStack {
                    // Status (Open/Closed)
                    HStack(spacing: 4) {
                        Circle()
                            .fill(shop.isOpenNow ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(shop.openStatusText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(shop.isOpenNow ? .green : .red)
                    }

                    Spacer()

                    // Distance (if available from service)
                    if let lat = shop.latitude, let lng = shop.longitude {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "location")
                                .font(.system(size: 12))
                            Text(formatDistance(lat: lat, lng: lng))
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
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
