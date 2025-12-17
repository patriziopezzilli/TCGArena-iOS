//
//  PlayerRequestDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct PlayerRequestDetailView: View {
    @EnvironmentObject var requestService: RequestService
    @Environment(\.dismiss) var dismiss
    
    let request: CustomerRequest
    let onUpdate: () -> Void
    
    @State private var messages: [RequestMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = false
    @State private var isSendingMessage = false
    @State private var errorMessage: String?
    @State private var showingCancelConfirmation = false
    
    var canSendMessages: Bool {
        request.status == .pending || request.status == .accepted
    }
    
    var canCancel: Bool {
        request.status == .pending || request.status == .accepted
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Request Header
            requestHeader
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages.sorted(by: { $0.createdAt < $1.createdAt })) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message Input
            if canSendMessages {
                messageInputSection
            }
            
            // Error Message
            if let error = errorMessage {
                Text(error)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Chiudi") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: loadMessages) {
                        SwiftUI.Image(systemName: "arrow.clockwise")
                    }
                    
                    if canCancel {
                        Button(action: { showingCancelConfirmation = true }) {
                            SwiftUI.Image(systemName: "xmark.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "Annulla Richiesta",
            isPresented: $showingCancelConfirmation,
            titleVisibility: .visible
        ) {
            Button("Annulla Richiesta", role: .destructive) {
                cancelRequest()
            }
        } message: {
            Text("Sei sicuro di voler annullare questa richiesta?")
        }
        .onAppear {
            loadMessages()
            markAsRead()
        }
    }
    
    private var requestHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.type.displayName)
                        .font(.headline)
                    
                    Text(request.title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Badge (inline)
                Text(request.status.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(statusColor)
                    )
            }
            
            if let shopName = request.shopName {
                HStack(spacing: 6) {
                    SwiftUI.Image(systemName: "storefront.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(shopName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let desc = request.description, !desc.isEmpty {
                Text(desc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 6) {
                SwiftUI.Image(systemName: "calendar")
                    .font(.caption)
                
                Text("Creata \(request.createdAt, style: .date)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    private var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .accepted: return .blue
        case .completed: return .green
        case .rejected, .cancelled: return .red
        }
    }
    
    private var messageInputSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: sendMessage) {
                    SwiftUI.Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(newMessage.isEmpty ? .gray : Color(AdaptiveColors.primary))
                }
                .disabled(newMessage.isEmpty || isSendingMessage)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }
    
    private func loadMessages() {
        isLoading = true
        
        Task {
            do {
                let loadedMessages = try await requestService.getMessages(requestId: request.id)
                
                await MainActor.run {
                    messages = loadedMessages
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load messages"
                    isLoading = false
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        
        let messageText = newMessage
        newMessage = ""
        isSendingMessage = true
        
        Task {
            do {
                try await requestService.sendMessage(
                    requestId: request.id,
                    content: messageText
                )
                
                await MainActor.run {
                    loadMessages()
                    isSendingMessage = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to send message"
                    newMessage = messageText // Restore message
                    isSendingMessage = false
                }
            }
        }
    }
    
    private func markAsRead() {
        guard request.hasUnreadMessages else { return }
        
        Task {
            try? await requestService.markAsRead(requestId: request.id)
            onUpdate()
        }
    }
    
    private func cancelRequest() {
        Task {
            do {
                try await requestService.cancelRequest(id: request.id)
                
                await MainActor.run {
                    onUpdate()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to cancel request"
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: RequestMessage
    
    var isFromUser: Bool {
        message.senderType == .user
    }
    
    var body: some View {
        HStack {
            if isFromUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isFromUser ? .white : .primary)
                    .padding(12)
                    .background(isFromUser ? Color.blue : Color(.systemGray5))
                    .cornerRadius(16)
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !isFromUser {
                Spacer(minLength: 50)
            }
        }
    }
}

// Preview removed - CustomerRequest uses custom decoder init
