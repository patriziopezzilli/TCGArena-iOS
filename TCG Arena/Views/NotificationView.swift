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
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading notifications...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if notifications.isEmpty {
                    VStack(spacing: 20) {
                        SwiftUI.Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No notifications yet")
                            .font(.headline)
                        Text("You'll see updates about tournaments, rewards, and more here.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List(notifications) { notification in
                        NotificationRow(notification: notification)
                            .onTapGesture {
                                markAsRead(notification)
                            }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                sendTestPushNotification()
            }) {
                SwiftUI.Image(systemName: "bell.badge")
                    .foregroundColor(.blue)
            })
            .onAppear {
                loadNotifications()
            }
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
        notificationService.markAsRead(notificationId: notification.id) { result in
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index] = Notification(id: notification.id, userId: notification.userId, title: notification.title, message: notification.message, isRead: true, createdAt: notification.createdAt, type: notification.type)
            }
        }
    }
    
    private func sendTestPushNotification() {
        notificationService.sendTestPushNotification { result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    // Reload notifications to show the new test notification
                    loadNotifications()
                case .failure(let error):
                    self.errorMessage = "Failed to send test notification: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct NotificationRow: View {
    let notification: Notification
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: iconForType(notification.type))
                .font(.system(size: 20))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(notification.isRead ? .secondary : .primary)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(formatDate(notification.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func iconForType(_ type: String?) -> String {
        switch type {
        case "tournament": return "trophy"
        case "reward": return "gift"
        case "achievement": return "star"
        case "friend": return "person.2"
        default: return "bell"
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // Simple date formatting - in real app, use proper DateFormatter
        return String(dateString.prefix(10)) // Just show date part
    }
}

#Preview {
    NotificationView()
        .environmentObject(NotificationService.shared)
}