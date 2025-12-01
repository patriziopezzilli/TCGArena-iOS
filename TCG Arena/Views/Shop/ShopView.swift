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
    @State private var userLocationText = "Milano, Italy"
    @State private var hasLoadedInitialData = false
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clean Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Stores")
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(selectedSection == 0 ? "\(shopService.nearbyShops.count) nearby" : "\(tournamentService.nearbyTournaments.count) events")
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Location Chip in top right
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        
                        Text(userLocationText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        SwiftUI.Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .onTapGesture {
                        showingLocationInput = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Section Segmented Control
                Picker("Section", selection: $selectedSection) {
                    Text("Stores").tag(0)
                    Text("Events").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Content based on selected section
                if selectedSection == 0 {
                    ShopListView(isLoading: isLoading)
                } else {
                    EventListView(isLoading: isLoading)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                // Only load data once on first appearance
                guard !hasLoadedInitialData else { return }
                hasLoadedInitialData = true
                
                // Load tournaments
                await tournamentService.loadTournaments()
                
                // Use current location for tournaments, but shops are already loaded with all items
                if let userLocation = locationManager.location {
                    await tournamentService.loadNearbyTournaments(userLocation: userLocation)
                } else {
                    // Load nearby tournaments with Milano center for demo
                    let milanoCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
                    await tournamentService.loadNearbyTournaments(userLocation: milanoCenter)
                }
                
                isLoading = false
            }
            .sheet(isPresented: $showingLocationInput) {
                LocationInputView(locationText: $userLocationText)
            }
        }
    }
}

// MARK: - Shop List View
struct ShopListView: View {
    @EnvironmentObject var shopService: ShopService
    let isLoading: Bool
    
    var body: some View {
        ScrollView {
            if !isLoading && shopService.nearbyShops.isEmpty {
                // Empty state
                VStack(spacing: 24) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        SwiftUI.Image(systemName: "building.2")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(spacing: 12) {
                        Text("No Stores Found")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("There are no stores in your area yet.\nTry adjusting your location or check back later!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(shopService.nearbyShops) { shop in
                        NavigationLink(destination: ShopDetailView(shop: shop)
                            .environmentObject(shopService)) {
                            ShopCardView(shop: shop)
                                .skeleton(with: isLoading)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Event List View
struct EventListView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @State private var showingCreateEvent = false
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Create Event Button
            HStack {
                Spacer()
                
                Button(action: { showingCreateEvent = true }) {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        
                        Text("Create Event")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.blue)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            ScrollView {
                if !isLoading && tournamentService.nearbyTournaments.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.0, green: 0.7, blue: 1.0).opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            SwiftUI.Image(systemName: "trophy")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
                        }
                        
                        VStack(spacing: 12) {
                            Text("No Events Found")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("There are no events in your area yet.\nTry adjusting your location or check back later!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(tournamentService.nearbyTournaments) { tournament in
                            NavigationLink(destination: TournamentDetailView(tournament: tournament)) {
                                TournamentCardView(
                                    tournament: tournament,
                                    isUserRegistered: false,
                                    onRegisterTap: {}
                                )
                                .skeleton(with: isLoading)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }
        }
        .sheet(isPresented: $showingCreateEvent) {
            CreateTournamentView()
        }
    }
}

// MARK: - Shop Card View
struct ShopCardView: View {
    let shop: Shop
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with verification
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(shop.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if shop.isVerified {
                            SwiftUI.Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(shop.address)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Description
            Text(shop.description ?? "")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // TCG Types
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(shop.tcgTypes ?? [], id: \.self) { tcg in
                        TCGTypeBadge(tcgType: tcg)
                    }
                }
            }
            
            // Services
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach((shop.services ?? []).prefix(4), id: \.self) { service in
                        Text(service)
                            .font(.system(size: 12))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if (shop.services ?? []).count > 4 {
                        Text("+\((shop.services ?? []).count - 4)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray5))
                            )
                    }
                }
            }
            
            // Opening Hours
            // TODO: Add opening hours display
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    ShopView()
        .environmentObject(ShopService())
        .environmentObject(TournamentService())
}
