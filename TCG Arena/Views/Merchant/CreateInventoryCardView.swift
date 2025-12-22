//
//  CreateInventoryCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct CreateInventoryCardView: View {
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var cardService: CardService
    
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText = ""
    @State private var selectedCard: Card?
    @State private var searchResults: [Card] = []
    @State private var isSearching = false
    
    // Form fields
    @State private var tcgType: TCGType = .pokemon
    @State private var condition: CardCondition = .nearMint
    @State private var price: Double = 0.0
    @State private var quantity: Int = 1
    @State private var notes: String = ""
    
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if selectedCard == nil {
                    // Search for card
                    cardSearchView
                } else {
                    // Card details form
                    cardDetailsForm
                }
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("Add to Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                if selectedCard != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: saveCard) {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save")
                                    .fontWeight(.semibold)
                            }
                        }
                        .disabled(isSaving || price <= 0)
                    }
                }
            }
            }
        }
    }
    
    // MARK: - Card Search View
    private var cardSearchView: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Cerca una carta...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .onChange(of: searchText) { _, newValue in
                        searchCards(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AdaptiveColors.backgroundSecondary)
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // TCG Type Filter
            Picker("TCG Type", selection: $tcgType) {
                Text("Pokémon").tag(TCGType.pokemon)
                Text("Magic").tag(TCGType.magic)
                Text("Yu-Gi-Oh!").tag(TCGType.yugioh)
                Text("One Piece").tag(TCGType.onePiece)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .onChange(of: tcgType) { _, _ in
                if !searchText.isEmpty {
                    searchCards(query: searchText)
                }
            }
            
            Divider()
            
            // Search Results
            if isSearching {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else if searchResults.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: searchText.isEmpty ? "Search for Cards" : "No Results",
                    message: searchText.isEmpty ?
                        "Type to search for cards in the database" :
                        "No cards found matching '\(searchText)'"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults) { card in
                            CardSearchResultRow(card: card) {
                                selectedCard = card
                                // Pre-fill some fields
                                if let marketPrice = card.marketPrice {
                                    price = marketPrice
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
    
    // MARK: - Card Details Form
    private var cardDetailsForm: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Selected Card Preview
                if let card = selectedCard {
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
                            
                            Button(action: { selectedCard = nil }) {
                                Text("Change Card")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AdaptiveColors.brandPrimary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                }
                
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
                        
                        if let marketPrice = selectedCard?.marketPrice {
                            Button(action: { price = marketPrice }) {
                                Text("Use Market Price (€\(String(format: "%.2f", marketPrice)))")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AdaptiveColors.brandPrimary)
                            }
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
                            if quantity > 1 {
                                quantity -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(quantity > 1 ? AdaptiveColors.brandPrimary : .secondary.opacity(0.3))
                        }
                        .disabled(quantity <= 1)
                        
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
                }
                
                // Notes (Optional)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes (Optional)")
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
            }
            .padding(20)
        }
    }
    
    // MARK: - Actions
    private func searchCards(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let results = try await cardService.searchCards(
                    query: query,
                    tcgType: tcgType
                )
                
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
    
    private func saveCard() {
        guard let card = selectedCard,
              let shopId = authService.currentUser?.shopId else { return }
        
        isSaving = true
        
        let request = CreateInventoryCardRequest(
            cardId: card.id,
            shopId: shopId,
            condition: condition,
            price: price,
            quantity: quantity,
            notes: notes.isEmpty ? nil : notes
        )
        
        Task {
            do {
                try await inventoryService.createCard(request: request)
                
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

// MARK: - Card Search Result Row
struct CardSearchResultRow: View {
    let card: Card
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: card.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AdaptiveColors.backgroundSecondary)
                }
                .frame(width: 50, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let setName = card.setName {
                        Text(setName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let marketPrice = card.marketPrice {
                        Text("Market: €\(String(format: "%.2f", marketPrice))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AdaptiveColors.brandPrimary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AdaptiveColors.backgroundSecondary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Condition Option Row
struct ConditionOptionRow: View {
    let condition: CardCondition
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(condition.color))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(condition.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(condition.description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AdaptiveColors.brandPrimary)
                        .font(.system(size: 20))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AdaptiveColors.brandPrimary.opacity(0.1) : AdaptiveColors.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AdaptiveColors.brandPrimary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateInventoryCardView()
        .environmentObject(InventoryService())
        .environmentObject(AuthService())
        .environmentObject(CardService())
}
