//
//  OnboardingView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService()
    @State private var email = ""
    @State private var isLoading = false
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var selectedTCG: TCGType? = nil

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Header
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.blue.opacity(0.8))

                    VStack(spacing: 8) {
                        Text("Join TCG Arena")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)

                        Text("Enter your email to get started")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }

                // Email field
                VStack(spacing: 20) {
                    TextField("Email address", text: $email)
                        .font(.system(size: 18))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)

                    // TCG Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose your favorite TCG")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            ForEach(TCGType.allCases.filter { $0 != .digimon }, id: \.self) { tcg in
                                Button(action: {
                                    selectedTCG = tcg
                                }) {
                                    VStack(spacing: 8) {
                                        SwiftUI.Image(systemName: tcg.systemIcon)
                                            .font(.system(size: 30, weight: .medium))
                                            .foregroundColor(selectedTCG == tcg ? .white : tcg.themeColor)

                                        Text(tcg.rawValue)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(selectedTCG == tcg ? .white : .black)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(selectedTCG == tcg ? tcg.themeColor : Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedTCG == tcg ? tcg.themeColor : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Continue button
                    Button(action: continueOnboarding) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .padding(.horizontal, 24)
                    .disabled(isLoading || email.isEmpty || selectedTCG == nil)
                    .opacity((isLoading || email.isEmpty || selectedTCG == nil) ? 0.6 : 1.0)
                }

                Spacer()

                // Skip option
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    dismiss()
                }) {
                    Text("Continue as Guest")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(.vertical, 40)
        }
        .sheet(isPresented: $showLogin) {
            LoginView(email: email)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(email: email, selectedTCG: selectedTCG)
        }
    }

    private func continueOnboarding() {
        guard !email.isEmpty, let _ = selectedTCG else { return }

        isLoading = true

        // Per ora, mostriamo sempre la registrazione
        // In futuro potremmo implementare un controllo email
        showRegister = true
        isLoading = false
    }
}