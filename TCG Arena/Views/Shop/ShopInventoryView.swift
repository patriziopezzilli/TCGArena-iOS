//
//  ShopInventoryView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct ShopInventoryView: View {
    @EnvironmentObject var inventoryService: InventoryService
    let shopId: String
    
    @State private var searchText = ""
    @State private var selectedTCG: TCGType?
    @State private var selectedCard: InventoryCard?
    
    var filteredInventory: [InventoryCard] {
        inventoryService.inventory.filter { card in
            let matchesSearch = searchText.isEmpty ||
                card.name.localizedCaseInsensitiveContains(searchText)
            let matchesTCG = selectedTCG == nil || card.tcgType == selectedTCG
            return matchesSearch && matchesTCG && card.isAvailable
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search & Filter
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search cards...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AdaptiveColors.backgroundSecondary)
                )
                
                // TCG Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        TCGFilterButton(title: "All", isSelected: selectedTCG == nil) {
                            selectedTCG = nil
                        }
                        
                        ForEach([TCGType.pokemon, .magic, .yugioh, .onePiece], id: \.self) { tcg in
                            TCGFilterButton(title: tcg.rawValue, isSelected: selectedTCG == tcg) {
                                selectedTCG = tcg
                            }
                        }
                    }
                }
            }
            .padding(16)
            
            Divider()
            
            // Inventory Grid
            if filteredInventory.isEmpty {
                EmptyStateView(
                    icon: "square.stack.3d.up.slash",
                    title: "No Cards Available",
                    message: searchText.isEmpty ?
                        "This shop doesn't have any cards in stock" :
                        "No cards found matching '\(searchText)'"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredInventory) { card in
                            ShopInventoryCardCell(card: card) {
                                selectedCard = card
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(AdaptiveColors.backgroundPrimary)
        .sheet(item: $selectedCard) { card in
            CardReservationView(card: card, shopId: shopId)
        }
        .onAppear {
            loadInventory()
        }
    }
    
    private func loadInventory() {
        Task {
            await inventoryService.loadInventory(shopId: shopId, filters: InventoryFilters(onlyAvailable: true))
        }
    }
}

// MARK: - TCG Filter Button
struct TCGFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : AdaptiveColors.brandPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? AdaptiveColors.brandPrimary : AdaptiveColors.brandPrimary.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shop Inventory Card Cell
struct ShopInventoryCardCell: View {
    let card: InventoryCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Card Image
                AsyncImage(url: URL(string: card.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AdaptiveColors.backgroundSecondary)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let setName = card.setName {
                        Text(setName)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text(card.condition.displayName)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color(card.condition.color))
                            )
                        
                        Spacer()
                        
                        Text(card.formattedPrice)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AdaptiveColors.brandPrimary)
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.backgroundSecondary)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Card Reservation View
struct CardReservationView: View {
    @EnvironmentObject var reservationService: ReservationService
    @Environment(\.dismiss) var dismiss
    
    let card: InventoryCard
    let shopId: String
    
    @State private var isReserving = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Preview
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: card.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(AdaptiveColors.backgroundSecondary)
                        }
                        .frame(width: 120, height: 168)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            if let setName = card.setName {
                                Text(setName)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(card.tcgType.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(AdaptiveColors.brandPrimary))
                        }
                        
                        Spacer()
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(label: "Condition", value: card.condition.displayName)
                        DetailRow(label: "Price", value: card.formattedPrice)
                        DetailRow(label: "Available", value: "\(card.quantity) in stock")
                        
                        if let notes = card.notes {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                Text(notes)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                    
                    // Reservation Info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AdaptiveColors.brandPrimary)
                            
                            Text("Reservation Details")
                                .font(.system(size: 16, weight: .bold))
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                Text("Reserved for 30 minutes")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "qrcode")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                Text("Show QR code at the shop to pick up")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                Text("Free cancellation before validation")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.brandPrimary.opacity(0.1))
                    )
                    
                    // Reserve Button
                    Button(action: createReservation) {
                        HStack {
                            if isReserving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Reserve Card")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AdaptiveColors.brandPrimary)
                        )
                    }
                    .disabled(isReserving)
                }
                .padding(20)
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("Reserve Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("View Reservation") {
                    dismiss()
                    // Navigate to reservations
                }
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your reservation has been created. You have 30 minutes to pick it up.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createReservation() {
        isReserving = true
        
        Task {
            do {
                let request = CreateReservationRequest(
                    cardId: card.cardId,
                    shopId: shopId
                )
                
                try await reservationService.createReservation(request: request)
                
                await MainActor.run {
                    isReserving = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isReserving = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ShopInventoryView(shopId: "shop1")
        .environmentObject(InventoryService())
}
