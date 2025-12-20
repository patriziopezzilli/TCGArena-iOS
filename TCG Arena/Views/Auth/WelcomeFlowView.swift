//
//  WelcomeFlowView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

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
    @State private var continueAsGuest = false
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Current step view
            Group {
                switch currentStep {
                case .welcome:
                    WelcomeView(onStart: goToNextStep)
                        .transition(.opacity)
                case .notifications:
                    OnboardingPermissionsView(
                        type: .notifications,
                        onContinue: goToNextStep,
                        onSkip: goToNextStep
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                case .location:
                    OnboardingPermissionsView(
                        type: .location,
                        onContinue: goToNextStep,
                        onSkip: goToNextStep
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                case .auth:
                    authView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
        .onChange(of: continueAsGuest) { newValue in
            if newValue {
                dismiss()
            }
        }
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

