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
        case pendingRequests = "Richieste"
        case upcoming = "Upcoming"
        case inProgress = "In Progress"
        case completed = "Completed"
        
        var icon: String {
            switch self {
            case .pendingRequests: return "clock.badge.exclamationmark"
            case .upcoming: return "calendar"
            case .inProgress: return "play.circle.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    var filteredTournaments: [Tournament] {
        tournamentService.tournaments.filter { tournament in
            switch selectedFilter {
            case .pendingRequests:
                return tournament.status == .pendingApproval
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
                                case .pendingRequests: return tournament.status == .pendingApproval
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
    
    @State private var showApproveAlert = false
    @State private var showRejectSheet = false
    @State private var rejectionReason = ""
    @State private var isProcessing = false
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var tournamentService: TournamentService
    
    var body: some View {
        Button(action: { if tournament.status != .pendingApproval { onTap() } }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        if tournament.status == .pendingApproval, let creatorId = tournament.createdByUserId {
                            Text("Richiesto da utente #\(creatorId)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status Badge
                    if tournament.status == .pendingApproval {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                            Text("In Attesa")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.orange.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                
                // Tournament Details
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(icon: "calendar", text: formatDate(tournament.startDate))
                    DetailRow(icon: "gamecontroller.fill", text: tournament.tcgType.displayName)
                    if let maxParticipants = tournament.maxParticipants {
                        DetailRow(icon: "person.2.fill", text: "\(maxParticipants) giocatori max")
                    }
                    if let entryFee = tournament.entryFee, entryFee > 0 {
                        DetailRow(icon: "eurosign.circle", text: "€\(String(format: "%.0f", entryFee))")
                    }
                }
                
                // Pending Approval Actions
                if tournament.status == .pendingApproval {
                    Divider()
                        .padding(.vertical, 4)
                    
                    HStack(spacing: 12) {
                        // Approve Button
                        Button(action: { showApproveAlert = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Approva")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.green)
                            )
                        }
                        .disabled(isProcessing)
                        
                        // Reject Button
                        Button(action: { showRejectSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                Text("Rifiuta")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red)
                            )
                        }
                        .disabled(isProcessing)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Approva Richiesta", isPresented: $showApproveAlert) {
            Button("Annulla", role: .cancel) {}
            Button("Approva") {
                approveTournament()
            }
        } message: {
            Text("Vuoi approvare questa richiesta di torneo? Il torneo diventerà visibile pubblicamente.")
        }
        .sheet(isPresented: $showRejectSheet) {
            RejectTournamentSheet(
                tournamentTitle: tournament.title,
                rejectionReason: $rejectionReason,
                onReject: rejectTournament
            )
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
    
    private func approveTournament() {
        guard let tournamentId = tournament.id else { return }
        
        isProcessing = true
        
        Task {
            do {
                guard let url = URL(string: "\(APIConfig.baseURL)/api/tournaments/\(tournamentId)/approve") else { return }
                
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                
                if let token = authService.authToken {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Errore nell'approvazione"])
                }
                
                await MainActor.run {
                    isProcessing = false
                    // Reload tournaments
                    Task {
                        await tournamentService.loadTournaments()
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
    
    private func rejectTournament() {
        guard let tournamentId = tournament.id else { return }
        
        isProcessing = true
        
        Task {
            do {
                guard let url = URL(string: "\(APIConfig.baseURL)/api/tournaments/\(tournamentId)/reject") else { return }
                
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                if let token = authService.authToken {
                    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                }
                
                let body: [String: String] = ["reason": rejectionReason]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Errore nel rifiuto"])
                }
                
                await MainActor.run {
                    isProcessing = false
                    showRejectSheet = false
                    // Reload tournaments
                    Task {
                        await tournamentService.loadTournaments()
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 16)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

struct RejectTournamentSheet: View {
    let tournamentTitle: String
    @Binding var rejectionReason: String
    let onReject: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stai rifiutando:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(tournamentTitle)
                        .font(.system(size: 18, weight: .bold))
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Motivo del rifiuto")
                        .font(.system(size: 16, weight: .semibold))
                    
                    TextEditor(text: $rejectionReason)
                        .font(.system(size: 15))
                        .frame(height: 120)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.tertiarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    
                    Text("Spiega perché questa richiesta non può essere accettata.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button(action: {
                    onReject()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Conferma Rifiuto")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(!rejectionReason.isEmpty ? Color.red : Color.gray)
                    )
                }
                .disabled(rejectionReason.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Rifiuta Richiesta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
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
