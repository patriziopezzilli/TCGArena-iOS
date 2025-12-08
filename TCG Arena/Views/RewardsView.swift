//
//  RewardsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct RewardsView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @State private var userPoints: Int = 0
    @State private var selectedCategory: RewardCategory = .all
    @State private var showingRedeemedRewards = false
    @State private var showingRedeemConfirmation = false
    @State private var rewardToRedeem: Reward?
    @State private var rewards: [Reward] = []
    @State private var partners: [Partner] = []
    @State private var selectedPartner: Partner? = nil
    @State private var isLoading = true

    enum RewardCategory: String, CaseIterable {
        case all = "All"
        case digital = "Digital"
        case physical = "Physical"
        case exclusive = "Exclusive"

        var icon: String {
            switch self {
            case .all: return "star.fill"
            case .digital: return "ipad.and.iphone"
            case .physical: return "shippingbox.fill"
            case .exclusive: return "crown.fill"
            }
        }
    }

    var filteredRewards: [Reward] {
        var result = rewards
        
        // Filter by Category
        if selectedCategory != .all {
            result = result.filter { $0.category == selectedCategory }
        }
        
        // Filter by Partner
        if let partner = selectedPartner {
            result = result.filter { $0.partner?.id == partner.id }
        }
        
        return result
    }

    @State private var selectedTab = 0 // 0: Available, 1: History, 2: Earn Points
    @State private var historySubTab = 0 // 0: Premi Riscattati, 1: Attività
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        // Title
                        HStack {
                            Text("Rewards")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Tabs
                        HStack(spacing: 12) {
                            PremiumTabButton(
                                title: "Available",
                                icon: "gift.fill",
                                isSelected: selectedTab == 0
                            ) {
                                withAnimation {
                                    selectedTab = 0
                                }
                            }
                            
                            PremiumTabButton(
                                title: "History",
                                icon: "clock.arrow.circlepath",
                                isSelected: selectedTab == 1
                            ) {
                                withAnimation {
                                    selectedTab = 1
                                }
                            }
                            
                            PremiumTabButton(
                                title: "Earn Points",
                                icon: "star.circle.fill",
                                isSelected: selectedTab == 2
                            ) {
                                withAnimation {
                                    selectedTab = 2
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                    .background(
                        Rectangle()
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                    )
                    .zIndex(1)
                    
                    // Content
                    if selectedTab == 0 {
                        ScrollView {
                            VStack(spacing: 24) {
                                // 1. Points Card
                                PointsCard(points: userPoints)
                                .padding(.horizontal, 20)
                                .padding(.top, 10)

                                // 2. Partners Section
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text("Partner Brands")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedPartner != nil {
                                            Button("Clear Filter") {
                                                withAnimation {
                                                    selectedPartner = nil
                                                }
                                            }
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 20)

                                    if partners.isEmpty && !isLoading {
                                        // Empty State for Partners
                                        VStack(spacing: 12) {
                                            SwiftUI.Image(systemName: "building.2.crop.circle")
                                                .font(.system(size: 40))
                                                .foregroundColor(.secondary.opacity(0.5))
                                            Text("More partners coming soon!")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(.secondarySystemGroupedBackground))
                                        )
                                        .padding(.horizontal, 20)
                                    } else {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 16) {
                                                ForEach(partners) { partner in
                                                    PartnerBrandCard(
                                                        partner: partner,
                                                        isSelected: selectedPartner?.id == partner.id
                                                    ) {
                                                        withAnimation {
                                                            if selectedPartner?.id == partner.id {
                                                                selectedPartner = nil
                                                            } else {
                                                                selectedPartner = partner
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }
                                }

                                // 3. Rewards Section
                                VStack(alignment: .leading, spacing: 16) {
                                    // Header & Filter
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Rewards")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                            .padding(.horizontal, 20)
                                        
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(RewardCategory.allCases, id: \.self) { category in
                                                    PremiumTabButton(
                                                        title: category.rawValue,
                                                        icon: category.icon,
                                                        isSelected: selectedCategory == category,
                                                        flexibleWidth: false
                                                    ) {
                                                        withAnimation {
                                                            selectedCategory = category
                                                        }
                                                    }
                                                    .fixedSize() // Prevent expanding in scroll view
                                                }
                                            }
                                            .padding(.horizontal, 20)
                                        }
                                    }

                                    // Rewards List
                                    LazyVStack(spacing: 20) {
                                        if filteredRewards.isEmpty && !isLoading {
                                            VStack(spacing: 16) {
                                                SwiftUI.Image(systemName: "gift")
                                                    .font(.system(size: 48))
                                                    .foregroundColor(.secondary.opacity(0.5))
                                                Text("No rewards available")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(.top, 40)
                                        } else {
                                            ForEach(filteredRewards) { reward in
                                                PremiumRewardCard(reward: reward, userPoints: userPoints) {
                                                    rewardToRedeem = reward
                                                    showingRedeemConfirmation = true
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 40)
                                }
                            }
                        }
                        .transition(.opacity)
                    } else if selectedTab == 1 {
                        // History tab with sub-tabs
                        VStack(spacing: 0) {
                            // Sub-tabs
                            HStack(spacing: 0) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        historySubTab = 0
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Text("Premi Riscattati")
                                            .font(.system(size: 14, weight: historySubTab == 0 ? .semibold : .medium))
                                            .foregroundColor(historySubTab == 0 ? .blue : .secondary)
                                        Rectangle()
                                            .fill(historySubTab == 0 ? Color.blue : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        historySubTab = 1
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Text("Attività")
                                            .font(.system(size: 14, weight: historySubTab == 1 ? .semibold : .medium))
                                            .foregroundColor(historySubTab == 1 ? .blue : .secondary)
                                        Rectangle()
                                            .fill(historySubTab == 1 ? Color.blue : Color.clear)
                                            .frame(height: 2)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .background(Color(.systemBackground))
                            
                            Divider()
                            
                            if historySubTab == 0 {
                                RedeemedRewardsView()
                            } else {
                                PointsActivityView()
                            }
                        }
                        .transition(.opacity)
                    } else {
                        HowToGetPointsView()
                            .transition(.opacity)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                loadData()
            }
            .confirmationDialog("Confirm Redemption", isPresented: $showingRedeemConfirmation, presenting: rewardToRedeem) { reward in
                Button("Redeem") {
                    redeemReward(reward)
                    rewardToRedeem = nil
                }
                Button("Cancel", role: .cancel) {
                    rewardToRedeem = nil
                }
            } message: { reward in
                VStack(spacing: 8) {
                    Text("Are you sure you want to redeem this reward?")
                    Text("\n\(reward.name)")
                        .font(.headline)
                    Text("\n\(reward.costPoints) points will be deducted from your balance.")
                    Text("\nYour new balance will be: \(userPoints - reward.costPoints) points")
                }
            }
        }
    }

    private func loadData() {
        isLoading = true
        let group = DispatchGroup()
        
        group.enter()
        rewardsService.getAllActiveRewards { result in
            switch result {
            case .success(let rewards):
                self.rewards = rewards
            case .failure(let error):
                ToastManager.shared.showError("Error loading rewards: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        rewardsService.getUserPoints { result in
            switch result {
            case .success(let points):
                self.userPoints = points.points
            case .failure(let error):
                ToastManager.shared.showError("Error loading points: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        rewardsService.getAllPartners { result in
            switch result {
            case .success(let partners):
                self.partners = partners
                print("Loaded \(partners.count) partners")
            case .failure(let error):
                ToastManager.shared.showError("Error loading partners: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            isLoading = false
        }
    }

    private func redeemReward(_ reward: Reward) {
        rewardsService.redeemReward(reward.id) { result in
            switch result {
            case .success(_):
                // Reload points
                loadData()
                ToastManager.shared.showSuccess("Reward redeemed successfully!")
            case .failure(let error):
                ToastManager.shared.showError("Error redeeming reward: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Components

struct PointsCard: View {
    let points: Int
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.7, blue: 0.0), // Gold
                    Color(red: 1.0, green: 0.5, blue: 0.0)  // Orange
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Pattern Overlay (Optional)
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 20)
                .frame(width: 200, height: 200)
                .offset(x: 100, y: -50)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available Balance")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(points)")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                HStack {
                    SwiftUI.Image(systemName: "star.fill")
                        .foregroundColor(.white)
                    Text("TCG Arena Points")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
        }
        .frame(height: 160)
        .cornerRadius(20)
        .shadow(color: Color.orange.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct PartnerBrandCard: View {
    let partner: Partner
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Logo Placeholder
                ZStack {
                    if let logoUrl = partner.logoUrl, let url = URL(string: logoUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [partner.type.color.opacity(0.2), partner.type.color.opacity(0.1)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        SwiftUI.Image(systemName: partner.type.icon)
                            .font(.system(size: 24))
                            .foregroundColor(partner.type.color)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                Text(partner.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .blue : .primary)
                    .lineLimit(1)
                    .frame(width: 80)
            }
        }
    }
}



struct PremiumRewardCard: View {
    let reward: Reward
    let userPoints: Int
    let onRedeem: () -> Void
    
    private var canRedeem: Bool {
        userPoints >= reward.costPoints
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Area
            ZStack(alignment: .topTrailing) {
                if let imageUrl = reward.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.1)
                        SwiftUI.Image(systemName: reward.imageIcon)
                            .font(.system(size: 40))
                            .foregroundColor(reward.genre.color)
                    }
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [reward.genre.color.opacity(0.1), reward.genre.color.opacity(0.05)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 160)
                        .overlay(
                            SwiftUI.Image(systemName: reward.imageIcon)
                                .font(.system(size: 40))
                                .foregroundColor(reward.genre.color)
                        )
                }
                
                // Type Badge
                HStack(spacing: 4) {
                    SwiftUI.Image(systemName: reward.type.icon)
                        .font(.system(size: 10))
                    Text(reward.type.displayName.uppercased())
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
                .padding(12)
            }
            
            // Content Area
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let partner = reward.partner {
                            Text(partner.name.uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(reward.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Cost Badge
                    HStack(spacing: 2) {
                        Text("\(reward.costPoints)")
                            .font(.system(size: 16, weight: .bold))
                        Text("pts")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                }
                
                Text(reward.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Button(action: canRedeem ? onRedeem : {}) {
                    Text(canRedeem ? "Redeem Reward" : "Not Enough Points")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(canRedeem ? reward.genre.color : Color.gray.opacity(0.5))
                        )
                }
                .disabled(!canRedeem)
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Redeemed Rewards View (Kept as is, just ensuring it compiles)
struct RedeemedRewardsView: View {
    @State private var redeemedRewards: [RedeemedReward] = [] // Should load from API in real app

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if redeemedRewards.isEmpty {
                    Text("No redemption history")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    ForEach(redeemedRewards) { reward in
                        RedeemedRewardCard(reward: reward)
                    }
                }
            }
            .padding(20)
        }
    }
}

struct RedeemedReward: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let redeemedDate: Date
    let status: RewardStatus
    let code: String?
    let trackingNumber: String?
    let type: RewardType // Using global RewardType

    init(name: String, description: String, redeemedDate: Date, status: RewardStatus, code: String? = nil, trackingNumber: String? = nil, type: RewardType) {
        self.name = name
        self.description = description
        self.redeemedDate = redeemedDate
        self.status = status
        self.code = code
        self.trackingNumber = trackingNumber
        self.type = type
    }

    enum RewardStatus: String, CaseIterable {
        case processing = "Processing"
        case shipping = "Shipping"
        case delivered = "Delivered"
        case cancelled = "Cancelled"

        var color: Color {
            switch self {
            case .processing: return .orange
            case .shipping: return .blue
            case .delivered: return .green
            case .cancelled: return .red
            }
        }

        var icon: String {
            switch self {
            case .processing: return "clock"
            case .shipping: return "shippingbox"
            case .delivered: return "checkmark.circle.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
    }
}

struct RedeemedRewardCard: View {
    let reward: RedeemedReward

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.name)
                        .font(.headline)
                    Text(DateFormatter.shortDate.string(from: reward.redeemedDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(reward.status.rawValue)
                    .font(.caption)
                    .padding(6)
                    .background(reward.status.color.opacity(0.2))
                    .foregroundColor(reward.status.color)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

// MARK: - Points Activity View
struct PointsActivityView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @State private var activities: [PointsActivity] = []
    @State private var isLoading = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if activities.isEmpty {
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Nessuna attività registrata")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(activities) { activity in
                        PointsActivityRow(activity: activity)
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            loadActivities()
        }
    }
    
    private func loadActivities() {
        isLoading = true
        // Load activities from API
        Task {
            do {
                if let userId = AuthService.shared.currentUserId {
                    let userActivities = try await UserService.shared.getUserActivities(userId: userId)
                    await MainActor.run {
                        // Convert to PointsActivity
                        activities = userActivities.compactMap { activity in
                            // Filter only activities that affect points
                            let pointsChange = getPointsForActivityType(activity.activityType)
                            if pointsChange != 0 {
                                return PointsActivity(
                                    id: String(activity.id),
                                    type: activity.activityType,
                                    description: activity.description,
                                    pointsChange: pointsChange,
                                    timestamp: activity.timestamp
                                )
                            }
                            return nil
                        }
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func getPointsForActivityType(_ type: String) -> Int {
        switch type {
        case "TOURNAMENT_WON": return 100
        case "TOURNAMENT_JOINED": return 20
        case "DECK_CREATED": return 5
        case "CARD_ADDED_TO_COLLECTION": return 1
        case "USER_REGISTERED": return 50
        case "REWARD_REDEEMED": return -1 // Indicates point deduction
        default: return 0
        }
    }
}

struct PointsActivity: Identifiable {
    let id: String
    let type: String
    let description: String
    let pointsChange: Int
    let timestamp: String
    
    var isBonus: Bool { pointsChange > 0 }
    
    var displayType: String {
        switch type {
        case "TOURNAMENT_WON": return "Vittoria Torneo"
        case "TOURNAMENT_JOINED": return "Iscrizione Torneo"
        case "DECK_CREATED": return "Deck Creato"
        case "CARD_ADDED_TO_COLLECTION": return "Carta Aggiunta"
        case "USER_REGISTERED": return "Registrazione"
        case "REWARD_REDEEMED": return "Premio Riscattato"
        default: return type
        }
    }
    
    var icon: String {
        switch type {
        case "TOURNAMENT_WON": return "trophy.fill"
        case "TOURNAMENT_JOINED": return "person.2.fill"
        case "DECK_CREATED": return "rectangle.stack.badge.plus"
        case "CARD_ADDED_TO_COLLECTION": return "plus.circle.fill"
        case "USER_REGISTERED": return "person.badge.plus"
        case "REWARD_REDEEMED": return "gift.fill"
        default: return "star.fill"
        }
    }
}

struct PointsActivityRow: View {
    let activity: PointsActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.isBonus ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                SwiftUI.Image(systemName: activity.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(activity.isBonus ? .green : .red)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.displayType)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(activity.description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(formatTimestamp(activity.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            
            Spacer()
            
            // Points
            Text(activity.isBonus ? "+\(activity.pointsChange)" : "\(activity.pointsChange)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(activity.isBonus ? .green : .red)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = isoFormatter.date(from: timestamp) else {
            return timestamp
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}
