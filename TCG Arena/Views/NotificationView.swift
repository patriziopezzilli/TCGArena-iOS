//
//  NotificationView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var notificationService: NotificationService
    @State private var notifications: [Notification] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView()
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        loadNotifications()
                    }
                }
                .padding()
            } else if notifications.isEmpty {
                EmptyStateView(
                    icon: "bell.slash",
                    title: "No Notifications",
                    message: "You're all caught up! Check back later for updates."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(notifications) { notification in
                            NotificationCard(notification: notification) {
                                markAsRead(notification)
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        isLoading = true
        errorMessage = nil
        
        notificationService.getUserNotifications { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let notifications):
                    self.notifications = notifications
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func markAsRead(_ notification: Notification) {
        guard !notification.isRead else { return }
        
        notificationService.markAsRead(notificationId: notification.id) { result in
            if case .success = result {
                DispatchQueue.main.async {
                    if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                        var updatedNotification = notification
                        updatedNotification = Notification(
                            id: notification.id,
                            userId: notification.userId,
                            title: notification.title,
                            message: notification.message,
                            isRead: true,
                            createdAt: notification.createdAt,
                            type: notification.type
                        )
                        notifications[index] = updatedNotification
                    }
                }
            }
        }
    }
}

struct NotificationCard: View {
    let notification: Notification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    SwiftUI.Image(systemName: iconName)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(notification.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(notification.message)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                if !notification.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch notification.type {
        case "tournament": return "trophy.fill"
        case "reward": return "gift.fill"
        case "achievement": return "star.fill"
        case "friend": return "person.2.fill"
        default: return "bell.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case "tournament": return .yellow
        case "reward": return .purple
        case "achievement": return .orange
        case "friend": return .blue
        default: return .gray
        }
    }
    
    private var timeAgo: String {
        // Simple formatter, in real app use RelativeDateTimeFormatter
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        // Assuming createdAt is ISO string, need parsing logic here
        // For simplicity returning raw date prefix
        return String(notification.createdAt.prefix(10))
    }
}