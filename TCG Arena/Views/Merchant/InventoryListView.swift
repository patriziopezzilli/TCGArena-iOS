//
//  InventoryListView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct InventoryListView: View {
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var authService: AuthService
    
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var showAddCard = false
    @State private var selectedCard: InventoryCard?
    @State private var filters = InventoryFilters()
    
    var filteredInventory: [InventoryCard] {
        inventoryService.inventory.filter { card in
            let matchesSearch = searchText.isEmpty || 
                card.name.localizedCaseInsensitiveContains(searchText) ||
                card.setName?.localizedCaseInsensitiveContains(searchText) == true
            
            let matchesTCG = filters.tcgType == nil || card.tcgType == filters.tcgType
            let matchesCondition = filters.condition == nil || card.condition == filters.condition
            let matchesAvailability = !filters.onlyAvailable || card.isAvailable
            
            return matchesSearch && matchesTCG && matchesCondition && matchesAvailability
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Cerca carte...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AdaptiveColors.backgroundSecondary)
                )
                
                Button(action: { showFilters.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(hasActiveFilters ? .white : AdaptiveColors.brandPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(hasActiveFilters ? AdaptiveColors.brandPrimary : AdaptiveColors.brandPrimary.opacity(0.1))
                        )
                }
                
                Button(action: { showAddCard = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AdaptiveColors.brandPrimary)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Filter Summary
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let tcgType = filters.tcgType {
                            FilterChip(title: tcgType.rawValue) {
                                filters.tcgType = nil
                            }
                        }
                        
                        if let condition = filters.condition {
                            FilterChip(title: condition.displayName) {
                                filters.condition = nil
                            }
                        }
                        
                        if filters.onlyAvailable {
                            FilterChip(title: "Available Only") {
                                filters.onlyAvailable = false
                            }
                        }
                        
                        Button(action: { filters = InventoryFilters() }) {
                            Text("Clear All")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AdaptiveColors.error)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 8)
            }
            
            // Inventory List
            if filteredInventory.isEmpty {
                EmptyStateView(
                    icon: "square.stack.3d.up.slash",
                    title: searchText.isEmpty ? "Nessun Inventario" : "Nessun Risultato",
                    message: searchText.isEmpty ? 
                        "Add cards to your inventory to get started" :
                        "Try adjusting your search or filters"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredInventory) { card in
                            InventoryCardRow(card: card) {
                                selectedCard = card
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(AdaptiveColors.backgroundPrimary)
        .sheet(isPresented: $showFilters) {
            InventoryFiltersView(filters: $filters)
        }
        .sheet(isPresented: $showAddCard) {
            CreateInventoryCardView()
        }
        .sheet(item: $selectedCard) { card in
            EditInventoryCardView(card: card)
        }
        .onAppear {
            loadInventory()
        }
    }
    
    private var hasActiveFilters: Bool {
        filters.tcgType != nil || filters.condition != nil || filters.onlyAvailable
    }
    
    private func loadInventory() {
        guard let shopId = authService.currentUser?.shopId else { return }
        
        Task {
            await inventoryService.loadInventory(shopId: shopId, filters: filters)
        }
    }
}

// MARK: - Inventory Card Row
struct InventoryCardRow: View {
    let card: InventoryCard
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
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
                .frame(width: 60, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Card Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let setName = card.setName {
                        Text(setName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 8) {
                        // TCG Badge
                        Text(card.tcgType.rawValue)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(AdaptiveColors.brandPrimary)
                            )
                        
                        // Country Badge
                        if let nationalityDisplayName = card.nationalityDisplayName {
                            Text(nationalityDisplayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                        }
                        
                        // Condition Badge
                        Text(card.condition.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(card.condition.color))
                            )
                    }
                }
                
                Spacer()
                
                // Price & Quantity
                VStack(alignment: .trailing, spacing: 6) {
                    Text(card.formattedPrice)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AdaptiveColors.brandPrimary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "square.stack.3d.up.fill")
                            .font(.system(size: 11))
                        
                        Text("\(card.quantity)")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(card.isAvailable ? AdaptiveColors.success : AdaptiveColors.error)
                    
                    if !card.isAvailable {
                        Text("Out of Stock")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AdaptiveColors.error)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.backgroundSecondary)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(AdaptiveColors.brandPrimary)
        )
    }
}

// MARK: - Inventory Filters View
struct InventoryFiltersView: View {
    @Binding var filters: InventoryFilters
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("TCG Type") {
                    Picker("TCG Type", selection: $filters.tcgType) {
                        Text("All").tag(nil as TCGType?)
                        ForEach([TCGType.pokemon, .magic, .yugioh, .onePiece], id: \.self) { type in
                            Text(type.rawValue).tag(type as TCGType?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Condition") {
                    Picker("Condition", selection: $filters.condition) {
                        Text("All").tag(nil as InventoryCard.CardCondition?)
                        ForEach([InventoryCard.CardCondition.nearMint, .lightPlayed, .played, .poor], id: \.self) { condition in
                            Text(condition.displayName).tag(condition as InventoryCard.CardCondition?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section {
                    Toggle("Available Only", isOn: $filters.onlyAvailable)
                }
                
                Section("Price Range") {
                    HStack {
                        TextField("Min", value: $filters.minPrice, format: .currency(code: "EUR"))
                            .keyboardType(.decimalPad)
                        
                        Text("-")
                        
                        TextField("Max", value: $filters.maxPrice, format: .currency(code: "EUR"))
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        filters = InventoryFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    InventoryListView()
        .environmentObject(InventoryService())
        .environmentObject(AuthService())
}
