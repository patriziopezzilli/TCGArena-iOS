//
//  TournamentDetailManagementView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct TournamentDetailManagementView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @Environment(\.dismiss) var dismiss
    
    let tournament: Tournament
    
    @State private var selectedTab: ManagementTab = .overview
    @State private var showStartConfirmation = false
    @State private var isProcessing = false
    
    enum ManagementTab: String, CaseIterable {
        case overview = "Overview"
        case participants = "Participants"
        case pairings = "Pairings"
        case standings = "Standings"
        
        var icon: String {
            switch self {
            case .overview: return "info.circle.fill"
            case .participants: return "person.2.fill"
            case .pairings: return "list.bullet.clipboard.fill"
            case .standings: return "chart.bar.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tournament Header
                tournamentHeader
                
                // Tab Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ManagementTab.allCases, id: \.self) { tab in
                            TabButton(
                                title: tab.rawValue,
                                icon: tab.icon,
                                isSelected: selectedTab == tab
                            ) {
                                withAnimation {
                                    selectedTab = tab
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(AdaptiveColors.backgroundSecondary)
                
                Divider()
                
                // Content
                TabView(selection: $selectedTab) {
                    TournamentOverviewTab(tournament: tournament)
                        .tag(ManagementTab.overview)
                    
                    TournamentParticipantsTab(tournament: tournament)
                        .tag(ManagementTab.participants)
                    
                    TournamentPairingsTab(tournament: tournament)
                        .tag(ManagementTab.pairings)
                    
                    TournamentStandingsTab(tournament: tournament)
                        .tag(ManagementTab.standings)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Start Tournament", isPresented: $showStartConfirmation, titleVisibility: .visible) {
                Button("Start") {
                    startTournament()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will close registration and start the tournament. Continue?")
            }
        }
    }
    
    // MARK: - Tournament Header
    private var tournamentHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(tournament.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(tournament.format.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AdaptiveColors.brandPrimary))
                        
                        Text(tournament.status.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color(tournament.status.color)))
                    }
                }
                
                Spacer()
            }
            
            // Quick Stats
            HStack(spacing: 16) {
                StatBox(icon: "person.2.fill", value: "\(tournament.currentParticipants)/\(tournament.maxParticipants)", label: "Players")
                StatBox(icon: "calendar", value: tournament.date.formatted(date: .abbreviated, time: .omitted), label: "Date")
                if let prize = tournament.prizePool {
                    StatBox(icon: "trophy.fill", value: prize, label: "Prize")
                }
            }
            
            // Action Button
            if tournament.status == .registrationOpen && tournament.currentParticipants >= 4 {
                Button(action: { showStartConfirmation = true }) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                        Text("Start Tournament")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AdaptiveColors.success)
                    )
                }
                .disabled(isProcessing)
            }
        }
        .padding(20)
        .background(AdaptiveColors.backgroundSecondary)
    }
    
    private func startTournament() {
        isProcessing = true
        
        Task {
            do {
                try await tournamentService.startTournament(tournamentId: tournament.id)
                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AdaptiveColors.brandPrimary)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.backgroundPrimary)
        )
    }
}

// MARK: - Overview Tab
struct TournamentOverviewTab: View {
    let tournament: Tournament
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let description = tournament.description {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 10) {
                        DetailRow(label: "TCG Type", value: tournament.tcgType.rawValue)
                        DetailRow(label: "Format", value: tournament.format.displayName)
                        DetailRow(label: "Date & Time", value: tournament.date.formatted(date: .long, time: .shortened))
                        DetailRow(label: "Max Participants", value: "\(tournament.maxParticipants)")
                        
                        if let entryFee = tournament.entryFee {
                            DetailRow(label: "Entry Fee", value: "€\(String(format: "%.2f", entryFee))")
                        }
                        
                        if let prize = tournament.prizePool {
                            DetailRow(label: "Prize Pool", value: prize)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AdaptiveColors.backgroundSecondary)
                )
                
                if let rules = tournament.rules {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rules")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(rules)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Participants Tab
struct TournamentParticipantsTab: View {
    @EnvironmentObject var tournamentService: TournamentService
    let tournament: Tournament
    
    @State private var participants: [TournamentRegistration] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if participants.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "No Participants",
                    message: "No one has registered yet"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(participants) { participant in
                            ParticipantRow(participant: participant, tournament: tournament)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadParticipants()
        }
    }
    
    private func loadParticipants() {
        Task {
            // Load participants from service
            // participants = await tournamentService.getParticipants(tournamentId: tournament.id)
            isLoading = false
        }
    }
}

// MARK: - Participant Row
struct ParticipantRow: View {
    let participant: TournamentRegistration
    let tournament: Tournament
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(AdaptiveColors.brandPrimary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(participant.user?.displayName.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AdaptiveColors.brandPrimary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.user?.displayName ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Registered: \(participant.registeredAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status Badge
            Text(participant.status.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(participant.status.color))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
}

// MARK: - Pairings Tab
struct TournamentPairingsTab: View {
    @EnvironmentObject var tournamentService: TournamentService
    let tournament: Tournament
    
    @State private var currentRound: TournamentRound?
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if tournament.status != .inProgress {
                EmptyStateView(
                    icon: "play.circle",
                    title: "Tournament Not Started",
                    message: "Start the tournament to see pairings"
                )
                .frame(maxHeight: .infinity)
            } else if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if let round = currentRound {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Round \(round.roundNumber)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(round.matches) { match in
                                MatchRow(match: match, tournament: tournament)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .onAppear {
            loadCurrentRound()
        }
    }
    
    private func loadCurrentRound() {
        Task {
            // Load current round from service
            isLoading = false
        }
    }
}

// MARK: - Match Row
struct MatchRow: View {
    @EnvironmentObject var tournamentService: TournamentService
    let match: Match
    let tournament: Tournament
    
    @State private var showResultEntry = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Table \(match.tableNumber ?? 0)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let result = match.result {
                    Text(result.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AdaptiveColors.success))
                }
            }
            
            HStack(spacing: 12) {
                // Player 1
                PlayerMatchCell(
                    player: match.player1,
                    isWinner: match.result == .player1Win
                )
                
                Text("VS")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                
                // Player 2
                PlayerMatchCell(
                    player: match.player2,
                    isWinner: match.result == .player2Win
                )
            }
            
            if match.result == nil {
                Button(action: { showResultEntry = true }) {
                    Text("Enter Result")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AdaptiveColors.brandPrimary)
                        )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AdaptiveColors.backgroundSecondary)
        )
        .sheet(isPresented: $showResultEntry) {
            MatchResultEntryView(match: match, tournament: tournament)
        }
    }
}

// MARK: - Player Match Cell
struct PlayerMatchCell: View {
    let player: User?
    let isWinner: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(isWinner ? AdaptiveColors.success.opacity(0.2) : AdaptiveColors.backgroundPrimary)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(player?.displayName.prefix(1).uppercased() ?? "?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isWinner ? AdaptiveColors.success : AdaptiveColors.brandPrimary)
                )
            
            Text(player?.displayName ?? "Unknown")
                .font(.system(size: 13, weight: isWinner ? .bold : .medium))
                .foregroundColor(isWinner ? AdaptiveColors.success : .primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Standings Tab
struct TournamentStandingsTab: View {
    @EnvironmentObject var tournamentService: TournamentService
    let tournament: Tournament
    
    @State private var standings: [TournamentStanding] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if tournament.status == .registrationOpen || tournament.status == .scheduled {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Standings Yet",
                    message: "Standings will appear once the tournament starts"
                )
                .frame(maxHeight: .infinity)
            } else if isLoading {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if standings.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Standings",
                    message: "Complete matches to see standings"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(standings) { standing in
                            StandingRow(standing: standing)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadStandings()
        }
    }
    
    private func loadStandings() {
        Task {
            // Load standings from service
            isLoading = false
        }
    }
}

// MARK: - Standing Row
struct StandingRow: View {
    let standing: TournamentStanding
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("\(standing.rank)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(standing.rank <= 3 ? AdaptiveColors.brandSecondary : .secondary)
                .frame(width: 40)
            
            // Player
            VStack(alignment: .leading, spacing: 2) {
                Text(standing.user?.displayName ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("\(standing.wins)-\(standing.losses)-\(standing.draws)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Points
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(standing.points)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AdaptiveColors.brandPrimary)
                
                Text("pts")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(standing.rank <= 3 ? AdaptiveColors.brandSecondary.opacity(0.1) : AdaptiveColors.backgroundSecondary)
        )
    }
}

#Preview {
    TournamentDetailManagementView(tournament: Tournament(
        id: "1",
        shopId: "shop1",
        name: "Weekly Pokemon Tournament",
        description: "Standard format tournament",
        tcgType: .pokemon,
        format: .swiss,
        date: Date(),
        maxParticipants: 16,
        currentParticipants: 8,
        status: .registrationOpen,
        entryFee: 10.0,
        prizePool: "Booster Box",
        rules: nil,
        createdAt: Date()
    ))
    .environmentObject(TournamentService.shared)
}
