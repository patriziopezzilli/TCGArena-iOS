//
//  ProfileView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var settingsService: SettingsService
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var requestService: RequestService
    @State private var showingSettings = false
    @State private var showingUserRequests = false
    @State private var showingMyReservations = false
    @State private var userActivities: [UserActivity] = []
    @State private var userStats: UserStats?
    @State private var isLoadingActivities = false
    @State private var isLoadingStats = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clean Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profile")
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)
                        
                        if let user = authService.currentUser {
                            Text("\(user.displayName) • \(user.favoriteGame?.rawValue.capitalized ?? "TCG Collector")")
                                .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                                .foregroundColor(.secondary)
                        } else {
                            Text("TCG Collector")
                                .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        SwiftUI.Image(systemName: "gearshape.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.7, blue: 1.0))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Quick Actions Section (Prominent)
                        VStack(spacing: 12) {
                            // My Reservations Card
                            Button(action: { showingMyReservations = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.orange.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        SwiftUI.Image(systemName: "qrcode.viewfinder")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.orange)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Le mie Prenotazioni")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.primary)
                                        Text("Visualizza le tue prenotazioni attive")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    SwiftUI.Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .frame(height: 80) // Altezza fissa per uniformità
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // My Requests Card
                            Button(action: { showingUserRequests = true }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                        SwiftUI.Image(systemName: "envelope.badge")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Le mie Richieste")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(.primary)
                                        Text("Gestisci le richieste inviate")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    SwiftUI.Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(16)
                                .frame(height: 80) // Altezza fissa per uniformità
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        
                        // MARK: - Recent Activity Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SwiftUI.Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.purple)
                                Text("Attività Recenti")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                if isLoadingActivities {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                        Spacer()
                                    }
                                    .padding(.vertical, 20)
                                } else if userActivities.isEmpty {
                                    HStack {
                                        Spacer()
                                        VStack(spacing: 8) {
                                            SwiftUI.Image(systemName: "clock")
                                                .font(.system(size: 32))
                                                .foregroundColor(.secondary.opacity(0.5))
                                            Text("Nessuna attività recente")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 24)
                                } else {
                                    ForEach(userActivities.prefix(5), id: \.id) { activity in
                                        HStack(spacing: 12) {
                                            SwiftUI.Image(systemName: iconForActivityType(activity.activityType))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(colorForActivityType(activity.activityType))
                                                .frame(width: 28, height: 28)
                                                .background(
                                                    Circle()
                                                        .fill(colorForActivityType(activity.activityType).opacity(0.15))
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(activity.description)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                Text(formatTimestamp(activity.timestamp))
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        
                                        if activity.id != userActivities.prefix(5).last?.id {
                                            Divider()
                                                .padding(.leading, 56)
                                        }
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }
                        
                        // MARK: - Statistics Section (Compact, at bottom)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Statistiche")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                CompactStatItem(value: "\(userStats?.totalCards ?? 0)", label: "Carte", icon: "rectangle.stack")
                                CompactStatItem(value: "\(userStats?.totalDecks ?? 0)", label: "Deck", icon: "rectangle.stack.fill")
                                CompactStatItem(value: "\(userStats?.totalTournaments ?? 0)", label: "Tornei", icon: "trophy")
                                CompactStatItem(value: "\(userStats?.totalWins ?? 0)", label: "Vittorie", icon: "checkmark.circle")
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settingsService)
                    .environmentObject(requestService)
            }
            .sheet(isPresented: $showingUserRequests) {
                NavigationView {
                    UserRequestsView()
                        .environmentObject(requestService)
                        .environmentObject(authService)
                }
            }
            .sheet(isPresented: $showingMyReservations) {
                NavigationView {
                    MyReservationsView()
                        .environmentObject(ReservationService())
                        .environmentObject(authService)
                }
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        guard let userId = authService.currentUserId else { return }
        
        // Load activities
        isLoadingActivities = true
        Task {
            do {
                userActivities = try await UserService.shared.getUserActivities(userId: userId)
            } catch APIError.sessionExpired {
                // Sessione scaduta, logout automatico
                authService.signOut()
            } catch {
                // Handle other errors silently
            }
            isLoadingActivities = false
        }
        
        // Load stats
        isLoadingStats = true
        Task {
            do {
                userStats = try await UserService.shared.getUserStats(userId: userId)
            } catch APIError.sessionExpired {
                // Sessione scaduta, logout automatico
                authService.signOut()
            } catch {
                // Handle other errors silently
            }
            isLoadingStats = false
        }
    }
    
    private func iconForActivityType(_ type: String) -> String {
        switch type {
        case "CARD_ADDED_TO_COLLECTION": return "plus.circle.fill"
        case "CARD_REMOVED_FROM_COLLECTION": return "minus.circle.fill"
        case "DECK_CREATED": return "rectangle.stack.badge.plus"
        case "DECK_UPDATED": return "pencil.circle.fill"
        case "DECK_DELETED": return "trash.circle.fill"
        case "TOURNAMENT_JOINED": return "person.2.circle.fill"
        case "TOURNAMENT_WON": return "trophy.fill"
        case "USER_REGISTERED": return "person.badge.plus"
        default: return "circle.fill"
        }
    }
    
    private func colorForActivityType(_ type: String) -> Color {
        switch type {
        case "CARD_ADDED_TO_COLLECTION": return .green
        case "CARD_REMOVED_FROM_COLLECTION": return .red
        case "DECK_CREATED": return .blue
        case "DECK_UPDATED": return .orange
        case "DECK_DELETED": return .red
        case "TOURNAMENT_JOINED": return .purple
        case "TOURNAMENT_WON": return Color(red: 1.0, green: 0.7, blue: 0.0)
        case "USER_REGISTERED": return .green
        default: return .gray
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: timestamp) else {
            return timestamp
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else if let seconds = components.second, seconds > 0 {
            return seconds == 1 ? "1 second ago" : "\(seconds) seconds ago"
        } else {
            return "Just now"
        }
    }
    
struct MinimalStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct CompactStatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct StatCard: View {
        let title: String
        let value: String
        let icon: String
        
        var body: some View {
            VStack(spacing: 8) {
                SwiftUI.Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    struct ActivityRow: View {
        let icon: String
        let title: String
        let time: String
        let iconColor: Color
        
        var body: some View {
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    struct SettingsRow: View {
        let title: String
        let icon: String
        var isDestructive = false
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isDestructive ? .red : .blue)
                        .frame(width: 24, height: 24)
                    
                    Text(title)
                        .font(.body)
                        .foregroundColor(isDestructive ? .red : .primary)
                    
                    Spacer()
                    
                    SwiftUI.Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    struct FavoriteTCGRow: View {
        let tcgType: TCGType
        @EnvironmentObject private var authService: AuthService
        @State private var isSelected: Bool = false
        
        var body: some View {
            Button(action: toggleFavorite) {
                HStack(spacing: 12) {
                    TCGIconView(tcgType: tcgType, size: 20, color: tcgType.themeColor)
                    
                    Text(tcgType.displayName)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    SwiftUI.Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isSelected ? tcgType.themeColor : .secondary)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
            .onAppear {
                isSelected = authService.favoriteTCGTypes.contains(tcgType)
            }
            .onChange(of: authService.currentUser?.id) { _ in
                isSelected = authService.favoriteTCGTypes.contains(tcgType)
            }
        }
        
        private func toggleFavorite() {
            isSelected.toggle()
            
            Task {
                var updatedFavorites = authService.favoriteTCGTypes
                if isSelected {
                    if !updatedFavorites.contains(tcgType) {
                        updatedFavorites.append(tcgType)
                    }
                } else {
                    updatedFavorites.removeAll { $0 == tcgType }
                }
                
                let success = await authService.updateFavoriteTCGs(updatedFavorites)
                if !success {
                    // Revert on failure
                    isSelected.toggle()
                }
            }
        }
    }
    
    struct FavoriteTCGChipsView: View {
        @EnvironmentObject private var authService: AuthService
        @State private var selectedTCGs: Set<TCGType> = []
        
        private let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        var body: some View {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(TCGType.allCases, id: \.self) { tcgType in
                    FavoriteTCGCard(
                        tcgType: tcgType,
                        isSelected: selectedTCGs.contains(tcgType)
                    ) {
                        toggleTCG(tcgType)
                    }
                }
            }
            .padding(.vertical, 8)
            .onAppear {
                selectedTCGs = Set(authService.favoriteTCGTypes)
            }
            .onChange(of: authService.favoriteTCGs) { newValue in
                selectedTCGs = Set(newValue)
            }
        }
        
        private func toggleTCG(_ tcgType: TCGType) {
            HapticManager.shared.selectionChanged()
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedTCGs.contains(tcgType) {
                    selectedTCGs.remove(tcgType)
                } else {
                    selectedTCGs.insert(tcgType)
                }
            }
            
            Task {
                let success = await authService.updateFavoriteTCGs(Array(selectedTCGs))
                if !success {
                    HapticManager.shared.error()
                    // Revert on failure
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if selectedTCGs.contains(tcgType) {
                            selectedTCGs.remove(tcgType)
                        } else {
                            selectedTCGs.insert(tcgType)
                        }
                    }
                }
            }
        }
    }
    
    struct FavoriteTCGCard: View {
        let tcgType: TCGType
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    // Large TCG icon
                    ZStack {
                        Circle()
                            .fill(isSelected ? tcgType.themeColor.opacity(0.2) : Color(.systemGray5))
                            .frame(width: 56, height: 56)
                        
                        TCGIconView(tcgType: tcgType, size: 32)
                            .foregroundColor(isSelected ? tcgType.themeColor : .secondary)
                        
                        // Checkmark overlay when selected
                        if isSelected {
                            Circle()
                                .fill(tcgType.themeColor)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    SwiftUI.Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 20, y: -20)
                        }
                    }
                    
                    // TCG name
                    Text(tcgType.displayName)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? tcgType.themeColor : .primary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ?
                              tcgType.themeColor.opacity(0.1) :
                              Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? tcgType.themeColor : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                )
                .scaleEffect(isSelected ? 1.02 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    struct SettingsView: View {
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject private var settingsService: SettingsService
        @EnvironmentObject private var authService: AuthService
        @EnvironmentObject private var requestService: RequestService
        @State private var showingTerms = false
        @State private var showingPrivacy = false
        @State private var showingFAQ = false
        @State private var showingSupport = false
        @State private var showingEditProfile = false
        @State private var showingSignOutAlert = false
        @State private var showingDeleteAlert = false
        @State private var notificationsEnabled = true
        @State private var isPrivate: Bool = false
        
        var body: some View {
            NavigationView {
                List {
                    // Favorite TCGs Section - Compact horizontal chips
                    Section {
                        FavoriteTCGChipsView()
                    } header: {
                        Text("Favorite TCGs")
                    } footer: {
                        Text("Filter Discover section by your favorite games")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // App Settings Section
                    Section {
                        SettingsRow(
                            title: "Notifications",
                            icon: "bell.fill"
                        ) {
                            notificationsEnabled.toggle()
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                Toggle("", isOn: $notificationsEnabled)
                                    .labelsHidden()
                            }
                        )
                        
                        SettingsRow(
                            title: "Profilo Privato",
                            icon: "eye.slash.fill"
                        ) {
                            togglePrivacy()
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                Toggle("", isOn: $isPrivate)
                                    .labelsHidden()
                                    .onChange(of: isPrivate) { newValue in
                                        updatePrivacySetting(newValue)
                                    }
                            }
                        )
                    } header: {
                        Text("App Settings")
                    } footer: {
                        Text("Quando attivo, il tuo profilo non sarà visibile nella sezione Discover")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Account Section
                    Section("Account") {
                        SettingsRow(
                            title: "Edit Profile",
                            icon: "person.circle.fill"
                        ) {
                            showingEditProfile = true
                        }
                    }
                    
                    // Support Section
                    Section("Support & Legal") {
                        SettingsRow(
                            title: "FAQ",
                            icon: "questionmark.circle.fill"
                        ) {
                            showingFAQ = true
                        }
                        
                        SettingsRow(
                            title: "Contact Support",
                            icon: "envelope.fill"
                        ) {
                            showingSupport = true
                        }
                        
                        SettingsRow(
                            title: "Terms & Conditions",
                            icon: "doc.text.fill"
                        ) {
                            showingTerms = true
                        }
                        
                        SettingsRow(
                            title: "Privacy Policy",
                            icon: "hand.raised.fill"
                        ) {
                            showingPrivacy = true
                        }
                        
                        SettingsRow(
                            title: "Rate App",
                            icon: "star.fill"
                        ) {
                            // TODO: App Store rating
                        }
                    }
                    
                    // App Info Section
                    Section("About") {
                        HStack {
                            SwiftUI.Image(systemName: "info.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 24, height: 24)
                            
                            Text("Version")
                                .font(.body)
                            
                            Spacer()
                            
                            Text("1.0.0")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // TCG Rules Section
                    Section("Regolamenti TCG") {
                        ForEach(TCGType.allCases, id: \.self) { tcgType in
                            TCGRulesRow(tcgType: tcgType)
                        }
                    }
                    
                    // Danger Zone
                    Section("Account Actions") {
                        SettingsRow(
                            title: "Sign Out",
                            icon: "rectangle.portrait.and.arrow.right.fill",
                            isDestructive: true
                        ) {
                            showingSignOutAlert = true
                        }
                        
                        SettingsRow(
                            title: "Delete Account",
                            icon: "trash.fill",
                            isDestructive: true
                        ) {
                            showingDeleteAlert = true
                        }
                    }
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                .sheet(isPresented: $showingTerms) {
                    TermsView()
                }
                .sheet(isPresented: $showingPrivacy) {
                    PrivacyPolicyView()
                }
                .sheet(isPresented: $showingFAQ) {
                    FAQView()
                }
                .sheet(isPresented: $showingSupport) {
                    SupportView()
                }
                .sheet(isPresented: $showingEditProfile) {
                    EditProfileView()
                }
                .confirmationDialog("Sign Out", isPresented: $showingSignOutAlert) {
                    Button("Sign Out", role: .destructive) {
                        authService.signOut()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to sign out? You'll need to sign back in to access your collection.")
                }
                .confirmationDialog("Delete Account", isPresented: $showingDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        // Handle account deletion
                        presentationMode.wrappedValue.dismiss()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This action cannot be undone. All your collection data, decks, and progress will be permanently deleted.")
                }
                .overlay(
                    ToastManager.shared.currentToast.map { toast in
                        ToastNotificationView(toast: toast)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut, value: toast.id)
                    },
                    alignment: .bottom
                )
                .onAppear {
                    // Sync privacy state with current user
                    isPrivate = authService.currentUser?.isPrivate ?? false
                }
            }
        }
        
        private func togglePrivacy() {
            HapticManager.shared.selectionChanged()
            isPrivate.toggle()
        }
        
        private func updatePrivacySetting(_ newValue: Bool) {
            Task {
                let success = await authService.updatePrivacy(isPrivate: newValue)
                if !success {
                    HapticManager.shared.error()
                    // Revert on failure
                    await MainActor.run {
                        isPrivate = !newValue
                    }
                    ToastManager.shared.showError("Impossibile aggiornare la privacy")
                }
            }
        }
    }
    
    struct TermsView: View {
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Terms & Conditions")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom)
                        
                        Group {
                            Text("1. Acceptance of Terms")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("By downloading and using TCG Arena, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our application.")
                                .font(.body)
                            
                            Text("2. Use of the Application")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("TCG Arena is designed for personal use to manage your trading card game collection. You may not use the app for commercial purposes without written permission.")
                                .font(.body)
                            
                            Text("3. User Content")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("You retain ownership of your collection data. We do not claim ownership of the cards you track or the photos you upload. However, you grant us permission to use this data to provide app functionality.")
                                .font(.body)
                            
                            Text("4. Privacy and Data")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Your privacy is important to us. Please review our Privacy Policy to understand how we collect, use, and protect your information.")
                                .font(.body)
                            
                            Text("5. Modifications")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("We reserve the right to modify these terms at any time. Continued use of the app after changes constitutes acceptance of new terms.")
                                .font(.body)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Terms")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    struct PrivacyPolicyView: View {
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Privacy Policy")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom)
                        
                        Group {
                            Text("Dati Raccolti")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("• Dati Collezione: informazioni sulle tue carte, condizioni e valori\n• Dati Utilizzo: come interagisci con l'app per migliorare le funzionalità\n• Dati Dispositivo: informazioni di base per supporto tecnico\n• Posizione: solo se autorizzata, per trovare negozi e tornei vicini")
                                .font(.body)
                            
                            Text("Utilizzo dei Dati")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("• Fornire e mantenere le funzionalità dell'app\n• Sincronizzare la collezione tra dispositivi\n• Mostrare negozi e tornei nella tua zona\n• Gestire prenotazioni e iscrizioni\n• Migliorare l'esperienza utente")
                                .font(.body)
                            
                            Text("Sicurezza")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("I tuoi dati sono protetti con crittografia in transito e a riposo. Utilizziamo protocolli standard del settore.")
                                .font(.body)
                            
                            Text("I Tuoi Diritti")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Hai il diritto di accedere, modificare o eliminare i tuoi dati personali. Contattaci per esercitare questi diritti.")
                                .font(.body)
                            
                            Text("Contatti")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Per domande sulla privacy: privacy@tcgarena.com")
                                .font(.body)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Privacy")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Fatto") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    struct FAQView: View {
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                List {
                    Section("Come Iniziare") {
                        FAQItem(
                            question: "Come aggiungo carte alla mia collezione?",
                            answer: "Tocca il '+' nella tab Collezione. Puoi cercare nel database o inserire manualmente i dettagli della carta."
                        )
                        
                        FAQItem(
                            question: "Come creo un deck?",
                            answer: "Vai nella tab Collezione, seleziona 'Deck' in alto e tocca '+' per creare un nuovo mazzo. Scegli il TCG e inizia ad aggiungere carte."
                        )
                    }
                    
                    Section("Tornei ed Eventi") {
                        FAQItem(
                            question: "Come trovo tornei vicino a me?",
                            answer: "Usa la tab Eventi per scoprire tornei nella tua zona. Puoi filtrare per TCG, data e distanza."
                        )
                        
                        FAQItem(
                            question: "Come funziona il check-in?",
                            answer: "Il giorno del torneo, vai nei dettagli dell'evento e tocca 'Check-in'. Guadagnerai punti bonus!"
                        )
                        
                        FAQItem(
                            question: "Cosa sono i punti rewards?",
                            answer: "Guadagni punti partecipando a tornei, creando deck e completando azioni nell'app. Riscattali per premi esclusivi!"
                        )
                    }
                    
                    Section("Negozi e Prenotazioni") {
                        FAQItem(
                            question: "Come prenoto una carta?",
                            answer: "Trova un negozio vicino, naviga il suo inventario e tocca 'Prenota'. Mostra il QR code al ritiro."
                        )
                        
                        FAQItem(
                            question: "Quanto tempo ho per ritirare?",
                            answer: "Le prenotazioni scadono dopo 24 ore. Riceverai notifiche di promemoria."
                        )
                    }
                    
                    Section("Problemi Tecnici") {
                        FAQItem(
                            question: "La mia collezione non si sincronizza",
                            answer: "Assicurati di essere connesso a internet. Prova a chiudere e riaprire l'app."
                        )
                        
                        FAQItem(
                            question: "L'app è lenta",
                            answer: "Collezioni molto grandi possono rallentare l'app. Prova a chiudere altre app in background."
                        )
                    }
                }
                .navigationTitle("FAQ")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Fatto") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    struct SupportView: View {
        @Environment(\.presentationMode) var presentationMode
        @State private var selectedIssue = "General"
        @State private var description = ""
        @State private var email = ""
        
        let issueTypes = ["General", "Bug Report", "Feature Request", "Account Issue", "Payment Issue"]
        
        var body: some View {
            NavigationView {
                Form {
                    Section("Contact Information") {
                        HStack {
                            Text("Email")
                            TextField("your.email@example.com", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Section("Issue Type") {
                        Picker("Issue Type", selection: $selectedIssue) {
                            ForEach(issueTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Section("Description") {
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                    
                    Section {
                        Button(action: {
                            // TODO: Submit support request
                        }) {
                            Text("Submit Request")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(email.isEmpty || description.isEmpty)
                    }
                    
                    Section("Other Ways to Reach Us") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                SwiftUI.Image(systemName: "envelope.fill")
                                    .foregroundColor(.blue)
                                Text("support@tcgarena.com")
                            }
                            
                            HStack {
                                SwiftUI.Image(systemName: "message.fill")
                                    .foregroundColor(.green)
                                Text("Live chat available 9 AM - 6 PM EST")
                            }
                            
                            HStack {
                                SwiftUI.Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("Response time: 24-48 hours")
                            }
                        }
                        .font(.subheadline)
                    }
                }
                .navigationTitle("Support")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    struct FAQItem: View {
        let question: String
        let answer: String
        @State private var isExpanded = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        Text(question)
                            .font(.body)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        SwiftUI.Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if isExpanded {
                    Text(answer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    struct ScannerSettingsView: View {
        @Environment(\.presentationMode) var presentationMode
        @State private var autoDetectEnabled = true
        @State private var flashEnabled = false
        @State private var soundEnabled = true
        @State private var selectedQuality = "High"
        
        let qualityOptions = ["Low", "Medium", "High", "Ultra"]
        
        var body: some View {
            NavigationView {
                List {
                    Section("Detection Settings") {
                        HStack {
                            Text("Auto-Detect Cards")
                            Spacer()
                            Toggle("", isOn: $autoDetectEnabled)
                        }
                        
                        HStack {
                            Text("Flash Light")
                            Spacer()
                            Toggle("", isOn: $flashEnabled)
                        }
                        
                        HStack {
                            Text("Scan Sound")
                            Spacer()
                            Toggle("", isOn: $soundEnabled)
                        }
                    }
                    
                    Section("Image Quality") {
                        Picker("Quality", selection: $selectedQuality) {
                            ForEach(qualityOptions, id: \.self) { quality in
                                Text(quality).tag(quality)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Section("Tips") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Hold your device steady")
                            Text("• Ensure good lighting")
                            Text("• Keep card flat and centered")
                            Text("• Clean camera lens for best results")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Scanner Settings")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    struct EditProfileView: View {
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject private var authService: AuthService
        @State private var displayName: String = ""
        @State private var bio = ""
        @State private var favoriteGame: TCGType = .pokemon
        @State private var isPublic = true
        @State private var isSaving = false
        
        let tcgOptions: [TCGType] = [.pokemon, .magic, .yugioh, .onePiece]
        
        init() {
            // Initialize with current user data if available
            if let user = AuthService.shared.currentUser {
                _displayName = State(initialValue: user.displayName)
                // bio is optional and not in User model, so leave empty
                _favoriteGame = State(initialValue: user.favoriteGame ?? .pokemon)
            }
        }
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with User Avatar (display only, not editable)
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Text(displayName.prefix(2).uppercased())
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Modifica Profilo")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 20)
                        
                        // Profile Information Card
                        VStack(alignment: .leading, spacing: 20) {
                            // Section Header
                            HStack(spacing: 8) {
                                SwiftUI.Image(systemName: "person.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                                Text("Informazioni Profilo")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            // Display Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nome Visualizzato")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextField("Il tuo nome", text: $displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            }
                            
                            // Bio Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bio (Opzionale)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                ZStack(alignment: .topLeading) {
                                    if bio.isEmpty {
                                        Text("Racconta qualcosa di te...")
                                            .foregroundColor(.secondary.opacity(0.6))
                                            .padding(.top, 14)
                                            .padding(.leading, 14)
                                            .font(.system(size: 16))
                                    }
                                    
                                    TextEditor(text: $bio)
                                        .font(.system(size: 16))
                                        .frame(minHeight: 80)
                                        .padding(10)
                                        .scrollContentBackground(.hidden)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color(.systemGray6))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(.systemGray4), lineWidth: 1)
                                        )
                                }
                            }

                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        // Privacy Card
                        VStack(alignment: .leading, spacing: 16) {
                            // Section Header
                            HStack(spacing: 8) {
                                SwiftUI.Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.green)
                                Text("Privacy")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Profilo Pubblico")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("Altri utenti possono vedere la tua collezione e attività")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: $isPublic)
                                    .labelsHidden()
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        // Save Button
                        Button(action: saveProfile) {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    SwiftUI.Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Salva Modifiche")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                            )
                        }
                        .disabled(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Annulla") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        
        private func saveProfile() {
            guard let userId = authService.currentUserId else {
                ToastManager.shared.showError("Impossibile salvare: utente non trovato")
                return
            }
            
            let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                ToastManager.shared.showError("Il nome non può essere vuoto")
                return
            }
            
            isSaving = true
            
            Task {
                do {
                    try await UserService.shared.updateUserProfile(
                        userId: userId,
                        displayName: trimmedName,
                        bio: bio.isEmpty ? nil : bio,
                        favoriteGame: favoriteGame
                    )
                    
                    // Refresh the user data in AuthService
                    await authService.refreshCurrentUser()
                    
                    await MainActor.run {
                        isSaving = false
                        ToastManager.shared.showSuccess("Profilo aggiornato con successo!")
                        presentationMode.wrappedValue.dismiss()
                    }
                } catch {
                    await MainActor.run {
                        isSaving = false
                        ToastManager.shared.showError("Errore nel salvataggio: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    struct ExportOptionsView: View {
        @Environment(\.presentationMode) var presentationMode
        @State private var selectedFormat = "CSV"
        @State private var includeImages = false
        @State private var includeCondition = true
        @State private var includeValues = true
        
        let formatOptions = ["CSV", "Excel", "PDF", "JSON"]
        
        var body: some View {
            NavigationView {
                List {
                    Section("Export Format") {
                        Picker("Format", selection: $selectedFormat) {
                            ForEach(formatOptions, id: \.self) { format in
                                Text(format).tag(format)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    Section("Include Data") {
                        HStack {
                            Text("Card Images")
                            Spacer()
                            Toggle("", isOn: $includeImages)
                        }
                        
                        HStack {
                            Text("Card Condition")
                            Spacer()
                            Toggle("", isOn: $includeCondition)
                        }
                        
                        HStack {
                            Text("Market Values")
                            Spacer()
                            Toggle("", isOn: $includeValues)
                        }
                    }
                    
                    Section("Export Actions") {
                        Button(action: {
                            // Handle export
                        }) {
                            HStack {
                                SwiftUI.Image(systemName: "square.and.arrow.up")
                                Text("Export Collection")
                            }
                        }
                        
                        Button(action: {
                            // Handle email export
                        }) {
                            HStack {
                                SwiftUI.Image(systemName: "envelope")
                                Text("Email Export")
                            }
                        }
                        
                        Button(action: {
                            // Handle cloud save
                        }) {
                            HStack {
                                SwiftUI.Image(systemName: "icloud.and.arrow.up")
                                Text("Save to iCloud")
                            }
                        }
                    }
                    
                    Section("Note") {
                        Text("Export includes all cards in your collection with selected data fields. Large collections may take longer to process.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .navigationTitle("Export Collection")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString) ?? Date()
    }
    
    private func formattedJoinDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}
