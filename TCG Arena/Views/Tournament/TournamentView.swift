//
//  TournamentView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/6/25.
//

import SwiftUI
import MapKit
import CoreLocation
import SkeletonUI
import Combine

struct TournamentView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @StateObject private var locationManager = LocationManager()
    @State private var showingLocationInput = false
    @State private var userLocationText = "Milano, Italy"
    @State private var isLoading = true
    @State private var selectedTournament: Tournament?
    @State private var refreshTrigger = UUID()
    @State private var selectedTab = 0
    @State private var isLoadingPastTournaments = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Upcoming Tournaments Tab
                VStack(spacing: 0) {
                // Clean Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tournaments")
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(tournamentService.nearbyTournaments.isEmpty ? tournamentService.tournaments.count : tournamentService.nearbyTournaments.count) available")
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Create Tournament Button - Only for merchants
                    if authService.currentUser?.isMerchant == true {
                        NavigationLink(destination: CreateTournamentView()) {
                            HStack(spacing: 6) {
                                SwiftUI.Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text("Create")
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
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Location Input Section
                HStack {
                    HStack(spacing: 12) {
                        SwiftUI.Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(userLocationText.isEmpty ? "Set your location" : userLocationText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(userLocationText.isEmpty ? .secondary : .primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        SwiftUI.Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    .onTapGesture {
                        showingLocationInput = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Tournament List
                TournamentListView(
                    selectedTournament: $selectedTournament,
                    tournaments: tournamentService.tournaments,
                    nearbyTournaments: tournamentService.nearbyTournaments,
                    isLoading: isLoading
                )
                    .id(refreshTrigger)
                    .onAppear {
                        print("TournamentListView appeared, isLoading = \(isLoading)")
                    }
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .task(id: tournamentService.hasLoadedInitialData) {
                // Only load if we haven't loaded initial data yet
                guard !tournamentService.hasLoadedInitialData else {
                    print("TournamentView: Initial data already loaded, skipping")
                    isLoading = false
                    return
                }
                
                print("TournamentView task started - loading initial data")
                await tournamentService.loadTournaments()
                
                if let userLocation = locationManager.location {
                    print("Using user location for nearby tournaments")
                    await tournamentService.loadNearbyTournaments(userLocation: userLocation)
                } else {
                    // Load nearby tournaments with Milano center for demo
                    print("Using Milano center for nearby tournaments")
                    let milanCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
                    await tournamentService.loadNearbyTournaments(userLocation: milanCenter)
                }
                
                tournamentService.hasLoadedInitialData = true
                print("TournamentView task completed, tournaments: \(tournamentService.tournaments.count), nearby: \(tournamentService.nearbyTournaments.count)")
                print("Setting isLoading to false")
                isLoading = false
            }
            .sheet(isPresented: $showingLocationInput) {
                LocationInputView(locationText: $userLocationText) { location in
                    Task {
                        await tournamentService.loadNearbyTournaments(userLocation: location)
                    }
                }
            }
            .tabItem {
                Label("Upcoming", systemImage: "calendar")
            }
            .tag(0)
            
            // Past Tournaments Tab
            VStack(spacing: 0) {
                    // Header for Past Tournaments
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Past Tournaments")
                                .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("\(tournamentService.pastTournaments.count) completed")
                                .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // Past Tournament List
                    if tournamentService.pastTournaments.isEmpty && !isLoadingPastTournaments {
                        if isLoadingPastTournaments {
                            // Show skeleton while loading
                            ScrollView {
                                LazyVStack(spacing: 16) {
                                    ForEach(0..<3) { _ in
                                        PastTournamentCard(tournament: Tournament(
                                            title: "Loading tournament",
                                            description: "",
                                            tcgType: .pokemon,
                                            type: .casual,
                                            status: .upcoming,
                                            startDate: "",
                                            endDate: "",
                                            maxParticipants: 0,
                                            currentParticipants: nil,
                                            entryFee: 0.0,
                                            prizePool: "",
                                            organizerId: 0
                                        ))
                                        .skeleton(with: true)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        } else {
                            Text("No past tournaments")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(tournamentService.pastTournaments) { tournament in
                                    PastTournamentCard(tournament: tournament)
                                        .onTapGesture {
                                            selectedTournament = tournament
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
                .onAppear {
                    // Only load if not already loaded and not currently loading
                    if tournamentService.pastTournaments.isEmpty && !isLoadingPastTournaments {
                        isLoadingPastTournaments = true
                        Task {
                            await tournamentService.loadPastTournaments()
                            isLoadingPastTournaments = false
                        }
                    }
                }
            }
            .tabItem {
                Label("Past", systemImage: "clock")
            }
            .tag(1)
            }
            .onReceive(tournamentService.objectWillChange) { _ in
                print("TournamentView: tournamentService changed - tournaments: \(tournamentService.tournaments.count), nearby: \(tournamentService.nearbyTournaments.count), isLoading: \(tournamentService.isLoading)")
                refreshTrigger = UUID()
            }
            .refreshable {
                // Haptic feedback on refresh
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                await tournamentService.loadTournaments()
                
                if let userLocation = locationManager.location {
                    await tournamentService.loadNearbyTournaments(userLocation: userLocation)
                } else {
                    let milanCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
                    await tournamentService.loadNearbyTournaments(userLocation: milanCenter)
                }
            }
            .sheet(item: $selectedTournament) { tournament in
                TournamentDetailView(tournament: tournament)
            }
            .navigationTitle("Tournaments")
        }
}

// MARK: - Tournament List View
struct TournamentListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var locationManager = LocationManager()
    @Binding var selectedTournament: Tournament?
    
    let tournaments: [Tournament]
    let nearbyTournaments: [Tournament]
    let isLoading: Bool
    
    // Show nearby tournaments if available, otherwise show all tournaments
    private var tournamentsToShow: [Tournament] {
        let result = !nearbyTournaments.isEmpty ? nearbyTournaments : tournaments
        print("TournamentListView: tournamentsToShow returning \(result.count) tournaments (nearby: \(nearbyTournaments.count), all: \(tournaments.count))")
        return result
    }
    
    var body: some View {
        let tournamentsCount = tournamentsToShow.count
        let isLoadingState = isLoading
        
        print("TournamentListView body: tournamentsToShow.count = \(tournamentsCount), isLoading = \(isLoadingState)")
        
        return ScrollView {
            if !isLoadingState && tournamentsCount == 0 {
                EmptyTournamentsView()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(tournamentsToShow) { tournament in
                        TournamentListCard(
                            tournament: tournament,
                            userRegistrationStatus: getUserRegistrationStatus(for: tournament),
                            onTap: {
                                selectedTournament = tournament
                            }
                        )
                        .skeleton(with: isLoadingState)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    private func getUserRegistrationStatus(for tournament: Tournament) -> ParticipantStatus? {
        guard let currentUserId = authService.currentUser?.id else { return nil }
        return tournament.tournamentParticipants.first { $0.userId == currentUserId }?.status
    }
}

// MARK: - Tournament List Card
struct TournamentListCard: View {
    let tournament: Tournament
    let userRegistrationStatus: ParticipantStatus?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // TCG Icon
                ZStack {
                    Circle()
                        .fill(tournament.tcgType.themeColor)
                        .frame(width: 50, height: 50)
                    
                    SwiftUI.Image(systemName: tournament.tcgType.systemIcon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Tournament Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(tournament.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        SwiftUI.Image(systemName: "location.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(tournament.location?.venueName ?? "Location TBA")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    HStack {
                        SwiftUI.Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(tournament.formattedStartDate)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Status Badge
                        if let userStatus = userRegistrationStatus {
                            // User is registered/waiting
                            Text(userStatus == .REGISTERED ? "REGISTERED" : "WAITING LIST")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(userStatus == .REGISTERED ? Color.green : Color.orange)
                                )
                        } else {
                            // Tournament Status
                            Text(tournament.status.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(statusColor(tournament.status))
                                )
                        }
                    }
                    
                    // Participants and Fee
                    HStack {
                        Text("\(tournament.registeredParticipantsCount)/\(tournament.maxParticipants)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("€\(Int(tournament.entryFee))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(tournament.tcgType.themeColor)
                    }
                }
                
                // Arrow
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(UIConstants.shadowOpacity),
                    radius: UIConstants.shadowRadius,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                .stroke(Color(.systemGray6), lineWidth: 1)
        )
    }
    
    private func statusColor(_ status: Tournament.TournamentStatus) -> Color {
        switch status {
        case .upcoming: return Color(red: 0.0, green: 0.7, blue: 1.0)
        case .registrationOpen: return Color(red: 0.0, green: 1.0, blue: 0.4)
        case .registrationClosed: return Color(red: 1.0, green: 0.6, blue: 0.0)
        case .inProgress: return Color(red: 1.0, green: 0.0, blue: 0.6)
        case .completed: return Color.gray
        case .cancelled: return Color.red
        }
    }
}

// MARK: - Empty State View
struct EmptyTournamentsView: View {
    var body: some View {
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
                Text("No Tournaments Found")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("There are no tournaments in your area yet.\nTry adjusting your location or check back later!")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
}

#Preview {
    TournamentView()
        .environmentObject(TournamentService())
        .environmentObject(AuthService())
}