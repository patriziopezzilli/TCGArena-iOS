//
//  UserRequestsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/3/25.
//

import SwiftUI

struct UserRequestsView: View {
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedFilter: RequestFilter = .all
    @State private var isLoading = true
    @State private var selectedRequest: CustomerRequest?
    
    enum RequestFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        
        var icon: String {
            switch self {
            case .all: return "tray.full.fill"
            case .active: return "clock.fill"
            case .completed: return "checkmark.circle.fill"
            }
        }
    }
    
    private var filteredRequests: [CustomerRequest] {
        switch selectedFilter {
        case .all:
            return requestService.requests
        case .active:
            return requestService.requests.filter { $0.isActive }
        case .completed:
            return requestService.requests.filter { !$0.isActive }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            if isLoading {
                loadingView
            } else if filteredRequests.isEmpty {
                emptyStateView
            } else {
                requestsListView
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("My Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadRequests()
        }
        .refreshable {
            await loadRequests()
        }
        .sheet(item: $selectedRequest) { request in
            RequestDetailView(request: request)
                .environmentObject(requestService)
                .environmentObject(authService)
        }
    }
    
    // MARK: - Filter Tabs
    private var filterTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RequestFilter.allCases, id: \.self) { filter in
                    RequestFilterChip(
                        title: filter.rawValue,
                        icon: filter.icon,
                        count: countFor(filter),
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
    }
    
    private func countFor(_ filter: RequestFilter) -> Int {
        switch filter {
        case .all: return requestService.requests.count
        case .active: return requestService.requests.filter { $0.isActive }.count
        case .completed: return requestService.requests.filter { !$0.isActive }.count
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading requests...")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.1))
                    .frame(width: 120, height: 120)
                
                SwiftUI.Image(systemName: "envelope.open")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color(red: 0.0, green: 0.5, blue: 1.0))
            }
            
            VStack(spacing: 12) {
                Text(selectedFilter == .all ? "No Requests Yet" : "No \(selectedFilter.rawValue) Requests")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("When you send requests to shops, they'll appear here so you can track their progress and communicate with merchants.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Requests List
    private var requestsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredRequests) { request in
                    RequestCard(request: request)
                        .onTapGesture {
                            selectedRequest = request
                        }
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Load Requests
    private func loadRequests() async {
        guard let userId = authService.currentUserId else {
            isLoading = false
            return
        }
        
        do {
            _ = try await requestService.getUserRequests(userId: String(userId))
        } catch {
            print("Error loading requests: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Request Filter Chip
private struct RequestFilterChip: View {
    let title: String
    let icon: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? Color(red: 0.0, green: 0.5, blue: 1.0) : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.2) : Color.secondary.opacity(0.15))
                        )
                }
            }
            .foregroundColor(isSelected ? Color(red: 0.0, green: 0.5, blue: 1.0) : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color(red: 0.0, green: 0.5, blue: 1.0).opacity(0.1) : Color.clear)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color(red: 0.0, green: 0.5, blue: 1.0) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Request Card
private struct RequestCard: View {
    let request: CustomerRequest
    
    private var statusColor: Color {
        switch request.status.color {
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.0) // Warm orange
        case "blue": return Color(red: 0.0, green: 0.5, blue: 1.0) // Bright blue
        case "red": return Color(red: 1.0, green: 0.3, blue: 0.3) // Soft red
        case "green": return Color(red: 0.2, green: 0.8, blue: 0.4) // Fresh green
        case "gray": return Color(.systemGray)
        default: return Color(.systemGray)
        }
    }
    
    private var typeColor: Color {
        switch request.type.color {
        case "blue": return Color(red: 0.0, green: 0.5, blue: 1.0)
        case "green": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.0)
        case "purple": return Color(red: 0.6, green: 0.4, blue: 1.0)
        case "cyan": return Color(red: 0.0, green: 0.8, blue: 0.8)
        case "gray": return Color(.systemGray)
        default: return Color(.systemGray)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Type Badge
                HStack(spacing: 6) {
                    SwiftUI.Image(systemName: request.type.icon)
                        .font(.system(size: 12, weight: .semibold))
                    
                    Text(request.type.displayName)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(typeColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(typeColor.opacity(0.12))
                .cornerRadius(6)
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    
                    Text(request.status.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(statusColor)
                }
            }
            
            // Title
            Text(request.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            // Shop Info
            if let shopName = request.shopName {
                HStack(spacing: 8) {
                    SwiftUI.Image(systemName: "storefront.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Text(shopName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            // Footer
            HStack {
                SwiftUI.Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text(timeAgo(from: request.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Request Detail View
private struct RequestDetailView: View {
    let request: CustomerRequest
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var authService: AuthService
    
    @State private var messages: [RequestMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var showCancelAlert = false
    
    private var statusColor: Color {
        switch request.status.color {
        case "orange": return .orange
        case "blue": return .indigo
        case "red": return .red
        case "green": return .green
        case "gray": return .gray
        default: return .gray
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Request Info Header
                requestInfoHeader
                
                Divider()
                
                // Messages
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    messagesView
                }
                
                // Message Input (only for active requests)
                if request.isActive {
                    messageInputView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.indigo)
                }
                
                if request.canBeCancelled {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive, action: { showCancelAlert = true }) {
                                Label("Cancel Request", systemImage: "xmark.circle")
                            }
                        } label: {
                            SwiftUI.Image(systemName: "ellipsis.circle")
                                .foregroundColor(.indigo)
                        }
                    }
                }
            }
            .task {
                await loadDetails()
            }
            .confirmationDialog("Cancel Request?", isPresented: $showCancelAlert) {
                Button("Cancel Request", role: .destructive) {
                    cancelRequest()
                }
                Button("Keep", role: .cancel) { }
            } message: {
                Text("Are you sure you want to cancel this request?")
            }
        }
    }
    
    // MARK: - Request Info Header
    private var requestInfoHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            HStack {
                HStack(spacing: 6) {
                    SwiftUI.Image(systemName: request.status.icon)
                        .font(.system(size: 14))
                    
                    Text(request.status.displayName)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(statusColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(statusColor.opacity(0.12))
                .cornerRadius(8)
                
                Spacer()
                
                Text(request.type.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(request.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            // Description
            if let description = request.description {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            // Shop Info
            if let shopName = request.shopName {
                HStack(spacing: 10) {
                    SwiftUI.Image(systemName: "storefront.fill")
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shopName)
                            .font(.system(size: 16, weight: .semibold))
                        if let shopAddress = request.shopAddress {
                            Text(shopAddress)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Messages View
    private var messagesView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if messages.isEmpty {
                    VStack(spacing: 12) {
                        SwiftUI.Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        
                        Text("No messages yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text("The merchant will respond here")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(messages) { message in
                        // Compare senderId with current user ID for proper alignment
                        let isFromMe = message.senderId == String(authService.currentUserId ?? 0)
                        MessageBubble(message: message, isFromCurrentUser: isFromMe)
                    }
                }
            }
            .padding(16)
        }
        .refreshable {
            await loadMessages()
        }
    }
    
    // MARK: - Message Input
    private var messageInputView: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $newMessage)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(20)
            
            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(newMessage.isEmpty ? Color.gray : Color.indigo)
                        .frame(width: 40, height: 40)
                    
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        SwiftUI.Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Actions
    private func loadDetails() async {
        do {
            let request = try await requestService.getRequestDetail(id: request.id)
            let loadedMessages = try await requestService.getMessages(requestId: request.id)
            await MainActor.run {
                messages = loadedMessages
            }
            // Mark as read if there are unread messages
            if request.hasUnreadMessages {
                try await requestService.markAsRead(requestId: request.id)
            }
        } catch {
            print("Error loading request details: \(error)")
        }
        isLoading = false
    }
    
    private func loadMessages() async {
        do {
            let loadedMessages = try await requestService.getMessages(requestId: request.id)
            await MainActor.run {
                messages = loadedMessages
            }
        } catch {
            print("Error loading messages: \(error)")
        }
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSending = true
        let messageText = newMessage
        newMessage = ""
        
        Task {
            do {
                _ = try await requestService.sendMessage(requestId: request.id, content: messageText)
                await MainActor.run {
                    isSending = false
                    // Reload messages to show the new message
                    Task { await loadMessages() }
                }
            } catch {
                await MainActor.run {
                    newMessage = messageText // Restore message on error
                    isSending = false
                }
            }
        }
    }
    
    private func cancelRequest() {
        Task {
            do {
                _ = try await requestService.cancelRequest(id: request.id)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error cancelling request: \(error)")
            }
        }
    }
}

// MARK: - Message Bubble
private struct MessageBubble: View {
    let message: RequestMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isFromCurrentUser ? Color.indigo : Color(.tertiarySystemBackground))
                    )
                
                Text(formatTime(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser { Spacer() }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        UserRequestsView()
            .environmentObject(RequestService())
            .environmentObject(AuthService())
    }
}
