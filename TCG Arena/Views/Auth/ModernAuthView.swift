//
//  ModernAuthView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

// Disambiguate between SwiftUI.Image and our Image model
typealias SUIImage = SwiftUI.Image

enum AuthMode {
    case login
    case register
}

struct ModernAuthView: View {
    @EnvironmentObject private var authService: AuthService
    @State private var mode: AuthMode = .login
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedTCGs: Set<TCGType> = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onSkip: () -> Void
    let onSuccess: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.05),
                    Color(.systemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 80, height: 80)
                            
                            SUIImage(systemName: mode == .login ? "person.circle.fill" : "person.badge.plus.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        
                        VStack(spacing: 8) {
                            Text(mode == .login ? "Welcome Back" : "Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text(mode == .login ? "Sign in to continue your journey" : "Join the TCG Arena community")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Mode Toggle
                    HStack(spacing: 0) {
                        Button(action: { withAnimation(.spring()) { mode = .login } }) {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(mode == .login ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(mode == .login ? Color.blue : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button(action: { withAnimation(.spring()) { mode = .register } }) {
                            Text("Register")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(mode == .register ? .white : .primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(mode == .register ? Color.blue : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(4)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    
                    // Form
                    VStack(spacing: 20) {
                        if mode == .register {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Email", systemImage: "envelope.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                TextField("your@email.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(16)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Username", systemImage: "person.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            TextField("Enter your username", text: $username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding(16)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Password", systemImage: "lock.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            SecureField("Enter password", text: $password)
                                .padding(16)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        
                        if mode == .register {
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Confirm Password", systemImage: "lock.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                SecureField("Confirm password", text: $confirmPassword)
                                    .padding(16)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                            
                            // TCG Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Favorite TCGs", systemImage: "gamecontroller.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                Text("Choose at least one")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach([TCGType.pokemon, .magic, .yugioh, .onePiece], id: \.self) { tcg in
                                        Button(action: {
                                            if selectedTCGs.contains(tcg) {
                                                selectedTCGs.remove(tcg)
                                            } else {
                                                selectedTCGs.insert(tcg)
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                SUIImage(systemName: tcg.icon)
                                                    .font(.system(size: 20))
                                                Text(tcg.displayName)
                                                    .font(.system(size: 14, weight: .semibold))
                                                Spacer()
                                                if selectedTCGs.contains(tcg) {
                                                    SUIImage(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 18))
                                                }
                                            }
                                            .foregroundColor(selectedTCGs.contains(tcg) ? .white : .primary)
                                            .padding(12)
                                            .background(selectedTCGs.contains(tcg) ? tcg.themeColor : Color(.systemGray6))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Action Button
                    Button(action: handleSubmit) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(mode == .login ? "Sign In" : "Create Account")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue)
                                .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                    }
                    .disabled(isLoading || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 24)
                    
                    // Skip Button
                    Button(action: onSkip) {
                        Text("Continue as Guest")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        if mode == .login {
            return !username.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty &&
                   !username.isEmpty &&
                   !password.isEmpty &&
                   password == confirmPassword &&
                   !selectedTCGs.isEmpty
        }
    }
    
    private func handleSubmit() {
        guard isFormValid else { return }
        
        isLoading = true
        
        if mode == .login {
            performLogin()
        } else {
            performRegister()
        }
    }
    
    private func performLogin() {
        Task {
            await authService.signIn(email: username, password: password)
            if authService.isAuthenticated {
                onSuccess()
            } else if let error = authService.errorMessage {
                errorMessage = error
                showError = true
            }
            isLoading = false
        }
    }
    
    private func performRegister() {
        Task {
            await authService.signUp(
                email: email,
                password: password,
                username: username,
                displayName: username,
                favoriteGames: Array(selectedTCGs)
            )
            if authService.isAuthenticated {
                // Registration successful, already logged in
                onSuccess()
            } else if let error = authService.errorMessage {
                errorMessage = error
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    ModernAuthView(onSkip: {}, onSuccess: {})
}
