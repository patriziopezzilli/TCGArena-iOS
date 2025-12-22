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
    
    var title: String {
        switch self {
        case .login: return "Bentornato"
        case .register: return "Crea Account"
        }
    }
    
    var subtitle: String {
        switch self {
        case .login: return "Accedi per continuare la tua esperienza"
        case .register: return "Unisciti all'arena e trova la tua community"
        }
    }
    
    var buttonTitle: String {
        switch self {
        case .login: return "Accedi"
        case .register: return "Crea Account"
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
    
    let onSkip: () -> Void
    let onSuccess: () -> Void
    
    var body: some View {
        ZStack {
            // Pure White Background
            Color(.systemBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    Spacer().frame(height: 20)
                    
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mode.title)
                            .font(.system(size: 40, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        Text(mode.subtitle)
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                    
                    // MARK: - Segmented Control (Minimal)
                    HStack(spacing: 32) {
                        Button(action: { withAnimation { mode = .login } }) {
                            VStack(spacing: 8) {
                                Text("Login")
                                    .font(.system(size: 16, weight: mode == .login ? .bold : .medium))
                                    .foregroundColor(mode == .login ? .primary : .secondary)
                                
                                Rectangle()
                                    .fill(mode == .login ? Color.primary : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        
                        Button(action: { withAnimation { mode = .register } }) {
                            VStack(spacing: 8) {
                                Text("Registrati")
                                    .font(.system(size: 16, weight: mode == .register ? .bold : .medium))
                                    .foregroundColor(mode == .register ? .primary : .secondary)
                                
                                Rectangle()
                                    .fill(mode == .register ? Color.primary : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // MARK: - Form
                    VStack(spacing: 24) {
                        if mode == .register {
                            MinimalTextField(title: "Email", icon: "envelope", text: $email, keyboardType: .emailAddress)
                                .transition(.opacity)
                        }
                        
                        MinimalTextField(title: "Username", icon: "person", text: $username)
                        
                        MinimalSecureField(title: "Password", icon: "lock", text: $password)
                        
                        if mode == .register {
                            MinimalSecureField(title: "Conferma Password", icon: "lock.shield", text: $confirmPassword)
                                .transition(.opacity)
                            
                            // TCG Selection
                            VStack(alignment: .leading, spacing: 12) {
                                Text("I TUOI GIOCHI")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach([TCGType.pokemon, .magic, .yugioh, .onePiece], id: \.self) { tcg in
                                            TCGPill(tcg: tcg, isSelected: selectedTCGs.contains(tcg)) {
                                                if selectedTCGs.contains(tcg) {
                                                    selectedTCGs.remove(tcg)
                                                } else {
                                                    selectedTCGs.insert(tcg)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    if mode == .login {
                        HStack {
                            Spacer()
                            Button("Password dimenticata?") {
                                // Action
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, -12)
                    }
                    
                    Spacer()
                    
                    // MARK: - Actions
                    VStack(spacing: 16) {
                        Button(action: handleSubmit) {
                            ZStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white) // Use tint instead of Color
                                        // or if targeting older SwiftUI: .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(mode.buttonTitle)
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isFormValid ? Color.primary : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(28)
                        }
                        .disabled(isLoading || !isFormValid)
                        
                        Button(action: onSkip) {
                            Text("Continua come ospite")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }
    
    // MARK: - Logic
    private var isFormValid: Bool {
        if mode == .login {
            return !username.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty && !username.isEmpty && !password.isEmpty && password == confirmPassword && !selectedTCGs.isEmpty
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
                ToastManager.shared.showError(error)
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
                ToastManager.shared.showError(error)
                print("Registration error: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Minimal Components

struct MinimalTextField: View {
    let title: String
    let icon: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                TextField("", text: $text)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct MinimalSecureField: View {
    let title: String
    let icon: String
    @Binding var text: String
    @State private var showPassword = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                if showPassword {
                    TextField("", text: $text)
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField("", text: $text)
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
                
                Button(action: { showPassword.toggle() }) {
                    SwiftUI.Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

struct TCGPill: View {
    let tcg: TCGType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(tcg.themeColor)
                    .frame(width: 8, height: 8)
                
                Text(tcg.displayName)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.primary : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? Color(.systemBackground) : .primary)
            .cornerRadius(20)
        }
    }
}

#Preview {
    ModernAuthView(onSkip: {}, onSuccess: {})
        .environmentObject(AuthService())
}
