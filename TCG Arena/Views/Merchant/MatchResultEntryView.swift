//
//  MatchResultEntryView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct MatchResultEntryView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @Environment(\.dismiss) var dismiss
    
    let match: Match
    let tournament: Tournament
    
    @State private var selectedResult: Match.MatchResult?
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Match Info
                    VStack(spacing: 16) {
                        Text("Round \(match.roundNumber)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            // Player 1
                            PlayerCard(
                                player: match.player1,
                                isSelected: selectedResult == .player1Win
                            ) {
                                selectedResult = .player1Win
                            }
                            
                            Text("VS")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            // Player 2
                            PlayerCard(
                                player: match.player2,
                                isSelected: selectedResult == .player2Win
                            ) {
                                selectedResult = .player2Win
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                    
                    // Result Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Match Result")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ResultOption(
                                title: "\(match.player1?.displayName ?? "Player 1") Wins",
                                icon: "checkmark.circle.fill",
                                color: AdaptiveColors.success,
                                isSelected: selectedResult == .player1Win
                            ) {
                                selectedResult = .player1Win
                            }
                            
                            ResultOption(
                                title: "\(match.player2?.displayName ?? "Player 2") Wins",
                                icon: "checkmark.circle.fill",
                                color: AdaptiveColors.success,
                                isSelected: selectedResult == .player2Win
                            ) {
                                selectedResult = .player2Win
                            }
                            
                            ResultOption(
                                title: "Draw",
                                icon: "equal.circle.fill",
                                color: AdaptiveColors.warning,
                                isSelected: selectedResult == .draw
                            ) {
                                selectedResult = .draw
                            }
                        }
                    }
                    
                    // Submit Button
                    Button(action: submitResult) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Submit Result")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedResult == nil ? Color.secondary : AdaptiveColors.brandPrimary)
                        )
                    }
                    .disabled(selectedResult == nil || isSaving)
                }
                .padding(20)
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("Match Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submitResult() {
        guard let result = selectedResult else { return }
        
        isSaving = true
        
        Task {
            do {
                try await tournamentService.submitMatchResult(
                    tournamentId: tournament.id,
                    matchId: match.id,
                    result: result
                )
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    ToastManager.shared.showError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Player Card
struct PlayerCard: View {
    let player: User?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Circle()
                    .fill(isSelected ? AdaptiveColors.success.opacity(0.2) : AdaptiveColors.brandPrimary.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(player?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(isSelected ? AdaptiveColors.success : AdaptiveColors.brandPrimary)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? AdaptiveColors.success : Color.clear, lineWidth: 3)
                    )
                
                Text(player?.displayName ?? "Unknown")
                    .font(.system(size: 15, weight: isSelected ? .bold : .semibold))
                    .foregroundColor(isSelected ? AdaptiveColors.success : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AdaptiveColors.success)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? AdaptiveColors.success.opacity(0.1) : AdaptiveColors.backgroundPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AdaptiveColors.success : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Result Option
struct ResultOption: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MatchResultEntryView(
        match: Match(
            id: "1",
            tournamentId: "t1",
            roundNumber: 1,
            player1Id: "p1",
            player2Id: "p2",
            tableNumber: 1,
            result: nil,
            createdAt: Date()
        ),
        tournament: Tournament(
            id: "t1",
            shopId: "s1",
            name: "Test Tournament",
            description: nil,
            tcgType: .pokemon,
            format: .swiss,
            date: Date(),
            maxParticipants: 16,
            currentParticipants: 8,
            status: .inProgress,
            entryFee: nil,
            prizePool: nil,
            rules: nil,
            createdAt: Date()
        )
    )
    .environmentObject(TournamentService.shared)
}
.withToastSupport()
