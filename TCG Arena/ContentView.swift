//
//  ContentView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import CoreLocation

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
    @StateObject private var inventoryService = InventoryService()
    @StateObject private var reservationService = ReservationService()
    @StateObject private var marketService = MarketDataService()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var requestService = RequestService()
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var authService: AuthService
    
    // Location update throttling
    @State private var lastLocationUpdate: Date? = nil
    
    var body: some View {
            TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    SwiftUI.Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            CollectionView()
                .environmentObject(cardService)
                .environmentObject(deckService)
                .environmentObject(marketService)
                .environmentObject(authService)
                .tabItem {
                    SwiftUI.Image(systemName: "rectangle.stack")
                    Text("Carte")
                }
                .tag(1)
            
            ShopView()
                .environmentObject(shopService)
                .environmentObject(tournamentService)
                .environmentObject(inventoryService)
                .environmentObject(reservationService)
                .environmentObject(authService)
                .environmentObject(locationManager)
                .tabItem {
                    SwiftUI.Image(systemName: "storefront")
                    Text("Negozi")
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
            
            MoreView()
                .environmentObject(authService)
                .environmentObject(rewardsService)
                .environmentObject(reservationService)
                .environmentObject(requestService)
                .environmentObject(settingsService)
                .tabItem {
                    SwiftUI.Image(systemName: "line.3.horizontal")
                    Text("Altro")
                }
                .tag(4)
        }
        .accentColor(AdaptiveColors.brandPrimary)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.2),
            value: settingsService.isDarkMode
        )
        .padding(.top, 8) // Add spacing for modern look
        .onAppear {
            // Check permissions on start
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                // This usually triggers startUpdatingLocation in LocationManager delegate
            } else {
                // If not determined, we don't ask here to avoid annoying user if they skipped onboarding
                // Check if we should ask? No, keep it non-intrusive.
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            guard let location = newLocation, 
                  let currentUserId = authService.currentUserId else { return }
            
            // Update backend max once every 15 minutes
            let now = Date()
            if let lastUpdate = lastLocationUpdate, now.timeIntervalSince(lastUpdate) < 900 {
                return
            }
            
            // Perform update
            Task {
                print("📍 Detected significant location change, updating backend...")
                // Reverse geocode
                var city: String?
                var country: String?
                
                let geocoder = CLGeocoder()
                if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
                   let placemark = placemarks.first {
                    city = placemark.locality
                    country = placemark.country
                }
                
                if let updatedUser = try? await UserService.shared.updateUserLocation(
                    userId: Int64(currentUserId),
                    city: city,
                    country: country,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                ) {
                    await MainActor.run {
                        authService.currentUser = updatedUser
                    }
                }
                
                lastLocationUpdate = now
                print("📍 Backend location updated successfully")
            }
        }
    }
}

#Preview {
    ContentView()
}
