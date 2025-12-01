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
    let onComplete: (Bool) -> Void
    
    @State private var deckName = ""
    @State private var notes = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(tournament.name)
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
                            Text(tournament.startDate, style: .date)
                            Text(tournament.startDate, style: .time)
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
        
        Task {
            do {
                try await tournamentService.register(
                    tournamentId: tournament.id,
                    deckName: deckName,
                    notes: notes.isEmpty ? nil : notes
                )
                
                await MainActor.run {
                    onComplete(true)
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
