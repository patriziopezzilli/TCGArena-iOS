//
//  ContentView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var cardService = CardService()
    @StateObject private var shopService = ShopService()
    @StateObject private var tournamentService = TournamentService()
    @StateObject private var deckService = DeckService()
    @StateObject private var rewardsService = RewardsService()
    @StateObject private var notificationService = NotificationService()
    @StateObject private var achievementService = AchievementService()
    @StateObject private var imageService = ImageService()
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var authService: AuthService
    
    var body: some View {
        TabView(selection: $selectedTab) {
            CollectionView()
                .environmentObject(cardService)
                .environmentObject(deckService)
                .environmentObject(authService)
                .tabItem {
                    SwiftUI.Image(systemName: "rectangle.stack")
                    Text("Cards")
                }
                .tag(0)
            
            ShopView()
                .environmentObject(shopService)
                .environmentObject(tournamentService)
                .tabItem {
                    SwiftUI.Image(systemName: "storefront")
                    Text("Stores")
                }
                .tag(1)
            
            RewardsMainView()
                .environmentObject(rewardsService)
                .tabItem {
                    SwiftUI.Image(systemName: "gift.fill")
                    Text("Rewards")
                }
                .tag(2)
            
            CommunityView()
                .environmentObject(notificationService)
                .environmentObject(achievementService)
                .tabItem {
                    SwiftUI.Image(systemName: "person.2")
                    Text("Community")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    SwiftUI.Image(systemName: "person.crop.circle")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(AdaptiveColors.brandPrimary)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2),
            value: settingsService.isDarkMode
        )
        .padding(.top, 8) // Add spacing for modern look
    }
}

#Preview {
    ContentView()
}
