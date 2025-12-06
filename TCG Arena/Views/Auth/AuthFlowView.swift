//
//  AuthFlowView.swift
//  TCG Arena
//
//  Simple login/registration flow for guest users who want to sign in
//  without going through the full onboarding process again.
//

import SwiftUI

struct AuthFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    
    var startWithLogin: Bool = true
    @State private var showingLogin: Bool = true
    
    init(startWithLogin: Bool = true) {
        self.startWithLogin = startWithLogin
        _showingLogin = State(initialValue: startWithLogin)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toggle between Login and Register
                Picker("", selection: $showingLogin) {
                    Text("Sign In").tag(true)
                    Text("Create Account").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Content
                if showingLogin {
                    LoginView()
                        .environmentObject(authService)
                } else {
                    RegisterView()
                        .environmentObject(authService)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        SwiftUI.Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
}

#Preview {
    AuthFlowView()
        .environmentObject(AuthService())
}
