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
                if let maxParticipants = tournament.maxParticipants {
                    StatBox(icon: "person.2.fill", value: "\(tournament.registeredParticipantsCount)/\(maxParticipants)", label: "Players")
                }
                StatBox(icon: "calendar", value: tournament.date.formatted(date: .abbreviated, time: .omitted), label: "Date")
                if let prize = tournament.prizePool {
                    StatBox(icon: "trophy.fill", value: prize, label: "Prize")
                }
            }
            
            // Action Button
            if tournament.status == .registrationOpen && tournament.registeredParticipantsCount >= 4 {
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

// MARK: - Check-in Stat Box
struct CheckInStatBox: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
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
                        if let maxParticipants = tournament.maxParticipants {
                            DetailRow(label: "Max Participants", value: "\(maxParticipants)")
                        }
                        
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

// MARK: - Participants Tab
struct TournamentParticipantsTab: View {
    @EnvironmentObject var tournamentService: TournamentService
    let tournament: Tournament
    
    @State private var participants: [TournamentParticipantWithUser] = []
    @State private var isLoading = true
    @State private var showQRScanner = false
    @State private var showManualRegistration = false
    
    var checkedInCount: Int {
        participants.filter { $0.isCheckedIn }.count
    }
    
    var body: some View {
        VStack {
            // Check-in Header
            if tournament.status == .registrationOpen || tournament.status == .scheduled {
                VStack(spacing: 12) {
                    HStack {
                        Text("Check-in Status")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Button(action: { showManualRegistration = true }) {
                                HStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "person.badge.plus")
                                    Text("Add")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AdaptiveColors.brandSecondary)
                                )
                            }
                            
                            Button(action: { showQRScanner = true }) {
                                HStack(spacing: 6) {
                                    SwiftUI.Image(systemName: "qrcode.viewfinder")
                                    Text("Scan")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AdaptiveColors.brandPrimary)
                                )
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        CheckInStatBox(
                            icon: "person.2.fill",
                            value: "\(participants.count)",
                            label: "Registered",
                            color: AdaptiveColors.brandPrimary
                        )
                        
                        CheckInStatBox(
                            icon: "checkmark.circle.fill",
                            value: "\(checkedInCount)",
                            label: "Checked In",
                            color: AdaptiveColors.success
                        )
                        
                        CheckInStatBox(
                            icon: "clock.fill",
                            value: "\(participants.count - checkedInCount)",
                            label: "Pending",
                            color: AdaptiveColors.warning
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(AdaptiveColors.backgroundSecondary)
                
                Divider()
            }
            
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
                            ParticipantWithCheckInRow(participant: participant)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView { code in
                handleCheckIn(code: code)
            }
        }
        .sheet(isPresented: $showManualRegistration) {
            if let id = tournament.id {
                ManualRegistrationView(tournamentId: id) {
                    loadParticipants()
                }
            }
        }
        .onAppear {
            loadParticipants()
        }
    }
    
    private func loadParticipants() {
        Task {
            do {
                guard let tournamentId = tournament.id else {
                    print("Tournament ID is nil")
                    isLoading = false
                    return
                }
                participants = try await tournamentService.getTournamentParticipantsWithDetails(tournamentId: tournamentId)
                isLoading = false
            } catch {
                print("Error loading participants: \(error)")
                isLoading = false
            }
        }
    }
    
    private func handleCheckIn(code: String) {
        Task {
            do {
                let checkedInParticipant = try await tournamentService.checkInParticipant(checkInCode: code)
                
                // Update the participant in the list
                if let index = participants.firstIndex(where: { $0.id == checkedInParticipant.id }) {
                    // Reload participants to get updated data
                    await loadParticipants()
                }
                
                // Show success feedback
                print("Successfully checked in participant")
            } catch {
                print("Error checking in participant: \(error)")
                // Show error feedback
            }
        }
    }
}

// MARK: - Participant with Check-in Row
struct ParticipantWithCheckInRow: View {
    let participant: TournamentParticipantWithUser
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(participant.isCheckedIn ? AdaptiveColors.success.opacity(0.2) : AdaptiveColors.brandPrimary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(participant.displayName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(participant.isCheckedIn ? AdaptiveColors.success : AdaptiveColors.brandPrimary)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(participant.email)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text("Registered: \(participant.registrationDateFormatted?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status & Check-in
            VStack(alignment: .trailing, spacing: 4) {
                // Registration Status Badge
                if participant.status == .WAITING_LIST {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                        Text("Waiting List")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.orange.opacity(0.1)))
                } else if participant.status == .REGISTERED {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "checkmark.circle")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                        Text("Registered")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue.opacity(0.1)))
                }
                
                // Check-in Status
                if participant.isCheckedIn {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AdaptiveColors.success)
                        
                        Text("Checked In")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AdaptiveColors.success)
                    }
                    
                    if let checkedInDate = participant.checkedInDate {
                        Text(checkedInDate.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else if participant.status != .WAITING_LIST {
                    Text("Not Checked In")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AdaptiveColors.warning)
                }
            }
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
// MARK: - Manual Registration View
struct ManualRegistrationView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @Environment(\.dismiss) var dismiss
    
    let tournamentId: Int64
    let onComplete: () -> Void
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var isValid: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Participant Details")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email (Optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: register) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Register Participant")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(isValid ? .white : .secondary)
                        }
                    }
                    .disabled(!isValid || isSubmitting)
                    .listRowBackground(isValid ? AdaptiveColors.brandPrimary : Color.gray.opacity(0.2))
                }
            }
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func register() {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await tournamentService.registerManualParticipant(
                    tournamentId: tournamentId,
                    firstName: firstName,
                    lastName: lastName,
                    email: email.isEmpty ? nil : email
                )
                
                await MainActor.run {
                    isSubmitting = false
                    onComplete()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to register: \(error.localizedDescription)"
                }
            }
        }
    }
}
