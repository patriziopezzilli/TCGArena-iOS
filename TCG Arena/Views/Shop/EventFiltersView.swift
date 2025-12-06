//
//  EventFiltersView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/6/24.
//

import SwiftUI

// MARK: - Event Filters Model
struct EventFilters {
    var dateRange: DateRangeFilter = .all
    var priceRange: PriceRangeFilter = .all
    var selectedTCGTypes: Set<TCGType> = []
    var selectedTournamentTypes: Set<Tournament.TournamentType> = []
    
    enum DateRangeFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        
        var displayName: String {
            rawValue
        }
        
        var icon: String {
            switch self {
            case .all: return "calendar"
            case .today: return "sun.max.fill"
            case .thisWeek: return "calendar.badge.clock"
            case .thisMonth: return "calendar.circle"
            }
        }
    }
    
    enum PriceRangeFilter: String, CaseIterable {
        case all = "All"
        case free = "Free"
        case low = "€0-10"
        case medium = "€10-25"
        case high = "€25+"
        
        var displayName: String {
            rawValue
        }
        
        var priceRange: ClosedRange<Double>? {
            switch self {
            case .all: return nil
            case .free: return 0...0
            case .low: return 0.01...10
            case .medium: return 10.01...25
            case .high: return 25.01...10000
            }
        }
    }
    
    var isActive: Bool {
        dateRange != .all ||
        priceRange != .all ||
        !selectedTCGTypes.isEmpty ||
        !selectedTournamentTypes.isEmpty
    }
    
    var activeFilterCount: Int {
        var count = 0
        if dateRange != .all { count += 1 }
        if priceRange != .all { count += 1 }
        count += selectedTCGTypes.count
        count += selectedTournamentTypes.count
        return count
    }
    
    mutating func reset() {
        dateRange = .all
        priceRange = .all
        selectedTCGTypes = []
        selectedTournamentTypes = []
    }
}

// MARK: - Event Filters View (Bottom Sheet)
struct EventFiltersView: View {
    @Binding var filters: EventFilters
    @Binding var isPresented: Bool
    let onApply: () -> Void
    
    @State private var tempFilters: EventFilters
    
    init(filters: Binding<EventFilters>, isPresented: Binding<Bool>, onApply: @escaping () -> Void) {
        self._filters = filters
        self._isPresented = isPresented
        self.onApply = onApply
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Date Filter Section
                    FilterSection(title: "Date", icon: "calendar") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(EventFilters.DateRangeFilter.allCases, id: \.self) { option in
                                FilterChip(
                                    title: option.displayName,
                                    icon: option.icon,
                                    isSelected: tempFilters.dateRange == option
                                ) {
                                    tempFilters.dateRange = option
                                }
                            }
                        }
                    }
                    
                    // Price Filter Section
                    FilterSection(title: "Entry Fee", icon: "eurosign.circle") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(EventFilters.PriceRangeFilter.allCases, id: \.self) { option in
                                    FilterChip(
                                        title: option.displayName,
                                        isSelected: tempFilters.priceRange == option
                                    ) {
                                        tempFilters.priceRange = option
                                    }
                                }
                            }
                        }
                    }
                    
                    // TCG Type Filter Section
                    FilterSection(title: "TCG Type", icon: "gamecontroller") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach([TCGType.pokemon, .magic, .yugioh, .onePiece], id: \.self) { tcgType in
                                FilterChip(
                                    title: tcgType.displayName,
                                    icon: tcgType.systemIcon,
                                    isSelected: tempFilters.selectedTCGTypes.contains(tcgType),
                                    accentColor: tcgType.themeColor
                                ) {
                                    if tempFilters.selectedTCGTypes.contains(tcgType) {
                                        tempFilters.selectedTCGTypes.remove(tcgType)
                                    } else {
                                        tempFilters.selectedTCGTypes.insert(tcgType)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Tournament Type Filter Section
                    FilterSection(title: "Tournament Type", icon: "trophy") {
                        HStack(spacing: 10) {
                            ForEach(Tournament.TournamentType.allCases, id: \.self) { type in
                                FilterChip(
                                    title: type.displayName,
                                    isSelected: tempFilters.selectedTournamentTypes.contains(type)
                                ) {
                                    if tempFilters.selectedTournamentTypes.contains(type) {
                                        tempFilters.selectedTournamentTypes.remove(type)
                                    } else {
                                        tempFilters.selectedTournamentTypes.insert(type)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .navigationTitle("Filter Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        tempFilters.reset()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresented = false
                    }) {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    // Apply Button
                    Button(action: {
                        filters = tempFilters
                        onApply()
                        isPresented = false
                    }) {
                        HStack {
                            Text("Apply Filters")
                                .font(.system(size: 17, weight: .semibold))
                            
                            if tempFilters.activeFilterCount > 0 {
                                Text("(\(tempFilters.activeFilterCount))")
                                    .font(.system(size: 15, weight: .medium))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue)
                        )
                    }
                    
                    // Clear All Button
                    if tempFilters.isActive {
                        Button(action: {
                            tempFilters.reset()
                        }) {
                            Text("Clear All")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: -5)
                        .ignoresSafeArea()
                )
            }
        }
    }
}

// MARK: - Filter Section Component
struct FilterSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            content
        }
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    var accentColor: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? accentColor : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tournament Type Extension
extension Tournament.TournamentType {
    var displayName: String {
        switch self {
        case .casual: return "Casual"
        case .competitive: return "Competitive"
        case .championship: return "Championship"
        }
    }
}
