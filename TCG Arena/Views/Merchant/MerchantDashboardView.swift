//
//  MerchantDashboardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct MerchantDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var tournamentService: TournamentService
    
    @State private var selectedTab: MerchantTab = .overview
    
    enum MerchantTab: String, CaseIterable {
        case overview = "Overview"
        case inventory = "Inventory"
        case reservations = "Reservations"
        case tournaments = "Tournaments"
        case requests = "Requests"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .inventory: return "square.stack.3d.up.fill"
            case .reservations: return "qrcode"
            case .tournaments: return "trophy.fill"
            case .requests: return "bubble.left.and.bubble.right.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                merchantHeader
                
                // Tab Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(MerchantTab.allCases, id: \.self) { tab in
                            TabButton(
                                title: tab.rawValue,
                                icon: tab.icon,
                                isSelected: selectedTab == tab
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTab = tab
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                
                Divider()
                
                // Content
                TabView(selection: $selectedTab) {
                    MerchantOverviewView()
                        .tag(MerchantTab.overview)
                    
                    InventoryListView()
                        .tag(MerchantTab.inventory)
                    
                    ReservationListView()
                        .tag(MerchantTab.reservations)
                    
                    TournamentManagementView()
                        .tag(MerchantTab.tournaments)
                    
                    RequestManagementView()
                        .tag(MerchantTab.requests)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    private var merchantHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Merchant Portal")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                if let user = authService.currentUser {
                    Text(user.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Notifications Badge
            ZStack(alignment: .topTrailing) {
                SwiftUI.Image(systemName: "bell.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AdaptiveColors.brandPrimary)
                
                if requestService.activeRequests.count > 0 {
                    Circle()
                        .fill(AdaptiveColors.error)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Text("\(min(requestService.activeRequests.count, 9))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 8, y: -8)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : AdaptiveColors.brandPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AdaptiveColors.brandPrimary : AdaptiveColors.brandPrimary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Merchant Overview
struct MerchantOverviewView: View {
    @EnvironmentObject var inventoryService: InventoryService
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var tournamentService: TournamentService
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quick Stats
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Stats")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        StatCard(
                            title: "Inventory",
                            value: "\(inventoryService.inventory.count)",
                            icon: "square.stack.3d.up.fill",
                            color: AdaptiveColors.brandPrimary
                        )
                        
                        StatCard(
                            title: "Active Reservations",
                            value: "\(reservationService.activeReservations.count)",
                            icon: "qrcode",
                            color: AdaptiveColors.brandSecondary
                        )
                        
                        StatCard(
                            title: "Pending Requests",
                            value: "\(requestService.activeRequests.count)",
                            icon: "bubble.left.and.bubble.right.fill",
                            color: AdaptiveColors.success
                        )
                        
                        StatCard(
                            title: "Active Tournaments",
                            value: "\(tournamentService.tournaments.filter { $0.status == .inProgress }.count)",
                            icon: "trophy.fill",
                            color: AdaptiveColors.warning
                        )
                    }
                }
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Activity")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("View All")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AdaptiveColors.brandPrimary)
                        }
                    }
                    
                    if reservationService.activeReservations.isEmpty &&
                        requestService.activeRequests.isEmpty {
                        EmptyStateView(
                            icon: "tray",
                            title: "No Recent Activity",
                            message: "Your recent reservations and requests will appear here"
                        )
                    } else {
                        VStack(spacing: 12) {
                            // Show recent reservations
                            ForEach(reservationService.activeReservations.prefix(3)) { reservation in
                                ActivityRow(
                                    icon: "qrcode",
                                    title: "New Reservation",
                                    subtitle: reservation.card?.name ?? "Card",
                                    time: reservation.createdAt,
                                    color: AdaptiveColors.brandSecondary
                                )
                            }
                            
                            // Show recent requests
                            ForEach(requestService.activeRequests.prefix(3)) { request in
                                ActivityRow(
                                    icon: request.type.icon,
                                    title: request.type.displayName,
                                    subtitle: request.title,
                                    time: request.createdAt,
                                    color: Color(request.type.color)
                                )
                            }
                        }
                    }
                }
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        QuickActionButton(
                            icon: "plus.circle.fill",
                            title: "Add Inventory Item",
                            color: AdaptiveColors.brandPrimary
                        ) {
                            // Navigate to add inventory
                        }
                        
                        QuickActionButton(
                            icon: "qrcode.viewfinder",
                            title: "Scan Reservation QR",
                            color: AdaptiveColors.brandSecondary
                        ) {
                            // Open QR scanner
                        }
                        
                        QuickActionButton(
                            icon: "trophy.fill",
                            title: "Create Tournament",
                            color: AdaptiveColors.success
                        ) {
                            // Navigate to create tournament
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: Date
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(timeAgo(from: time))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        SwiftUI.Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(color)
                    )
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.backgroundSecondary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MerchantDashboardView()
        .environmentObject(AuthService())
        .environmentObject(InventoryService())
        .environmentObject(ReservationService())
        .environmentObject(RequestService())
        .environmentObject(TournamentService.shared)
}
