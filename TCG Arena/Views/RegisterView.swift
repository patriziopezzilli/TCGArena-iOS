//
//  RegisterView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/19/25.
//

import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService()
    @State private var email: String
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var agreedToTerms = false
    @State private var selectedTCGs: Set<TCGType> = []

    init(email: String = "", selectedTCG: TCGType? = nil) {
        _email = State(initialValue: email)
        if let tcg = selectedTCG {
            _selectedTCGs = State(initialValue: [tcg])
        }
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
                            SwiftUI.Image(systemName: "person.badge.plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AdaptiveColors.brandPrimary)
                        }

                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AdaptiveColors.brandPrimary)

                        Text("Join the TCG community and start your collection")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(AdaptiveColors.neutralDark)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 60)

                    // Main registration card
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
                            }

                            // Email field with icon
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    SwiftUI.Image(systemName: "envelope")
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                        .frame(width: 20, height: 20)
                                    Text("Email")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                }

                                TextField("Enter your email", text: $email)
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
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
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

                                SecureField("Create a password", text: $password)
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

                            // Confirm Password field with icon
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    SwiftUI.Image(systemName: "lock.shield")
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                        .frame(width: 20, height: 20)
                                    Text("Confirm Password")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                }

                                SecureField("Confirm your password", text: $confirmPassword)
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

                            // TCG Selection with icon - Multiple selection
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    SwiftUI.Image(systemName: "gamecontroller")
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                        .frame(width: 20, height: 20)
                                    Text("Favorite TCGs")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(AdaptiveColors.brandPrimary)
                                    
                                    if !selectedTCGs.isEmpty {
                                        Text("(\(selectedTCGs.count) selected)")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(AdaptiveColors.neutralDark.opacity(0.6))
                                    }
                                }

                                VStack(spacing: 12) {
                                    ForEach(TCGType.allCases, id: \.self) { tcg in
                                        Button(action: {
                                            if selectedTCGs.contains(tcg) {
                                                selectedTCGs.remove(tcg)
                                            } else {
                                                selectedTCGs.insert(tcg)
                                            }
                                        }) {
                                            HStack {
                                                // Checkbox
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .stroke(selectedTCGs.contains(tcg) ? AdaptiveColors.brandPrimary : AdaptiveColors.neutralLight, lineWidth: 2)
                                                        .frame(width: 24, height: 24)
                                                    
                                                    if selectedTCGs.contains(tcg) {
                                                        RoundedRectangle(cornerRadius: 6)
                                                            .fill(AdaptiveColors.brandPrimary)
                                                            .frame(width: 24, height: 24)
                                                        
                                                        SwiftUI.Image(systemName: "checkmark")
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(.white)
                                                    }
                                                }
                                                
                                                Text(tcg.rawValue.capitalized)
                                                    .font(.system(size: 16))
                                                    .foregroundColor(AdaptiveColors.neutralDark)
                                                
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(selectedTCGs.contains(tcg) ? AdaptiveColors.brandPrimary.opacity(0.05) : Color.white.opacity(0.9))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(selectedTCGs.contains(tcg) ? AdaptiveColors.brandPrimary : AdaptiveColors.neutralLight, lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.95))
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )

                        // Sign Up Button with enhanced styling
                        Button(action: register) {
                            if isLoading {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Creating Account...")
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text("Create Account")
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
                        .disabled(isLoading || !isFormValid)
                        .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)

                    // Terms and login section
                    VStack(spacing: 24) {
                        termsView
                        loginPromptView
                    }

                    Spacer(minLength: 60)
                }
            }
        }
        .alert("Registration Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Subviews

    private var termsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                Button(action: {
                    agreedToTerms.toggle()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 28, height: 28)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AdaptiveColors.neutralLight, lineWidth: 2)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )

                        if agreedToTerms {
                            SwiftUI.Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AdaptiveColors.brandPrimary)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("I agree to the Terms of Service and Privacy Policy")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(AdaptiveColors.neutralDark)
                        .lineLimit(2)

                    Button(action: {
                        // Open terms and conditions
                    }) {
                        HStack(spacing: 4) {
                            Text("Read Terms")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(AdaptiveColors.brandPrimary)
                            SwiftUI.Image(systemName: "arrow.up.right")
                                .font(.system(size: 12))
                                .foregroundColor(AdaptiveColors.brandPrimary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var loginPromptView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AdaptiveColors.neutralDark.opacity(0.8))

                Button(action: {
                    // Switch to login view
                    dismiss()
                }) {
                    HStack(spacing: 6) {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(AdaptiveColors.accent)
                        SwiftUI.Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AdaptiveColors.accent)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        !username.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        agreedToTerms
    }

    private func getValidationMessage() -> String {
        if email.isEmpty {
            return "Please enter your email address"
        } else if username.isEmpty {
            return "Please choose a username"
        } else if password.isEmpty {
            return "Please create a password"
        } else if password.count < 6 {
            return "Password must be at least 6 characters"
        } else if password != confirmPassword {
            return "Passwords do not match"
        } else if !agreedToTerms {
            return "Please agree to the Terms of Service"
        }
        return ""
    }

    private func register() {
        guard isFormValid else { return }

        isLoading = true

        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    username: username,
                    displayName: username, // Per ora usa username come displayName
                    favoriteGames: Array(selectedTCGs)
                )
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
