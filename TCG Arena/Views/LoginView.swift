//
//  LoginView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/19/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authService: AuthService
    @State private var username: String
    @State private var password = ""
    @State private var showForgotPassword = false
    @State private var showRegister = false
    @State private var isLoading = false

    init(username: String = "") {
        _username = State(initialValue: username)
    }

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
                            Circle()
                                .fill(AdaptiveColors.brandSecondary.opacity(0.1))
                                .frame(width: 60, height: 60)
                            SwiftUI.Image(systemName: "person.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AdaptiveColors.brandPrimary)
                        }

                        VStack(spacing: 8) {
                            Text("Welcome Back")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AdaptiveColors.brandPrimary)

                            Text("Sign in to continue")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(AdaptiveColors.neutralDark)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 60)

                    // Main login card
                    VStack(spacing: 24) {
                        // Form Fields Card
                        VStack(spacing: 20) {
                            // Username field with icon
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    SwiftUI.Image(systemName: "person.circle")
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                        .frame(width: 20, height: 20)
                                    Text("Username")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                }

                                TextField("Enter your username", text: $username)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.9))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(AdaptiveColors.neutralLight, lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                                    .foregroundColor(AdaptiveColors.neutralDark)
                                    .font(.system(size: 16))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }

                            // Password field with icon
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    SwiftUI.Image(systemName: "lock")
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                        .frame(width: 20, height: 20)
                                    Text("Password")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                }

                                SecureField("Enter your password", text: $password)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.9))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(AdaptiveColors.neutralLight, lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                    )
                                    .foregroundColor(AdaptiveColors.neutralDark)
                                    .font(.system(size: 16))
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )

                        // Forgot password link
                        HStack {
                            Spacer()
                            Button(action: {
                                showForgotPassword = true
                            }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AdaptiveColors.brandPrimary)
                                    .underline()
                            }
                        }

                        // Login Button with enhanced styling
                        Button(action: login) {
                            if isLoading {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Signing In...")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text("Sign In")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    SwiftUI.Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [AdaptiveColors.brandPrimary, AdaptiveColors.brandPrimary.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: AdaptiveColors.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                        .disabled(isLoading || username.isEmpty || password.isEmpty)
                        .opacity(isLoading || username.isEmpty || password.isEmpty ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)

                    // Register section
                    VStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(AdaptiveColors.neutralDark.opacity(0.8))

                            Button(action: {
                                showRegister = true
                            }) {
                                Text("Sign Up")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(AdaptiveColors.brandPrimary)
                            }
                        }
                    }

                    Spacer(minLength: 60)
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(email: username)
        }
    }

    // MARK: - Subviews

    private func login() {
        guard !username.isEmpty, !password.isEmpty else { return }

        isLoading = true

        Task {
            await authService.signIn(email: username, password: password)
            if authService.isAuthenticated {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                dismiss()
            } else if let error = authService.errorMessage {
                ToastManager.shared.showError(error)
            }
            isLoading = false
        }
    }
}
