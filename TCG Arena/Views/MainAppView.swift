//
//  MainAppView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/19/25.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var settingsService: SettingsService
    
    var body: some View {
        Group {
            if authService.isAuthenticated && authService.currentUserId != nil {
                // User is authenticated and has valid user ID - full access
                ContentView()
                    .environmentObject(authService)
            } else {
                // User is not authenticated or missing user data - readonly mode
                // Debug: Force logout to ensure clean state
                ReadOnlyContentView()
                    .onAppear {
                        // Force logout on appear to ensure clean guest mode
                        authService.forceLogout()
                    }
            }
        }
        .withToastSupport() // Enable toast notifications throughout the app
    }
}