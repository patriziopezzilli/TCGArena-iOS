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
    @State private var showSuccess = false
    @State private var showError = false
    @State private var message = ""

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

                            SwiftUI.Image(systemName: "envelope.fill")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(.blue)
                        }

                        VStack(spacing: 8) {
                            Text("Reset Password")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)

                            Text("Enter your email to receive reset instructions")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Email form in card
                    VStack(spacing: 24) {
                        VStack(spacing: 20) {
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
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

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
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.horizontal, 24)
                        .disabled(isLoading || email.isEmpty)
                        .opacity((isLoading || email.isEmpty) ? 0.6 : 1.0)
                    }

                    Spacer()
                }
                .padding(.vertical, 40)
            }
        }
        .alert(isPresented: $showSuccess) {
            Alert(
                title: Text("Email Sent"),
                message: Text("Check your email for password reset instructions"),
                dismissButton: .default(Text("OK")) {
                    dismiss()
                }
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message)
        }
    }

    private func resetPassword() {
        guard !email.isEmpty else { return }

        isLoading = true

        Task {
            do {
                try await authService.resetPassword(email: email)
                showSuccess = true
            } catch {
                message = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}
