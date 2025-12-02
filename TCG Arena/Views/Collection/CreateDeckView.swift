//
//  CreateDeckView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/30/25.
//

import SwiftUI

struct CreateDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var deckService: DeckService
    
    let userId: Int64
    
    @State private var deckName = ""
    @State private var deckDescription = ""
    @State private var selectedTCGType: TCGType = .pokemon
    @State private var selectedDeckType: DeckType = .lista
    @State private var isCreating = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 80, height: 80)
                        
                        SwiftUI.Image(systemName: "square.stack")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Create New Deck")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Set up your new deck or list")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Form
                VStack(spacing: 24) {
                    // Deck Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Deck Name")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("Enter deck name", text: $deckName)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemFill))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(deckName.isEmpty ? Color.clear : Color.blue.opacity(0.5), lineWidth: 1.5)
                            )
                    }
                    
                    // Deck Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ZStack(alignment: .topLeading) {
                            if deckDescription.isEmpty {
                                Text("Enter deck description...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                            }
                            
                            TextEditor(text: $deckDescription)
                                .font(.system(size: 16))
                                .padding(12)
                                .frame(minHeight: 80, maxHeight: 120)
                                .background(Color.clear)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemFill))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(deckDescription.isEmpty ? Color.clear : Color.blue.opacity(0.5), lineWidth: 1.5)
                        )
                    }
                    
                    // Deck Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Deck Type")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            DeckTypeOption(
                                type: .lista,
                                title: "List",
                                subtitle: "Organize and collect cards",
                                isSelected: selectedDeckType == .lista
                            ) {
                                selectedDeckType = .lista
                            }
                            
                            DeckTypeOption(
                                type: .deck,
                                title: "Deck",
                                subtitle: "Build competitive decks",
                                isSelected: selectedDeckType == .deck
                            ) {
                                selectedDeckType = .deck
                            }
                        }
                    }
                    
                    // TCG Type
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Game Type")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(TCGType.allCases, id: \.self) { tcgType in
                                    TCGTypeOption(
                                        tcgType: tcgType,
                                        isSelected: selectedTCGType == tcgType
                                    ) {
                                        selectedTCGType = tcgType
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.leading, 4) // Margine a sinistra
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Create Button
                VStack(spacing: 16) {
                    Button(action: createDeck) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canCreateDeck ? Color.green : Color.gray.opacity(0.3))
                                .frame(height: 56)
                            
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Deck")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(!canCreateDeck || isCreating)
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    private var canCreateDeck: Bool {
        !deckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func createDeck() {
        guard canCreateDeck else { return }
        
        isCreating = true
        
        deckService.createDeck(
            name: deckName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: deckDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : deckDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            tcgType: selectedTCGType,
            deckType: selectedDeckType,
            userId: userId
        ) { result in
            DispatchQueue.main.async {
                isCreating = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    // Handle error - could show alert
                    print("Error creating deck: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Deck Type Option
struct DeckTypeOption: View {
    let type: DeckType
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(type == .lista ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        SwiftUI.Image(systemName: type == .lista ? "list.bullet" : "square.stack")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(type == .lista ? .green : .blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        SwiftUI.Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(type == .lista ? .green : .blue)
                    }
                }
            }
            .padding(16)
            .frame(width: 170, height: 100) // Dimensione fissa aumentata
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? (type == .lista ? Color.green : Color.blue) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - TCG Type Option
struct TCGTypeOption: View {
    let tcgType: TCGType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? tcgType.themeColor : Color(.secondarySystemFill))
                        .frame(width: 60, height: 60)
                    
                    SwiftUI.Image(systemName: tcgType.systemIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isSelected ? .white : tcgType.themeColor)
                }
                
                Text(tcgType.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1) // Forza una sola riga per altezza uniforme
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(width: 85, height: 110) // Dimensione fissa aumentata
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? tcgType.themeColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateDeckView(userId: 1)
        .environmentObject(DeckService())
}