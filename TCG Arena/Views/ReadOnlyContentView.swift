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
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Collection - Limited access
                ReadOnlyCollectionView()
                    .environmentObject(cardService)
                    .environmentObject(deckService)
                    .tabItem {
                        SwiftUI.Image(systemName: "rectangle.stack")
                        Text("Decks")
                    }
                    .tag(0)

                // Shop - Full access (browsing)
                ShopView()
                    .environmentObject(shopService)
                    .environmentObject(tournamentService)
                    .environmentObject(inventoryService)
                    .environmentObject(authService)
                    .tabItem {
                        SwiftUI.Image(systemName: "storefront")
                        Text("Stores")
                    }
                    .tag(1)

                // Rewards - Limited access
                ReadOnlyRewardsView()
                    .tabItem {
                        SwiftUI.Image(systemName: "gift.fill")
                        Text("Rewards")
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
        .overlay(
            // Guest mode indicator
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        SwiftUI.Image(systemName: "eye.fill")
                            .font(.system(size: 12))
                        Text("GUEST MODE")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemBackground).opacity(0.8))
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                Spacer()
            }
            .padding(.top, 50)
            .padding(.trailing, 16)
        )
    }
}

// MARK: - ReadOnly Collection View
struct ReadOnlyCollectionView: View {
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    @StateObject private var expansionService = ExpansionService()
    @State private var showLoginPrompt = false
    @State private var selectedExpansion: Expansion?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("TCG Collection")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Browse expansions and discover cards")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Login prompt card
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "lock.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.orange)

                        Text("Sign in to create your own collection")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text("Track your cards and build custom decks")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            showLoginPrompt = true
                        }) {
                            Text("Sign In to Unlock")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                    }
                    .padding(24)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // Expansions List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Browse Expansions")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 20)

                        if expansionService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 40)
                                Spacer()
                            }
                        } else if expansionService.expansions.isEmpty {
                            VStack(spacing: 12) {
                                SwiftUI.Image(systemName: "square.stack.3d.up.slash")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No expansions available")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(expansionService.expansions) { expansion in
                                    Button(action: {
                                        selectedExpansion = expansion
                                    }) {
                                        PublicExpansionCard(expansion: expansion)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLoginPrompt) {
            WelcomeFlowView()
        }
        .sheet(item: $selectedExpansion) { expansion in
            ExpansionDetailView(expansion: expansion)
        }
    }
}

// MARK: - Public Expansion Card
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
                    .fill(expansion.tcgType.themeColor.opacity(0.2))
                    .overlay(
                        SwiftUI.Image(systemName: expansion.tcgType.icon)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(expansion.tcgType.themeColor)
                    )
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Expansion Info
            VStack(alignment: .leading, spacing: 6) {
                Text(expansion.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(expansion.tcgType.themeColor)
                        .frame(width: 8, height: 8)
                    
                    Text(expansion.tcgType.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(expansion.tcgType.themeColor)
                }
                
                HStack(spacing: 12) {
                    Label("\(expansion.sets.count) sets", systemImage: "square.stack.3d.up.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Label("\(expansion.cardCount) cards", systemImage: "rectangle.stack")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - ReadOnly Rewards View
struct ReadOnlyRewardsView: View {
    @State private var showLoginPrompt = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Rewards")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Earn points and unlock rewards")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Login prompt
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "gift.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.purple)

                        Text("Create an account to earn rewards")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text("Complete challenges, earn points, and unlock exclusive content")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            showLoginPrompt = true
                        }) {
                            Text("Sign In to Earn Rewards")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                    }
                    .padding(24)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginView()
        }
    }
}

// MARK: - ReadOnly Community View
struct ReadOnlyCommunityView: View {
    @State private var showLoginPrompt = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Community")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Connect with fellow collectors")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Login prompt
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "person.2.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.blue)

                        Text("Join the TCG Arena community")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                        Text("Follow players, share decks, and participate in tournaments")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        Button(action: {
                            showLoginPrompt = true
                        }) {
                            Text("Sign In to Connect")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 25))
                        }
                    }
                    .padding(24)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showLoginPrompt) {
            LoginView()
        }
    }
}

// MARK: - Login Prompt View
struct LoginPromptView: View {
    @Binding var isPresented: Bool
    @State private var showLogin = false
    @State private var showRegister = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "person.circle.fill")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.blue)

                    Text("Sign in to unlock this feature")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text("Create collections, join tournaments, and connect with the community")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                        showRegister = true
                    }) {
                        Text("Create Account")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                    }

                    Button(action: {
                        isPresented = false
                        showLogin = true
                    }) {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(.systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                }
                .padding(.horizontal, 32)

                Button(action: {
                    isPresented = false
                }) {
                    Text("Continue as Guest")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 32)
        }
        .fullScreenCover(isPresented: $showLogin) {
            WelcomeFlowView()
        }
        .fullScreenCover(isPresented: $showRegister) {
            WelcomeFlowView()
        }
    }
}