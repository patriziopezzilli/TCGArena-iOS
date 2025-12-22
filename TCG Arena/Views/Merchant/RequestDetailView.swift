//
//  RequestDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct RequestDetailView: View {
    @EnvironmentObject var requestService: RequestService
    @Environment(\.dismiss) var dismiss
    
    let request: CustomerRequest
    
    @State private var messages: [RequestMessage] = []
    @State private var newMessage = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var isProcessing = false
    @State private var showAcceptConfirmation = false
    @State private var showRejectConfirmation = false
    @State private var showCompleteConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Request Header
                requestHeader
                
                Divider()
                
                // Messages
                if isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, isMerchant: true)
                            }
                        }
                        .padding(20)
                    }
                }
                
                // Message Input
                if request.status != .rejected && request.status != .completed && request.status != .cancelled {
                    messageInput
                }
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle(request.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if request.status == .pending {
                            Button(action: { showAcceptConfirmation = true }) {
                                Label("Accept Request", systemImage: "checkmark.circle")
                            }
                            
                            Button(role: .destructive, action: { showRejectConfirmation = true }) {
                                Label("Reject Request", systemImage: "xmark.circle")
                            }
                        }
                        
                        if request.status == .accepted {
                            Button(action: { showCompleteConfirmation = true }) {
                                Label("Mark as Completed", systemImage: "checkmark.circle.fill")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                    }
                }
            }
            .confirmationDialog("Accept Request", isPresented: $showAcceptConfirmation, titleVisibility: .visible) {
                Button("Accept") { acceptRequest() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Accept this request and start working on it?")
            }
            .confirmationDialog("Reject Request", isPresented: $showRejectConfirmation, titleVisibility: .visible) {
                Button("Rifiuta", role: .destructive) { rejectRequest() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Sei sicuro di voler rifiutare questa richiesta?")
            }
            .confirmationDialog("Complete Request", isPresented: $showCompleteConfirmation, titleVisibility: .visible) {
                Button("Complete") { completeRequest() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Mark this request as completed?")
            }
            .onAppear {
                loadMessages()
            }
        }
    }
    
    // MARK: - Request Header
    private var requestHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Customer Info
            HStack(spacing: 12) {
                Circle()
                    .fill(AdaptiveColors.brandPrimary.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(request.user?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AdaptiveColors.brandPrimary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.user?.displayName ?? "Unknown User")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(request.user?.email ?? "")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                Text(request.status.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(request.status.color))
                    )
            }
            
            // Request Details
            VStack(alignment: .leading, spacing: 8) {
                Text(request.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                if let description = request.description {
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            
            // Metadata
            HStack(spacing: 16) {
                Label(request.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                if request.cardDetails != nil {
                    Label("Card Request", systemImage: "square.on.square")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(AdaptiveColors.backgroundSecondary)
    }
    
    // MARK: - Message Input
    private var messageInput: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                TextField("Type a message...", text: $newMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 15))
                    .lineLimit(1...4)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                
                Button(action: sendMessage) {
                    if isSending {
                        ProgressView()
                            .frame(width: 40, height: 40)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(newMessage.isEmpty ? .secondary : AdaptiveColors.brandPrimary)
                    }
                }
                .disabled(newMessage.isEmpty || isSending)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AdaptiveColors.backgroundPrimary)
        }
    }
    
    // MARK: - Actions
    private func loadMessages() {
        Task {
            do {
                let request = try await requestService.getRequestDetail(requestId: request.id)
                await MainActor.run {
                    messages = [] // TODO: Load messages from separate endpoint when backend supports it
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func sendMessage() {
        let messageText = newMessage
        newMessage = ""
        isSending = true
        
        Task {
            do {
                let message = try await requestService.sendMessageAsMerchant(
                    requestId: request.id,
                    content: messageText
                )
                
                await MainActor.run {
                    messages.append(message)
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    newMessage = messageText
                    isSending = false
                }
            }
        }
    }
    
    private func acceptRequest() {
        isProcessing = true
        
        Task {
            do {
                try await requestService.acceptRequest(requestId: request.id)
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
    
    private func rejectRequest() {
        isProcessing = true
        
        Task {
            do {
                try await requestService.rejectRequest(requestId: request.id)
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
    
    private func completeRequest() {
        isProcessing = true
        
        Task {
            do {
                try await requestService.completeRequest(requestId: request.id)
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: RequestMessage
    let isMerchant: Bool
    
    var isOwnMessage: Bool {
        (isMerchant && message.senderType == .merchant) ||
        (!isMerchant && message.senderType == .customer)
    }
    
    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isOwnMessage ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(isOwnMessage ? AdaptiveColors.brandPrimary : AdaptiveColors.backgroundSecondary)
                    )
                
                Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !isOwnMessage {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    RequestDetailView(request: CustomerRequest(
        id: "1",
        userId: 1,
        shopId: 1,
        type: .availability,
        title: "Looking for Pikachu VMAX",
        description: "Do you have any Pikachu VMAX cards in stock?",
        status: .pending,
        hasUnreadMessages: false,
        messageCount: 0,
        createdAt: Date(),
        updatedAt: Date(),
        resolvedAt: nil
    ))
    .environmentObject(RequestService())
}
