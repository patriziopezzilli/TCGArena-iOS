//
//  ShopRequestsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/6/25.
//

import SwiftUI

struct ShopRequestsView: View {
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var authService: AuthService
    let shopId: String
    let shopName: String
    
    @State private var isLoading = true
    @State private var selectedRequest: CustomerRequest?
    
    private var shopRequests: [CustomerRequest] {
        requestService.requests.filter { String($0.shopId ?? 0) == shopId }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            if isLoading {
                loadingView
            } else if shopRequests.isEmpty {
                emptyStateView
            } else {
                requestsListView
            }
        }
        .background(Color.gray.opacity(0.1).ignoresSafeArea())
        .navigationTitle("Requests to \(shopName)")
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
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Caricamento richieste...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            SwiftUI.Image(systemName: "envelope.open")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(.secondary)
            
            Text("Nessuna Richiesta")
                .font(.headline)
            
            Text("Non hai inviato richieste a \(shopName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var requestsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(shopRequests) { request in
                    RequestCard(request: request)
                        .onTapGesture {
                            selectedRequest = request
                        }
                }
            }
            .padding(20)
        }
    }
    
    private func loadRequests() async {
        guard let userId = authService.currentUserId else {
            isLoading = false
            return
        }
        
        do {
            _ = try await requestService.getUserRequests(userId: String(userId))
            isLoading = false
        } catch {
            isLoading = false
            // Handle error - could add error state later
        }
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
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12, height: 12)
                    
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
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
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
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "gray": return Color(.systemGray)
        default: return Color(.systemGray)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Caricamento messaggi...")
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Request Header
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(request.title)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(statusColor)
                                            .frame(width: 8, height: 8)
                                        
                                        Text(request.status.displayName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(statusColor)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(statusColor.opacity(0.1))
                                    .cornerRadius(20)
                                }
                                
                                if let description = request.description {
                                    Text(description)
                                        .font(.system(size: 16))
                                        .foregroundColor(.secondary)
                                        .lineSpacing(4)
                                }
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 6) {
                                        SwiftUI.Image(systemName: "storefront.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                            .foregroundColor(.secondary)
                                        
                                        Text(request.shopName ?? "Unknown Shop")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 6) {
                                        SwiftUI.Image(systemName: "clock")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 14, height: 14)
                                            .foregroundColor(.secondary)
                                        
                                        Text(formatDate(request.createdAt))
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            // Messages Section
                            if messages.isEmpty {
                                VStack(spacing: 16) {
                                SwiftUI.Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    
                                    Text("Nessun messaggio")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Inizia la conversazione con il negozio")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 40)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(messages) { message in
                                        ShopMessageBubble(message: message)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // Message Input
                    if request.isActive {
                        VStack(spacing: 0) {
                            Divider()
                            
                            HStack(spacing: 12) {
                                TextField("Type a message...", text: $newMessage)
                                    .textFieldStyle(.roundedBorder)
                                    .disabled(isSending)
                                
                                Button(action: sendMessage) {
                                    if isSending {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        SwiftUI.Image(systemName: "paperplane.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .cornerRadius(22)
                                .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                        }
                    }
                }
            }
            .navigationTitle("Dettagli Richiesta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                
                if request.isActive {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Annulla Richiesta") {
                            showCancelAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Annulla Richiesta", isPresented: $showCancelAlert) {
                Button("Annulla", role: .destructive) {
                    Task {
                        await cancelRequest()
                    }
                }
                Button("Mantieni", role: .cancel) {}
            } message: {
                Text("Sei sicuro di voler annullare questa richiesta? L'azione non può essere annullata.")
            }
            .task {
                await loadMessages()
            }
        }
    }
    
    private func loadMessages() async {
        messages = (try? await requestService.getMessages(requestId: request.id)) ?? []
        isLoading = false
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let messageText = newMessage
        newMessage = ""
        
        Task {
            isSending = true
            do {
                try await requestService.sendMessage(requestId: request.id, content: messageText)
                await loadMessages() // Reload messages to show the new one
            } catch {
                newMessage = messageText // Restore message on error
                // Handle error
            }
            isSending = false
        }
    }
    
    private func cancelRequest() async {
        do {
            try await requestService.cancelRequest(id: request.id)
            dismiss()
        } catch {
            // Handle error
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Shop Message Bubble
private struct ShopMessageBubble: View {
    let message: RequestMessage
    
    private var isFromCurrentUser: Bool {
        // User messages go on the right, shop messages on the left
        message.senderType == .user
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(isFromCurrentUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isFromCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                    .cornerRadius(18)
                
                Text(formatDate(message.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isFromCurrentUser { Spacer() }
        }
        .padding(.horizontal, 20)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
