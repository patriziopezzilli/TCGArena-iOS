//
//  EditInventoryCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct EditInventoryCardView: View {
    @EnvironmentObject var inventoryService: InventoryService
    @Environment(\.dismiss) var dismiss
    
    let card: InventoryCard
    
    @State private var condition: CardCondition
    @State private var price: Double
    @State private var quantity: Int
    @State private var notes: String
    
    @State private var showDeleteConfirmation = false
    @State private var isSaving = false
    @State private var isDeleting = false
    
    init(card: InventoryCard) {
        self.card = card
        _condition = State(initialValue: card.condition)
        _price = State(initialValue: card.price)
        _quantity = State(initialValue: card.quantity)
        _notes = State(initialValue: card.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Card Preview
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: card.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(AdaptiveColors.backgroundSecondary)
                        }
                        .frame(width: 80, height: 112)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            if let setName = card.setName {
                                Text(setName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(card.tcgType.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(AdaptiveColors.brandPrimary)
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                    
                    // Condition
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Condition")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 8) {
                            ForEach([CardCondition.nearMint, .slightlyPlayed, .moderatelyPlayed, .heavilyPlayed, .damaged], id: \.self) { cond in
                                ConditionOptionRow(
                                    condition: cond,
                                    isSelected: condition == cond
                                ) {
                                    condition = cond
                                }
                            }
                        }
                    }
                    
                    // Price
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Price")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if let marketPrice = card.marketPrice {
                                Text("Market: €\(String(format: "%.2f", marketPrice))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("€")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            TextField("0.00", value: $price, format: .number.precision(.fractionLength(2)))
                                .font(.system(size: 20, weight: .semibold))
                                .keyboardType(.decimalPad)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AdaptiveColors.backgroundSecondary)
                        )
                    }
                    
                    // Quantity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quantity")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                if quantity > 0 {
                                    quantity -= 1
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(quantity > 0 ? AdaptiveColors.brandPrimary : .secondary.opacity(0.3))
                            }
                            .disabled(quantity <= 0)
                            
                            Text("\(quantity)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                                .frame(minWidth: 60)
                            
                            Button(action: {
                                quantity += 1
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AdaptiveColors.brandPrimary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        
                        if quantity == 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(AdaptiveColors.warning)
                                
                                Text("Card will be marked as out of stock")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AdaptiveColors.warning)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AdaptiveColors.warning.opacity(0.1))
                            )
                        }
                    }
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Note (Opzionale)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextEditor(text: $notes)
                            .frame(height: 100)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.backgroundSecondary)
                            )
                    }
                    
                    // Delete Button
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Elimina dall'Inventario")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AdaptiveColors.error)
                        )
                    }
                    .disabled(isDeleting)
                }
                .padding(20)
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveChanges) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || isDeleting || !hasChanges)
                }
            }
            .confirmationDialog(
                "Elimina Carta",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteCard()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Sei sicuro di voler eliminare questa carta dal tuo inventario? Questa azione non può essere annullata.")
            }
        }
    }
    
    private var hasChanges: Bool {
        condition != card.condition ||
        price != card.price ||
        quantity != card.quantity ||
        notes != (card.notes ?? "")
    }
    
    private func saveChanges() {
        isSaving = true
        
        let request = UpdateInventoryCardRequest(
            condition: condition,
            price: price,
            quantity: quantity,
            notes: notes.isEmpty ? nil : notes
        )
        
        Task {
            do {
                try await inventoryService.updateCard(cardId: card.id, request: request)
                
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
    
    private func deleteCard() {
        isDeleting = true
        
        Task {
            do {
                try await inventoryService.deleteCard(cardId: card.id)
                
                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    ToastManager.shared.showError(error.localizedDescription)
                }
            }
        }
    }
}

#Preview {
    EditInventoryCardView(card: InventoryCard(
        id: "1",
        cardId: "card1",
        shopId: "shop1",
        name: "Pikachu VMAX",
        setName: "Vivid Voltage",
        tcgType: .pokemon,
        imageUrl: nil,
        condition: .nearMint,
        price: 25.99,
        quantity: 3,
        marketPrice: 24.50,
        notes: nil,
        createdAt: Date(),
        updatedAt: Date()
    ))
    .environmentObject(InventoryService())
}
.withToastSupport()
