//
//  TournamentView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/6/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct TournamentView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @StateObject private var locationManager = LocationManager()
    @State private var showingLocationInput = false
    @State private var userLocationText = "Milano, Italy"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clean Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tournaments")
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(tournamentService.nearbyTournaments.count) nearby")
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Create Tournament Button
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
                TournamentListView()
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .task {
                await tournamentService.loadTournaments()
                
                if let userLocation = locationManager.location {
                    await tournamentService.loadNearbyTournaments(userLocation: userLocation)
                } else {
                    // Load nearby tournaments with Milano center for demo
                    let milanCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
                    await tournamentService.loadNearbyTournaments(userLocation: milanCenter)
                }
            }
            .sheet(isPresented: $showingLocationInput) {
                LocationInputView(locationText: $userLocationText) { location in
                    Task {
                        await tournamentService.loadNearbyTournaments(userLocation: location)
                    }
                }
            }
        }
    }
}

// MARK: - Tournament List View
struct TournamentListView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @State private var selectedTournament: Tournament?
    
    var body: some View {
        ScrollView {
            if tournamentService.nearbyTournaments.isEmpty {
                EmptyTournamentsView()
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(tournamentService.nearbyTournaments) { tournament in
                        TournamentListCard(tournament: tournament) {
                            selectedTournament = tournament
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(item: $selectedTournament) { tournament in
            TournamentDetailView(tournament: tournament)
        }
    }
}

// MARK: - Tournament List Card
struct TournamentListCard: View {
    let tournament: Tournament
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
                        
                        Text(tournament.location?.name ?? "Location TBA")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    
                    HStack {
                        SwiftUI.Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(DateFormatter.shortDate.string(from: tournament.startDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Status Badge
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
                    
                    // Participants and Fee
                    HStack {
                        Text("\(tournament.currentParticipants)/\(tournament.maxParticipants)")
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
}