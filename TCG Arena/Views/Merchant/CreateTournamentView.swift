//
//  CreateTournamentView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct CreateTournamentView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var tcgType: TCGType = .pokemon
    @State private var format: Tournament.TournamentFormat = .swiss
    @State private var date = Date().addingTimeInterval(86400 * 7) // 1 week from now
    @State private var maxParticipants = 16
    @State private var entryFee: Double = 0.0
    @State private var prizePool = ""
    @State private var rules = ""
    
    @State private var isSaving = false
    
    let maxParticipantsOptions = [8, 16, 32, 64, 128]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Basic Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        TournamentSectionHeader(title: "Basic Information")
                        
                        VStack(spacing: 12) {
                            CustomTextField(
                                icon: "trophy.fill",
                                placeholder: "Tournament Name",
                                text: $name
                            )
                            
                            CustomTextEditor(
                                icon: "text.alignleft",
                                placeholder: "Description",
                                text: $description
                            )
                        }
                    }
                    
                    // Game Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        TournamentSectionHeader(title: "Game Settings")
                        
                        VStack(spacing: 12) {
                            // TCG Type
                            VStack(alignment: .leading, spacing: 8) {
                                Label("TCG Type", systemImage: "gamecontroller.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Picker("TCG Type", selection: $tcgType) {
                                    Text("Pokémon").tag(TCGType.pokemon)
                                    Text("Magic").tag(TCGType.magic)
                                    Text("Yu-Gi-Oh!").tag(TCGType.yugioh)
                                    Text("One Piece").tag(TCGType.onePiece)
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.backgroundSecondary)
                            )
                            
                            // Format
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Tournament Format", systemImage: "list.bullet")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Picker("Format", selection: $format) {
                                    ForEach([Tournament.TournamentFormat.swiss, .singleElimination, .doubleElimination, .roundRobin], id: \.self) { fmt in
                                        Text(fmt.displayName).tag(fmt)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.backgroundSecondary)
                            )
                        }
                    }
                    
                    // Schedule & Participants Section
                    VStack(alignment: .leading, spacing: 16) {
                        TournamentSectionHeader(title: "Schedule & Participants")
                        
                        VStack(spacing: 12) {
                            // Date Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Tournament Date", systemImage: "calendar")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                DatePicker("", selection: $date, in: Date()...)
                                    .datePickerStyle(.graphical)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.backgroundSecondary)
                            )
                            
                            // Max Participants
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Maximum Participants", systemImage: "person.2.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Picker("Max Participants", selection: $maxParticipants) {
                                    ForEach(maxParticipantsOptions, id: \.self) { count in
                                        Text("\(count) Players").tag(count)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.backgroundSecondary)
                            )
                        }
                    }
                    
                    // Entry & Prizes Section
                    VStack(alignment: .leading, spacing: 16) {
                        TournamentSectionHeader(title: "Entry & Prizes")
                        
                        VStack(spacing: 12) {
                            // Entry Fee
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Entry Fee", systemImage: "eurosign.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Text("€")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    TextField("0.00", value: $entryFee, format: .number.precision(.fractionLength(2)))
                                        .font(.system(size: 18, weight: .semibold))
                                        .keyboardType(.decimalPad)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.backgroundSecondary)
                            )
                            
                            // Prize Pool
                            CustomTextField(
                                icon: "gift.fill",
                                placeholder: "Prize Pool (e.g., Booster Box)",
                                text: $prizePool
                            )
                        }
                    }
                    
                    // Rules Section
                    VStack(alignment: .leading, spacing: 16) {
                        TournamentSectionHeader(title: "Rules (Optional)")
                        
                        CustomTextEditor(
                            icon: "doc.text.fill",
                            placeholder: "Tournament rules and special instructions...",
                            text: $rules,
                            height: 120
                        )
                    }
                }
                .padding(20)
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("Create Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createTournament) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Create")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || !isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && maxParticipants > 0
    }
    
    private func createTournament() {
        guard let shopId = authService.currentUser?.shopId else { return }
        
        isSaving = true
        
        let tournament = Tournament(
            id: UUID().uuidString,
            shopId: shopId,
            name: name,
            description: description.isEmpty ? nil : description,
            tcgType: tcgType,
            format: format,
            date: date,
            maxParticipants: maxParticipants,
            currentParticipants: 0,
            status: .registrationOpen,
            entryFee: entryFee > 0 ? entryFee : nil,
            prizePool: prizePool.isEmpty ? nil : prizePool,
            rules: rules.isEmpty ? nil : rules,
            createdAt: Date()
        )
        
        Task {
            do {
                try await tournamentService.createTournament(tournament: tournament)
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    ToastManager.shared.showError("Failed to create tournament: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Section Header
struct TournamentSectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.primary)
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AdaptiveColors.brandPrimary)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
}

// MARK: - Custom Text Editor
struct CustomTextEditor: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 80
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AdaptiveColors.brandPrimary)
                .frame(width: 24)
                .padding(.top, 8)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 16))
                    .frame(height: height)
                    .scrollContentBackground(.hidden)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
}

#Preview {
    CreateTournamentView()
        .environmentObject(TournamentService.shared)
        .environmentObject(AuthService())
}
