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
    
    var accentColor: Color {
        switch self {
        case .login:
            return Color.blue
        case .register:
            return Color.green
        }
    }
    
    var title: String {
        switch self {
        case .login:
            return "Welcome Back"
        case .register:
            return "Create Account"
        }
    }
    
    var subtitle: String {
        switch self {
        case .login:
            return "Sign in to continue your journey"
        case .register:
            return "Join the TCG Arena community"
        }
    }
    
    var icon: String {
        switch self {
        case .login:
            return "person.circle.fill"
        case .register:
            return "person.badge.plus.fill"
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .login:
            return "Sign In"
        case .register:
            return "Create Account"
        }
    }
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
    // Removed: @State private var showError = false
    // Removed: @State private var errorMessage = ""
    
    let onSkip: () -> Void
    let onSuccess: () -> Void
    
    var body: some View {
        ZStack {
            // Background with gradient based on mode
            LinearGradient(
                gradient: Gradient(colors: [
                    mode.accentColor.opacity(0.08),
                    Color(.systemBackground)
                ]),
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: mode)
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Header
                    headerView
                    
                    // Mode Toggle
                    modeToggle
                    
                    // Form
                    formFields
                    
                    // Action Button
                    actionButton
                    
                    // Skip Button
                    skipButton
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(mode.accentColor.opacity(0.15))
                    .frame(width: 90, height: 90)
                
                Circle()
                    .fill(mode.accentColor.opacity(0.25))
                    .frame(width: 70, height: 70)
                
                SUIImage(systemName: mode.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(mode.accentColor)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: mode)
            
            VStack(spacing: 8) {
                Text(mode.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(mode.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Mode Toggle
    private var modeToggle: some View {
        HStack(spacing: 0) {
            // Login Tab
            Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { mode = .login } }) {
                Text("Sign In")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(mode == .login ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            if mode == .login {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                    )
            }
            
            // Register Tab
            Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { mode = .register } }) {
                Text("Register")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(mode == .register ? .white : .primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            if mode == .register {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green)
                                    .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                    )
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
    
    // MARK: - Form Fields
    private var formFields: some View {
        VStack(spacing: 20) {
            if mode == .register {
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Label("Email", systemImage: "envelope.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                    
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
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Username Field
            VStack(alignment: .leading, spacing: 8) {
                Label("Username", systemImage: "person.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(mode.accentColor)
                
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
                    .foregroundColor(mode == .login ? .blue.opacity(0.8) : .green.opacity(0.8))
                
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
                    Label("Confirm Password", systemImage: "lock.shield.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.cyan)
                    
                    SecureField("Confirm password", text: $confirmPassword)
                        .padding(16)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
                
                // TCG Selection
                tcgSelectionView
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: mode)
    }
    
    // MARK: - TCG Selection
    private var tcgSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Favorite TCGs", systemImage: "gamecontroller.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.indigo)
            
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
                            TCGIconView(tcgType: tcg, size: 20, color: selectedTCGs.contains(tcg) ? .white : .primary)
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
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: handleSubmit) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(mode.buttonTitle)
                        .font(.system(size: 18, weight: .bold))
                    SUIImage(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [mode.accentColor, mode.accentColor.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: mode.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading || !isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.2), value: mode)
    }
    
    // MARK: - Skip Button
    private var skipButton: some View {
        Button(action: onSkip) {
            Text("Continue as Guest")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Validation
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
    
    // MARK: - Actions
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
                // ToastManager.shared.showError(error)
                print("Auth error: \(error)")
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
                // ToastManager.shared.showError(error)
                print("Registration error: \(error)")
            }
            isLoading = false
        }
    }
}

#Preview {
    ModernAuthView(onSkip: {}, onSuccess: {})
        .environmentObject(AuthService())
}
