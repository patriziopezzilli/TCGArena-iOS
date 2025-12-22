//
//  ReadOnlyContentView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/19/25.
//

import SwiftUI

struct ReadOnlyContentView: View {
    @State private var selectedTab = 0
    @State private var showLoginPrompt = false
    @StateObject private var cardService = CardService()
    @StateObject private var shopService = ShopService()
    @StateObject private var tournamentService = TournamentService()
    @StateObject private var deckService = DeckService()
    @StateObject private var inventoryService = InventoryService()
    @StateObject private var marketService = MarketDataService()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Collection - Limited access
                ReadOnlyCollectionView()
                    .environmentObject(cardService)
                    .environmentObject(deckService)
                    .environmentObject(marketService)
                    .environmentObject(authService)
                    .tabItem {
                        SwiftUI.Image(systemName: "rectangle.stack")
                        Text("Mazzi")
                    }
                    .tag(0)

                // Shop - Full access (browsing)
                ShopView()
                    .environmentObject(shopService)
                    .environmentObject(tournamentService)
                    .environmentObject(inventoryService)
                    .environmentObject(authService)
                    .environmentObject(locationManager)
                    .tabItem {
                        SwiftUI.Image(systemName: "storefront")
                        Text("Negozi")
                    }
                    .tag(1)

                // Rewards - Limited access
                ReadOnlyRewardsView()
                    .tabItem {
                        SwiftUI.Image(systemName: "gift.fill")
                        Text("Premi")
                    }
                    .tag(2)

                // Community - Limited access
                ReadOnlyCommunityView()
                    .tabItem {
                        SwiftUI.Image(systemName: "person.2")
                        Text("Community")
                    }
                    .tag(3)
            }

            // Login prompt overlay
            if showLoginPrompt {
                LoginPromptView(isPresented: $showLoginPrompt)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Guest mode indicator - Minimal style
            HStack(spacing: 6) {
                SwiftUI.Image(systemName: "eye.fill")
                    .font(.system(size: 11))
                Text("OSPITE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.secondarySystemBackground))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
            .padding(.top, 50)
            .padding(.trailing, 16)
        }
    }
}

// MARK: - ReadOnly Collection View
struct ReadOnlyCollectionView: View {
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    @EnvironmentObject var marketService: MarketDataService
    @EnvironmentObject var authService: AuthService
    @StateObject private var expansionService = ExpansionService()
    @State private var showLoginPrompt = false
    @State private var selectedExpansion: Expansion?
    @State private var showAllExpansions = false
    @State private var selectedTCGFilter: TCGType? = nil
    
    // Computed properties for filtered expansions
    private var filteredExpansions: [Expansion] {
        var expansions = expansionService.expansions
        if let tcgFilter = selectedTCGFilter {
            expansions = expansions.filter { $0.tcgType == tcgFilter }
        }
        return expansions
    }
    
    private var displayedExpansions: [Expansion] {
        if showAllExpansions {
            return filteredExpansions
        } else {
            return Array(filteredExpansions.prefix(5))
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // MARK: - Header Section (Home Style)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("TCG ARENA")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(2)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Benvenuto,")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(.primary)
                            Text("scopri il mondo TCG")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // MARK: - CTA Card (Minimal Home Style)
                    Button(action: { showLoginPrompt = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 56, height: 56)
                                SwiftUI.Image(systemName: "person.badge.plus")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Accedi per Iniziare")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Crea collezioni, mazzi e partecipa ai tornei")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            SwiftUI.Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(20)
                        .background(Color.black)
                        .cornerRadius(24)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 24)
                    
                    // MARK: - Features Grid (Home Style Stats)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Funzionalità")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            FeatureTile(icon: "rectangle.stack.fill.badge.plus", title: "Collezione", subtitle: "Organizza carte")
                            FeatureTile(icon: "gamecontroller.fill", title: "Mazzi", subtitle: "Costruisci strategie")
                            FeatureTile(icon: "trophy.fill", title: "Tornei", subtitle: "Gareggia")
                            FeatureTile(icon: "person.2.fill", title: "Community", subtitle: "Connettiti")
                        }
                        .padding(.horizontal, 24)
                    }

                    // MARK: - Expansions List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Esplora Serie")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        // TCG Filters (Minimal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                FilterPill(title: "Tutte", isSelected: selectedTCGFilter == nil) {
                                    selectedTCGFilter = nil
                                }
                                
                                ForEach(TCGType.allCases, id: \.self) { tcgType in
                                    FilterPill(
                                        title: tcgType.displayName,
                                        isSelected: selectedTCGFilter == tcgType,
                                        accentColor: tcgType.themeColor
                                    ) {
                                        selectedTCGFilter = tcgType
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        if expansionService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 40)
                                Spacer()
                            }
                        } else if filteredExpansions.isEmpty {
                            VStack(spacing: 12) {
                                SwiftUI.Image(systemName: "square.stack.3d.up.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(.tertiaryLabel))
                                Text(selectedTCGFilter != nil ? "Nessuna espansione per questo TCG" : "Nessuna espansione")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(displayedExpansions) { expansion in
                                    Button(action: {
                                        selectedExpansion = expansion
                                    }) {
                                        PublicExpansionCard(expansion: expansion)
                                    }
                                }
                                
                                // Show more/less button
                                if filteredExpansions.count > 5 {
                                    Button(action: {
                                        showAllExpansions.toggle()
                                    }) {
                                        HStack {
                                            Text(showAllExpansions ? "Mostra Meno" : "Vedi Tutte (\(filteredExpansions.count))")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Spacer()
                                            SwiftUI.Image(systemName: showAllExpansions ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 20)
                                        .background(Color(.secondarySystemBackground))
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLoginPrompt) {
            ModernAuthView(
                onSkip: {
                    showLoginPrompt = false
                },
                onSuccess: {
                    showLoginPrompt = false
                }
            )
            .environmentObject(authService)
        }
        .sheet(item: $selectedExpansion) { expansion in
            ExpansionDetailView(expansion: expansion)
                .environmentObject(marketService)
        }
        .task {
            await expansionService.loadExpansions()
        }
    }
}

// MARK: - Feature Tile (Home Style)
struct FeatureTile: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.primary.opacity(0.7))
                .padding(.bottom, 16)
            
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
    }
}

// MARK: - Filter Pill (Minimal)
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var accentColor: Color = .primary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? accentColor : Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(.separator).opacity(isSelected ? 0 : 0.5), lineWidth: 0.5)
                )
        }
    }
}

// MARK: - Public Expansion Card (Minimal)
struct PublicExpansionCard: View {
    let expansion: Expansion
    
    var body: some View {
        HStack(spacing: 16) {
            // Expansion Image
            AsyncImage(url: URL(string: expansion.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        SwiftUI.Image(systemName: expansion.tcgType.icon)
                            .font(.system(size: 24))
                            .foregroundColor(expansion.tcgType.themeColor.opacity(0.6))
                    )
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Expansion Info
            VStack(alignment: .leading, spacing: 6) {
                Text(expansion.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(expansion.tcgType.themeColor)
                        .frame(width: 6, height: 6)
                    
                    Text(expansion.tcgType.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Text("\(expansion.sets.count) set • \(expansion.cardCount) carte")
                    .font(.system(size: 12))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            Spacer()
            
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
    }
}

// MARK: - ReadOnly Rewards View (Minimal)
struct ReadOnlyRewardsView: View {
    @State private var showLoginPrompt = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header (Home Style)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PREMI")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(2)
                        
                        Text("Guadagna Punti,\nSblocca Premi")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // CTA Card (Minimal)
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color(.tertiarySystemBackground))
                                .frame(width: 80, height: 80)
                            SwiftUI.Image(systemName: "gift.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.primary)
                        }

                        VStack(spacing: 8) {
                            Text("Sblocca il Sistema Premi")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Completa sfide, guadagna punti e ottieni ricompense esclusive")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: { showLoginPrompt = true }) {
                            Text("Accedi per Iniziare")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.black)
                                .cornerRadius(26)
                        }
                    }
                    .padding(24)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 50)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginView()
        }
    }
}

// MARK: - ReadOnly Community View (Minimal)
struct ReadOnlyCommunityView: View {
    @State private var showLoginPrompt = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header (Home Style)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("COMMUNITY")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(2)
                        
                        Text("Connettiti con\nAltri Collezionisti")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // CTA Card (Minimal)
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color(.tertiarySystemBackground))
                                .frame(width: 80, height: 80)
                            SwiftUI.Image(systemName: "person.2.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.primary)
                        }

                        VStack(spacing: 8) {
                            Text("Unisciti alla Community")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Segui giocatori, condividi mazzi e partecipa agli eventi")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Button(action: { showLoginPrompt = true }) {
                            Text("Accedi per Connetterti")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.black)
                                .cornerRadius(26)
                        }
                    }
                    .padding(24)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 50)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginView()
        }
    }
}

// MARK: - Login Prompt View (Minimal)
struct LoginPromptView: View {
    @Binding var isPresented: Bool
    @State private var showLogin = false
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 72, height: 72)
                    SwiftUI.Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.primary)
                }
                
                // Text
                VStack(spacing: 8) {
                    Text("Accedi per Continuare")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Crea collezioni, partecipa a tornei e connettiti con la community")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                        showRegister = true
                    }) {
                        Text("Crea Account")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.black)
                            .cornerRadius(26)
                    }

                    Button(action: {
                        isPresented = false
                        showLogin = true
                    }) {
                        Text("Accedi")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(26)
                            .overlay(
                                RoundedRectangle(cornerRadius: 26)
                                    .stroke(Color(.separator), lineWidth: 1)
                            )
                    }
                }

                Button(action: {
                    isPresented = false
                }) {
                    Text("Continua come Ospite")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(32)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .padding(.horizontal, 32)
        }
        .fullScreenCover(isPresented: $showLogin) {
            AuthFlowView(startWithLogin: true)
        }
        .fullScreenCover(isPresented: $showRegister) {
            AuthFlowView(startWithLogin: false)
        }
    }
}
