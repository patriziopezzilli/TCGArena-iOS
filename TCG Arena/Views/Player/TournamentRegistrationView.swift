//
//  TournamentRegistrationView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct TournamentRegistrationView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @Environment(\.dismiss) var dismiss
    
    let tournament: Tournament
    let onComplete: (TournamentParticipant?) -> Void
    
    @State private var deckName = ""
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tournament.title)
                            .font(.headline)
                        
                        HStack {
                            Text(tournament.tcgType.displayName)
                            Text("•")
                            Text(tournament.format.displayName)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Image(systemName: "calendar")
                            Text(formatDate(tournament.startDate))
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Tournament Details")
                }
                
                Section {
                    TextField("Deck Name", text: $deckName)
                        .autocapitalization(.words)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Registration Info")
                } footer: {
                    Text("Enter your deck name and any additional notes for the tournament organizer.")
                }
                
                if tournament.entryFee > 0 {
                    Section {
                        HStack {
                            Text("Entry Fee")
                                .font(.headline)
                            
                            Spacer()
                            
                            Text("€\(tournament.entryFee, specifier: "%.2f")")
                                .font(.headline)
                                .foregroundColor(Color(AdaptiveColors.primary))
                        }
                    } footer: {
                        Text("Entry fee must be paid at the shop before the tournament starts.")
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Register")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Register") {
                        submitRegistration()
                    }
                    .disabled(deckName.isEmpty || isSubmitting)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func submitRegistration() {
        isSubmitting = true
        errorMessage = nil
        
        guard let tournamentId = tournament.id else {
            errorMessage = "Invalid tournament ID"
            isSubmitting = false
            return
        }
        
        Task {
            do {
                let participant = try await tournamentService.registerForTournament(tournamentId: tournamentId)
                
                await MainActor.run {
                    onComplete(participant)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to register: \(error.localizedDescription)"
                    isSubmitting = false
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    TournamentRegistrationView(
        tournament: Tournament(
            id: "1",
            name: "Weekly Magic Tournament",
            description: "Standard format tournament",
            tcgType: .magic,
            format: .standard,
            maxParticipants: 16,
            currentParticipants: 8,
            entryFee: 5.0,
            prizeDistribution: [1: "3 boosters"],
            startDate: Date().addingTimeInterval(86400),
            registrationDeadline: Date().addingTimeInterval(3600),
            shopId: "shop1",
            status: .scheduled,
            rules: "Standard rules apply",
            createdAt: Date(),
            updatedAt: Date(),
            shop: nil
        ),
        onComplete: { _ in }
    )
    .environmentObject(TournamentService(apiClient: APIClient.shared))
}
