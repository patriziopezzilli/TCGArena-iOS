//
//  ShopView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct ShopView: View {
    @EnvironmentObject var shopService: ShopService
    @EnvironmentObject var tournamentService: TournamentService
    @StateObject private var locationManager = LocationManager()
    @State private var selectedSection = 0
    @State private var showingLocationInput = false
    @State private var userLocationText = "Milano, Italy"
    @State private var hasLoadedInitialData = false
    
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
                        HStack(spacing: 0) {
                            SegmentButton(title: "Stores", isSelected: selectedSection == 0) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSection = 0
                                }
                            }
                            
                            SegmentButton(title: "Events", isSelected: selectedSection == 1) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedSection = 1
                                }
                            }
                        }
                        .background(
                            Capsule()
                                .fill(Color(.tertiarySystemFill))
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
                await tournamentService.loadTournaments()
                
                if let userLocation = locationManager.location {
                    await tournamentService.loadNearbyTournaments(userLocation: userLocation)
                } else {
                    let milanoCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
                    await tournamentService.loadNearbyTournaments(userLocation: milanoCenter)
                }
            }
            .sheet(isPresented: $showingLocationInput) {
                LocationInputView(locationText: $userLocationText)
            }
        }
    }
}

// MARK: - Custom Segment Button
struct SegmentButton: View {
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
                                .matchedGeometryEffect(id: "TAB", in: NamespaceWrapper.shared.namespace)
                        }
                    }
                )
        }
        .padding(2)
    }
}

// Helper for matched geometry in separate views if needed, though here it's local
class NamespaceWrapper {
    static let shared = NamespaceWrapper()
    @Namespace var namespace
}

// MARK: - Shop List View
struct ShopListView: View {
    @EnvironmentObject var shopService: ShopService
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Summary Text
                HStack {
                    Text("\(shopService.nearbyShops.count) stores nearby")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ForEach(shopService.nearbyShops) { shop in
                    NavigationLink(destination: ShopDetailView(shop: shop)
                        .environmentObject(shopService)) {
                        ShopCardView(shop: shop)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .refreshable {
            if let userLocation = locationManager.location {
                await shopService.loadNearbyShops(userLocation: userLocation)
            } else {
                let milanoCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
                await shopService.loadNearbyShops(userLocation: milanoCenter)
            }
        }
    }
}

// MARK: - Event List View
struct EventListView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @StateObject private var locationManager = LocationManager()
    @State private var showingCreateEvent = false
    @State private var registeringTournamentId: Int64?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Summary Text
                    HStack {
                        Text("\(tournamentService.nearbyTournaments.count) upcoming events")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    ForEach(tournamentService.nearbyTournaments) { tournament in
                        NavigationLink(destination: TournamentDetailView(tournament: tournament)
                            .environmentObject(tournamentService)
                            .environmentObject(authService)) {
                            TournamentCardView(
                                tournament: tournament,
                                isUserRegistered: isUserRegistered(for: tournament),
                                onRegisterTap: {
                                    handleRegisterTap(for: tournament)
                                }
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 80) // Space for FAB
            }
            .refreshable {
                await tournamentService.loadTournaments()
                
                if let userLocation = locationManager.location {
                    await tournamentService.loadNearbyTournaments(userLocation: userLocation)
                } else {
                    let milanoCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
                    await tournamentService.loadNearbyTournaments(userLocation: milanoCenter)
                }
            }
            
            // Floating Action Button
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
        .sheet(isPresented: $showingCreateEvent) {
            CreateTournamentView()
        }
    }
    
    private func isUserRegistered(for tournament: Tournament) -> Bool {
        guard let currentUserId = authService.currentUser?.id else { return false }
        return tournament.tournamentParticipants.contains { $0.userId == currentUserId }
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
                let _ = try await tournamentService.registerForTournament(tournamentId: tournamentId)
                
                // Refresh tournaments to update UI
                await tournamentService.loadTournaments()
                
                await MainActor.run {
                    registeringTournamentId = nil
                }
            } catch {
                await MainActor.run {
                    registeringTournamentId = nil
                    print("Registration failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Shop Card View
struct ShopCardView: View {
    let shop: Shop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card Image / Map Placeholder
            ZStack(alignment: .topTrailing) {
                // Placeholder Gradient or Image
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 140)
                    .overlay(
                        SwiftUI.Image(systemName: "storefront.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color.blue.opacity(0.2))
                    )
                
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
                    .padding(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Title and Address
                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(shop.address)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(shop.tcgTypes ?? [], id: \.self) { tcg in
                            TCGTypeBadge(tcgType: tcg)
                        }
                        
                        ForEach((shop.services ?? []).prefix(3), id: \.self) { service in
                            Text(service)
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
                    .padding(.vertical, 4)
                
                // Footer Info
                HStack {
                    // Status (Open/Closed) - Mock data for now
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Open Now")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    // Distance - Mock
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "location")
                            .font(.system(size: 12))
                        Text("1.2 km")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
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
}
