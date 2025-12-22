//
//  SettingsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var requestService: RequestService
    
    @State private var showingEditProfile = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAlert = false
    @State private var notificationsEnabled = true
    @State private var isPrivate: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CONFIGURAZIONE")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(2)
                        
                        Text("Impostazioni")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // MARK: - TCG Preferiti
                    VStack(alignment: .leading, spacing: 16) {
                        Text("TCG Preferiti")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        Text("Filtra la sezione Discover per i tuoi giochi preferiti")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(TCGType.allCases, id: \.self) { tcg in
                                    MinimalTCGChip(
                                        tcg: tcg,
                                        isSelected: authService.favoriteTCGTypes.contains(tcg)
                                    ) {
                                        toggleTCG(tcg)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // MARK: - Privacy
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                title: "Notifiche Push",
                                subtitle: "Ricevi aggiornamenti su tornei e premi",
                                icon: "bell.fill",
                                color: .blue,
                                isOn: $notificationsEnabled
                            )
                            
                            Divider().padding(.horizontal, 16)
                            
                            SettingsToggleRow(
                                title: "Profilo Privato",
                                subtitle: "Nascondi il tuo profilo dalla sezione Discover",
                                icon: "eye.slash.fill",
                                color: .purple,
                                isOn: $isPrivate
                            )
                            .onChange(of: isPrivate) { newValue in
                                updatePrivacySetting(newValue)
                            }
                        }
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }
                    
                    // MARK: - Account Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            SettingsActionRow(
                                title: "Modifica Profilo",
                                icon: "person.circle.fill",
                                color: .blue
                            ) {
                                showingEditProfile = true
                            }
                            
                            SettingsActionRow(
                                title: "Esci",
                                icon: "arrow.right.square.fill",
                                color: .red
                            ) {
                                showingSignOutAlert = true
                            }
                            
                            SettingsActionRow(
                                title: "Elimina Account",
                                icon: "trash.fill",
                                color: .red
                            ) {
                                showingDeleteAlert = true
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // MARK: - App Info
                    VStack(spacing: 8) {
                        Text("TCG Arena v1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Made with ❤️ for TCG Players")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Chiudi") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert("Esci", isPresented: $showingSignOutAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Esci", role: .destructive) {
                    authService.signOut()
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Sei sicuro di voler uscire?")
            }
            .alert("Elimina Account", isPresented: $showingDeleteAlert) {
                Button("Annulla", role: .cancel) { }
                Button("Elimina", role: .destructive) {
                    // TODO: Implement account deletion
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Questa azione è irreversibile. Tutti i tuoi dati verranno persi.")
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(authService)
        }
        .onAppear {
            isPrivate = authService.currentUser?.isPrivate ?? false
        }
    }
    
    private func toggleTCG(_ tcg: TCGType) {
        var updated = authService.favoriteTCGTypes
        if updated.contains(tcg) {
            updated.removeAll { $0 == tcg }
        } else {
            updated.append(tcg)
        }
        Task {
            await authService.updateFavoriteTCGs(updated)
        }
    }
    
    private func updatePrivacySetting(_ isPrivate: Bool) {
        Task {
            let success = await authService.updatePrivacy(isPrivate: isPrivate)
            if !success {
                self.isPrivate = !isPrivate
            }
        }
    }
}

// MARK: - Components

struct MinimalTCGChip: View {
    let tcg: TCGType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                TCGIconView(tcgType: tcg, size: 16)
                Text(tcg.displayName)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? tcg.themeColor.opacity(0.15) : Color.gray.opacity(0.08))
            .foregroundColor(isSelected ? tcg.themeColor : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? tcg.themeColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(16)
    }
}

struct SettingsActionRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 40, height: 40)
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
