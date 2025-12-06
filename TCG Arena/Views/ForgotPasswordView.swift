//
//  ForgotPasswordView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/19/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var isLoading = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    AdaptiveColors.brandPrimary.opacity(0.1),
                    AdaptiveColors.brandSecondary.opacity(0.05),
                    AdaptiveColors.background
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header with decorative elements
                    VStack(spacing: 16) {
                        // Decorative circles
                        ZStack {
                            Circle()
                                .fill(AdaptiveColors.brandPrimary.opacity(0.1))
                                .frame(width: 80, height: 80)
                                .offset(x: -60, y: -40)

                            Circle()
                                .fill(AdaptiveColors.brandSecondary.opacity(0.1))
                                .frame(width: 60, height: 60)
                                .offset(x: 40, y: 30)

                            // Main icon
                            ZStack {
                                Circle()
                                    .fill(AdaptiveColors.brandPrimary.opacity(0.1))
                                    .frame(width: 120, height: 120)

                                SwiftUI.Image(systemName: "envelope.fill")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundColor(AdaptiveColors.brandPrimary)
                            }
                        }

                        VStack(spacing: 8) {
                            Text("Reset Password")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AdaptiveColors.brandPrimary)

                            Text("Enter your email to receive reset instructions")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(AdaptiveColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Email form in card
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        SwiftUI.Image(systemName: "envelope")
                                            .foregroundColor(AdaptiveColors.brandPrimary)
                                            .frame(width: 20, height: 20)

                                        Text("Email")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AdaptiveColors.textSecondary)
                                    }
                                TextField("Enter your email", text: $email)
                                    .font(.system(size: 16))
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(AdaptiveColors.backgroundSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AdaptiveColors.brandPrimary.opacity(0.3), lineWidth: 1)
                                    )
                                    .foregroundColor(AdaptiveColors.neutralDark)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(AdaptiveColors.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)

                        // Reset button
                        Button(action: resetPassword) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Send Reset Link")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [AdaptiveColors.brandPrimary, AdaptiveColors.brandSecondary]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .shadow(color: AdaptiveColors.brandPrimary.opacity(0.3), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 24)
                        .disabled(isLoading || email.isEmpty)
                        .opacity((isLoading || email.isEmpty) ? 0.6 : 1.0)
                    }

                    Spacer()
                }
                .padding(.vertical, 40)
            }
        }
    }

    private func resetPassword() {
        guard !email.isEmpty else { return }

        isLoading = true

        Task {
            do {
                try await authService.resetPassword(email: email)
                ToastManager.shared.showSuccess("Check your email for password reset instructions")
                dismiss()
            } catch {
                ToastManager.shared.showError(error.localizedDescription)
            }
            isLoading = false
        }
    }
}
