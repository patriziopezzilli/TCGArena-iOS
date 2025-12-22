//
//  TournamentMapDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import MapKit

struct TournamentMapDetailView: View {
    let tournament: Tournament
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @State private var showingParticipantProfile: User?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Clean Header with TCG Icon - aggiunto padding top
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(tournament.tcgType.themeColor)
                            .frame(width: 60, height: 60)
                        
                        TCGIconView(tcgType: tournament.tcgType, size: 24, color: .white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.title)
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        Text(tournament.tcgType.displayName)
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // Main Tournament Card
                VStack(spacing: 20) {
                    // Key Info Card
                    InfoCard(title: "Event Details") {
                        VStack(spacing: 12) {
                            InfoRow(icon: "calendar", title: "Date", value: tournament.formattedStartDate)
                            InfoRow(icon: "clock", title: "Time", value: tournament.formattedStartDate)
                            if let maxParticipants = tournament.maxParticipants {
                                InfoRow(icon: "person.2", title: "Players", value: "\(tournament.registeredParticipantsCount)/\(maxParticipants)")
                            }
                            if let entryFee = tournament.entryFee {
                                InfoRow(icon: "dollarsign.circle", title: "Entry Fee", value: entryFee > 0 ? String(format: "$%.0f", entryFee) : "Free")
                            }
                            if let prizePool = tournament.prizePool {
                                InfoRow(icon: "trophy", title: "Prize Pool", value: prizePool)
                            }
                        }
                    }
                    
                    // Location Card
                    if let location = tournament.location {
                        InfoCard(title: "Location") {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    SwiftUI.Image(systemName: "location.fill")
                                        .foregroundColor(tournament.tcgType.themeColor)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.venueName)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text(location.address)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                        
                                        Text(location.city)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Description Card (if exists)
                    if let description = tournament.description, !description.isEmpty {
                        InfoCard(title: "About This Event") {
                            Text(description)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                    
                    // Rules Card (if exists)
                    if let rules = tournament.rules, !rules.isEmpty {
                        InfoCard(title: "Tournament Rules") {
                            Text(rules)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Participants Section
                if !tournament.participants.isEmpty {
                    InfoCard(title: "Participants") {
                        DisclosureGroup("Show Participants (\(tournament.participants.count))") {
                            VStack(spacing: 12) {
                                ForEach(tournament.participants.prefix(5)) { participant in
                                    Button(action: {
                                        showingParticipantProfile = participant
                                    }) {
                                        HStack(spacing: 12) {
                                            // Avatar
                                            ZStack {
                                                Circle()
                                                    .fill(tournament.tcgType.themeColor.opacity(0.2))
                                                    .frame(width: 40, height: 40)
                                                
                                                if let profileImageURL = participant.profileImageUrl,
                                                   let url = URL(string: profileImageURL) {
                                                    AsyncImage(url: url) { image in
                                                        image
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 40, height: 40)
                                                            .clipShape(Circle())
                                                    } placeholder: {
                                                        SwiftUI.Image(systemName: "person.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(tournament.tcgType.themeColor)
                                                    }
                                                } else {
                                                    Text(String(participant.displayName.prefix(2)).uppercased())
                                                        .font(.system(size: 16, weight: .bold))
                                                        .foregroundColor(tournament.tcgType.themeColor)
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(participant.displayName)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                
                                                Text("@\(participant.username)")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.secondary)
                                                
                                                if let location = participant.location {
                                                    HStack(spacing: 4) {
                                                        SwiftUI.Image(systemName: "location.fill")
                                                            .font(.system(size: 12, weight: .medium))
                                                            .foregroundColor(.secondary)
                                                        
                                                        Text("\(location.city)")
                                                            .font(.system(size: 12, weight: .medium))
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            SwiftUI.Image(systemName: "chevron.right")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                if tournament.participants.count > 5 {
                                    Text("+\(tournament.participants.count - 5) more participants")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .accentColor(tournament.tcgType.themeColor)
                    }
                    .padding(.horizontal, 20)
                }
                
                // Prominent Registration Section
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ready to compete?")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Registration closes \(tournament.formattedStartDate)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        if isRegistered || isWaitingList {
                            // Unregister action
                            unregisterFromTournament()
                        } else {
                            // Register directly
                            registerForTournament()
                        }
                    }) {
                        HStack(spacing: 12) {
                            if isRegistered {
                                SwiftUI.Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Registered ✓")
                                    .font(.system(size: 18, weight: .bold))
                            } else if isWaitingList {
                                SwiftUI.Image(systemName: "clock.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Waiting List")
                                    .font(.system(size: 18, weight: .bold))
                            } else if tournament.isFull {
                                SwiftUI.Image(systemName: "clock.badge.plus")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Join Waiting List")
                                    .font(.system(size: 18, weight: .bold))
                            } else {
                                SwiftUI.Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Register Now")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                .fill(buttonColor)
                        )
                    }
                    
                    if tournament.isFull && !isRegistered && !isWaitingList {
                        Text("Tournament is full - Join the waiting list!")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle(tournament.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $showingParticipantProfile) { participant in
            UserProfileDetailView(userProfile: participant.toUserProfile())
        }
        .overlay(
            ToastManager.shared.currentToast.map { toast in
                ToastNotificationView(toast: toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: toast.id)
            },
            alignment: .bottom
        )
    }
    
    // Computed properties
    private var userRegistrationStatus: ParticipantStatus? {
        guard let currentUserId = authService.currentUser?.id else { return nil }
        return tournament.tournamentParticipants.first { $0.userId == currentUserId }?.status
    }
    
    private var isRegistered: Bool {
        userRegistrationStatus == .REGISTERED || userRegistrationStatus == .CHECKED_IN
    }
    
    private var isWaitingList: Bool {
        userRegistrationStatus == .WAITING_LIST
    }
    
    private var buttonColor: Color {
        if isRegistered {
            return .green
        } else if isWaitingList {
            return .orange
        } else {
            return tournament.tcgType.themeColor
        }
    }
    
    private func registerForTournament() {
        guard let tournamentId = tournament.id else { return }
        
        Task {
            do {
                let participant = try await tournamentService.registerForTournament(tournamentId: tournamentId)
                await tournamentService.loadTournaments()
                
                await MainActor.run {
                    let message = participant.status == .REGISTERED 
                        ? "Registrazione completata!" 
                        : "Added to waiting list. You'll be notified if a spot opens up."
                    ToastManager.shared.showSuccess(message)
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Failed to register: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func unregisterFromTournament() {
        guard let tournamentId = tournament.id else { return }
        
        Task {
            do {
                try await tournamentService.unregisterFromTournament(tournamentId: tournamentId)
                await tournamentService.loadTournaments()
                
                await MainActor.run {
                    ToastManager.shared.showSuccess("Disiscrizione completata.")
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Failed to unregister: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    // Helper function to format dates as strings for backend
    func formatDateForBackend(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
    return TournamentMapDetailView(
        tournament: Tournament(
            title: "Pokemon Regional Championship 2024",
            description: "Official Pokemon TCG Regional Championship with players from across the region competing for championship points and prizes.",
            tcgType: .pokemon,
            type: .championship,
            status: .upcoming,
            startDate: formatDateForBackend(Date().addingTimeInterval(86400 * 7)),
            endDate: formatDateForBackend(Date().addingTimeInterval(86400 * 7 + 3600 * 8)),
            maxParticipants: 128,
            entryFee: 50.0,
            prizePool: "$5000 + Booster Box",
            organizerId: 1,
            location: Tournament.TournamentLocation(
                venueName: "San Francisco Game Center",
                address: "123 Game Street",
                city: "San Francisco",
                country: "United States",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            rules: "Standard format rules apply."
        )
    )
}
