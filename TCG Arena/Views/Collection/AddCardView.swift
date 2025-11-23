//
//  AddCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import PhotosUI

struct AddCardView: View {
    @EnvironmentObject var cardService: CardService
    @Environment(\.presentationMode) var presentationMode
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
    @State private var showingScanner = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cardImage: UIImage?
    
    var body: some View {
        NavigationView {
            Form {
                cardInformationSection
                descriptionSection
                cardImageSection
                conditionSection
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { 
                    presentationMode.wrappedValue.dismiss() 
                },
                trailing: Button("Add Card") { saveCard() }
                    .disabled(cardName.isEmpty || cardSet.isEmpty)
            )
        }
        .sheet(isPresented: $showingScanner) {
            CardScannerView(isPresented: $showingScanner) { cardName in
                self.cardName = cardName
                // Auto-fill some fields based on card name for demo
                if cardName.contains("Pikachu") {
                    selectedTCG = .pokemon
                    cardSet = "Base Set"
                    selectedRarity = .rare
                    cardNumber = "25/102"
                    cardDescription = "A mouse Pokemon known for its electric abilities"
                } else if cardName.contains("Luffy") {
                    selectedTCG = .onePiece
                    cardSet = "Romance Dawn"
                    selectedRarity = .rare
                    cardNumber = "ST01-001"
                    cardDescription = "Captain of the Straw Hat Pirates"
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
        .sheet(isPresented: $showingScanner) {
            CardScannerView(isPresented: $showingScanner) { cardName in
                self.cardName = cardName
            }
        }
    }
    
    private var cardInformationSection: some View {
        Section("Card Information") {
            HStack {
                TextField("Card Name", text: $cardName)
                
                Button(action: { showingScanner = true }) {
                    SwiftUI.Image(systemName: "camera")
                }
            }
            
            Picker("TCG Type", selection: $selectedTCG) {
                ForEach(TCGType.allCases, id: \.self) { tcg in
                    Text(tcg.displayName).tag(tcg)
                }
            }
            
            TextField("Set", text: $cardSet)
            TextField("Card Number", text: $cardNumber)
            
            Picker("Rarity", selection: $selectedRarity) {
                ForEach(Rarity.allCases, id: \.self) { rarity in
                    Text(rarity.rawValue).tag(rarity)
                }
            }
        }
    }
    
    private var descriptionSection: some View {
        Section("Description") {
            TextField("Card Description", text: $cardDescription, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var cardImageSection: some View {
        Section("Card Image") {
            HStack {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    if let cardImage = cardImage {
                        SwiftUI.Image(uiImage: cardImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 140)
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 140)
                            .overlay {
                                VStack {
                                    SwiftUI.Image(systemName: "photo")
                                    Text("Add Photo")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var conditionSection: some View {
        Section("Condition") {
            Picker("Condition", selection: $selectedCondition) {
                ForEach(CardCondition.allCases, id: \.self) { condition in
                    Text(condition.rawValue).tag(condition)
                }
            }
            
            Toggle("Graded Card", isOn: $isGraded)
            
            if isGraded {
                        Picker("Grade Service", selection: $selectedGradeService) {
                            ForEach(GradeService.allCases, id: \.self) { service in
                                Text(service.rawValue).tag(service)
                            }
                        }
                        
                        Stepper("Grade: \(gradeScore)", value: $gradeScore, in: 1...10)
            }
        }
    }
    
    private func saveCard() {
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
                isFoil: false, // Default to non-foil
                quantity: 1, // Default quantity
                ownerId: 1, // Mock user ID as Int64
                createdAt: Date(),
                updatedAt: Date(),
                tcgType: selectedTCG,
                set: cardSet,
                cardNumber: cardNumber,
                expansion: nil,
                marketPrice: nil
            )
            
            // For mock purposes, just add to the array
            cardService.userCards.append(card)
            
            // Close the view
            presentationMode.wrappedValue.dismiss()
        }
    }
}

#Preview {
    AddCardView()
        .environmentObject(CardService())
}