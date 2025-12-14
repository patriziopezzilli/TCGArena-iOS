//
//  PlayerTournamentDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct PlayerTournamentDetailView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    let tournament: Tournament
    
    @State private var participants: [TournamentParticipant] = []
    @State private var pairings: [Pairing] = []
    @State private var standings: [Standing] = []
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var showingRegistration = false
    @State private var showingCheckIn = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var userParticipant: TournamentParticipant? {
        guard let userId = authService.currentUser?.id else { return nil }
        return participants.first { $0.userId == userId }
    }
    
    var isRegistered: Bool {
        userParticipant != nil
    }
    
    var canRegister: Bool {
        !isRegistered && tournament.canRegister
    }
    
    var canCheckIn: Bool {
        guard let participant = userParticipant else { return false }
        
        // Parse tournament start date
        guard let tournamentStartDate = parseTournamentDate(tournament.startDate) else { return false }
        
        // Allow check-in 1 hour before start until 30 minutes after start
        let now = Date()
        let oneHourBefore = tournamentStartDate.addingTimeInterval(-60 * 60)  // 1 hour before
        let thirtyMinutesAfter = tournamentStartDate.addingTimeInterval(30 * 60)  // 30 min after
        let isWithinCheckInWindow = now >= oneHourBefore && now <= thirtyMinutesAfter
        
        return isWithinCheckInWindow && !participant.checkedIn
    }
    
    /// Parses tournament date string to Date object
    private func parseTournamentDate(_ dateString: String) -> Date? {
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
        NavigationView {
            VStack(spacing: 0) {
                // Tournament Header
                tournamentHeader
                
                // Action Buttons
                if canRegister || canCheckIn {
                    actionButtons
                }
                
                // Messages
                if let message = errorMessage {
                    MessageBanner(message: message, type: .error) {
                        errorMessage = nil
                    }
                }
                
                if let message = successMessage {
                    MessageBanner(message: message, type: .success) {
                        successMessage = nil
                    }
                }
                
                // Tabs
                if isRegistered {
                    Picker("View", selection: $selectedTab) {
                        Text("Info").tag(0)
                        Text("Participants").tag(1)
                        if tournament.status == .inProgress || tournament.status == .completed {
                            Text("Pairings").tag(2)
                            Text("Standings").tag(3)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    TabView(selection: $selectedTab) {
                        tournamentInfoTab.tag(0)
                        participantsTab.tag(1)
                        if tournament.status == .inProgress || tournament.status == .completed {
                            pairingsTab.tag(2)
                            standingsTab.tag(3)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                } else {
                    tournamentInfoTab
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $showingRegistration) {
                TournamentRegistrationView(tournament: tournament) { participant in
                    if let participant = participant {
                        successMessage = participant.status == .REGISTERED
                            ? "Successfully registered for tournament!"
                            : "Added to waiting list. You'll be notified if a spot opens up."
                        loadData()
                    }
                }
                .environmentObject(tournamentService)
            }
        }
        .onAppear(perform: loadData)
    }
    
    private var tournamentHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(tournament.tcgType.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: tournament.status)
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(tournament.startDate, style: .date)
                        .font(.subheadline)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(tournament.startDate, style: .time)
                        .font(.subheadline)
                }
            }
            .foregroundColor(.secondary)
            
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.secondary)
                    if let maxParticipants = tournament.maxParticipants {
                        Text("\(tournament.registeredParticipantsCount)/\(maxParticipants) Players")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                if let entryFee = tournament.entryFee, entryFee > 0 {
                    Text("Entry: €\(entryFee, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(AdaptiveColors.primary))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if canRegister {
                Button(action: { showingRegistration = true }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Register for Tournament")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(AdaptiveColors.primary))
                    .cornerRadius(12)
                }
            }
            
            if canCheckIn {
                Button(action: performCheckIn) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Check In")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    private var tournamentInfoTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Description
                if !tournament.description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(tournament.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Format
                VStack(alignment: .leading, spacing: 8) {
                    Text("Format")
                        .font(.headline)
                    
                    Text(tournament.format.displayName)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Shop Info
                if let shop = tournament.shop {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shop.name)
                                .font(.body)
                            
                            if !shop.address.isEmpty {
                                Text(shop.address)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !shop.city.isEmpty {
                                Text("\(shop.city), \(shop.country)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Rules
                if !tournament.rules.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Rules")
                            .font(.headline)
                        
                        Text(tournament.rules)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Prize Distribution
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prize Distribution")
                        .font(.headline)
                    
                    ForEach(tournament.prizeDistribution.sorted(by: { $0.key < $1.key }), id: \.key) { place, prize in
                        HStack {
                            Text("\(ordinal(place)) Place")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(prize)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var participantsTab: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(participants.sorted(by: { $0.registrationDate > $1.registrationDate })) { participant in
                    ParticipantRow(participant: participant)
                }
            }
            .padding()
        }
    }
    
    private var pairingsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                if pairings.isEmpty {
                    Text("No pairings yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(pairings.sorted(by: { $0.roundNumber > $1.roundNumber })) { pairing in
                        PairingCard(pairing: pairing)
                    }
                }
            }
            .padding()
        }
    }
    
    private var standingsTab: some View {
        ScrollView {
            VStack(spacing: 8) {
                if standings.isEmpty {
                    Text("No standings yet")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(standings.sorted(by: { $0.rank < $1.rank })) { standing in
                        StandingRow(standing: standing)
                    }
                }
            }
            .padding()
        }
    }
    
    private func loadData() {
        isLoading = true
        
        Task {
            do {
                async let participantsData = tournamentService.getParticipants(tournamentId: tournament.id)
                
                if tournament.status == .inProgress || tournament.status == .completed {
                    async let pairingsData = tournamentService.getPairings(tournamentId: tournament.id)
                    async let standingsData = tournamentService.getStandings(tournamentId: tournament.id)
                    
                    let (p, pa, s) = try await (participantsData, pairingsData, standingsData)
                    
                    await MainActor.run {
                        participants = p
                        pairings = pa
                        standings = s
                        isLoading = false
                    }
                } else {
                    let p = try await participantsData
                    
                    await MainActor.run {
                        participants = p
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load tournament data"
                    isLoading = false
                }
            }
        }
    }
    
    private func performCheckIn() {
        Task {
            do {
                try await tournamentService.checkIn(tournamentId: tournament.id)
                
                await MainActor.run {
                    successMessage = "Check-in effettuato con successo! +25 punti"
                    loadData()
                }
            } catch let error as TournamentService.CheckInError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Errore check-in: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func ordinal(_ number: Int) -> String {
        let suffix: String
        switch number {
        case 1: suffix = "st"
        case 2: suffix = "nd"
        case 3: suffix = "rd"
        default: suffix = "th"
        }
        return "\(number)\(suffix)"
    }
}

struct ParticipantRow: View {
    let participant: TournamentParticipant
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let user = participant.user {
                    Text(user.username)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Player #\(participant.userId.prefix(8))")
                        .font(.subheadline)
                }
                
                if !participant.deckName.isEmpty {
                    Text(participant.deckName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if participant.checkedIn {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct PairingCard: View {
    let pairing: Pairing
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Round \(pairing.roundNumber)")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pairing.player1?.user?.username ?? "Player 1")
                        .font(.subheadline)
                    
                    if let wins = pairing.player1Wins {
                        Text("\(wins) wins")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(pairing.player2?.user?.username ?? "Player 2")
                        .font(.subheadline)
                    
                    if let wins = pairing.player2Wins {
                        Text("\(wins) wins")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let result = pairing.result {
                HStack {
                    Spacer()
                    Text(result.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(resultColor(result))
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func resultColor(_ result: Pairing.MatchResult) -> Color {
        switch result {
        case .player1Win: return .green
        case .player2Win: return .red
        case .draw: return .orange
        }
    }
}

struct StandingRow: View {
    let standing: Standing
    
    var body: some View {
        HStack {
            Text("#\(standing.rank)")
                .font(.headline)
                .foregroundColor(Color(AdaptiveColors.primary))
                .frame(width: 40, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 2) {
                if let user = standing.participant?.user {
                    Text(user.username)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Player")
                        .font(.subheadline)
                }
                
                Text("\(standing.wins)-\(standing.losses)-\(standing.draws)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(standing.matchPoints) pts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("OMW: \(standing.opponentMatchWinPercentage, specifier: "%.1f")%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(standing.rank <= 3 ? Color(AdaptiveColors.primary).opacity(0.1) : Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct MessageBanner: View {
    let message: String
    let type: MessageType
    let onDismiss: () -> Void
    
    enum MessageType {
        case error, success
        
        var color: Color {
            switch self {
            case .error: return .red
            case .success: return .green
            }
        }
        
        var icon: String {
            switch self {
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: type.icon)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
        }
        .foregroundColor(.white)
        .padding()
        .background(type.color)
        .cornerRadius(8)
        .padding()
    }
}

#Preview {
    PlayerTournamentDetailView(
        tournament: Tournament(
            id: "1",
            name: "Weekly Magic Tournament",
            description: "Standard format tournament",
            tcgType: .magic,
            format: .standard,
            maxParticipants: 16,
            currentParticipants: 8,
            entryFee: 5.0,
            prizeDistribution: [1: "3 boosters", 2: "2 boosters", 3: "1 booster"],
            startDate: Date().addingTimeInterval(86400),
            registrationDeadline: Date().addingTimeInterval(3600),
            shopId: "shop1",
            status: .scheduled,
            rules: "Standard rules apply",
            createdAt: Date(),
            updatedAt: Date(),
            shop: nil
        )
    )
    .environmentObject(TournamentService(apiClient: APIClient.shared))
    .environmentObject(AuthService())
}
