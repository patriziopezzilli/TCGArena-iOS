//
//  EditProfileView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    
    @State private var displayName: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // Avatar Section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            if let user = authService.currentUser,
                               let urlString = user.profileImageUrl,
                               let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Text(String(user.displayName.prefix(1)).uppercased())
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                            } else {
                                Text(authService.currentUser?.displayName.prefix(1).uppercased() ?? "U")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Coming Soon badge
                        Text("Modifica foto: Coming Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 24) {
                        EditProfileField(
                            label: "Nome Visualizzato",
                            placeholder: "Il tuo nome",
                            text: $displayName
                        )
                        
                        // Username is read-only (shown for reference only)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Text("@\(authService.currentUser?.username ?? "")")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Error Message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }
                    
                    // Save Button
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Salva Modifiche")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationTitle("Modifica Profilo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Annulla") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            if let user = authService.currentUser {
                displayName = user.displayName
            }
        }
    }
    
    private func saveProfile() {
        guard !displayName.isEmpty else {
            errorMessage = "Il nome visualizzato è obbligatorio"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        Task {
            do {
                // Update profile via API
                if let userId = authService.currentUserId {
                    try await UserService.shared.updateUserProfile(
                        userId: Int64(userId),
                        displayName: displayName,
                        bio: nil,
                        favoriteGame: authService.currentUser?.favoriteGame ?? .pokemon
                    )
                    await MainActor.run {
                        // Update local user data with new displayName
                        // (Full refresh would require page reload or re-login)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Errore nel salvataggio: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }
}

struct EditProfileField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
                .padding(16)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(12)
        }
    }
}
