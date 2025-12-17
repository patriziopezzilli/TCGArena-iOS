//
//  ExpansionDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

struct ExpansionDetailView: View {
    let expansion: Expansion
    @EnvironmentObject private var expansionService: ExpansionService
    @EnvironmentObject private var marketService: MarketDataService
    @State private var isLoadingExpansion = false
    @State private var loadedExpansion: Expansion? = nil
    
    init(expansion: Expansion) {
        self.expansion = expansion
        print("🆕 [ExpansionDetailView] View initialized for expansion: \(expansion.title) (ID: \(expansion.id))")
    }
    
    private var currentExpansion: Expansion {
        loadedExpansion ?? expansion
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Section
                expansionHeaderSection
                
                // Sets Section
                expansionSetsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
        .task {
            await loadExpansionIfNeeded()
        }
        .onAppear {
            print("👁️ [ExpansionDetailView] View appeared for expansion: \(expansion.title)")
        }
    }
    
    // MARK: - Header Section
    private var expansionHeaderSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(currentExpansion.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(currentExpansion.tcgType.themeColor)
                        .frame(width: 8, height: 8)
                    
                    Text("\(currentExpansion.sets.count) sets")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(currentExpansion.tcgType.themeColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(currentExpansion.tcgType.themeColor.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Sets Section
    private var expansionSetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sets List")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            if currentExpansion.sets.isEmpty {
                // Show loading state if no sets are available
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading sets...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(currentExpansion.sets) { set in
                    NavigationLink(destination: SetDetailView(set: set).environmentObject(marketService)) {
                        SetDetailCard(set: set)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Actions
    private func loadExpansionIfNeeded() async {
        print("🔍 [ExpansionDetailView] Checking expansion: \(expansion.title) (ID: \(expansion.id))")
        print("📊 [ExpansionDetailView] Expansion has \(expansion.sets.count) sets")
        
        // If expansion already has sets, no need to reload
        if !expansion.sets.isEmpty {
            print("✅ Expansion \(expansion.title) already has \(expansion.sets.count) sets loaded")
            // Debug: print set details
            for (index, set) in expansion.sets.enumerated() {
                print("   Set \(index + 1): \(set.name) (\(set.setCode)) - \(set.cardCount) cards")
            }
            return
        }
        
        print("🔄 Expansion \(expansion.title) has no sets, loading details from API...")
        isLoadingExpansion = true
        
        // Load complete expansion details from API
        await withCheckedContinuation { continuation in
            expansionService.getExpansionById(expansion.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let detailedExpansion):
                        print("✅ Loaded expansion details with \(detailedExpansion.sets.count) sets")
                        // Debug: print loaded set details
                        for (index, set) in detailedExpansion.sets.enumerated() {
                            print("   Loaded Set \(index + 1): \(set.name) (\(set.setCode)) - \(set.cardCount) cards")
                        }
                        self.loadedExpansion = detailedExpansion
                    case .failure(let error):
                        print("❌ Failed to load expansion details: \(error.localizedDescription)")
                        // Keep original expansion as fallback
                    }
                    self.isLoadingExpansion = false
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Set Detail Card Component
struct SetDetailCard: View {
    let set: TCGSet
    
    private var cardColor: Color {
        let hash = abs(set.setCode.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Set Image/Icon
            ZStack {
                AsyncImage(url: URL(string: set.logoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(cardColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .overlay(
                            SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(cardColor)
                        )
                }
            }
            
            // Set Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(set.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if set.setCode.count <= 5 {
                        Text(set.setCode.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(cardColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(cardColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                HStack(spacing: 4) {
                    SwiftUI.Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text("\(set.cardCount) cards")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: cardColor.opacity(0.2), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardColor.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    let mockSet = TCGSet(
        id: 1,
        name: "Mock Set",
        setCode: "MST",
        imageURL: nil,
        releaseDateString: "2023-01-01T00:00:00Z",
        cardCount: 100,
        description: "A mock set for testing",
        productType: nil,
        parentSetId: nil,
        cards: []
    )
    let mockExpansion = Expansion(
        id: 1,
        title: "Mock Expansion",
        tcgType: .magic,
        imageUrl: nil,
        productType: nil,
        sets: [mockSet]
    )
    ExpansionDetailView(expansion: mockExpansion)
        .environmentObject(ExpansionService())
}