//
//  TournamentDetailView.swift
//  TCG Arena
//
//  Created by Assistant on 22/11/2024.
//

import SwiftUI
import MapKit

struct TournamentDetailView: View {
    let tournament: Tournament
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @State private var isRegistering = false
    @State private var showingRegistrationAlert = false
    @State private var registrationMessage = ""
    @State private var userRegistrationStatus: TournamentParticipant?
    @State private var isLoadingStatus = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [tournament.tcgType.themeColor.opacity(0.6), tournament.tcgType.themeColor.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(tournament.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        HStack(spacing: 12) {
                            Text(tournament.type.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)

                            Text(tournament.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(20)
                }

                VStack(spacing: 24) {
                    // Registration Status
                    if let userStatus = userRegistrationStatus {
                        VStack(spacing: 12) {
                            HStack {
                                SwiftUI.Image(systemName: userStatus.status == .REGISTERED ? "checkmark.circle.fill" : "clock.fill")
                                    .foregroundColor(userStatus.status == .REGISTERED ? .green : .orange)

                                Text(userStatus.status == .REGISTERED ? "Registered" : "On Waiting List")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                            }

                            if userStatus.status == .WAITING_LIST {
                                Text("You're on the waiting list. You'll be notified if a spot opens up.")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }

                    // Registration Button
                    if tournament.status == .registrationOpen && userRegistrationStatus == nil {
                        VStack(spacing: 16) {
                            if tournament.isFull {
                                Text("Tournament is full")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.orange)
                            }

                            Button(action: registerForTournament) {
                                HStack {
                                    if isRegistering {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        SwiftUI.Image(systemName: tournament.isFull ? "clock" : "person.badge.plus")
                                    }

                                    Text(tournament.isFull ? "Join Waiting List" : "Register")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(tournament.isFull ? Color.orange : Color.blue)
                                )
                            }
                            .disabled(isRegistering)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Tournament Info
                    VStack(spacing: 20) {
                        // Basic Info
                        InfoRow(icon: "calendar", title: "Date",
                               value: "\(formatDate(tournament.startDate)) - \(formatDate(tournament.endDate))")

                        InfoRow(icon: "person.2", title: "Participants",
                               value: "\(tournament.registeredParticipantsCount)/\(tournament.maxParticipants)")

                        if tournament.waitingListCount > 0 {
                            InfoRow(icon: "clock", title: "Waiting List",
                                   value: "\(tournament.waitingListCount) people")
                        }

                        InfoRow(icon: "dollarsign.circle", title: "Entry Fee",
                               value: tournament.entryFee == 0 ? "Free" : "$\(String(format: "%.2f", tournament.entryFee))")

                        InfoRow(icon: "trophy", title: "Prize Pool",
                               value: "$\(String(format: "%.2f", tournament.prizePool))")

                        // Location
                        if let location = tournament.location {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Location")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)

                                HStack(alignment: .top, spacing: 12) {
                                    SwiftUI.Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.red)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(location.name)
                                            .font(.system(size: 15, weight: .medium))

                                        Text("\(location.address), \(location.city)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }

                        // Description
                        if let description = tournament.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)

                                Text(description)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Registration", isPresented: $showingRegistrationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(registrationMessage)
        }
        .onAppear {
            checkRegistrationStatus()
        }
    }

    private func registerForTournament() {
        guard let userId = authService.currentUserId,
              let tournamentId = tournament.id else { return }

        isRegistering = true

        tournamentService.registerForTournament(tournamentId: tournamentId) { result in
            isRegistering = false

            switch result {
            case .success(let participant):
                userRegistrationStatus = participant
                registrationMessage = participant.status == .REGISTERED
                    ? "Successfully registered for the tournament!"
                    : "Added to waiting list. You'll be notified if a spot opens up."
                showingRegistrationAlert = true

                // Refresh tournament data to update counts
                loadTournamentDetails()

            case .failure(let error):
                registrationMessage = "Registration failed: \(error.localizedDescription)"
                showingRegistrationAlert = true
            }
        }
    }

    private func checkRegistrationStatus() {
        guard let tournamentId = tournament.id else { return }
        
        isLoadingStatus = true

        tournamentService.getTournamentParticipants(tournamentId: tournamentId) { result in
            switch result {
            case .success(let participants):
                // Find current user's registration
                userRegistrationStatus = participants.first { participant in
                    // In a real implementation, compare with current user ID
                    // For now, we'll assume no registration
                    false
                }
            case .failure:
                userRegistrationStatus = nil
            }
            isLoadingStatus = false
        }
    }

    private func loadTournamentDetails() {
        // In a real implementation, reload tournament data from service
        // For now, this is a placeholder
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}