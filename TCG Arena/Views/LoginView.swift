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
    @State private var showError = false
    @State private var errorMessage = ""

    init(username: String = "") {
        _username = State(initialValue: username)
    }
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 120, height: 120)

                        SwiftUI.Image(systemName: "person.circle.fill")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.blue)
                    }

                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)

                        Text("Sign in to continue")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }

                // Login form in card
                VStack(spacing: 24) {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            TextField("Enter your username", text: $username)
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
                            Text("Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            SecureField("Enter your password", text: $password)
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    // Forgot password
                    HStack {
                        Spacer()
                        Button(action: {
                            showForgotPassword = true
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Login button
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .padding(.horizontal, 24)
                    .disabled(isLoading || username.isEmpty || password.isEmpty)
                    .opacity((isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                }

                Spacer()

                // Register option
                Button(action: {
                    showRegister = true
                }) {
                    Text("Don't have an account? Sign Up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding(.vertical, 40)
        }
        .alert("Login Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
        .sheet(isPresented: $showRegister) {
            RegisterView()
                .environmentObject(authService)
        }
    }

    private func login() {
        guard !username.isEmpty, !password.isEmpty else { return }

        isLoading = true

        Task {
            await authService.signIn(email: username, password: password)
            if authService.isAuthenticated {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                dismiss()
            } else if let error = authService.errorMessage {
                errorMessage = error
                showError = true
            }
            isLoading = false
        }
    }
}
