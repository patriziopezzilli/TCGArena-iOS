//
//  OnboardingPermissionsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/5/25.
//

import SwiftUI
import CoreLocation
import UserNotifications

// MARK: - Permission Step Enum
enum PermissionStep {
    case notifications
    case location
}

// MARK: - Onboarding Permissions View
struct OnboardingPermissionsView: View {
    let step: PermissionStep
    let onContinue: () -> Void
    let onSkip: () -> Void
    
    @StateObject private var locationManager = LocationManager()
    @State private var isRequestingPermission = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    backgroundColor.opacity(0.15),
                    Color(.systemBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(backgroundColor.opacity(0.15))
                        .frame(width: 140, height: 140)
                    
                    Circle()
                        .fill(backgroundColor.opacity(0.25))
                        .frame(width: 100, height: 100)
                    
                    SwiftUI.Image(systemName: iconName)
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(backgroundColor)
                }
                .padding(.bottom, 40)
                
                // Title
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Description
                Text(description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                
                Spacer()
                
                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(features, id: \.title) { feature in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(backgroundColor.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                SwiftUI.Image(systemName: feature.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(backgroundColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text(feature.description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    // Primary button
                    Button(action: requestPermission) {
                        HStack(spacing: 10) {
                            if isRequestingPermission {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                SwiftUI.Image(systemName: buttonIcon)
                                    .font(.system(size: 18, weight: .semibold))
                                Text(buttonTitle)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [backgroundColor, backgroundColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isRequestingPermission)
                    
                    // Skip button
                    Button(action: onSkip) {
                        Text(skipButtonTitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var iconName: String {
        switch step {
        case .notifications:
            return "bell.badge.fill"
        case .location:
            return "location.fill"
        }
    }
    
    private var title: String {
        switch step {
        case .notifications:
            return "Stay Updated"
        case .location:
            return "Find Nearby Events"
        }
    }
    
    private var description: String {
        switch step {
        case .notifications:
            return "Get notified about tournaments, reservations, and special offers from your favorite shops."
        case .location:
            return "Discover tournaments, shops, and players near you for the best TCG experience."
        }
    }
    
    private var backgroundColor: Color {
        switch step {
        case .notifications:
            return Color.orange
        case .location:
            return Color.blue
        }
    }
    
    private var buttonTitle: String {
        switch step {
        case .notifications:
            return "Enable Notifications"
        case .location:
            return "Share Location"
        }
    }
    
    private var buttonIcon: String {
        switch step {
        case .notifications:
            return "bell.fill"
        case .location:
            return "location.fill"
        }
    }
    
    private var skipButtonTitle: String {
        switch step {
        case .notifications:
            return "Maybe Later"
        case .location:
            return "Skip for Now"
        }
    }
    
    private var features: [PermissionFeature] {
        switch step {
        case .notifications:
            return [
                PermissionFeature(
                    icon: "trophy.fill",
                    title: "Tournament Updates",
                    description: "Know when registration opens or events start"
                ),
                PermissionFeature(
                    icon: "qrcode",
                    title: "Reservation Alerts",
                    description: "Get reminded about your card reservations"
                ),
                PermissionFeature(
                    icon: "tag.fill",
                    title: "Special Offers",
                    description: "Exclusive deals from shops you follow"
                )
            ]
        case .location:
            return [
                PermissionFeature(
                    icon: "map.fill",
                    title: "Nearby Shops",
                    description: "Discover TCG stores close to you"
                ),
                PermissionFeature(
                    icon: "calendar",
                    title: "Local Tournaments",
                    description: "Find events happening in your area"
                ),
                PermissionFeature(
                    icon: "person.2.fill",
                    title: "Player Community",
                    description: "Connect with players nearby"
                )
            ]
        }
    }
    
    // MARK: - Actions
    
    private func requestPermission() {
        isRequestingPermission = true
        
        switch step {
        case .notifications:
            requestNotificationPermission()
        case .location:
            requestLocationPermission()
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                isRequestingPermission = false
                // Continue regardless of permission result
                onContinue()
            }
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestLocationPermission()
        
        // Give time for the permission dialog
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isRequestingPermission = false
            onContinue()
        }
    }
}

// MARK: - Permission Feature Model
struct PermissionFeature {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview
#Preview {
    OnboardingPermissionsView(
        step: .notifications,
        onContinue: {},
        onSkip: {}
    )
}
