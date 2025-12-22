//
//  CardScanResultView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

struct CardScanResultView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    
    let scannedCard: ScannedCardData
    
    @State private var cardName: String
    @State private var selectedTCG: TCGType
    @State private var cardSet: String
    @State private var selectedRarity: Rarity
    @State private var cardNumber: String
    @State private var cardDescription = ""
    @State private var selectedCondition: CardCondition = .nearMint
    @State private var isGraded = false
    @State private var selectedGradeService: GradeService = .psa
    @State private var gradeScore = 10
    @State private var isSaving = false
    @State private var showSuccess = false
    @State private var selectedDeckID: String?
    
    init(scannedCard: ScannedCardData) {
        self.scannedCard = scannedCard
        self._cardName = State(initialValue: scannedCard.name)
        self._selectedTCG = State(initialValue: scannedCard.tcgType)
        self._cardSet = State(initialValue: scannedCard.set)
        self._selectedRarity = State(initialValue: scannedCard.rarity)
        self._cardNumber = State(initialValue: scannedCard.cardNumber)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            SwiftUI.Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 8) {
                            Text("Card Scanned!")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Review and confirm the detected information")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Scanned Image & Info
                    HStack(spacing: 20) {
                        // Card Image
                        SwiftUI.Image(uiImage: scannedCard.image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 168)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        // Detected Info Summary
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Detected Information")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Text(cardName)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                InfoPillView(
                                    text: selectedTCG.displayName,
                                    color: selectedTCG.themeColor
                                ) {
                                    TCGIconView(tcgType: selectedTCG, size: 12, color: selectedTCG.themeColor)
                                }
                                
                                InfoPillView(
                                    icon: "number",
                                    text: cardNumber,
                                    color: .blue
                                )
                                
                                InfoPillView(
                                    icon: "star.fill",
                                    text: selectedRarity.rawValue,
                                    color: rarityColor(selectedRarity)
                                )
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // Editable Fields
                    VStack(spacing: 20) {
                        SectionHeaderView(title: "Card Details", subtitle: "Edit any incorrect information")
                        
                        VStack(spacing: 16) {
                            ModernTextField(
                                title: "Card Name",
                                text: $cardName,
                                icon: "textformat"
                            )
                            
                            ModernPickerField(
                                title: "TCG Type",
                                selection: $selectedTCG,
                                options: TCGType.allCases,
                                icon: "gamecontroller"
                            ) { tcg in
                                tcg.displayName
                            }
                            
                            HStack(spacing: 12) {
                                ModernTextField(
                                    title: "Set",
                                    text: $cardSet,
                                    icon: "folder"
                                )
                                
                                ModernTextField(
                                    title: "Card #",
                                    text: $cardNumber,
                                    icon: "number"
                                )
                            }
                            
                            ModernPickerField(
                                title: "Rarity",
                                selection: $selectedRarity,
                                options: Rarity.allCases,
                                icon: "star"
                            ) { rarity in
                                rarity.rawValue
                            }
                        }
                        
                        SectionHeaderView(title: "Card Condition", subtitle: "Assess the physical condition")
                        
                        VStack(spacing: 16) {
                            ModernPickerField(
                                title: "Condition",
                                selection: $selectedCondition,
                                options: CardCondition.allCases,
                                icon: "shield"
                            ) { condition in
                                condition.displayName
                            }
                            
                            ModernToggleField(
                                title: "Graded Card",
                                subtitle: "Is this card professionally graded?",
                                isOn: $isGraded,
                                icon: "award"
                            )
                            
                            if isGraded {
                                HStack(spacing: 12) {
                                    ModernPickerField(
                                        title: "Grade Service",
                                        selection: $selectedGradeService,
                                        options: GradeService.allCases,
                                        icon: "building.2"
                                    ) { service in
                                        service.rawValue
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Grade Score")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Stepper("Score: \(gradeScore)", value: $gradeScore, in: 1...10)
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                }
                            }
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            TextField("Enter card description...", text: $cardDescription, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Deck Selection Section
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
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Review Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveCard) {
                        HStack(spacing: 6) {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            } else {
                                SwiftUI.Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(isSaving ? "Saving" : "Save")
                                .fontWeight(.semibold)
                        }
                        .animation(.easeInOut(duration: 0.2), value: isSaving)
                    }
                    .disabled(cardName.isEmpty || cardSet.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    LoadingOverlay(message: "Saving scanned card...")
                }
            }
            .overlay {
                if showSuccess {
                    SuccessAnimation()
                }
            }
        }
    }
    
    private func saveCard() {
        isSaving = true
        
        Task {
            var imageURL: String? = nil
            
            // Upload image
            if let imageData = scannedCard.image.jpegData(compressionQuality: 0.8) {
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
                marketPrice: nil,
                description: nil
            )
            
            // For scanned cards, we need to find or create a card template first
            // For now, show success without adding to backend (requires template management)
            await MainActor.run {
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
    
    private func rarityColor(_ rarity: Rarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .ultraRare: return .purple
        case .secretRare: return .orange
        case .holographic: return .cyan
        case .promo: return .mint
        case .mythic: return .red
        case .legendary: return .yellow
        case .superRare: return .red
        case .hyperRare: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        }
    }
}

// MARK: - Supporting Views

struct InfoPillView<Icon: View>: View {
    let icon: Icon
    let text: String
    let color: Color
    
    init(icon: String, text: String, color: Color) where Icon == SwiftUI.Image {
        self.icon = SwiftUI.Image(systemName: icon)
        self.text = text
        self.color = color
    }
    
    init(text: String, color: Color, @ViewBuilder icon: () -> Icon) {
        self.icon = icon()
        self.text = text
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 6) {
            icon
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

#Preview {
    CardScanResultView(
        scannedCard: ScannedCardData(
            name: "Pikachu",
            tcgType: TCGType.pokemon,
            set: "Base Set",
            cardNumber: "25/102",
            rarity: Rarity.rare,
            image: UIImage(systemName: "photo")!,
            recognizedTexts: []
        )
    )
    .environmentObject(CardService())
    .environmentObject(DeckService())
}
