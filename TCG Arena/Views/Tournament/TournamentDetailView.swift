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
    @State private var isCheckingIn = false
    @State private var userRegistrationStatus: TournamentParticipant?
    @State private var isLoadingStatus = false
    @State private var participants: [TournamentParticipantWithUser] = []
    @State private var isLoadingParticipants = false
    @State private var showAllParticipants = false
    
    /// Check if tournament is locked (no more changes allowed)
    private var isTournamentLocked: Bool {
        tournament.status == .inProgress || tournament.status == .completed || tournament.status == .cancelled
    }
    
    /// Check if user can check-in (1 hour before to 30 min after start, and tournament not locked)
    private var canCheckIn: Bool {
        guard !isTournamentLocked else { return false }
        guard let userStatus = userRegistrationStatus,
              userStatus.status == .REGISTERED,
              !userStatus.isCheckedIn else { return false }
        
        guard let tournamentStartDate = parseTournamentDate(tournament.startDate) else { return false }
        
        let now = Date()
        let oneHourBefore = tournamentStartDate.addingTimeInterval(-60 * 60)  // 1 hour before
        let thirtyMinutesAfter = tournamentStartDate.addingTimeInterval(30 * 60)  // 30 min after
        
        return now >= oneHourBefore && now <= thirtyMinutesAfter
    }
    
    /// Parse tournament date string to Date
    private func parseTournamentDate(_ dateString: String) -> Date? {
        let formatters: [DateFormatter] = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "dd MMM yyyy, HH:mm",
            "yyyy-MM-dd HH:mm:ss"
        ].map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }

    // MARK: - Header View (extracted to reduce body complexity)
    private var headerView: some View {
        GeometryReader { geometry in
            let offset = geometry.frame(in: .global).minY
            let isRanked = tournament.isRanked == true

            ZStack(alignment: .bottomLeading) {
                // Background Color - Gold for ranked, TCG color for local
                Group {
                    if isRanked {
                        // Premium gold gradient for ranked tournaments
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.15, green: 0.12, blue: 0.08),
                                Color(red: 0.25, green: 0.18, blue: 0.08),
                                Color(red: 0.35, green: 0.25, blue: 0.10)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        tournament.tcgType.themeColor
                    }
                }
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
                        
                        // Official Tournament Badge - Premium gold on dark
                        if tournament.isRanked == true {
                            HStack(spacing: 5) {
                                Text("🏆")
                                Text("Ufficiale")
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 14))
                            .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.45))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 0.85, green: 0.65, blue: 0.2), lineWidth: 1.5)
                            )
                            .cornerRadius(8)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                        }

                        // Tournament type badge - only for local tournaments
                        if tournament.isRanked != true, let type = tournament.type {
                            Text(type.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(20)
                .offset(y: min(0, -offset))
            }
        }
        .frame(height: 250)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerView

                    VStack(spacing: 24) {
                        // Tournament In Progress Banner
                        if isTournamentLocked {
                            InProgressBannerView(status: tournament.status)
                                .padding(.horizontal, 20)
                        }
                        
                        // Winner Podium Section - shown when tournament is completed
                        if tournament.status == .completed {
                            let placedParticipants = participants.filter { $0.placement != nil }.sorted { ($0.placement ?? 99) < ($1.placement ?? 99) }
                            
                            if !placedParticipants.isEmpty {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("🏆 Winners")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    
                                    ForEach(placedParticipants, id: \.id) { participant in
                                        HStack(spacing: 12) {
                                            Text(participant.placementBadge ?? "")
                                                .font(.system(size: 28))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(participant.displayName)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                
                                                Text("@\(participant.username)")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            if let placement = participant.placement {
                                                Text("+\(placement == 1 ? 100 : placement == 2 ? 50 : 25) pts")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(.green)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.green.opacity(0.1))
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemBackground))
                                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                        )
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.yellow.opacity(0.1), Color.orange.opacity(0.1)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Registration/Status Section (first item in body)
                        if let userStatus = userRegistrationStatus {
                            // Compact Registration Status Badge
                            let isCheckedIn = userStatus.isCheckedIn
                            let statusIcon: String = isCheckedIn ? "checkmark.circle.fill" : (userStatus.status == .REGISTERED ? "checkmark.seal.fill" : "clock.fill")
                            let statusColor: Color = isCheckedIn ? .purple : (userStatus.status == .REGISTERED ? .green : .orange)
                            let statusTitle: String = isCheckedIn ? "You're Checked In!" : (userStatus.status == .REGISTERED ? "You're Registered" : "⏳ On Waiting List")
                            let statusSubtitle: String = isCheckedIn ? "Enjoy the tournament!" : (userStatus.status == .REGISTERED ? "You're all set for this tournament" : "We'll notify you if a spot opens")
                            
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    SwiftUI.Image(systemName: statusIcon)
                                        .font(.system(size: 20))
                                        .foregroundColor(statusColor)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(statusTitle)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.primary)

                                        Text(statusSubtitle)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    if !isCheckedIn && !isTournamentLocked {
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
                                }
                                
                                // Check-in button - shown when user can check in
                                if canCheckIn {
                                    Button(action: performCheckIn) {
                                        HStack(spacing: 10) {
                                            if isCheckingIn {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else {
                                                SwiftUI.Image(systemName: "qrcode.viewfinder")
                                                    .font(.system(size: 18))
                                                Text("Check In Now")
                                                    .font(.system(size: 16, weight: .bold))
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.purple]),
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    )
                                                )
                                                .shadow(color: Color.purple.opacity(0.4), radius: 8, x: 0, y: 4)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    .disabled(isCheckingIn)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                        } else if tournament.isRanked == true {
                            // Safari redirect button for ranked/official tournaments
                            Button(action: {
                                if let urlString = tournament.externalRegistrationUrl,
                                   let url = URL(string: urlString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 10) {
                                    SwiftUI.Image(systemName: "trophy.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Iscrizione su App Ufficiale")
                                        .font(.system(size: 17, weight: .semibold))
                                    SwiftUI.Image(systemName: "arrow.up.right")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color.yellow.opacity(0.4), radius: 12, x: 0, y: 6)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.horizontal, 20)
                        } else if tournament.status == .registrationOpen && authService.isAuthenticated && authService.currentUserId != nil && !isTournamentLocked {
                            // Prominent Registration Button - only for authenticated users and tournament not locked
                            let buttonIcon: String = tournament.isFull ? "clock.badge.checkmark" : "checkmark.circle.fill"
                            let buttonText: String = tournament.isFull ? "Join Waiting List" : "Register for Tournament"
                            let buttonColors: [Color] = tournament.isFull ? [Color.orange.opacity(0.8), Color.orange] : [Color.blue.opacity(0.8), Color.blue]
                            let shadowColor: Color = (tournament.isFull ? Color.orange : Color.blue).opacity(0.4)
                            
                            Button(action: registerForTournament) {
                                HStack(spacing: 10) {
                                    if isRegistering {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        SwiftUI.Image(systemName: buttonIcon)
                                            .font(.system(size: 20))
                                        Text(buttonText)
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
                                                gradient: Gradient(colors: buttonColors),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: shadowColor, radius: 12, x: 0, y: 6)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(isRegistering)
                            .padding(.horizontal, 20)
                        } else if tournament.status == .registrationOpen && !(authService.isAuthenticated && authService.currentUserId != nil) {
                            // Disabled registration button for non-authenticated users
                            let disabledIcon: String = tournament.isFull ? "clock.badge.checkmark" : "checkmark.circle.fill"
                            let disabledText: String = tournament.isFull ? "Join Waiting List" : "Register for Tournament"
                            
                            ZStack {
                                HStack(spacing: 10) {
                                    SwiftUI.Image(systemName: disabledIcon)
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                    Text(disabledText)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.gray.opacity(0.2))
                                )
                                
                                // Login Required Badge
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Text("Registrati o fai login")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange)
                                            .cornerRadius(8)
                                            .shadow(radius: 2)
                                    }
                                    .padding(8)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Info Grid - Hide participants and entry fee for ranked tournaments
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            InfoCard(icon: "calendar", title: "Date", value: formatDate(tournament.startDate))
                            InfoCard(icon: "clock", title: "Time", value: formatTime(tournament.startDate))
                            // Only show for local tournaments
                            if tournament.isRanked != true {
                                if let maxParticipants = tournament.maxParticipants {
                                    InfoCard(icon: "person.2", title: "Participants", value: "\(tournament.registeredParticipantsCount)/\(maxParticipants)")
                                }
                                if let entryFee = tournament.entryFee {
                                    InfoCard(icon: "eurosign.circle", title: "Entry Fee", value: entryFee == 0 ? "Free" : "€\(String(format: "%.0f", entryFee))")
                                }
                            }
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
                                        openDirections(to: location)
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

                        // Description - Only show for local tournaments
                        if tournament.isRanked != true, let description = tournament.description {
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
                        
                        // Participants Section - Only show for local tournaments
                        if tournament.isRanked != true {
                            participantsSection
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
        .onAppear {
            // Force refresh registration status on appear
            userRegistrationStatus = nil
            isLoadingStatus = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkRegistrationStatus()
                loadParticipants()
            }
        }
    }
    
    // MARK: - Participants Section
    @ViewBuilder
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with count
            HStack {
                SectionHeader(title: "Participants", icon: "person.2.fill", color: .purple)
                
                Spacer()
                
                // Count badges
                HStack(spacing: 8) {
                    let registered = participants.filter { $0.status == .REGISTERED || $0.status == .CHECKED_IN }.count
                    let waitingList = participants.filter { $0.status == .WAITING_LIST }.count
                    
                    if registered > 0 {
                        Text("\(registered) joined")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .cornerRadius(6)
                    }
                    
                    if waitingList > 0 {
                        Text("\(waitingList) waiting")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
            }
            
            // Participants list
            VStack(spacing: 0) {
                if isLoadingParticipants {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 20)
                        Spacer()
                    }
                } else if participants.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            SwiftUI.Image(systemName: "person.slash")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            Text("No participants yet")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                } else {
                    // Show participants (max 5 if not expanded)
                    let displayedParticipants = showAllParticipants ? participants : Array(participants.prefix(5))
                    
                    ForEach(Array(displayedParticipants.enumerated()), id: \.element.id) { index, participant in
                        ParticipantRow(participant: participant, index: index + 1)
                        
                        if index < displayedParticipants.count - 1 {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                    
                    // Show more button
                    if participants.count > 5 && !showAllParticipants {
                        Divider()
                        
                        Button(action: { showAllParticipants = true }) {
                            HStack {
                                Spacer()
                                Text("Show all \(participants.count) participants")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                SwiftUI.Image(systemName: "chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                    } else if showAllParticipants && participants.count > 5 {
                        Divider()
                        
                        Button(action: { showAllParticipants = false }) {
                            HStack {
                                Spacer()
                                Text("Show less")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                                SwiftUI.Image(systemName: "chevron.up")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
    }
    
    private func loadParticipants() {
        guard let tournamentId = tournament.id else { return }
        
        isLoadingParticipants = true
        
        Task {
            do {
                let participantsList = try await tournamentService.getTournamentParticipantsWithDetails(tournamentId: tournamentId)
                
                // Sort: CHECKED_IN first, then REGISTERED, then WAITING_LIST
                await MainActor.run {
                    self.participants = participantsList.sorted { p1, p2 in
                        let order: [ParticipantStatus] = [.CHECKED_IN, .REGISTERED, .WAITING_LIST, .CANCELLED]
                        let i1 = order.firstIndex(of: p1.status) ?? 99
                        let i2 = order.firstIndex(of: p2.status) ?? 99
                        return i1 < i2
                    }
                    self.isLoadingParticipants = false
                }
            } catch {
                print("Failed to load participants: \(error)")
                await MainActor.run {
                    self.participants = []
                    self.isLoadingParticipants = false
                }
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
                    let message = participant.status == .REGISTERED
                        ? "Successfully registered for the tournament!"
                        : "Added to waiting list. You'll be notified if a spot opens up."
                    
                    if participant.status == .REGISTERED {
                        // Haptic feedback for successful registration
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        ToastManager.shared.showSuccess(message)
                        // Show points bonus toast after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            ToastManager.shared.showSuccess("🎉 +15 punti!")
                        }
                    } else {
                        ToastManager.shared.showInfo(message)
                    }
                    
                    isRegistering = false
                }

                // Refresh tournament data to update counts
                loadTournamentDetails()
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Registration failed: \(error.localizedDescription)")
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
                    ToastManager.shared.showSuccess("Successfully unregistered from the tournament.")
                    // Show points deduction toast after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        ToastManager.shared.showInfo("😢 -10 punti")
                    }
                    isRegistering = false
                }

                // Refresh tournament data to update counts
                loadTournamentDetails()
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Unregistration failed: \(error.localizedDescription)")
                    isRegistering = false
                }
            }
        }
    }
    
    private func performCheckIn() {
        guard let tournamentId = tournament.id else { return }
        
        isCheckingIn = true
        
        Task {
            do {
                try await tournamentService.checkIn(tournamentId: tournamentId)
                
                await MainActor.run {
                    // Haptic feedback for successful check-in
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    ToastManager.shared.showSuccess("Successfully checked in! Enjoy the tournament! 🎉")
                    // Show points bonus toast after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        ToastManager.shared.showSuccess("🎉 +25 punti!")
                    }
                    isCheckingIn = false
                    
                    // Refresh status and participants list
                    checkRegistrationStatus()
                    loadParticipants()
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Check-in failed: \(error.localizedDescription)")
                    isCheckingIn = false
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

    private func formatDate(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatTime(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: dateString)
    }
    
    private func openDirections(to location: Tournament.TournamentLocation) {
        // Try with coordinates first
        if let lat = location.latitude, let lng = location.longitude {
            let urlString = "maps://?daddr=\(lat),\(lng)&dirflg=d"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        // Fallback to address-based search
        let address = "\(location.address), \(location.city)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "maps://?daddr=\(address)&dirflg=d"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
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
    
    struct ParticipantRow: View {
        let participant: TournamentParticipantWithUser
        let index: Int
        
        private var statusColor: Color {
            switch participant.status {
            case .CHECKED_IN: return .green
            case .REGISTERED: return .blue
            case .WAITING_LIST: return .orange
            case .CANCELLED: return .gray
            }
        }
        
        private var statusText: String {
            switch participant.status {
            case .CHECKED_IN: return "Checked In"
            case .REGISTERED: return "Registered"
            case .WAITING_LIST: return "Waiting"
            case .CANCELLED: return "Cancelled"
            }
        }
        
        private var statusIcon: String {
            switch participant.status {
            case .CHECKED_IN: return "checkmark.circle.fill"
            case .REGISTERED: return "person.crop.circle.badge.checkmark"
            case .WAITING_LIST: return "clock.fill"
            case .CANCELLED: return "xmark.circle.fill"
            }
        }
        
        var body: some View {
            HStack(spacing: 12) {
                // Index number
                Text("#\(index)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 32)
                
                // Avatar placeholder
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    SwiftUI.Image(systemName: "person.fill")
                        .font(.system(size: 16))
                        .foregroundColor(statusColor)
                }
                
                // Name with displayName
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if participant.isCheckedIn, let checkedInDate = participant.checkedInDate {
                        Text("Checked in \(formatRelativeTime(checkedInDate))")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else {
                        Text("@\(participant.username)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status badge
                HStack(spacing: 4) {
                    SwiftUI.Image(systemName: statusIcon)
                        .font(.system(size: 10))
                    Text(statusText)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.12))
                .cornerRadius(6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        
        private func formatRelativeTime(_ date: Date) -> String {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
}

// MARK: - Animated In Progress Banner
struct InProgressBannerView: View {
    let status: Tournament.TournamentStatus
    
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    @State private var iconRotation: Double = 0
    
    private var isInProgress: Bool {
        status == .inProgress
    }
    
    private var bannerConfig: (icon: String, title: String, subtitle: String, colors: [Color]) {
        switch status {
        case .inProgress:
            return ("play.circle.fill", "Tournament In Progress", "Registrations and check-ins are closed", [Color.purple, Color.pink, Color.purple])
        case .completed:
            return ("checkmark.circle.fill", "✅ Tournament Completed", "This tournament has ended", [Color.green.opacity(0.8), Color.green])
        case .cancelled:
            return ("xmark.circle.fill", "❌ Tournament Cancelled", "This tournament was cancelled", [Color.gray.opacity(0.8), Color.gray])
        default:
            return ("info.circle.fill", "Tournament Status", "Status unknown", [Color.gray.opacity(0.8), Color.gray])
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Animated icon
            ZStack {
                // Pulsing glow for IN_PROGRESS
                if isInProgress {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 0.5)
                }
                
                SwiftUI.Image(systemName: bannerConfig.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isInProgress ? iconRotation : 0))
                    .scaleEffect(isInProgress && pulseAnimation ? 1.1 : 1.0)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(bannerConfig.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text(bannerConfig.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            // Live indicator for IN_PROGRESS
            if isInProgress {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .opacity(pulseAnimation ? 1.0 : 0.4)
                    
                    Text("LIVE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                )
            }
        }
        .padding(16)
        .background(
            ZStack {
                // Base gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: bannerConfig.colors),
                            startPoint: animateGradient ? .topLeading : .bottomLeading,
                            endPoint: animateGradient ? .bottomTrailing : .topTrailing
                        )
                    )
                
                // Shimmer effect for IN_PROGRESS
                if isInProgress {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.2),
                                    Color.white.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: animateGradient ? 300 : -300)
                }
            }
        )
        .shadow(color: isInProgress ? Color.purple.opacity(0.4) : Color.clear, radius: pulseAnimation ? 12 : 6, x: 0, y: 4)
        .onAppear {
            guard isInProgress else { return }
            
            // Gradient animation
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
            
            // Subtle icon rotation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                iconRotation = 360
            }
        }
    }
}
