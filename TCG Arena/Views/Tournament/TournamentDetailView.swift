//
//  TournamentDetailView.swift
//  TCG Arena
//
//  Created by Assistant on 22/11/2024.
//

import SwiftUI
import MapKit

struct TournamentDetailView: View {
    let tournament: Tournament
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var isRegistering = false
    @State private var showingRegistrationAlert = false
    @State private var registrationMessage = ""
    @State private var userRegistrationStatus: TournamentParticipant?
    @State private var isLoadingStatus = false

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    GeometryReader { geometry in
                        let offset = geometry.frame(in: .global).minY
                        
                        ZStack(alignment: .bottomLeading) {
                            // Background Color - extends upward on scroll
                            tournament.tcgType.themeColor
                                .frame(height: max(250, 250 + offset))
                                .clipped()
                            
                            // Gradient Overlay
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 100)
                            .offset(y: min(0, -offset))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(tournament.title)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .shadow(radius: 4)
                                
                                HStack(spacing: 12) {
                                    Label(tournament.tcgType.displayName, systemImage: tournament.tcgType.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                    
                                    Text(tournament.type.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                            .padding(20)
                            .offset(y: min(0, -offset))
                        }
                    }
                    .frame(height: 250)
                    
                    VStack(spacing: 24) {
                        // Registration/Status Section (first item in body)
                        if let userStatus = userRegistrationStatus {
                            // Compact Registration Status Badge
                            HStack(spacing: 12) {
                                SwiftUI.Image(systemName: userStatus.status == .REGISTERED ? "checkmark.seal.fill" : "clock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(userStatus.status == .REGISTERED ? .green : .orange)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(userStatus.status == .REGISTERED ? "✓ You're Registered" : "⏳ On Waiting List")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text(userStatus.status == .REGISTERED ? "You're all set for this tournament" : "We'll notify you if a spot opens")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: unregisterFromTournament) {
                                    HStack(spacing: 6) {
                                        if isRegistering {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .red))
                                                .scaleEffect(0.8)
                                        } else {
                                            SwiftUI.Image(systemName: "xmark.circle.fill")
                                            Text("Cancel")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                    }
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .stroke(Color.red, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .disabled(isRegistering)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                        } else if tournament.status == .registrationOpen {
                            // Prominent Registration Button
                            Button(action: registerForTournament) {
                                HStack(spacing: 10) {
                                    if isRegistering {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        SwiftUI.Image(systemName: tournament.isFull ? "clock.badge.checkmark" : "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                        Text(tournament.isFull ? "Join Waiting List" : "Register for Tournament")
                                            .font(.system(size: 17, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: tournament.isFull ? [Color.orange.opacity(0.8), Color.orange] : [Color.blue.opacity(0.8), Color.blue]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: (tournament.isFull ? Color.orange : Color.blue).opacity(0.4), radius: 12, x: 0, y: 6)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(isRegistering)
                            .padding(.horizontal, 20)
                        }
                        
                        // Info Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            InfoCard(icon: "calendar", title: "Date", value: formatDate(tournament.startDate))
                            InfoCard(icon: "clock", title: "Time", value: formatTime(tournament.startDate))
                            InfoCard(icon: "person.2", title: "Participants", value: "\(tournament.registeredParticipantsCount)/\(tournament.maxParticipants)")
                            InfoCard(icon: "eurosign.circle", title: "Entry Fee", value: tournament.entryFee == 0 ? "Free" : "€\(String(format: "%.0f", tournament.entryFee))")
                        }
                        .padding(.horizontal, 20)
                        
                        // Location Section
                        if let location = tournament.location {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "Location", icon: "mappin.circle.fill", color: .red)
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(location.venueName)
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    HStack(alignment: .top, spacing: 8) {
                                        SwiftUI.Image(systemName: "mappin.and.ellipse")
                                            .foregroundColor(.secondary)
                                        Text("\(location.address), \(location.city)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Button(action: {
                                        // Open maps
                                    }) {
                                        Text("Get Directions")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Description
                        if let description = tournament.description {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "About", icon: "info.circle.fill", color: .blue)
                                
                                Text(description)
                                    .font(.system(size: 15))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 24)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            // Custom Navigation Bar
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    SwiftUI.Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
        }
        .navigationBarHidden(true)
        .alert("Registration", isPresented: $showingRegistrationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(registrationMessage)
        }
        .onAppear {
            // Force refresh registration status on appear
            userRegistrationStatus = nil
            isLoadingStatus = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkRegistrationStatus()
            }
        }
    }

    private func registerForTournament() {
        guard let tournamentId = tournament.id else { return }
        
        // Check if already registered
        if userRegistrationStatus != nil {
            print("User is already registered for this tournament")
            return
        }

        isRegistering = true

        Task {
            do {
                let participant = try await tournamentService.registerForTournament(tournamentId: tournamentId)
                
                await MainActor.run {
                    userRegistrationStatus = participant
                    registrationMessage = participant.status == .REGISTERED
                        ? "Successfully registered for the tournament!"
                        : "Added to waiting list. You'll be notified if a spot opens up."
                    showingRegistrationAlert = true
                    isRegistering = false
                }
                
                // Refresh tournament data to update counts
                loadTournamentDetails()
            } catch {
                await MainActor.run {
                    registrationMessage = "Registration failed: \(error.localizedDescription)"
                    showingRegistrationAlert = true
                    isRegistering = false
                }
            }
        }
    }

    private func unregisterFromTournament() {
        guard let tournamentId = tournament.id else { return }

        isRegistering = true

        Task {
            do {
                try await tournamentService.unregisterFromTournament(tournamentId: tournamentId)
                
                await MainActor.run {
                    userRegistrationStatus = nil
                    registrationMessage = "Successfully unregistered from the tournament."
                    showingRegistrationAlert = true
                    isRegistering = false
                }
                
                // Refresh tournament data to update counts
                loadTournamentDetails()
            } catch {
                await MainActor.run {
                    registrationMessage = "Unregistration failed: \(error.localizedDescription)"
                    showingRegistrationAlert = true
                    isRegistering = false
                }
            }
        }
    }

    private func checkRegistrationStatus() {
        guard let tournamentId = tournament.id,
              let currentUserId = authService.currentUser?.id else {
            userRegistrationStatus = nil
            isLoadingStatus = false
            return
        }
        
        print("🔍 Checking registration status for tournamentId=\(tournamentId), userId=\(currentUserId)")

        tournamentService.getTournamentParticipants(tournamentId: tournamentId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let participants):
                    print("📋 Retrieved \(participants.count) participants from API")
                    
                    // Find current user's registration
                    let userParticipation = participants.first { participant in
                        participant.userId == currentUserId
                    }
                    
                    if let status = userParticipation {
                        print("✅ User IS registered: userId=\(status.userId), status=\(status.status)")
                        self.userRegistrationStatus = status
                    } else {
                        print("❌ User NOT registered (userId=\(currentUserId) not found in \(participants.count) participants)")
                        self.userRegistrationStatus = nil
                    }
                    
                case .failure(let error):
                    print("⚠️ Failed to check registration status: \(error.localizedDescription)")
                    self.userRegistrationStatus = nil
                }
                
                self.isLoadingStatus = false
            }
        }
    }

    private func loadTournamentDetails() {
        // In a real implementation, reload tournament data from service
        // For now, this is a placeholder
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Subviews
    struct InfoCard: View {
        let icon: String
        let title: String
        let value: String
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }
    
    struct SectionHeader: View {
        let title: String
        let icon: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 8) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
            }
        }
    }
}
