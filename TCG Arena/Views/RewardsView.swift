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
    @State private var rewardToRedeem: MockReward?
    @State private var rewards: [Reward] = []

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

    var mockRewards: [MockReward] {
        [
            MockReward(
                id: 1,
                name: "Pokemon Booster Pack",
                description: "Digital booster pack for Pokemon TCG Online",
                costPoints: 500,
                category: .digital,
                type: .pokemon,
                imageIcon: "bolt.fill"
            ),
            MockReward(
                id: 2,
                name: "Magic Arena Gems",
                description: "1000 Gems for Magic: The Gathering Arena",
                costPoints: 800,
                category: .digital,
                type: .magic,
                imageIcon: "sparkles"
            ),
            MockReward(
                id: 3,
                name: "Physical Card Sleeves",
                description: "Premium card sleeves set (100 pieces)",
                costPoints: 300,
                category: .physical,
                type: .physical,
                imageIcon: "rectangle.stack"
            ),
            MockReward(
                id: 4,
                name: "Exclusive Avatar Frame",
                description: "Limited edition golden avatar frame",
                costPoints: 1500,
                category: .exclusive,
                type: .exclusive,
                imageIcon: "crown.fill"
            ),
            MockReward(
                id: 5,
                name: "Tournament Entry",
                description: "Free entry to next local tournament",
                costPoints: 1000,
                category: .physical,
                type: .tournament,
                imageIcon: "trophy.fill"
            ),
            MockReward(
                id: 6,
                name: "One Piece Card Pack",
                description: "Physical One Piece TCG booster pack",
                costPoints: 600,
                category: .physical,
                type: .onePiece,
                imageIcon: "sailboat.fill"
            )
        ]
    }

    var filteredRewards: [MockReward] {
        // For now, no filtering, return all
        return mockRewards
    }

    var body: some View {
        VStack(spacing: 0) {
            // User Points Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Points")
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("\(userPoints)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                    }

                    Spacer()

                    Button(action: {
                        showingRedeemedRewards = true
                    }) {
                        VStack(spacing: 4) {
                            SwiftUI.Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.green)

                            Text("History")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(RewardCategory.allCases, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack(spacing: 6) {
                                    SwiftUI.Image(systemName: category.icon)
                                        .font(.system(size: 14, weight: .semibold))

                                    Text(category.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(
                                            selectedCategory == category ?
                                            Color(red: 0.56, green: 0.60, blue: 0.63) :
                                            Color(.systemGray6)
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            // Rewards List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRewards) { reward in
                        RewardCard(reward: reward, userPoints: userPoints) {
                            rewardToRedeem = reward
                            showingRedeemConfirmation = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            loadData()
        }
        .sheet(isPresented: $showingRedeemedRewards) {
            RedeemedRewardsView()
        }
        .alert("Confirm Redemption", isPresented: $showingRedeemConfirmation, presenting: rewardToRedeem) { reward in
            Button("Cancel", role: .cancel) {
                rewardToRedeem = nil
            }
            Button("Redeem") {
                redeemReward(reward)
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

    private func loadData() {
        rewardsService.getAllActiveRewards { result in
            switch result {
            case .success(let rewards):
                self.rewards = rewards
            case .failure(let error):
                print("Error loading rewards: \(error)")
            }
        }
        
        rewardsService.getUserPoints { result in
            switch result {
            case .success(let points):
                self.userPoints = points.points
            case .failure(let error):
                print("Error loading points: \(error)")
            }
        }
    }

    private func redeemReward(_ reward: MockReward) {
        rewardsService.redeemReward(reward.id) { result in
            switch result {
            case .success(let response):
                print("Redeemed: \(response)")
                // Reload points
                loadData()
            case .failure(let error):
                print("Error redeeming: \(error)")
            }
        }
    }
}

struct MockReward: Identifiable {
    let id: Int
    let name: String
    let description: String
    let costPoints: Int
    let category: RewardsView.RewardCategory
    let type: RewardType
    let imageIcon: String

    enum RewardType {
        case pokemon, magic, onePiece, yugioh, digimon, physical, exclusive, tournament

        var color: Color {
            switch self {
            case .pokemon: return Color(red: 1.0, green: 0.7, blue: 0.0)
            case .magic: return Color(red: 1.0, green: 0.5, blue: 0.0)
            case .onePiece: return Color(red: 0.0, green: 0.7, blue: 1.0)
            case .yugioh: return Color(red: 0.56, green: 0.60, blue: 0.63)
            case .digimon: return Color.cyan
            case .physical: return .brown
            case .exclusive: return Color(red: 0.56, green: 0.60, blue: 0.63)
            case .tournament: return .green
            }
        }
    }
}

struct RewardCard: View {
    let reward: MockReward
    let userPoints: Int
    let onRedeem: () -> Void

    private var canRedeem: Bool {
        userPoints >= reward.costPoints
    }

    var body: some View {
        HStack(spacing: 16) {
            // Reward Icon
            ZStack {
                Circle()
                    .fill(reward.type.color.opacity(0.2))
                    .frame(width: 60, height: 60)

                SwiftUI.Image(systemName: "gift.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(reward.type.color)
            }

            // Reward Info
            VStack(alignment: .leading, spacing: 6) {
                Text(reward.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(reward.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    SwiftUI.Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))

                    Text("\(reward.costPoints) pts")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(canRedeem ? Color(red: 1.0, green: 0.7, blue: 0.0) : .secondary)
                }
            }

            Spacer()

            // Redeem Button
            Button(action: canRedeem ? onRedeem : {}) {
                Text(canRedeem ? "Redeem" : "Locked")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(canRedeem ? .white : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(canRedeem ? reward.type.color : Color(.systemGray5))
                    )
            }
            .disabled(!canRedeem)
        }
        .padding(16)
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
                .stroke(
                    canRedeem ? reward.type.color.opacity(0.3) : Color(.systemGray6),
                    lineWidth: canRedeem ? 2 : 1
                )
        )
    }
}

// MARK: - Redeemed Rewards View
struct RedeemedRewardsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var redeemedRewards: [RedeemedReward] = [
        RedeemedReward(
            name: "Magic Arena Gems",
            description: "1000 Gems for Magic: The Gathering Arena",
            redeemedDate: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            status: .delivered,
            code: "MTG-1000-GEMS-ABC123",
            type: .digital
        ),
        RedeemedReward(
            name: "Physical Card Sleeves",
            description: "Premium card sleeves set (100 pieces)",
            redeemedDate: Date().addingTimeInterval(-86400 * 7), // 1 week ago
            status: .shipping,
            trackingNumber: "1234567890",
            type: .physical
        ),
        RedeemedReward(
            name: "Exclusive Avatar Frame",
            description: "Limited edition golden avatar frame",
            redeemedDate: Date().addingTimeInterval(-86400), // 1 day ago
            status: .delivered,
            code: "AVATAR-GOLD-XYZ789",
            type: .digital
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(redeemedRewards) { reward in
                        RedeemedRewardCard(reward: reward)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Redeemed Rewards")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
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
    let type: RewardType

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

    enum RewardType {
        case digital, physical
    }
}

struct RedeemedRewardCard: View {
    let reward: RedeemedReward

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(reward.status.color.opacity(0.2))
                        .frame(width: 50, height: 50)

                    SwiftUI.Image(systemName: reward.status.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(reward.status.color)
                }

                // Reward Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(reward.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(reward.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack {
                        Text("Redeemed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        Text(DateFormatter.shortDate.string(from: reward.redeemedDate))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        // Status Badge
                        Text(reward.status.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(reward.status.color)
                            )
                    }
                }
            }

            // Code/Tracking Info (if available)
            if let code = reward.code, reward.type == .digital {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Voucher Code")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack {
                        Text(code)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray6))
                            )

                        Button("Copy") {
                            UIPasteboard.general.string = code
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let trackingNumber = reward.trackingNumber, reward.type == .physical {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tracking Number")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack {
                        Text(trackingNumber)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray6))
                            )

                        Button("Track") {
                            // TODO: Open tracking URL
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
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
                .stroke(reward.status.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Partners View
struct PartnersView: View {
    @State private var selectedTCGType: TCGType? = nil
    @State private var mockPartners = MockPartner.sampleData()

    private var filteredPartners: [MockPartner] {
        if let selectedType = selectedTCGType {
            return mockPartners.filter { $0.tcgTypes.contains(selectedType) }
        }
        return mockPartners
    }

    var body: some View {
        VStack(spacing: 0) {
            // TCG Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([nil] + TCGType.allCases, id: \.self) { tcgType in
                        Button(action: {
                            selectedTCGType = tcgType
                        }) {
                            HStack(spacing: 6) {
                                if let type = tcgType {
                                    SwiftUI.Image(systemName: type.systemIcon)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(iconColorFor(tcgType, type: type))
                                }

                                Text(tcgType?.displayName ?? "All")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(textColorFor(tcgType))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(backgroundColorFor(tcgType))
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)

            // Partners Grid
            if filteredPartners.isEmpty {
                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.56, green: 0.60, blue: 0.63).opacity(0.2),
                                        Color(red: 0.56, green: 0.60, blue: 0.63).opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color(red: 0.56, green: 0.60, blue: 0.63).opacity(0.2), radius: 12, x: 0, y: 6)

                            SwiftUI.Image(systemName: "building.2.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(Color(red: 0.56, green: 0.60, blue: 0.63))
                        }

                        VStack(spacing: 12) {
                            Text("No Partners Yet")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.primary)

                            Text("Partner offers and promotions\nwill appear here soon!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 60)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 16) {
                        ForEach(filteredPartners) { partner in
                            PartnerCard(partner: partner)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // Helper functions
    private func backgroundColorFor(_ tcgType: TCGType?) -> Color {
        guard let tcgType = tcgType else {
            return selectedTCGType == nil ? Color(red: 0.56, green: 0.60, blue: 0.63).opacity(0.8) : Color(UIColor.secondarySystemFill)
        }
        return selectedTCGType == tcgType ? tcgType.themeColor.opacity(0.8) : Color(UIColor.secondarySystemFill)
    }

    private func textColorFor(_ tcgType: TCGType?) -> Color {
        guard let tcgType = tcgType else {
            return selectedTCGType == nil ? .white : .primary
        }
        return selectedTCGType == tcgType ? .white : .primary
    }

    private func iconColorFor(_ selectedType: TCGType?, type: TCGType) -> Color {
        return selectedType == type ? .white : type.themeColor
    }
}

// MARK: - Partner Card
struct PartnerCard: View {
    let partner: MockPartner

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with logo and badge
            HStack {
                // Partner logo/icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    partner.type.color.opacity(0.8),
                                    partner.type.color.opacity(0.6)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: partner.type.color.opacity(0.3), radius: 4, x: 0, y: 2)

                    SwiftUI.Image(systemName: partner.type.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                // Type badge
                Text(partner.type.displayName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(partner.type.color)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(partner.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                Text(partner.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                // TCG Types supported
                HStack(spacing: 6) {
                    ForEach(partner.tcgTypes.prefix(3), id: \.self) { tcgType in
                        SwiftUI.Image(systemName: tcgType.systemIcon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(tcgType.themeColor)
                            .frame(width: 20, height: 20)
                            .background(
                                Circle()
                                    .fill(tcgType.themeColor.opacity(0.1))
                            )
                    }

                    if partner.tcgTypes.count > 3 {
                        Text("+\(partner.tcgTypes.count - 3)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Discount or offer
                    if let discount = partner.discount {
                        Text(discount)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }

            // Action button
            Button(action: {
                // TODO: Handle partner offer action
            }) {
                HStack {
                    Text(partner.actionText)
                        .font(.system(size: 14, weight: .semibold))

                    Spacer()

                    SwiftUI.Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    partner.type.color,
                                    partner.type.color.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: partner.type.color.opacity(0.4), radius: 4, x: 0, y: 2)
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(partner.type.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Mock Data Models
struct MockPartner: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let type: PartnerType
    let tcgTypes: [TCGType]
    let discount: String?
    let actionText: String

    enum PartnerType: CaseIterable {
        case store, brand, event, digital

        var displayName: String {
            switch self {
            case .store: return "STORE"
            case .brand: return "BRAND"
            case .event: return "EVENT"
            case .digital: return "DIGITAL"
            }
        }

        var color: Color {
            switch self {
            case .store: return .blue
            case .brand: return .purple
            case .event: return .orange
            case .digital: return .green
            }
        }

        var icon: String {
            switch self {
            case .store: return "storefront.fill"
            case .brand: return "crown.fill"
            case .event: return "calendar.badge.exclamationmark"
            case .digital: return "laptopcomputer"
            }
        }
    }

    static func sampleData() -> [MockPartner] {
        return [
            MockPartner(
                title: "GameStop Exclusive Packs",
                description: "Get exclusive Pokemon booster packs with rare alternate art cards only at GameStop stores",
                type: .store,
                tcgTypes: [.pokemon],
                discount: "-20%",
                actionText: "Shop Now"
            ),
            MockPartner(
                title: "One Piece Film Red Set",
                description: "Limited edition One Piece cards featuring characters from the blockbuster movie",
                type: .brand,
                tcgTypes: [.onePiece],
                discount: "New Release",
                actionText: "Pre-Order"
            ),
            MockPartner(
                title: "Magic 30th Anniversary",
                description: "Celebrate 30 years of Magic with special anniversary products and events",
                type: .event,
                tcgTypes: [.magic],
                discount: "Limited Time",
                actionText: "Join Event"
            ),
            MockPartner(
                title: "Yu-Gi-Oh! Master Duel",
                description: "Get digital packs in Master Duel with every physical purchase over $50",
                type: .digital,
                tcgTypes: [.yugioh],
                discount: "Bonus Packs",
                actionText: "Learn More"
            ),
            MockPartner(
                title: "Local Tournament Store",
                description: "Weekly tournaments for all TCG types. Win prizes and climb the rankings!",
                type: .store,
                tcgTypes: [.pokemon, .magic, .yugioh, .onePiece],
                discount: "Free Entry",
                actionText: "Register"
            ),
            MockPartner(
                title: "Collector's Paradise",
                description: "Premium grading services and authenticated rare cards from all major TCGs",
                type: .brand,
                tcgTypes: [.pokemon, .magic, .yugioh, .onePiece],
                discount: "-15%",
                actionText: "Grade Cards"
            ),
            MockPartner(
                title: "Spring Championship",
                description: "Regional championship tournament with $10,000 prize pool across multiple games",
                type: .event,
                tcgTypes: [.pokemon, .magic],
                discount: "$10K Prize",
                actionText: "Register Now"
            ),
            MockPartner(
                title: "TCG Arena Pro App",
                description: "Premium deck analysis tools and market insights for serious competitive players",
                type: .digital,
                tcgTypes: [.pokemon, .magic, .yugioh, .onePiece],
                discount: "1 Month Free",
                actionText: "Try Premium"
            )
        ]
    }
}