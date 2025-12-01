//
//  RequestManagementView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct RequestManagementView: View {
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedFilter: RequestStatusFilter = .pending
    @State private var selectedRequest: MerchantRequest?
    
    enum RequestStatusFilter: String, CaseIterable {
        case pending = "Pending"
        case accepted = "Accepted"
        case completed = "Completed"
        case rejected = "Rejected"
        
        var status: RequestStatus {
            switch self {
            case .pending: return .pending
            case .accepted: return .accepted
            case .completed: return .completed
            case .rejected: return .rejected
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return AdaptiveColors.warning
            case .accepted: return AdaptiveColors.brandPrimary
            case .completed: return AdaptiveColors.success
            case .rejected: return AdaptiveColors.error
            }
        }
    }
    
    var filteredRequests: [MerchantRequest] {
        requestService.merchantRequests.filter { $0.status == selectedFilter.status }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("\(filteredRequests.count) Requests")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Unread badge
                if requestService.unreadCount > 0 {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AdaptiveColors.error)
                            .frame(width: 8, height: 8)
                        
                        Text("\(requestService.unreadCount) new")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AdaptiveColors.error)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(AdaptiveColors.error.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Status Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RequestStatusFilter.allCases, id: \.self) { filter in
                        let count = requestService.merchantRequests.filter { $0.status == filter.status }.count
                        
                        StatusFilterButton(
                            title: filter.rawValue,
                            count: count,
                            isSelected: selectedFilter == filter,
                            color: filter.color
                        ) {
                            withAnimation {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(AdaptiveColors.backgroundSecondary)
            
            Divider()
            
            // Requests List
            if filteredRequests.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No \(selectedFilter.rawValue) Requests",
                    message: "Customer requests will appear here"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredRequests) { request in
                            RequestRow(request: request) {
                                selectedRequest = request
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(AdaptiveColors.backgroundPrimary)
        .sheet(item: $selectedRequest) { request in
            RequestDetailView(request: request)
        }
        .onAppear {
            loadRequests()
        }
    }
    
    private func loadRequests() {
        guard let shopId = authService.currentUser?.shopId else { return }
        
        Task {
            await requestService.loadMerchantRequests(shopId: shopId)
        }
    }
}

// MARK: - Request Row
struct RequestRow: View {
    let request: MerchantRequest
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(alignment: .top) {
                    // Type Icon
                    Circle()
                        .fill(Color(request.type.color).opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: request.type.icon)
                                .font(.system(size: 18))
                                .foregroundColor(Color(request.type.color))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(request.type.displayName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(request.type.color))
                                )
                            
                            if request.hasUnreadMessages {
                                Circle()
                                    .fill(AdaptiveColors.error)
                                    .frame(width: 8, height: 8)
                            }
                            
                            Spacer()
                            
                            Text(request.status.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(request.status.color))
                                )
                        }
                        
                        Text(request.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 11))
                            
                            Text(request.user?.displayName ?? "Unknown User")
                                .font(.system(size: 13))
                            
                            Text("•")
                            
                            Text(timeAgo(from: request.createdAt))
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                // Preview of description
                if let description = request.description {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Quick Actions for pending requests
                if request.status == .pending {
                    Divider()
                    
                    HStack(spacing: 12) {
                        QuickActionButton(
                            icon: "checkmark.circle.fill",
                            text: "Accept",
                            color: AdaptiveColors.success
                        ) {
                            // Accept request
                        }
                        
                        QuickActionButton(
                            icon: "xmark.circle.fill",
                            text: "Reject",
                            color: AdaptiveColors.error
                        ) {
                            // Reject request
                        }
                    }
                }
                
                // Message count
                if request.messageCount > 0 {
                    Divider()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 12))
                        
                        Text("\(request.messageCount) message\(request.messageCount > 1 ? "s" : "")")
                            .font(.system(size: 13, weight: .medium))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AdaptiveColors.brandPrimary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.backgroundSecondary)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(request.hasUnreadMessages ? AdaptiveColors.error.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = hours / 24
        
        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else {
            let minutes = Int(interval / 60)
            return minutes > 0 ? "\(minutes)m ago" : "Just now"
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let text: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(text)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(color)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RequestManagementView()
        .environmentObject(RequestService())
        .environmentObject(AuthService())
}
