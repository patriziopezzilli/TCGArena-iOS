//
//  PlayerTournamentListView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct PlayerTournamentListView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @State private var tournaments: [Tournament] = []
    @State private var isLoading = false
    @State private var selectedTCG: TCGType?
    @State private var selectedStatus: TournamentStatusFilter = .upcoming
    @State private var searchText = ""
    @State private var showingRegistration = false
    @State private var selectedTournament: Tournament?
    
    enum TournamentStatusFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case registrationOpen = "Open Registration"
        case inProgress = "In Progress"
        case completed = "Completed"
    }
    
    var filteredTournaments: [Tournament] {
        tournaments.filter { tournament in
            // TCG Filter
            if let tcg = selectedTCG, tournament.tcgType != tcg {
                return false
            }
            
            // Status Filter
            switch selectedStatus {
            case .upcoming:
                return tournament.status == .scheduled
            case .registrationOpen:
                return tournament.status == .scheduled && tournament.canRegister
            case .inProgress:
                return tournament.status == .checkinOpen || tournament.status == .inProgress
            case .completed:
                return tournament.status == .completed
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filters
                filtersSection
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTournaments.isEmpty {
                    emptyStateView
                } else {
                    tournamentList
                }
            }
            .navigationTitle("Tournaments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadTournaments) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $selectedTournament) { tournament in
                PlayerTournamentDetailView(tournament: tournament)
                    .environmentObject(tournamentService)
                    .environmentObject(authService)
            }
        }
        .onAppear(perform: loadTournaments)
    }
    
    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Status Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TournamentStatusFilter.allCases, id: \.self) { status in
                        FilterChip(
                            title: status.rawValue,
                            isSelected: selectedStatus == status
                        ) {
                            selectedStatus = status
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // TCG Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All TCGs",
                        isSelected: selectedTCG == nil
                    ) {
                        selectedTCG = nil
                    }
                    
                    ForEach(TCGType.allCases, id: \.self) { tcg in
                        FilterChip(
                            title: tcg.displayName,
                            isSelected: selectedTCG == tcg
                        ) {
                            selectedTCG = tcg
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var tournamentList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTournaments) { tournament in
                    TournamentCardView(tournament: tournament)
                        .onTapGesture {
                            selectedTournament = tournament
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Tournaments Found")
                .font(.headline)
            
            Text("Check back later for upcoming tournaments")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func loadTournaments() {
        isLoading = true
        
        Task {
            do {
                let response = try await tournamentService.getTournaments(
                    tcgType: nil,
                    status: nil,
                    shopId: nil
                )
                
                await MainActor.run {
                    tournaments = response.tournaments
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading tournaments: \(error)")
                    isLoading = false
                }
            }
        }
    }
}

struct TournamentCardView: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.headline)
                    
                    Text(tournament.tcgType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: tournament.status)
            }
            
            // Shop Info
            if let shop = tournament.shop {
                HStack(spacing: 6) {
                    Image(systemName: "storefront.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(shop.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Date & Time
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    
                    Text(tournament.startDate, style: .date)
                        .font(.subheadline)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    
                    Text(tournament.startDate, style: .time)
                        .font(.subheadline)
                }
            }
            .foregroundColor(.secondary)
            
            // Participants
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                    
                    Text("\(tournament.currentParticipants)/\(tournament.maxParticipants)")
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Entry Fee
                if tournament.entryFee > 0 {
                    Text("€\(tournament.entryFee, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(AdaptiveColors.primary))
                }
            }
            .foregroundColor(.secondary)
            
            // Registration Status
            if tournament.canRegister {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Registration Open")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StatusBadge: View {
    let status: Tournament.TournamentStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(status.color))
            .cornerRadius(12)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : Color(AdaptiveColors.primary))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color(AdaptiveColors.primary) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(AdaptiveColors.primary), lineWidth: 1)
                )
                .cornerRadius(20)
        }
    }
}

#Preview {
    PlayerTournamentListView()
        .environmentObject(TournamentService(apiClient: APIClient.shared))
        .environmentObject(AuthService())
}
