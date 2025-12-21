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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(currentExpansion.title)
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // TCG Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(currentExpansion.tcgType.themeColor)
                        .frame(width: 8, height: 8)
                    Text(currentExpansion.tcgType.shortName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentExpansion.tcgType.themeColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(currentExpansion.tcgType.themeColor.opacity(0.1))
                .clipShape(Capsule())
            }
            
            Text("\(currentExpansion.sets.count) Sets Disponibili")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Sets Section
    private var expansionSetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if currentExpansion.sets.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Caricamento sets...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(currentExpansion.sets) { set in
                        NavigationLink(destination: SetDetailView(set: set).environmentObject(marketService)) {
                            SetDetailRow(set: set)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider()
                            .padding(.leading, 76) 
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func loadExpansionIfNeeded() async {
        // ... (Keep existing logic, just ensure print statements are minimal or as needed)
        // For brevity in this replacement, I will assume the logic remains the same.
        // But since I am replacing the UI components, I need to keep the logic methods if I don't touch them.
        // Wait, I am replacing the whole view body and subviews usually.
        // I will just replace the VIEW parts.
        
        // Actually, let's keep the logic correctly. The tool replaces blocks.
        // I'll replace the body and helper views, keeping the logic methods if they are outside the range or I'll include them if needed.
        
        // Re-implementing loadExpansionIfNeeded just to be safe and clean.
        print("Checking expansion: \(expansion.title)")
        if !expansion.sets.isEmpty { return }
        
        isLoadingExpansion = true
        await withCheckedContinuation { continuation in
            expansionService.getExpansionById(expansion.id) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let detailed):
                        self.loadedExpansion = detailed
                    case .failure:
                        break 
                    }
                    self.isLoadingExpansion = false
                    continuation.resume()
                }
            }
        }
    }
}

// MARK: - Set Detail Row Component (Ultra Minimal)
struct SetDetailRow: View {
    let set: TCGSet
    
    private var setCodeColor: Color {
        let hash = abs(set.setCode.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.8)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Set Icon
            ZStack {
                AsyncImage(url: URL(string: set.logoUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            Text(set.setCode.prefix(2))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                        )
                }
            }
            .frame(width: 60, height: 60)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(set.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text(set.setCode)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(6)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                        
                    Text("\(set.cardCount) carte")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
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
