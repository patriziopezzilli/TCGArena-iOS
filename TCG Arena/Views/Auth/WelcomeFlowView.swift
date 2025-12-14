//
//  WelcomeFlowView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI
import WelcomeSheet

// MARK: - Onboarding Step Enum
enum OnboardingFlowStep {
    case welcome
    case notifications
    case location
    case auth
}

struct WelcomeFlowView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: OnboardingFlowStep = .welcome
    @State private var showWelcomeSheet = false
    @State private var continueAsGuest = false
    @State private var isViewReady = false
    
    // MARK: - Welcome Sheet Pages
    private let welcomePages = [
        WelcomeSheetPage(
            title: "Welcome to TCG Arena",
            rows: [
                WelcomeSheetPageRow(
                    imageSystemName: "rectangle.stack.fill",
                    accentColor: .orange,
                    title: "Build Your Collection",
                    content: "Track your cards from Pokémon, Magic, Yu-Gi-Oh!, One Piece and more."
                ),
                WelcomeSheetPageRow(
                    imageSystemName: "square.stack.3d.up.fill",
                    accentColor: .purple,
                    title: "Create Powerful Decks",
                    content: "Build and share competitive decks with the community."
                ),
                WelcomeSheetPageRow(
                    imageSystemName: "trophy.fill",
                    accentColor: .yellow,
                    title: "Join Tournaments",
                    content: "Find local events and compete with players near you."
                ),
                WelcomeSheetPageRow(
                    imageSystemName: "storefront.fill",
                    accentColor: .blue,
                    title: "Discover Local Shops",
                    content: "Find TCG stores, check their inventory and get updates."
                )
            ],
            accentColor: .orange,
            mainButtonTitle: "Get Started"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Current step view
            Group {
                switch currentStep {
                case .welcome:
                    welcomeBackgroundView
                case .notifications:
                    notificationsView
                case .location:
                    locationView
                case .auth:
                    authView
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
        .welcomeSheet(
            isPresented: $showWelcomeSheet,
            onDismiss: {
                goToNextStep()
            },
            isSlideToDismissDisabled: true,
            pages: welcomePages
        )
        .onAppear {
            // Delay showing the welcome sheet to ensure view hierarchy is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if currentStep == .welcome {
                    showWelcomeSheet = true
                }
            }
        }
        .onChange(of: continueAsGuest) { newValue in
            if newValue {
                dismiss()
            }
        }
    }
    
    // MARK: - Welcome Background View
    private var welcomeBackgroundView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                SwiftUI.Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 12) {
                Text("TCG Arena")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Your TCG Companion")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !showWelcomeSheet {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(.bottom, 60)
            }
        }
    }
    
    // MARK: - Notifications Permission View
    private var notificationsView: some View {
        OnboardingPermissionsView(
            step: .notifications,
            onContinue: {
                goToNextStep()
            },
            onSkip: {
                goToNextStep()
            }
        )
    }
    
    // MARK: - Location Permission View
    private var locationView: some View {
        OnboardingPermissionsView(
            step: .location,
            onContinue: {
                goToNextStep()
            },
            onSkip: {
                goToNextStep()
            }
        )
    }
    
    // MARK: - Auth View
    private var authView: some View {
        ModernAuthView(
            onSkip: {
                continueAsGuest = true
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            },
            onSuccess: {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        )
        .environmentObject(authService)
    }
    
    // MARK: - Navigation
    private func goToNextStep() {
        withAnimation(.easeInOut(duration: 0.35)) {
            switch currentStep {
            case .welcome:
                currentStep = .notifications
            case .notifications:
                currentStep = .location
            case .location:
                currentStep = .auth
            case .auth:
                break
            }
        }
    }
}

#Preview {
    WelcomeFlowView()
        .environmentObject(AuthService())
}
