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
    @State private var selectedTCG: TCGType?

    init(email: String = "", selectedTCG: TCGType? = nil) {
        _email = State(initialValue: email)
        _selectedTCG = State(initialValue: selectedTCG)
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()

                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 120, height: 120)

                            SwiftUI.Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(.blue)
                        }

                        VStack(spacing: 8) {
                            Text("Create Account")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)

                            Text("Join TCG Arena")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                        }
                    }

                    // Registration form in card
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)

                                TextField("Choose a username", text: $username)
                                    .font(.system(size: 16))
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)

                                TextField("Enter your email", text: $email)
                                    .font(.system(size: 16))
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)

                                SecureField("Create a password", text: $password)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .foregroundColor(.black)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)

                                SecureField("Confirm your password", text: $confirmPassword)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .foregroundColor(.black)
                            }

                            // TCG Selection if not selected
                            if selectedTCG == nil {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Choose your favorite TCG")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.gray)

                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                        ForEach(TCGType.allCases.filter { $0 != .digimon }, id: \.self) { tcg in
                                            Button(action: {
                                                selectedTCG = tcg
                                            }) {
                                                VStack(spacing: 6) {
                                                    SwiftUI.Image(systemName: "star.fill")
                                                        .font(.system(size: 20, weight: .medium))
                                                        .foregroundColor(.yellow)

                                                    Text(tcg.rawValue)
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(.black)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 60)
                                                .background(Color.gray.opacity(0.1))
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                        // Terms agreement
                        HStack(alignment: .top, spacing: 16) {
                            Button(action: {
                                agreedToTerms.toggle()
                            }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )

                                    if agreedToTerms {
                                        SwiftUI.Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }

                            Text("I agree to the Terms of Service and Privacy Policy")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                                .lineLimit(2)

                            Spacer()
                        }
                        .padding(.horizontal, 24)

                        // Register button
                        Button(action: register) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.horizontal, 24)
                        .disabled(isLoading || !isFormValid)
                        .opacity(isLoading || !isFormValid ? 0.6 : 1.0)
                    }

                    Spacer()
                }
            }
        }
        .alert("Registration Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
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
                    favoriteGame: selectedTCG
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
