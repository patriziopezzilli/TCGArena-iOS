//
//  OnboardingPermissionsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI
import CoreLocation

enum OnboardingPermissionType {
    case location
    case notifications
}

struct OnboardingPermissionsView: View {
    let type: OnboardingPermissionType
    var onContinue: () -> Void
    var onSkip: () -> Void
    
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 32) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 80, height: 80)
                    
                    SwiftUI.Image(systemName: iconName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                
                // Text
                VStack(alignment: .leading, spacing: 12) {
                    Text(title)
                        .font(.system(size: 40, weight: .heavy))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(description)
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateContent)
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        requestPermission()
                    }) {
                        Text("Consenti")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(.systemBackground))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(28)
                    }
                    
                    Button(action: onSkip) {
                        Text("Più tardi")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateContent)
                .padding(.bottom, 24)
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    private var iconName: String {
        switch type {
        case .location: return "location.fill"
        case .notifications: return "bell.fill"
        }
    }
    
    private var title: String {
        switch type {
        case .location: return "Trova negozi\nvicino a te"
        case .notifications: return "Non perdere\ni tornei"
        }
    }
    
    private var description: String {
        switch type {
        case .location: return "Ci serve la tua posizione per mostrarti eventi e negozi nella tua zona."
        case .notifications: return "Ricevi aggiornamenti su iscrizioni, risultati e promozioni esclusive."
        }
    }
    
    private func requestPermission() {
        switch type {
        case .location:
            let locationManager = CLLocationManager()
            locationManager.requestWhenInUseAuthorization()
            // In a real flow we'd delegate checking status, but for onboarding speed we continue
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onContinue()
            }
            
        case .notifications:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async {
                    onContinue()
                }
            }
        }
    }
}

#Preview {
    OnboardingPermissionsView(type: .location, onContinue: {}, onSkip: {})
}
