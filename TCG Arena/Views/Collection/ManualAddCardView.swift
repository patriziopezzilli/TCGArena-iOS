//
//  ManualAddCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI
import PhotosUI

struct ManualAddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    
    @State private var cardName = ""
    @State private var selectedTCG: TCGType = .pokemon
    @State private var cardSet = ""
    @State private var selectedRarity: Rarity = .common
    @State private var cardNumber = ""
    @State private var cardDescription = ""
    @State private var selectedCondition: Card.CardCondition = .nearMint
    @State private var isGraded = false
    @State private var selectedGradeService: GradeService = .psa
    @State private var gradeScore = 10
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cardImage: UIImage?
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var selectedDeckID: Int64?
    
    private var headerView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 60, height: 60)
                
                SwiftUI.Image(systemName: "keyboard")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("Add Manually")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Fill in your card details")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 16)
    }
    
    private var cardInformationView: some View {
        VStack(spacing: 16) {
            SectionHeaderView(title: "Card Information", subtitle: "Enter card details")
            
            VStack(spacing: 12) {
                // Card Name + Photo Row
                HStack(spacing: 12) {
                    VStack {
                        ModernTextField(
                            title: "Card Name *",
                            text: $cardName,
                            icon: "textformat"
                        )
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Compact Photo Selector
                    VStack(spacing: 6) {
                        Text("Photo (Optional)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            if let cardImage = cardImage {
                                SwiftUI.Image(uiImage: cardImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 84)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.purple.opacity(0.4), lineWidth: 1.5)
                                    )
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color(.systemGray6))
                                        .frame(width: 60, height: 84)
                                    
                                    VStack(spacing: 4) {
                                        SwiftUI.Image(systemName: "camera.fill")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.purple)
                                        
                                        Text("Tap")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(.purple)
                                    }
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                ModernPickerField(
                    title: "TCG Type *",
                    selection: $selectedTCG,
                    options: TCGType.allCases,
                    icon: "gamecontroller"
                ) { tcg in
                    tcg.displayName
                }
                
                HStack(spacing: 10) {
                    ModernTextField(
                        title: "Set (Optional)",
                        text: $cardSet,
                        icon: "folder"
                    )
                    
                    ModernTextField(
                        title: "Card Number (Optional)",
                        text: $cardNumber,
                        icon: "number"
                    )
                }
                
                ModernPickerField(
                    title: "Rarity (Optional)",
                    selection: $selectedRarity,
                    options: Rarity.allCases,
                    icon: "star"
                ) { rarity in
                    rarity.rawValue
                }
            }
            
            // Description (Optional)
            VStack(alignment: .leading, spacing: 6) {
                Text("Description (Optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("Add card notes or description...", text: $cardDescription, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var conditionSectionView: some View {
        VStack(spacing: 16) {
            SectionHeaderView(title: "Condition & Grading", subtitle: "Optional details")
            
            VStack(spacing: 12) {
                ModernPickerField(
                    title: "Condition (Optional)",
                    selection: $selectedCondition,
                    options: Card.CardCondition.allCases,
                    icon: "shield"
                ) { condition in
                    condition.rawValue
                }
                
                ModernToggleField(
                    title: "Graded Card",
                    subtitle: "Professionally graded?",
                    isOn: $isGraded,
                    icon: "award"
                )
                
                if isGraded {
                    VStack(spacing: 10) {
                        ModernPickerField(
                            title: "Grading Service",
                            selection: $selectedGradeService,
                            options: GradeService.allCases,
                            icon: "building.2"
                        ) { service in
                            service.rawValue
                        }
                        
                        GradeScoreView(score: $gradeScore)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var deckSelectionView: some View {
        VStack(spacing: 16) {
            SectionHeaderView(title: "Deck Assignment", subtitle: "Choose which deck to add this card to")
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Deck *")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Picker("Select Deck", selection: $selectedDeckID) {
                        ForEach(deckService.userDecks, id: \.id) { deck in
                            Text(deck.name).tag(deck.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var saveButtonView: some View {
        LoadingButton(
            title: "Add to Collection",
            loadingTitle: "Adding Card...",
            isLoading: isSaving,
            isDisabled: cardName.isEmpty,
            color: .purple,
            action: saveCard
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    
                    cardInformationView
                    
                    conditionSectionView
                    
                    deckSelectionView
                    
                    saveButtonView
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isSaving {
                    LoadingOverlay(message: "Adding card to your collection...")
                }
            }
            .overlay {
                if showSuccess {
                    SuccessAnimation()
                }
            }
        }
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    cardImage = image
                }
            }
        }
    }
    
    private func saveCard() {
        isSaving = true
        
        Task {
            var imageURL: String? = nil
            
            // Upload image if available
            if let cardImage = cardImage,
               let imageData = cardImage.jpegData(compressionQuality: 0.8) {
                imageURL = await cardService.uploadCardImage(imageData)
            }
            
            // Create card
            let card = Card(
                id: nil,
                templateId: 1, // Mock template ID
                name: cardName,
                rarity: selectedRarity,
                condition: selectedCondition,
                imageURL: imageURL,
                isFoil: false,
                quantity: 1,
                ownerId: 1 as Int64, // Mock owner ID
                createdAt: Date(),
                updatedAt: Date(),
                tcgType: selectedTCG,
                set: cardSet,
                cardNumber: cardNumber,
                expansion: nil,
                marketPrice: nil
            )
            
            // For mock purposes, add to array
            await MainActor.run {
                cardService.userCards.append(card)
                isSaving = false
                
                // Show success animation
                showSuccess = true
                
                // Auto dismiss after success animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Grade Score View
struct GradeScoreView: View {
    @Binding var score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grade Score")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Score: \(score)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(scoreDescription(score))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(scoreColor(score))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(scoreColor(score).opacity(0.2))
                        )
                }
                
                Slider(value: .init(
                    get: { Double(score) },
                    set: { score = Int($0) }
                ), in: 1...10, step: 1)
                .accentColor(.purple)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
    
    private func scoreDescription(_ score: Int) -> String {
        switch score {
        case 10: return "Gem Mint"
        case 9: return "Mint"
        case 8: return "Near Mint"
        case 7: return "Very Fine"
        case 6: return "Fine"
        case 5: return "Very Good"
        case 4: return "Good"
        case 3: return "Fair"
        case 2: return "Poor"
        default: return "Authentic"
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 9...10: return .green
        case 7...8: return .blue
        case 5...6: return .orange
        default: return .red
        }
    }
}

#Preview {
    ManualAddCardView()
        .environmentObject(CardService())
        .environmentObject(DeckService())
}