//
//  RewardsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI
import UIKit

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
        case all = "Tutti"
        case digital = "Digitali"
        case physical = "Fisici"
        case exclusive = "Esclusivi"

        var icon: String {
            switch self {
            case .all: return "square.grid.2x2.fill"
            case .digital: return "wifi"
            case .physical: return "shippingbox.fill"
            case .exclusive: return "crown.fill"
            }
        }
    }

    var filteredRewards: [Reward] {
        var result = rewards
        
        // Filter by Category
        if selectedCategory != .all {
            switch selectedCategory {
            case .digital: result = result.filter { $0.category == .digital }
            case .physical: result = result.filter { $0.category == .physical }
            case .exclusive: result = result.filter { $0.category == .exclusive }
            default: break
            }
        }
        
        // Filter by Partner
        if let partner = selectedPartner {
            result = result.filter { $0.partner?.id == partner.id }
        }
        
        return result
    }

    @State private var selectedTab = 0 // 0: Premi, 1: Storico, 2: Guadagna
    @State private var historySubTab = 0 // 0: Riscattati, 1: Attività
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background - Pure White
                Color.white
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("TCG LOYALTY")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(2)
                            
                            Text("Il tuo bottino.")
                                .font(.system(size: 34, weight: .heavy, design: .default))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // MARK: - Points Card (Digital Wallet Style)
                        PremiumPointsCard(points: userPoints)
                            .padding(.horizontal, 24)
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                        
                        // MARK: - Custom Tabs
                        HStack(spacing: 0) {
                            RewardTabPill(title: "Premi", isSelected: selectedTab == 0) { withAnimation { selectedTab = 0 } }
                            RewardTabPill(title: "Storico", isSelected: selectedTab == 1) { withAnimation { selectedTab = 1 } }
                            RewardTabPill(title: "Guadagna", isSelected: selectedTab == 2) { withAnimation { selectedTab = 2 } }
                        }
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                        .padding(.horizontal, 24)
                        
                        // MARK: - Content
                        if selectedTab == 0 {
                            rewardsContent
                                .transition(.opacity)
                        } else if selectedTab == 1 {
                            historyContent
                                .transition(.opacity)
                        } else {
                            HowToGetPointsView()
                                .padding(.horizontal, 24)
                                .transition(.opacity)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadData()
            }
            .confirmationDialog("Conferma Riscatto", isPresented: $showingRedeemConfirmation, presenting: rewardToRedeem) { reward in
                Button("Riscatta") {
                    redeemReward(reward)
                    rewardToRedeem = nil
                }
                Button("Annulla", role: .cancel) {
                    rewardToRedeem = nil
                }
            } message: { reward in
                VStack(spacing: 8) {
                    Text("Vuoi riscattare \(reward.name)?")
                    Text("Costo: \(reward.costPoints) punti")
                }
            }
        }
    }
    
    // MARK: - Rewards Tab Content
    var rewardsContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            
            // Partners Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Partner")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    if selectedPartner != nil {
                        Button("Tutti") { withAnimation { selectedPartner = nil } }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(partners) { partner in
                            MinimalPartnerChip(
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
                    .padding(.horizontal, 24)
                }
            }
            
            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RewardCategory.allCases, id: \.self) { category in
                        Button(action: { withAnimation { selectedCategory = category } }) {
                            HStack(spacing: 6) {
                                SwiftUI.Image(systemName: category.icon)
                                    .font(.system(size: 12))
                                Text(category.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.primary : Color.gray.opacity(0.1))
                            .foregroundColor(selectedCategory == category ? Color.white : .primary)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Grid
            if filteredRewards.isEmpty && !isLoading {
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Nessun premio trovato")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 24) {
                    ForEach(filteredRewards) { reward in
                        PremiumRewardTile(reward: reward, userPoints: userPoints) {
                            rewardToRedeem = reward
                            showingRedeemConfirmation = true
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - History Tab Content
    var historyContent: some View {
        VStack(spacing: 0) {
            // Sub-tabs
            HStack(spacing: 32) {
                Button(action: { withAnimation { historySubTab = 0 } }) {
                    VStack(spacing: 8) {
                        Text("Riscattati")
                            .font(.system(size: 16, weight: historySubTab == 0 ? .bold : .medium))
                            .foregroundColor(historySubTab == 0 ? .primary : .secondary)
                        Circle()
                            .fill(historySubTab == 0 ? Color.primary : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
                
                Button(action: { withAnimation { historySubTab = 1 } }) {
                    VStack(spacing: 8) {
                        Text("Attività")
                            .font(.system(size: 16, weight: historySubTab == 1 ? .bold : .medium))
                            .foregroundColor(historySubTab == 1 ? .primary : .secondary)
                        Circle()
                            .fill(historySubTab == 1 ? Color.primary : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            
            if historySubTab == 0 {
                RedeemedRewardsView()
            } else {
                PointsActivityView()
            }
        }
    }

    // MARK: - Data Loading
    private func loadData() {
        isLoading = true
        let group = DispatchGroup()
        
        group.enter()
        rewardsService.getAllActiveRewards { result in
            if case .success(let rewards) = result { self.rewards = rewards }
            group.leave()
        }
        
        group.enter()
        rewardsService.getUserPoints { result in
            if case .success(let points) = result { self.userPoints = points.points }
            group.leave()
        }
        
        group.enter()
        rewardsService.getAllPartners { result in
            if case .success(let partners) = result { self.partners = partners }
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
                loadData()
                ToastManager.shared.showSuccess("Premio riscattato!")
            case .failure(let error):
                ToastManager.shared.showError("Errore: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            isLoading = true
            let group = DispatchGroup()
            group.enter(); rewardsService.getAllActiveRewards { if case .success(let r) = $0 { self.rewards = r }; group.leave() }
            group.enter(); rewardsService.getUserPoints { if case .success(let p) = $0 { self.userPoints = p.points }; group.leave() }
            group.enter(); rewardsService.getAllPartners { if case .success(let p) = $0 { self.partners = p }; group.leave() }
            group.notify(queue: .main) { self.isLoading = false; continuation.resume() }
        }
    }
}

// MARK: - Premium Components

struct PremiumPointsCard: View {
    let points: Int
    
    var body: some View {
        ZStack {
            // Premium Black Background
            Color(red: 0.1, green: 0.1, blue: 0.12)
            
            // Subtle Shine Effect
            LinearGradient(
                colors: [.white.opacity(0.1), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading) {
                HStack {
                    SwiftUI.Image(systemName: "sparkles")
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2)) // Gold
                    Text("ARENA LOYALTY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.2))
                        .tracking(1)
                    Spacer()
                    SwiftUI.Image(systemName: "wave.3.right")
                        .foregroundColor(.white.opacity(0.3))
                }
                
                Spacer()
                
                Text(String(format: "%d", points))
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Punti disponibili")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(24)
        }
        .frame(height: 200)
        .cornerRadius(24)
        // Gold Border Glow
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 0.85, green: 0.65, blue: 0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

struct RewardTabPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(.systemBackground) : Color.clear)
                .clipShape(Capsule())
                .shadow(color: isSelected ? Color.black.opacity(0.1) : .clear, radius: 4, x: 0, y: 2)
        }
    }
}

struct MinimalPartnerChip: View {
    let partner: Partner
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Initial or Logo
                ZStack {
                    Circle()
                        .fill(partner.type.color.opacity(0.2))
                        .frame(width: 24, height: 24)
                    if let logo = partner.logoUrl, let url = URL(string: logo) {
                         AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { Color.clear }
                            .clipShape(Circle())
                            .frame(width: 24, height: 24)
                    } else {
                        Text(String(partner.name.prefix(1)))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(partner.type.color)
                    }
                }
                
                Text(partner.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

struct PremiumRewardTile: View {
    let reward: Reward
    let userPoints: Int
    let action: () -> Void
    
    var canRedeem: Bool { userPoints >= reward.costPoints }
    
    var body: some View {
        Button(action: canRedeem ? action : {}) {
            VStack(alignment: .leading, spacing: 0) {
                // Image - Overlay Strategy for Rigid Sizing
                Color.gray.opacity(0.1)
                    .frame(height: 140)
                    .overlay(
                        Group {
                            if let urlString = reward.imageUrl, let url = URL(string: urlString) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    case .failure:
                                        VStack {
                                            SwiftUI.Image(systemName: reward.imageIcon)
                                                .font(.system(size: 30))
                                                .foregroundColor(reward.genre.color)
                                        }
                                    case .empty:
                                        ProgressView()
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                SwiftUI.Image(systemName: reward.imageIcon)
                                    .font(.system(size: 30))
                                    .foregroundColor(reward.genre.color)
                            }
                        }
                    )
                    .clipped() // Crucial: Cuts off any overflow from scaledToFill
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(reward.name)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                        .frame(height: 40, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .leading) // Ensure full width usage
                    
                    HStack {
                        Text("\(reward.costPoints)")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(canRedeem ? .primary : .secondary)
                        Text("pts")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Status Icon
                        Circle()
                            .fill(canRedeem ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                SwiftUI.Image(systemName: canRedeem ? "arrow.right" : "lock.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(12)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(canRedeem ? 1.0 : 0.6)
    }
}

// MARK: - Redeemed View (Minimal)
struct RedeemedRewardsView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @State private var transactions: [RewardTransaction] = []
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(transactions) { transaction in
                RedeemedTransactionRow(transaction: transaction)
            }
            if transactions.isEmpty {
                Text("Nessuna attività recente")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            }
        }
        .padding(.horizontal, 24)
        .onAppear { loadTransactions() }
    }
    
    private func loadTransactions() {
        rewardsService.getTransactionHistory { result in
            if case .success(let t) = result {
                self.transactions = t.filter { $0.pointsChange < 0 && $0.rewardId != nil }
            }
        }
    }
}

struct RedeemedTransactionRow: View {
    let transaction: RewardTransaction
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: 44, height: 44)
                    SwiftUI.Image(systemName: "gift.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(formatTimestamp(transaction.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(transaction.pointsChange)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(12)
            
            // Interaction Area (Coupon / Tracking)
            if let code = transaction.voucherCode, !code.isEmpty {
                Divider().padding(.horizontal, 12)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CODICE COUPON")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(code)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Button(action: {
                        UIPasteboard.general.string = code
                        ToastManager.shared.showSuccess("Copiato!")
                    }) {
                        HStack(spacing: 4) {
                            Text("COPIA")
                                .font(.system(size: 11, weight: .bold))
                            SwiftUI.Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(12)
            } else if let tracking = transaction.trackingNumber, !tracking.isEmpty {
                Divider().padding(.horizontal, 12)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SPEDIZIONE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(tracking)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    SwiftUI.Image(systemName: "box.truck.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                }
                .padding(12)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Points Activity View
struct PointsActivityView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @State private var activities: [RewardTransaction] = []
    
    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(activities) { activity in
                 // Re-use RedeemedTransactionRow or create simple one?
                 // The user asked for "Earn" section redesign, this is "Activity" log. 
                 // Activity log usually doesn't need "Redeem" logic. 
                 // Sticking to basic row for generic activity to avoid complexity.
                 SimpleActivityRow(transaction: activity)
            }
            if activities.isEmpty {
                Text("Nessuna attività recente")
                    .foregroundColor(.secondary)
                    .padding(.top, 40)
            }
        }
        .padding(.horizontal, 24)
        .onAppear { loadActivities() }
    }
    
    private func loadActivities() {
        rewardsService.getTransactionHistory { result in
            if case .success(let t) = result {
                self.activities = t
            }
        }
    }
}

struct SimpleActivityRow: View {
    let transaction: RewardTransaction
    var body: some View {
        HStack(spacing: 16) {
             ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.05))
                    .frame(width: 44, height: 44)
                 SwiftUI.Image(systemName: transaction.pointsChange > 0 ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 18))
                    .foregroundColor(transaction.pointsChange > 0 ? .green : .primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                
                Text(formatTimestamp(transaction.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(transaction.pointsChange > 0 ? "+" : "")\(transaction.pointsChange)")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(transaction.pointsChange > 0 ? .green : .primary)
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}


// MARK: - Helpers
func formatTimestamp(_ dateString: String) -> String {
    let isoFormatter = ISO8601DateFormatter()
    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    if let date = isoFormatter.date(from: dateString) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
    
    // Fallback for non-fractional seconds
    isoFormatter.formatOptions = [.withInternetDateTime]
    if let date = isoFormatter.date(from: dateString) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
    
    return "Data sconosciuta"
}
