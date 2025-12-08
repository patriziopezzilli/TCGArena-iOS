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
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var showFilters = false
    
    // Advanced filters
    @State private var minPrice: Double?
    @State private var maxPrice: Double?
    @State private var selectedCondition: InventoryCard.CardCondition?
    @State private var selectedSet: String?
    
    // Available sets from inventory
    private var availableSets: [String] {
        let sets = Set(inventoryService.inventory.compactMap { $0.setName })
        return Array(sets).sorted()
    }
    
    // Active filter count
    private var activeFilterCount: Int {
        var count = 0
        if selectedTCG != nil { count += 1 }
        if minPrice != nil || maxPrice != nil { count += 1 }
        if selectedCondition != nil { count += 1 }
        if selectedSet != nil { count += 1 }
        return count
    }
    
    var filteredInventory: [InventoryCard] {
        inventoryService.inventory.filter { card in
            let matchesSearch = searchText.isEmpty ||
                card.name.localizedCaseInsensitiveContains(searchText)
            let matchesTCG = selectedTCG == nil || card.tcgType == selectedTCG
            let matchesMinPrice = minPrice == nil || card.price >= (minPrice ?? 0)
            let matchesMaxPrice = maxPrice == nil || card.price <= (maxPrice ?? Double.infinity)
            let matchesCondition = selectedCondition == nil || card.condition == selectedCondition
            let matchesSet = selectedSet == nil || card.setName == selectedSet
            return matchesSearch && matchesTCG && matchesMinPrice && matchesMaxPrice && matchesCondition && matchesSet && card.isAvailable
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search & Filter
            VStack(spacing: 12) {
                // Search bar with filter button
                HStack(spacing: 12) {
                    HStack {
                        SwiftUI.Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Cerca carte...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .font(.system(size: 16))
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Filter toggle button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showFilters.toggle()
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            SwiftUI.Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .font(.system(size: 24))
                                .foregroundColor(activeFilterCount > 0 ? .indigo : .secondary)
                            
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Circle().fill(Color.red))
                                    .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
                
                // Expandable filters section
                if showFilters {
                    VStack(spacing: 12) {
                        // TCG Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                TCGFilterChip(title: "Tutti", isSelected: selectedTCG == nil) {
                                    selectedTCG = nil
                                }
                                
                                ForEach([TCGType.pokemon, .magic, .yugioh, .onePiece, .digimon], id: \.self) { tcg in
                                    TCGFilterChip(title: tcg.displayName, isSelected: selectedTCG == tcg) {
                                        selectedTCG = selectedTCG == tcg ? nil : tcg
                                    }
                                }
                            }
                        }
                        
                        // Condition Filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Text("Condizione:")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                ForEach([InventoryCard.CardCondition.nearMint, .lightPlayed, .played, .poor], id: \.self) { condition in
                                    TCGFilterChip(title: condition.shortName, isSelected: selectedCondition == condition) {
                                        selectedCondition = selectedCondition == condition ? nil : condition
                                    }
                                }
                            }
                        }
                        
                        // Price Range
                        HStack(spacing: 12) {
                            Text("Prezzo:")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                TextField("Min", value: $minPrice, format: .number)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 14))
                                    .frame(width: 60)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                                
                                Text("-")
                                    .foregroundColor(.secondary)
                                
                                TextField("Max", value: $maxPrice, format: .number)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 14))
                                    .frame(width: 60)
                                    .padding(8)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                                
                                Text("€")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Clear all filters button
                            if activeFilterCount > 0 {
                                Button(action: clearFilters) {
                                    Text("Resetta")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        // Set Filter (if sets available)
                        if !availableSets.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    Text("Set:")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    
                                    TCGFilterChip(title: "Tutti", isSelected: selectedSet == nil) {
                                        selectedSet = nil
                                    }
                                    
                                    ForEach(availableSets.prefix(10), id: \.self) { setName in
                                        TCGFilterChip(title: setName, isSelected: selectedSet == setName) {
                                            selectedSet = selectedSet == setName ? nil : setName
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            
            Divider()
            
            // Inventory Grid
            if let errorMessage = inventoryService.errorMessage {
                errorStateView(errorMessage: errorMessage)
            } else if filteredInventory.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredInventory) { card in
                            InventoryCardCell(card: card) {
                                selectedCard = card
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $selectedCard) { card in
            CardReservationView(card: card, shopId: shopId) {
                // Reservation successful callback
                toastMessage = "Prenotazione creata con successo! Hai 30 minuti per ritirare la carta."
                withAnimation {
                    showToast = true
                }
                // Hide toast after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showToast = false
                    }
                }
            }
        }
        .onAppear {
            loadInventory()
        }
        .overlay(toastOverlay)
    }
    
    // Toast overlay
    private var toastOverlay: some View {
        Group {
            if showToast {
                VStack {
                    Spacer()
                    ToastView(message: toastMessage, icon: "checkmark.circle.fill", color: .green)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showToast)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                SwiftUI.Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                Text("No Cards Available")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty ? "This shop doesn't have any cards in stock" : "No cards found matching '\(searchText)'")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    private func errorStateView(errorMessage: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                SwiftUI.Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 8) {
                Text("Error Loading Inventory")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(errorMessage)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: loadInventory) {
                Text("Try Again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.indigo)
                    .cornerRadius(12)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    private func loadInventory() {
        inventoryService.clearError()
        Task {
            await inventoryService.loadInventory(shopId: shopId, filters: InventoryFilters(onlyAvailable: true))
        }
    }
    
    private func clearFilters() {
        withAnimation {
            selectedTCG = nil
            minPrice = nil
            maxPrice = nil
            selectedCondition = nil
            selectedSet = nil
        }
    }
}

// MARK: - TCG Filter Chip
private struct TCGFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.selectionChanged()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .indigo)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.indigo : Color.indigo.opacity(0.1))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Inventory Card Cell
private struct InventoryCardCell: View {
    let card: InventoryCard
    let onTap: () -> Void
    
    private var conditionColor: Color {
        switch card.condition {
        case .nearMint: return .green
        case .lightPlayed: return .yellow
        case .played: return .orange
        case .poor: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Card Image
                AsyncImage(url: URL(string: card.fullImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .aspectRatio(2.5/3.5, contentMode: .fit)
                        .overlay(
                            SwiftUI.Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                .aspectRatio(2.5/3.5, contentMode: .fit)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.top, 12)
                .padding(.horizontal, 8)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let setName = card.setName {
                        Text(setName)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text(card.condition.shortName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(conditionColor)
                            )
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(card.formattedPrice)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.indigo)
                            
                            HStack(spacing: 3) {
                                SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                    .font(.system(size: 9))
                                Text("\(card.quantity) disp.")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(card.quantity > 0 ? .green : .red)
                        }
                    }
                }
                .padding(12)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
    let onReservationSuccess: () -> Void
    
    @State private var isReserving = false
    
    private var conditionColor: Color {
        switch card.condition {
        case .nearMint: return .green
        case .lightPlayed: return .yellow
        case .played: return .orange
        case .poor: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Card Preview
                        HStack(spacing: 16) {
                            AsyncImage(url: URL(string: card.fullImageURL ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray5))
                                    .aspectRatio(2.5/3.5, contentMode: .fit)
                            }
                            .frame(width: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
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
                                    .background(Capsule().fill(Color.indigo))
                                
                                if let nationalityDisplayName = card.nationalityDisplayName {
                                    Text(nationalityDisplayName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.blue))
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        
                        // Details
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Condition")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(card.condition.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(conditionColor)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Price")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(card.formattedPrice)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.indigo)
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Availability")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(card.quantity) in stock")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            if let nationalityDisplayName = card.nationalityDisplayName {
                                Divider()
                                
                                HStack {
                                    Text("Country")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(nationalityDisplayName)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            if let notes = card.notes {
                                Divider()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Notes")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                    
                                    Text(notes)
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        
                        // Reservation Info
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SwiftUI.Image(systemName: "info.circle.fill")
                                    .foregroundColor(.indigo)
                                
                                Text("Reservation Details")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ReservationInfoRow(icon: "clock.fill", text: "Reserved for 30 minutes")
                                ReservationInfoRow(icon: "qrcode", text: "Show QR code at the shop to pick up")
                                ReservationInfoRow(icon: "checkmark.circle.fill", text: "Free cancellation before validation")
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color.indigo.opacity(0.1))
                        .cornerRadius(16)
                        
                        // Reserve Button
                        Button(action: createReservation) {
                            HStack(spacing: 8) {
                                if isReserving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    SwiftUI.Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 16))
                                    Text("Reserve Card")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.indigo)
                            )
                        }
                        .disabled(isReserving)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Reserve Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private func createReservation() {
        isReserving = true
        
        Task {
            do {
                _ = try await reservationService.createReservation(
                    cardId: card.id,
                    quantity: 1,
                    availableQuantity: card.quantity
                )
                
                await MainActor.run {
                    isReserving = false
                    // Call success callback and dismiss immediately
                    onReservationSuccess()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isReserving = false
                    ToastManager.shared.showError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Reservation Info Row
private struct ReservationInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            SwiftUI.Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ShopInventoryView(shopId: "shop1")
        .environmentObject(InventoryService())
        .withToastSupport()
}
