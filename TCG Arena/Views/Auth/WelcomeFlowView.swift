//
//  WelcomeFlowView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI
import OnBoardingKit

struct WelcomeFlowView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var showOnBoarding = true
    @State private var showAuth = false
    @State private var continueAsGuest = false
    
    var body: some View {
        ZStack {
            if showOnBoarding {
                OnBoardingView(TCGArenaOnBoarding()) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnBoarding = false
                        showAuth = true
                    }
                }
                .tint(Color.blue)
                .transition(.opacity)
            } else if showAuth {
                ModernAuthView(onSkip: {
                    continueAsGuest = true
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }, onSuccess: {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                })
                .environmentObject(authService)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showOnBoarding)
        .animation(.easeInOut(duration: 0.3), value: showAuth)
    }
}
