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
            if authService.isAuthenticated {
                // User is authenticated - full access
                ContentView()
                    .environmentObject(authService)
            } else {
                // User is not authenticated - readonly mode
                ReadOnlyContentView()
            }
        }
    }
}