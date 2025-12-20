//
//  TCGArenaApp.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure notifications
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        
        // Send token to server
        Task {
            await AuthService.shared.registerDeviceTokenOnServer(token)
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Handle error silently
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        completionHandler()
    }
}

@main
struct TCGArenaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var settingsService = SettingsService()
    @StateObject private var authService = AuthService()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // Shop/Merchant Services
    @StateObject private var inventoryService = InventoryService()
    @StateObject private var reservationService = ReservationService()
    @StateObject private var requestService = RequestService()
    
    init() {
        // Hide scroll indicators globally throughout the app
        UIScrollView.appearance().showsVerticalScrollIndicator = false
        UIScrollView.appearance().showsHorizontalScrollIndicator = false
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding() {
                    // User has completed onboarding - show main app
                    MainAppView()
                        .environmentObject(settingsService)
                        .environmentObject(authService)
                        .environmentObject(inventoryService)
                        .environmentObject(reservationService)
                        .environmentObject(requestService)
                        .environmentObject(networkMonitor)
                        .preferredColorScheme(settingsService.isDarkMode ? .dark : .light)
                } else {
                    // First time user - show welcome/onboarding
                    // First time user - show welcome/onboarding
                    WelcomeFlowView()
                        .environmentObject(settingsService)
                        .environmentObject(authService)
                        .environmentObject(networkMonitor)
                        .preferredColorScheme(settingsService.isDarkMode ? .dark : .light)
                }
                
                // Overlay NoNetworkView when offline (blocks all navigation)
                if !networkMonitor.isConnected {
                    NoNetworkView()
                        .environmentObject(networkMonitor)
                        .transition(.opacity)
                        .zIndex(1000) // Ensure it's always on top
                }
            }
            .animation(.easeInOut(duration: 0.3), value: networkMonitor.isConnected)
        }
    }
    
    private func hasCompletedOnboarding() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
}

