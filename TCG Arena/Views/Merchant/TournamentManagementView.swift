//
//  TournamentManagementView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct TournamentManagementView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedFilter: TournamentFilter = .upcoming
    @State private var showCreateTournament = false
    @State private var selectedTournament: Tournament?
    
    enum TournamentFilter: String, CaseIterable {
        case upcoming = "Upcoming"
        case inProgress = "In Progress"
        case completed = "Completed"
        
        var icon: String {
            switch self {
            case .upcoming: return "calendar"
            case .inProgress: return "play.circle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    var filteredTournaments: [Tournament] {
        tournamentService.tournaments.filter { tournament in
            switch selectedFilter {
            case .upcoming:
                return tournament.status == .scheduled || tournament.status == .registrationOpen
            case .inProgress:
                return tournament.status == .inProgress
            case .completed:
                return tournament.status == .completed
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(filteredTournaments.count) Tournaments")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showCreateTournament = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Create")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AdaptiveColors.brandPrimary)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TournamentFilter.allCases, id: \.self) { filter in
                        FilterTab(
                            title: filter.rawValue,
                            icon: filter.icon,
                            count: tournamentService.tournaments.filter { tournament in
                                switch filter {
                                case .upcoming: return tournament.status == .scheduled || tournament.status == .registrationOpen
                                case .inProgress: return tournament.status == .inProgress
                                case .completed: return tournament.status == .completed
                                }
                            }.count,
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(AdaptiveColors.backgroundSecondary)
            
            Divider()
            
            // Tournaments List
            if filteredTournaments.isEmpty {
                EmptyStateView(
                    icon: "trophy.fill",
                    title: "No \(selectedFilter.rawValue) Tournaments",
                    message: "Create your first tournament to get started"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTournaments) { tournament in
                            TournamentManagementCard(tournament: tournament) {
                                selectedTournament = tournament
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(AdaptiveColors.backgroundPrimary)
        .sheet(isPresented: $showCreateTournament) {
            CreateTournamentView()
        }
        .sheet(item: $selectedTournament) { tournament in
            TournamentDetailManagementView(tournament: tournament)
        }
        .onAppear {
            loadTournaments()
        }
    }
    
    private func loadTournaments() {
        guard let shopId = authService.currentUser?.shopId else { return }
        
        Task {
            await tournamentService.loadShopTournaments(shopId: shopId)
        }
    }
}

// MARK: - Filter Tab
struct FilterTab: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                    
                    Text("\(count)")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(isSelected ? .white : AdaptiveColors.brandPrimary)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AdaptiveColors.brandPrimary : AdaptiveColors.brandPrimary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tournament Management Card
struct TournamentManagementCard: View {
    let tournament: Tournament
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(tournament.format.rawValue)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    Text(tournament.status.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(tournament.status.color))
                        )
                }
                
                // Info Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    InfoCell(icon: "calendar", value: tournament.date.formatted(date: .abbreviated, time: .omitted))
                    if let maxParticipants = tournament.maxParticipants {
                        InfoCell(icon: "person.2.fill", value: "\(tournament.registeredParticipantsCount)/\(maxParticipants)")
                    }
                    InfoCell(icon: "trophy.fill", value: tournament.prizePool ?? "No Prize")
                }
                
                // Quick Actions
                if tournament.status == .registrationOpen {
                    Divider()
                    
                    HStack(spacing: 12) {
                        QuickActionLabel(icon: "person.badge.plus", text: "Manage Registrations", color: AdaptiveColors.brandPrimary)
                        Spacer()
                        QuickActionLabel(icon: "play.circle.fill", text: "Start Tournament", color: AdaptiveColors.success)
                    }
                } else if tournament.status == .inProgress {
                    Divider()
                    
                    HStack(spacing: 12) {
                        QuickActionLabel(icon: "list.bullet.clipboard", text: "Enter Results", color: AdaptiveColors.brandPrimary)
                        Spacer()
                        QuickActionLabel(icon: "chart.bar.fill", text: "View Standings", color: AdaptiveColors.brandSecondary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.backgroundSecondary)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Cell
struct InfoCell: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AdaptiveColors.brandPrimary)
            
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Quick Action Label
struct QuickActionLabel: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(color)
    }
}

#Preview {
    TournamentManagementView()
        .environmentObject(TournamentService.shared)
        .environmentObject(AuthService())
}
