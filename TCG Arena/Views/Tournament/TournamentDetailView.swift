//
//  TournamentDetailView.swift
//  TCG Arena
//
//  Redesigned with Home-style minimal aesthetic
//  Created by TCG Arena Team
//

import SwiftUI
import MapKit
import ActivityKit
import CoreLocation

struct TournamentDetailView: View {
    let tournament: Tournament
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var locationManager = LocationManager()
    
    @State private var isRegistering = false
    @State private var isCheckingIn = false
    @State private var userRegistrationStatus: TournamentParticipant?
    @State private var isLoadingStatus = true
    @State private var participants: [TournamentParticipantWithUser] = []
    @State private var isLoadingParticipants = false
    @State private var showAllParticipants = false
    @State private var showLiveUpdates = false
    @State private var isLiveActivityActive = false
    @State private var showDistanceWarning = false
    @StateObject private var liveActivityManager = TournamentLiveActivityManager.shared
    
    // MARK: - Computed Properties
    private var isTournamentLocked: Bool {
        tournament.status == .inProgress || tournament.status == .completed || tournament.status == .cancelled || tournament.status == .pendingApproval
    }
    
    private var isUserParticipant: Bool {
        // Check userRegistrationStatus first
        if userRegistrationStatus != nil {
            return true
        }
        // Fallback: check if user is in the loaded participants list
        guard let currentUserId = authService.currentUser?.id else { return false }
        return participants.contains { $0.userId == currentUserId }
    }
    
    private var canCheckIn: Bool {
        guard !isTournamentLocked else { return false }
        guard let userStatus = userRegistrationStatus,
              userStatus.status == .REGISTERED,
              !userStatus.isCheckedIn else { return false }
        
        guard let tournamentStartDate = parseTournamentDate(tournament.startDate) else { return false }
        
        let now = Date()
        let oneHourBefore = tournamentStartDate.addingTimeInterval(-60 * 60)
        let thirtyMinutesAfter = tournamentStartDate.addingTimeInterval(30 * 60)
        
        return now >= oneHourBefore && now <= thirtyMinutesAfter
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // MARK: - Header Image
                        headerImage(width: geometry.size.width)
                        
                        VStack(alignment: .leading, spacing: 28) {
                            // MARK: - Title Section
                            titleSection
                            
                            // MARK: - Status Banner (if locked)
                            if isTournamentLocked {
                                statusBanner
                            }
                            
                            // MARK: - Winners Section
                            if tournament.status == .completed {
                                winnersSection
                            }
                            
                            // MARK: - Registration Section
                            registrationSection
                            
                            // MARK: - Quick Stats
                            quickStatsGrid
                            
                            // MARK: - Location Section
                            if let location = tournament.location {
                                locationSection(location: location)
                            }
                            
                            // MARK: - Description
                            if tournament.isRanked != true, let description = tournament.description {
                                descriptionSection(description: description)
                            }
                            
                            // MARK: - Participants
                            if tournament.isRanked != true {
                                participantsSection
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 24)
                    }
                }
                
                // MARK: - Top Bar
                topBar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            userRegistrationStatus = nil
            isLoadingStatus = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                checkRegistrationStatus()
                loadParticipants()
            }
            
            if let currentActivity = liveActivityManager.currentActivity,
               currentActivity.attributes.tournamentId == tournament.id {
                isLiveActivityActive = true
            }
        }
        .sheet(isPresented: $showLiveUpdates) {
            TournamentUpdatesView(tournament: tournament)
                .environmentObject(tournamentService)
        }
    }
    
    // MARK: - Header Image
    @ViewBuilder
    private func headerImage(width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // TCG Color background with subtle gradient
            tournament.tcgType.themeColor
                .frame(width: width, height: 200)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            TCGIconView(tcgType: tournament.tcgType, size: 60)
                                .opacity(0.15)
                            Spacer()
                        }
                        .padding(.leading, 30)
                        .padding(.bottom, 30)
                    }
                )
            
            // Gradient fade to white
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.white.opacity(0.6),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
        }
        .frame(width: width, height: 200)
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                SwiftUI.Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
            
            Spacer()
            
            // Share button
            Button(action: {}) {
                SwiftUI.Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title + Official badge
            HStack(spacing: 12) {
                Text(tournament.title)
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.primary)
                
                if tournament.isRanked == true {
                    Text("🏆 Ufficiale")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // TCG Type + Tournament Type badges
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    TCGIconView(tcgType: tournament.tcgType, size: 16)
                    Text(tournament.tcgType.displayName)
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(8)
                
                if let type = tournament.type, tournament.isRanked != true {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Status Banner
    private var statusBanner: some View {
        let config = getBannerConfig(for: tournament.status)
        let canShowUpdates = tournament.status == .inProgress && isUserParticipant
        
        return Group {
            if canShowUpdates {
                // Tappable banner with integrated live updates for participants
                Button(action: { showLiveUpdates = true }) {
                    statusBannerContent(config: config, showChevron: true)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Non-tappable banner for other statuses
                statusBannerContent(config: config, showChevron: false)
            }
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private func statusBannerContent(config: (icon: String, title: String, subtitle: String, color: Color), showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: config.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(config.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(config.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(showChevron ? "Tocca per vedere aggiornamenti" : config.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if tournament.status == .inProgress {
                HStack(spacing: 8) {
                    Text("LIVE")
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(config.color))
                    
                    if showChevron {
                        SwiftUI.Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
            }
        }
        .padding(16)
        .background(config.color.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Winners Section
    @ViewBuilder
    private var winnersSection: some View {
        let placedParticipants = participants.filter { $0.placement != nil }.sorted { ($0.placement ?? 99) < ($1.placement ?? 99) }
        
        if !placedParticipants.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("Vincitori")
                    .font(.system(size: 20, weight: .bold))
                
                VStack(spacing: 0) {
                    ForEach(placedParticipants, id: \.id) { participant in
                        HStack(spacing: 12) {
                            Text(participant.placementBadge ?? "")
                                .font(.system(size: 24))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(participant.displayName)
                                    .font(.system(size: 15, weight: .semibold))
                                Text("@\(participant.username)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if let placement = participant.placement {
                                Text("+\(placement == 1 ? 100 : placement == 2 ? 50 : 25) pts")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if participant.id != placedParticipants.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Registration Section
    @ViewBuilder
    private var registrationSection: some View {
        if !isTournamentLocked, let userStatus = userRegistrationStatus {
            // User is registered
            let isCheckedIn = userStatus.isCheckedIn
            let statusIcon = isCheckedIn ? "checkmark.circle.fill" : (userStatus.status == .REGISTERED ? "checkmark.seal.fill" : "clock.fill")
            let statusColor: Color = isCheckedIn ? .green : (userStatus.status == .REGISTERED ? .green : .orange)
            let statusTitle = isCheckedIn ? "Check-in Effettuato!" : (userStatus.status == .REGISTERED ? "Sei Iscritto" : "In Lista d'Attesa")
            
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: statusIcon)
                        .font(.system(size: 20))
                        .foregroundColor(statusColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusTitle)
                            .font(.system(size: 16, weight: .bold))
                        Text(isCheckedIn ? "Buon torneo!" : "Sei pronto per questo torneo")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !isCheckedIn && !isTournamentLocked {
                        Button(action: unregisterFromTournament) {
                            Text("Annulla")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .overlay(Capsule().stroke(Color.red, lineWidth: 1.5))
                        }
                        .disabled(isRegistering)
                    }
                }
                
                // Check-in button
                if canCheckIn {
                    Button(action: performCheckIn) {
                        HStack(spacing: 10) {
                            if isCheckingIn {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                SwiftUI.Image(systemName: "person.fill.checkmark")
                                Text("Check-in")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isCheckingIn)
                }
                
                // Live Activity toggle
                if tournament.canEnableLiveActivity && liveActivityManager.areActivitiesSupported {
                    Button(action: toggleLiveActivity) {
                        HStack(spacing: 12) {
                            SwiftUI.Image(systemName: isLiveActivityActive ? "bell.badge.fill" : "bell.fill")
                                .font(.system(size: 16))
                                .foregroundColor(isLiveActivityActive ? .green : .primary)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isLiveActivityActive ? "Live Activity Attiva" : "Attiva Live Activity")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Notifiche sulla Lock Screen")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if isLiveActivityActive {
                                SwiftUI.Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(14)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(16)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            
        } else if tournament.isRanked == true {
            // Official tournament - external link
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
                        .font(.system(size: 16, weight: .bold))
                    SwiftUI.Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.primary)
                .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            
        } else if (tournament.status == .registrationOpen || tournament.status == .upcoming) && authService.isAuthenticated && authService.currentUserId != nil && !isTournamentLocked {
            // Registration button
            if isLoadingStatus {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                    Spacer()
                }
                .frame(height: 56)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(14)
                .padding(.horizontal, 24)
            } else {
                let buttonText = tournament.isFull ? "Entra in Lista d'Attesa" : "Iscriviti al Torneo"
                
                Button(action: { checkDistanceAndRegister() }) {
                    HStack(spacing: 10) {
                        if isRegistering {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            SwiftUI.Image(systemName: tournament.isFull ? "clock.badge.checkmark" : "checkmark.circle.fill")
                            Text(buttonText)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primary)
                    .cornerRadius(14)
                }
                .disabled(isRegistering)
                .padding(.horizontal, 24)
                .alert("Torneo distante", isPresented: $showDistanceWarning) {
                    Button("Annulla", role: .cancel) { }
                    Button("Iscriviti comunque") {
                        proceedWithRegistration()
                    }
                } message: {
                    if let distance = calculateDistanceToTournament() {
                        Text("Questo torneo si trova a \(String(format: "%.1f", distance)) km di distanza. Sei sicuro di voler partecipare?")
                    }
                }
            }
            
        } else if (tournament.status == .registrationOpen || tournament.status == .upcoming) && !(authService.isAuthenticated && authService.currentUserId != nil) {
            // Login required
            VStack(spacing: 12) {
                SwiftUI.Image(systemName: "person.crop.circle")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
                
                Text("Accedi per iscriverti")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Registrati o accedi per partecipare a questo torneo")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Quick Stats Grid
    private var quickStatsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            TournamentStatTile(value: formatDate(tournament.startDate), label: "Data")
            TournamentStatTile(value: formatTime(tournament.startDate), label: "Orario")
            
            if tournament.isRanked != true {
                if let maxParticipants = tournament.maxParticipants {
                    TournamentStatTile(value: "\(tournament.registeredParticipantsCount)/\(maxParticipants)", label: "Partecipanti")
                }
                if let entryFee = tournament.entryFee {
                    TournamentStatTile(value: entryFee == 0 ? "Gratis" : "€\(String(format: "%.0f", entryFee))", label: "Iscrizione")
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Location Section
    private func locationSection(location: Tournament.TournamentLocation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Luogo")
                .font(.system(size: 20, weight: .bold))
            
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    SwiftUI.Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(location.venueName)
                            .font(.system(size: 15, weight: .semibold))
                        Text("\(location.address), \(location.city)")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: { openDirections(to: location) }) {
                    HStack {
                        SwiftUI.Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Ottieni indicazioni")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Description Section
    private func descriptionSection(description: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Descrizione")
                .font(.system(size: 20, weight: .bold))
            
            Text(description)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(16)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Participants Section
    @ViewBuilder
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Partecipanti")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                let registered = participants.filter { $0.status == .REGISTERED || $0.status == .CHECKED_IN }.count
                if registered > 0 {
                    Text("\(registered)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            VStack(spacing: 0) {
                if isLoadingParticipants {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding(.vertical, 20)
                        Spacer()
                    }
                } else if participants.isEmpty {
                    VStack(spacing: 8) {
                        SwiftUI.Image(systemName: "person.slash")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("Nessun partecipante")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    let displayedParticipants = showAllParticipants ? participants : Array(participants.prefix(5))
                    
                    ForEach(Array(displayedParticipants.enumerated()), id: \.element.id) { index, participant in
                        MinimalParticipantRow(participant: participant, index: index + 1)
                        
                        if index < displayedParticipants.count - 1 {
                            Divider().padding(.leading, 52)
                        }
                    }
                    
                    if participants.count > 5 {
                        Divider()
                        
                        Button(action: { showAllParticipants.toggle() }) {
                            HStack {
                                Spacer()
                                Text(showAllParticipants ? "Mostra meno" : "Mostra tutti (\(participants.count))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                SwiftUI.Image(systemName: showAllParticipants ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12))
                                Spacer()
                            }
                            .padding(.vertical, 12)
                        }
                    }
                }
            }
            .background(Color.gray.opacity(0.05))
            .cornerRadius(16)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helper Functions
    private func getBannerConfig(for status: Tournament.TournamentStatus) -> (icon: String, title: String, subtitle: String, color: Color) {
        switch status {
        case .inProgress:
            return ("play.circle.fill", "Torneo in Corso", "Iscrizioni e check-in chiusi", .purple)
        case .completed:
            return ("checkmark.circle.fill", "Torneo Completato", "Questo torneo è terminato", .green)
        case .cancelled:
            return ("xmark.circle.fill", "Torneo Annullato", "Questo torneo è stato annullato", .gray)
        case .pendingApproval:
            return ("clock.badge.exclamationmark.fill", "In Attesa di Approvazione", "Torneo da confermare", .orange)
        default:
            return ("info.circle.fill", "Stato Torneo", "Stato sconosciuto", .gray)
        }
    }
    
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
    
    private func formatDate(_ dateString: String) -> String {
        guard let date = parseTournamentDate(dateString) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ dateString: String) -> String {
        guard let date = parseTournamentDate(dateString) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func openDirections(to location: Tournament.TournamentLocation) {
        if let lat = location.latitude, let lng = location.longitude {
            let urlString = "maps://?daddr=\(lat),\(lng)&dirflg=d"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
                return
            }
        }
        
        let address = "\(location.address), \(location.city)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "maps://?daddr=\(address)&dirflg=d"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Actions
    private func registerForTournament() {
        guard let tournamentId = tournament.id else { return }
        if userRegistrationStatus != nil { return }
        
        isRegistering = true
        
        Task {
            do {
                let participant = try await tournamentService.registerForTournament(tournamentId: tournamentId)
                
                await MainActor.run {
                    userRegistrationStatus = participant
                    let message = participant.status == .REGISTERED ? "Iscrizione completata!" : "Aggiunto alla lista d'attesa"
                    
                    if participant.status == .REGISTERED {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        ToastManager.shared.showSuccess(message)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            ToastManager.shared.showSuccess("🎉 +15 punti!")
                        }
                    } else {
                        ToastManager.shared.showInfo(message)
                    }
                    
                    isRegistering = false
                    loadParticipants()
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Iscrizione fallita: \(error.localizedDescription)")
                    isRegistering = false
                }
            }
        }
    }
    
    // MARK: - Distance Check Functions
    
    private func calculateDistanceToTournament() -> Double? {
        guard let userLocation = locationManager.location,
              let tournamentLat = tournament.location?.latitude,
              let tournamentLon = tournament.location?.longitude else {
            return nil
        }
        
        let userCLLocation = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let tournamentCLLocation = CLLocation(latitude: tournamentLat, longitude: tournamentLon)
        let distanceInMeters = userCLLocation.distance(from: tournamentCLLocation)
        return distanceInMeters / 1000.0 // Convert to kilometers
    }
    
    private func checkDistanceAndRegister() {
        if let distance = calculateDistanceToTournament(), distance > 50.0 {
            // Show warning if tournament is more than 50km away
            showDistanceWarning = true
        } else {
            // Proceed directly if within 50km or location unavailable
            proceedWithRegistration()
        }
    }
    
    private func proceedWithRegistration() {
        registerForTournament()
    }
    
    private func unregisterFromTournament() {
        guard let tournamentId = tournament.id else { return }
        
        isRegistering = true
        
        Task {
            do {
                try await tournamentService.unregisterFromTournament(tournamentId: tournamentId)
                
                await MainActor.run {
                    userRegistrationStatus = nil
                    ToastManager.shared.showSuccess("Iscrizione annullata.")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        ToastManager.shared.showInfo("😢 -10 punti")
                    }
                    isRegistering = false
                    loadParticipants()
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Annullamento fallito: \(error.localizedDescription)")
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
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    ToastManager.shared.showSuccess("Check-in completato! Buon torneo! 🎉")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        ToastManager.shared.showSuccess("🎉 +25 punti!")
                    }
                    isCheckingIn = false
                    checkRegistrationStatus()
                    loadParticipants()
                }
            } catch {
                await MainActor.run {
                    ToastManager.shared.showError("Check-in fallito: \(error.localizedDescription)")
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
        
        tournamentService.getTournamentParticipants(tournamentId: tournamentId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let participants):
                    let userParticipation = participants.first { $0.userId == currentUserId }
                    self.userRegistrationStatus = userParticipation
                case .failure:
                    self.userRegistrationStatus = nil
                }
                self.isLoadingStatus = false
            }
        }
    }
    
    private func loadParticipants() {
        guard let tournamentId = tournament.id else { return }
        
        isLoadingParticipants = true
        
        Task {
            do {
                let participantsList = try await tournamentService.getTournamentParticipantsWithDetails(tournamentId: tournamentId)
                
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
                await MainActor.run {
                    self.participants = []
                    self.isLoadingParticipants = false
                }
            }
        }
    }
    
    private func toggleLiveActivity() {
        if isLiveActivityActive {
            Task {
                await liveActivityManager.endActivity()
                await MainActor.run {
                    isLiveActivityActive = false
                    ToastManager.shared.showInfo("Live Activity disattivata")
                }
            }
        } else {
            let shopName = tournament.location?.venueName ?? "Negozio"
            let success = tournament.startLiveActivity(shopName: shopName)
            
            if success {
                isLiveActivityActive = true
                ToastManager.shared.showSuccess("📍 Live Activity attivata!")
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } else {
                ToastManager.shared.showError("Impossibile avviare Live Activity")
            }
        }
    }
}

// MARK: - Minimal Participant Row
struct MinimalParticipantRow: View {
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
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(index)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
                .frame(width: 32)
            
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                SwiftUI.Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName)
                    .font(.system(size: 14, weight: .medium))
                
                Text("@\(participant.username)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if participant.status == .CHECKED_IN {
                SwiftUI.Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Minimal Stat Tile (Tournament)
struct TournamentStatTile: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(14)
    }
}
