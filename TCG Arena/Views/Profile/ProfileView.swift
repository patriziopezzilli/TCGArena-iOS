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
    @State private var showingSettings = false
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
                    VStack(spacing: 24) {
                        // Simple Profile Card
                        HStack(spacing: 16) {
                            // Profile Image
                            if let profileImageUrl = authService.currentUser?.profileImageUrl,
                               let url = URL(string: profileImageUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                        .shadow(radius: 3)
                                } placeholder: {
                                    Circle()
                                        .fill(Color(red: 0.0, green: 0.7, blue: 1.0))
                                        .frame(width: 80, height: 80)
                                        .overlay(
                                            Text(authService.currentUser?.displayName.prefix(2).uppercased() ?? "TC")
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                            } else {
                                Circle()
                                    .fill(Color(red: 0.0, green: 0.7, blue: 1.0))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(authService.currentUser?.displayName.prefix(2).uppercased() ?? "TC")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(authService.currentUser?.displayName ?? "TCG Collector")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    if let user = authService.currentUser {
                                        HStack(spacing: 4) {
                                            SwiftUI.Image(systemName: "star.fill")
                                                .font(.system(size: 12, weight: .semibold))
                                            Text("Member")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(user.isPremium ? Color(red: 1.0, green: 0.7, blue: 0.0) : Color.gray)
                                        )
                                        
                                        Text("Joined \(formattedJoinDate(user.dateJoined))")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    } else {
                                        HStack(spacing: 4) {
                                            SwiftUI.Image(systemName: "star.fill")
                                                .font(.system(size: 12, weight: .semibold))
                                            Text("Level 12")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color(red: 1.0, green: 0.7, blue: 0.0))
                                        )
                                        
                                        Text(userStats?.joinDate ?? "Joined Nov 2025")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                .fill(Color(.systemBackground))
                                .shadow(
                                    color: Color.black.opacity(UIConstants.shadowOpacity),
                                    radius: UIConstants.shadowRadius,
                                    x: 0,
                                    y: 2
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                .stroke(Color(.systemGray6), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        
                        // Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            MinimalStatCard(title: "Cards", value: "\(userStats?.totalCards ?? 247)", icon: "rectangle.stack", color: Color(red: 0.0, green: 0.7, blue: 1.0))
                            MinimalStatCard(title: "Decks", value: "\(userStats?.totalDecks ?? 12)", icon: "rectangle.stack.fill", color: Color(red: 0.8, green: 0.0, blue: 1.0))
                            MinimalStatCard(title: "Tournaments", value: "\(userStats?.totalTournaments ?? 8)", icon: "trophy", color: Color(red: 1.0, green: 0.7, blue: 0.0))
                            MinimalStatCard(title: "Wins", value: "\(userStats?.totalWins ?? 23)", icon: "checkmark.circle", color: Color(red: 0.2, green: 0.8, blue: 0.4))
                        }
                        .padding(.horizontal, 20)
                        
                        // Recent Activity Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Activity")
                                    .font(.system(size: UIConstants.sectionTitleFontSize, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            Group {
                                if isLoadingActivities {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 20)
                                } else if userActivities.isEmpty {
                                    Text("No recent activity")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 20)
                                } else {
                                    VStack(spacing: 0) {
                                        ForEach(userActivities.prefix(5), id: \.id) { activity in
                                            ActivityRow(
                                                icon: iconForActivityType(activity.activityType),
                                                title: activity.description,
                                                time: formatTimestamp(activity.timestamp),
                                                iconColor: colorForActivityType(activity.activityType)
                                            )
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            
                                            if activity.id != userActivities.prefix(5).last?.id {
                                                Divider()
                                                    .padding(.leading, 64)
                                                    .padding(.trailing, 20)
                                            }
                                        }
                                    }
                                }
                            }
                            .background(
                                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                    .fill(Color(.systemBackground))
                                    .shadow(
                                        color: Color.black.opacity(UIConstants.shadowOpacity),
                                        radius: UIConstants.shadowRadius,
                                        x: 0,
                                        y: 2
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                                    .stroke(Color(.systemGray6), lineWidth: 1)
                            )
                            .padding(.horizontal, 20)
                        }
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
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        guard let userId = authService.currentUser?.id else { return }
        
        // Load activities
        isLoadingActivities = true
        Task {
            do {
                userActivities = try await UserService.shared.getUserActivities(userId: userId)
            } catch {
                print("Failed to load user activities: \(error)")
            }
            isLoadingActivities = false
        }
        
        // Load stats
        isLoadingStats = true
        Task {
            do {
                userStats = try await UserService.shared.getUserStats(userId: userId)
            } catch {
                print("Failed to load user stats: \(error)")
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
    
    struct SettingsView: View {
        @Environment(\.presentationMode) var presentationMode
        @EnvironmentObject private var settingsService: SettingsService
        @EnvironmentObject private var authService: AuthService
        @State private var showingTerms = false
        @State private var showingPrivacy = false
        @State private var showingFAQ = false
        @State private var showingSupport = false
        @State private var showingScannerSettings = false
        @State private var showingEditProfile = false
        @State private var showingExportOptions = false
        @State private var showingSignOutAlert = false
        @State private var showingDeleteAlert = false
        @State private var notificationsEnabled = true
        
        var body: some View {
            NavigationView {
                List {
                    // App Settings Section
                    Section("App Settings") {
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
                            title: "Dark Mode",
                            icon: "moon.fill"
                        ) {
                            // Il toggle gestisce già il cambio di stato
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                Toggle("", isOn: $settingsService.isDarkMode)
                                    .labelsHidden()
                            }
                        )
                        
                        SettingsRow(
                            title: "Card Scanner",
                            icon: "camera.fill"
                        ) {
                            showingScannerSettings = true
                        }
                        
                        SettingsRow(
                            title: "Market Values",
                            icon: "chart.line.uptrend.xyaxis"
                        ) {
                            // Il toggle gestisce già il cambio di stato
                        }
                        .overlay(
                            HStack {
                                Spacer()
                                Toggle("", isOn: $settingsService.showMarketValues)
                                    .labelsHidden()
                            }
                        )
                        
                        if settingsService.showMarketValues {
                            HStack {
                                Text("Show real-time card values and portfolio tracking")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.leading, 50)
                            .padding(.top, -8)
                        }
                    }
                    
                    // Account Section
                    Section("Account") {
                        SettingsRow(
                            title: "Edit Profile",
                            icon: "person.circle.fill"
                        ) {
                            showingEditProfile = true
                        }
                        
                        SettingsRow(
                            title: "Privacy Settings",
                            icon: "lock.fill"
                        ) {
                            showingPrivacy = true
                        }
                        
                        SettingsRow(
                            title: "Export Collection",
                            icon: "square.and.arrow.up.fill"
                        ) {
                            showingExportOptions = true
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
                .sheet(isPresented: $showingScannerSettings) {
                    ScannerSettingsView()
                }
                .sheet(isPresented: $showingEditProfile) {
                    EditProfileView()
                }
                .sheet(isPresented: $showingExportOptions) {
                    ExportOptionsView()
                }
                .alert("Sign Out", isPresented: $showingSignOutAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Sign Out", role: .destructive) {
                        authService.signOut()
                    }
                } message: {
                    Text("Are you sure you want to sign out? You'll need to sign back in to access your collection.")
                }
                .alert("Delete Account", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        // Handle account deletion
                        presentationMode.wrappedValue.dismiss()
                    }
                } message: {
                    Text("This action cannot be undone. All your collection data, decks, and progress will be permanently deleted.")
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
                            Text("Information We Collect")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("• Collection Data: Information about your trading cards, including names, conditions, and values\n• Usage Data: How you interact with the app to improve functionality\n• Device Information: Basic device and app version information for support purposes")
                                .font(.body)
                            
                            Text("How We Use Information")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("• Provide and maintain app functionality\n• Sync your collection across devices\n• Provide customer support\n• Improve app features and performance")
                                .font(.body)
                            
                            Text("Data Security")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("We implement appropriate security measures to protect your personal information. Your data is encrypted in transit and at rest using industry-standard protocols.")
                                .font(.body)
                            
                            Text("Third-Party Services")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("We use secure backend services for authentication and data storage. Your data is protected with industry-standard security measures.")
                                .font(.body)
                            
                            Text("Your Rights")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("You have the right to access, update, or delete your personal information. Contact us if you wish to exercise these rights.")
                                .font(.body)
                        }
                    }
                    .padding()
                }
                .navigationTitle("Privacy")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
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
                    Section("Getting Started") {
                        FAQItem(
                            question: "How do I add cards to my collection?",
                            answer: "Tap the '+' button in the Collection tab. You can either scan a card using your camera or manually enter card details."
                        )
                        
                        FAQItem(
                            question: "How does card scanning work?",
                            answer: "Our AI-powered scanner recognizes cards from major TCGs including Pokemon, Magic, Yu-Gi-Oh, and One Piece. Simply point your camera at the card and the app will automatically identify it."
                        )
                    }
                    
                    Section("Collection Management") {
                        FAQItem(
                            question: "Can I track card conditions and grades?",
                            answer: "Yes! You can specify the condition (Mint, Near Mint, Lightly Played, etc.) and add professional grading information from services like PSA, BGS, and CGC."
                        )
                        
                        FAQItem(
                            question: "How are card values determined?",
                            answer: "We pull real-time market data from multiple sources to provide accurate pricing. Values update automatically based on current market conditions."
                        )
                    }
                    
                    Section("Tournaments & Community") {
                        FAQItem(
                            question: "How do I find local tournaments?",
                            answer: "Use the Tournament tab to discover events near you. You can filter by TCG type, date, and distance from your location."
                        )
                        
                        FAQItem(
                            question: "What are rewards points?",
                            answer: "Earn points by participating in the community, attending tournaments, and completing collection milestones. Redeem points for digital content and physical prizes."
                        )
                    }
                    
                    Section("Technical Issues") {
                        FAQItem(
                            question: "My collection isn't syncing",
                            answer: "Make sure you're signed in and have an internet connection. Try closing and reopening the app, or contact support if the issue persists."
                        )
                        
                        FAQItem(
                            question: "The app is running slowly",
                            answer: "Large collections may cause performance issues on older devices. Try closing other apps and ensure you have sufficient storage space available."
                        )
                    }
                }
                .navigationTitle("FAQ")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    trailing: Button("Done") {
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
        @State private var favoriteGame: String = ""
        @State private var isPublic = true
        @State private var selectedItem: PhotosPickerItem? = nil
        @State private var selectedImageData: Data? = nil
        @State private var isUploadingImage = false
        @State private var showingImagePicker = false
        
        let tcgOptions = ["Pokemon", "Magic: The Gathering", "Yu-Gi-Oh!", "One Piece"]
        
        init() {
            // Initialize with current user data if available
            if let user = AuthService.shared.currentUser {
                _displayName = State(initialValue: user.displayName)
                _favoriteGame = State(initialValue: user.favoriteGame?.rawValue.capitalized ?? "Pokemon")
            }
        }
        
        var body: some View {
            NavigationView {
                Form {
                    Section("Profile Picture") {
                        HStack {
                            Spacer()
                            VStack {
                                if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                                    SwiftUI.Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                                } else if let profileImageUrl = authService.currentUser?.profileImageUrl,
                                          let url = URL(string: profileImageUrl) {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 2))
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Text(authService.currentUser?.displayName.prefix(2).uppercased() ?? "TC")
                                                    .font(.system(size: 28, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Text(displayName.prefix(2).uppercased())
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                if isUploadingImage {
                                    ProgressView()
                                        .padding(.top, 8)
                                }
                            }
                            Spacer()
                        }
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Text("Change Profile Picture")
                                .foregroundColor(.blue)
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    selectedImageData = data
                                }
                            }
                        }
                    }
                    
                    Section("Profile Information") {
                        HStack {
                            Text("Display Name")
                            TextField("Display Name", text: $displayName)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Bio")
                            TextEditor(text: $bio)
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        }
                        
                        Picker("Favorite TCG", selection: $favoriteGame) {
                            ForEach(tcgOptions, id: \.self) { game in
                                Text(game).tag(game)
                            }
                        }
                    }
                    
                    Section("Privacy") {
                        HStack {
                            Text("Public Profile")
                            Spacer()
                            Toggle("", isOn: $isPublic)
                        }
                        
                        Text("When enabled, other users can view your collection and activity")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Section {
                        Button(action: {
                            // Upload profile image if selected
                            if let imageData = selectedImageData {
                                isUploadingImage = true
                                ImageService.shared.uploadProfileImage(imageData: imageData, filename: "profile.jpg") { result in
                                    switch result {
                                    case .success(let image):
                                        print("Profile image uploaded successfully: \(image.url)")
                                        
                                        // Update user profile image URL via API
                                        let updateData = ["profileImageUrl": image.url]
                                        APIClient.shared.request(endpoint: "/api/users/\(authService.currentUser?.id ?? 0)/profile-image", 
                                                               method: .put, 
                                                               body: image.url.data(using: .utf8), 
                                                               headers: ["Content-Type": "text/plain"]) { result in
                                            switch result {
                                            case .success(_):
                                                print("Profile image URL updated successfully")
                                                // Refresh user data
                                                Task {
                                                    await authService.refreshCurrentUser()
                                                }
                                            case .failure(let error):
                                                print("Failed to update profile image URL: \(error.localizedDescription)")
                                            }
                                            isUploadingImage = false
                                        }
                                    case .failure(let error):
                                        print("Failed to upload profile image: \(error.localizedDescription)")
                                        isUploadingImage = false
                                    }
                                }
                            }
                            
                            // Save profile changes
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .disabled(isUploadingImage)
                    }
                }
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
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
    
    private func formattedJoinDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}
