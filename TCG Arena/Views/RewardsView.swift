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
                            Text("Premi")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Tabs
                        HStack(spacing: 0) {
                            CompactTabButton(
                                icon: "gift.fill",
                                label: "Premi",
                                isSelected: selectedTab == 0
                            ) {
                                withAnimation {
                                    selectedTab = 0
                                }
                            }
                            
                            CompactTabButton(
                                icon: "clock.arrow.circlepath",
                                label: "Storico",
                                isSelected: selectedTab == 1
                            ) {
                                withAnimation {
                                    selectedTab = 1
                                }
                            }
                            
                            CompactTabButton(
                                icon: "star.circle.fill",
                                label: "Guadagna",
                                isSelected: selectedTab == 2
                            ) {
                                withAnimation {
                                    selectedTab = 2
                                }
                            }
                        }
                        .padding(4)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray6))
                        )
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
                    Group {
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
                                        Text("Brand Partner")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if selectedPartner != nil {
                                            Button("Rimuovi Filtro") {
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
                                            Text("Altri partner in arrivo!")
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
                                        Text("Premi")
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
                                                Text("Nessun premio disponibile")
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
                        .refreshable {
                            // Haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            
                            // Reload data
                            await refreshData()
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity.combined(with: .move(edge: .trailing))
                        ))
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
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: selectedTab > 0 ? .trailing : .leading)),
                            removal: .opacity.combined(with: .move(edge: selectedTab > 0 ? .leading : .trailing))
                        ))
                    } else {
                        HowToGetPointsView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            ))
                    }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
                }
            }
            .navigationTitle("")
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
                    Text("Sei sicuro di voler riscattare questo premio?")
                    Text("\n\(reward.name)")
                        .font(.headline)
                    Text("\n\(reward.costPoints) punti verranno detratti dal tuo saldo.")
                    Text("\nIl tuo nuovo saldo sarà: \(userPoints - reward.costPoints) punti")
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
                ToastManager.shared.showError("Errore caricamento premi: \(error.localizedDescription)")
            }
            group.leave()
        }
        
        group.enter()
        rewardsService.getUserPoints { result in
            switch result {
            case .success(let points):
                self.userPoints = points.points
            case .failure(let error):
                ToastManager.shared.showError("Errore caricamento punti: \(error.localizedDescription)")
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
                ToastManager.shared.showError("Errore caricamento partner: \(error.localizedDescription)")
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
                ToastManager.shared.showSuccess("Premio riscattato con successo!")
            case .failure(let error):
                ToastManager.shared.showError("Errore riscatto premio: \(error.localizedDescription)")
            }
        }
    }
    
    /// Async version of loadData for pull-to-refresh
    private func refreshData() async {
        await withCheckedContinuation { continuation in
            isLoading = true
            let group = DispatchGroup()
            
            group.enter()
            rewardsService.getAllActiveRewards { result in
                if case .success(let rewards) = result {
                    self.rewards = rewards
                }
                group.leave()
            }
            
            group.enter()
            rewardsService.getUserPoints { result in
                if case .success(let points) = result {
                    self.userPoints = points.points
                }
                group.leave()
            }
            
            group.enter()
            rewardsService.getAllPartners { result in
                if case .success(let partners) = result {
                    self.partners = partners
                }
                group.leave()
            }
            
            group.notify(queue: .main) {
                self.isLoading = false
                continuation.resume()
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
                        Text("Saldo Disponibile")
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
                    Text(canRedeem ? "Riscatta Premio" : "Punti Insufficienti")
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

// MARK: - Redeemed Rewards View
struct RedeemedRewardsView: View {
    @EnvironmentObject var rewardsService: RewardsService
    @State private var transactions: [RewardTransaction] = []
    @State private var isLoading = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 40)
                } else if transactions.isEmpty {
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "gift")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Nessun premio riscattato")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(transactions) { transaction in
                        TransactionHistoryCard(transaction: transaction)
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            loadTransactions()
        }
    }
    
    private func loadTransactions() {
        isLoading = true
        rewardsService.getTransactionHistory { result in
            switch result {
            case .success(let allTransactions):
                // Filter only reward redemptions (negative points AND has rewardId)
                // This excludes tournament cancellations and other penalties
                transactions = allTransactions.filter { $0.pointsChange < 0 && $0.rewardId != nil }
            case .failure(let error):
                print("Error loading transactions: \(error)")
            }
            isLoading = false
        }
    }
}

// MARK: - Transaction History Card
struct TransactionHistoryCard: View {
    let transaction: RewardTransaction
    
    private var statusColor: Color {
        guard let status = transaction.status else { return .orange }
        switch status.color {
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        default: return .orange
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    SwiftUI.Image(systemName: "gift.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.purple)
                }
                
                // Title & Date
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.description)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(formatTimestamp(transaction.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Points spent
                Text("\(transaction.pointsChange) pts")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
            }
            
            // Status & Details Section
            VStack(alignment: .leading, spacing: 8) {
                // Status Badge
                HStack(spacing: 6) {
                    SwiftUI.Image(systemName: transaction.status?.icon ?? "clock.fill")
                        .font(.system(size: 12))
                    Text(transaction.status?.displayName ?? "In preparazione")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(statusColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(statusColor.opacity(0.12))
                .cornerRadius(6)
                
                // Voucher Code (for digital rewards)
                if let voucherCode = transaction.voucherCode, !voucherCode.isEmpty {
                    HStack(spacing: 8) {
                        SwiftUI.Image(systemName: "ticket.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Codice Voucher")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(voucherCode)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = voucherCode
                            ToastManager.shared.showSuccess("Codice copiato!")
                        }) {
                            SwiftUI.Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(12)
                    .background(Color.blue.opacity(0.08))
                    .cornerRadius(8)
                }
                
                // Tracking Number (for physical rewards)
                if let trackingNumber = transaction.trackingNumber, !trackingNumber.isEmpty {
                    HStack(spacing: 8) {
                        SwiftUI.Image(systemName: "shippingbox.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Numero Tracking")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(trackingNumber)
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = trackingNumber
                            ToastManager.shared.showSuccess("Tracking copiato!")
                        }) {
                            SwiftUI.Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(8)
                }
            }
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
        // Load activities from RewardTransaction history (the real points tracking)
        rewardsService.getTransactionHistory { result in
            switch result {
            case .success(let transactions):
                // Show ALL transactions (both positive and negative) for full activity history
                // Filter out reward redemptions (they have rewardId) since those are shown in "Premi Riscattati" tab
                activities = transactions.filter { $0.rewardId == nil }.map { transaction in
                    PointsActivity(
                        id: String(transaction.id),
                        type: getActivityTypeFromDescription(transaction.description),
                        description: transaction.description,
                        pointsChange: transaction.pointsChange,
                        timestamp: transaction.timestamp
                    )
                }
                isLoading = false
            case .failure(let error):
                print("Error loading activities: \(error)")
                isLoading = false
            }
        }
    }
    
    private func getActivityTypeFromDescription(_ description: String) -> String {
        let lowercased = description.lowercased()
        if lowercased.contains("1st place") || lowercased.contains("1° posto") {
            return "TOURNAMENT_FIRST_PLACE"
        } else if lowercased.contains("2nd place") || lowercased.contains("2° posto") {
            return "TOURNAMENT_SECOND_PLACE"
        } else if lowercased.contains("3rd place") || lowercased.contains("3° posto") {
            return "TOURNAMENT_THIRD_PLACE"
        } else if lowercased.contains("check-in") || lowercased.contains("checkin") {
            return "TOURNAMENT_CHECKIN"
        } else if lowercased.contains("registration") || lowercased.contains("iscrizione") {
            return "TOURNAMENT_JOINED"
        } else if lowercased.contains("cancellation") || lowercased.contains("cancellazione") {
            return "TOURNAMENT_UNREGISTERED"
        } else if lowercased.contains("deck") {
            return "DECK_CREATED"
        } else if lowercased.contains("reservation") || lowercased.contains("prenotazione") {
            return "RESERVATION_MADE"
        } else if lowercased.contains("wishlist") {
            return "WISHLIST_ADDED"
        } else if lowercased.contains("achievement") {
            return "ACHIEVEMENT_UNLOCKED"
        }
        return "POINTS_EARNED"
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
        case "TOURNAMENT_WON", "TOURNAMENT_FIRST_PLACE": return "🥇 1° Posto"
        case "TOURNAMENT_SECOND_PLACE": return "🥈 2° Posto"
        case "TOURNAMENT_THIRD_PLACE": return "🥉 3° Posto"
        case "TOURNAMENT_JOINED": return "Iscrizione Torneo"
        case "TOURNAMENT_CHECKIN": return "Check-in Torneo"
        case "TOURNAMENT_UNREGISTERED": return "Cancellazione"
        case "DECK_CREATED": return "Deck Creato"
        case "CARD_ADDED_TO_COLLECTION": return "Carta Aggiunta"
        case "USER_REGISTERED": return "Registrazione"
        case "REWARD_REDEEMED": return "Premio Riscattato"
        case "RESERVATION_MADE": return "Prenotazione"
        case "WISHLIST_ADDED": return "Carta in Wishlist"
        case "ACHIEVEMENT_UNLOCKED": return "Achievement"
        case "POINTS_EARNED": return "Bonus Punti"
        default: return "Attività"
        }
    }
    
    var icon: String {
        switch type {
        case "TOURNAMENT_WON", "TOURNAMENT_FIRST_PLACE": return "trophy.fill"
        case "TOURNAMENT_SECOND_PLACE": return "medal.fill"
        case "TOURNAMENT_THIRD_PLACE": return "star.fill"
        case "TOURNAMENT_JOINED": return "ticket.fill"
        case "TOURNAMENT_CHECKIN": return "checkmark.circle.fill"
        case "TOURNAMENT_UNREGISTERED": return "xmark.circle.fill"
        case "DECK_CREATED": return "rectangle.stack.badge.plus"
        case "CARD_ADDED_TO_COLLECTION": return "plus.circle.fill"
        case "USER_REGISTERED": return "person.badge.plus"
        case "REWARD_REDEEMED": return "gift.fill"
        case "RESERVATION_MADE": return "calendar.badge.plus"
        case "WISHLIST_ADDED": return "heart.fill"
        case "ACHIEVEMENT_UNLOCKED": return "star.circle.fill"
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
