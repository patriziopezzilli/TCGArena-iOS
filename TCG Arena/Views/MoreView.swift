//
//  MoreView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var rewardsService: RewardsService
    @EnvironmentObject private var reservationService: ReservationService
    @EnvironmentObject private var requestService: RequestService
    @EnvironmentObject private var settingsService: SettingsService
    
    // Navigation States
    @State private var showingProfile = false
    @State private var showingRewards = false
    @State private var showingReservations = false
    @State private var showingRequests = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    @State private var showingSuggestionModal = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MENU")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(2)
                        
                        Text("Altro")
                            .font(.system(size: 34, weight: .heavy, design: .default))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        
                        // 1. Profile Tile
                        MoreTile(
                            title: "Profilo",
                            subtitle: "Il tuo spazio",
                            icon: "person.crop.circle.fill",
                            color: .blue
                        ) {
                            showingProfile = true
                        }
                        
                        // 2. Rewards Tile
                        MoreTile(
                            title: "Premi",
                            subtitle: "Loyalty Program",
                            icon: "gift.fill",
                            color: .purple
                        ) {
                            showingRewards = true
                        }
                        
                        // 3. Reservations Tile
                        MoreTile(
                            title: "Prenotazioni",
                            subtitle: "Eventi & Posti",
                            icon: "qrcode.viewfinder",
                            color: .orange
                        ) {
                            showingReservations = true
                        }
                        
                        // 4. Requests Tile
                        MoreTile(
                            title: "Richieste",
                            subtitle: "I tuoi ordini",
                            icon: "envelope.fill",
                            color: .green
                        ) {
                            showingRequests = true
                        }
                        
                        // 5. Settings Tile
                        MoreTile(
                            title: "Impostazioni",
                            subtitle: "Configurazione",
                            icon: "gearshape.fill",
                            color: .gray
                        ) {
                            showingSettings = true
                        }
                        
                        // 6. Help Tile
                        MoreTile(
                            title: "Aiuto",
                            subtitle: "FAQ & Supporto",
                            icon: "questionmark.circle.fill",
                            color: .pink
                        ) {
                            showingHelp = true
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Suggestions Box (Full Width)
                    Button(action: { showingSuggestionModal = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                SwiftUI.Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hai un'idea?")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                Text("Inviaci un suggerimento per migliorare l'app!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            SwiftUI.Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .buttonStyle(ScaleButtonStyle())
                    
                    // Footer / Version
                    VStack(spacing: 8) {
                        Text("TCG Arena v1.0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Esci") {
                            authService.signOut()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarHidden(true)
            
            // Profile -> UserProfileDetailView (readonly via toUserProfile)
            .background(
                NavigationLink(isActive: $showingProfile) {
                    if let user = authService.currentUser {
                        UserProfileDetailView(userProfile: user.toUserProfile())
                    } else {
                        Text("Profilo non disponibile")
                    }
                } label: { EmptyView() }
            )
            .background(
                NavigationLink(isActive: $showingRewards) {
                    RewardsMainView()
                        .environmentObject(rewardsService)
                } label: { EmptyView() }
            )
            .sheet(isPresented: $showingReservations) {
                NavigationView {
                    MyReservationsView()
                        .environmentObject(reservationService)
                        .environmentObject(authService)
                }
            }
            .sheet(isPresented: $showingRequests) {
                NavigationView {
                    UserRequestsView()
                        .environmentObject(requestService)
                        .environmentObject(authService)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settingsService)
                    .environmentObject(authService)
                    .environmentObject(requestService)
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
            .sheet(isPresented: $showingSuggestionModal) {
                SuggestionModalView()
            }
        }
    }
}

struct MoreTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon Container
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
