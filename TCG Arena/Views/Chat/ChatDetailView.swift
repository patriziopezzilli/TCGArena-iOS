import SwiftUI

struct ChatDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    @StateObject private var chatService = ChatService()
    
    let conversation: ChatConversation
    let currentUserId: Int64
    
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    @State private var showingCompleteSheet = false
    @State private var selectedRating = 3
    @State private var isCompleted = false
    
    // Auto-scroll
    @Namespace private var bottomID
    
    var otherUser: RadarUser? {
        // Debug: print participant IDs to debug the username issue
        print("🔍 ChatDetailView: currentUserId = \(currentUserId)")
        for participant in conversation.participants {
            print("🔍 ChatDetailView: participant id=\(participant.id), name=\(participant.displayName)")
        }
        let other = conversation.participants.first { $0.id != currentUserId }
        print("🔍 ChatDetailView: otherUser = \(other?.displayName ?? "nil")")
        return other
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Trade completed banner
                if conversation.isCompleted || isCompleted {
                    completedBanner
                }
                
                // Trade Context (if any)
                if conversation.type == .trade && !conversation.isCompleted && !isCompleted {
                    if let context = conversation.contextJson {
                        tradeContextView(context: context)
                    }
                }
                
                // Messages - using full available space
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(chatService.currentMessages) { msg in
                                ChatMessageBubble(message: msg, isCurrentUser: msg.senderId == currentUserId, maxWidth: geometry.size.width)
                            }
                            
                            // Invisible spacer for scrolling
                            Color.clear.frame(height: 1).id(bottomID)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemGroupedBackground))
                    .onChange(of: chatService.currentMessages) { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                }
                
                // Input Area or Completed State
                if conversation.isLocked || isCompleted {
                    lockedInputBar
                } else {
                    inputBar
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            isCompleted = conversation.isCompleted
            chatService.currentMessages = [] // Clear previous
            Task {
                await chatService.loadMessages(conversationId: conversation.id)
            }
            if !conversation.isLocked {
                chatService.startPolling(conversationId: conversation.id)
            }
        }
        .onDisappear {
            chatService.stopPolling()
        }
        .sheet(isPresented: $showingCompleteSheet) {
            completeTradeSheet
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                SwiftUI.Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            
            if let user = otherUser {
                if let urlString = user.profileImageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 40, height: 40)
                        .overlay(
                            SwiftUI.Image(systemName: "person.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if conversation.type == .trade {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(conversation.isCompleted || isCompleted ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)
                            Text(conversation.isCompleted || isCompleted ? "Trattativa conclusa" : "Trattativa attiva")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } else {
                Text("Chat")
                    .font(.system(size: 16, weight: .semibold))
            }
            
            Spacer()
            
            // Complete trade button for trade chats
            if conversation.type == .trade && !conversation.isCompleted && !isCompleted {
                Button(action: { showingCompleteSheet = true }) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Concludi")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var completedBanner: some View {
        HStack(spacing: 10) {
            SwiftUI.Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
            
            Text("Trattativa conclusa con successo")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
    }
    
    private func tradeContextView(context: String) -> some View {
        HStack(spacing: 10) {
            SwiftUI.Image(systemName: "arrow.left.arrow.right.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Trattativa in corso")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                Text(context)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.orange.opacity(0.08))
    }
    
    private var inputBar: some View {
        HStack(spacing: 12) {
            // Text input
            HStack {
                TextField("Scrivi un messaggio...", text: $messageText, axis: .vertical)
                    .focused($isFocused)
                    .font(.system(size: 15))
                    .lineLimit(1...5)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(22)
            
            // Send button
            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(messageText.isEmpty ? Color(.secondarySystemBackground) : Color.blue)
                        .frame(width: 40, height: 40)
                    
                    SwiftUI.Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(messageText.isEmpty ? .gray : .white)
                }
            }
            .disabled(messageText.isEmpty)
            .animation(.easeInOut(duration: 0.15), value: messageText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: -2)
        )
    }
    
    private var lockedInputBar: some View {
        HStack {
            SwiftUI.Image(systemName: "lock.fill")
                .foregroundColor(.secondary)
            Text("Questa conversazione è stata conclusa")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.secondarySystemBackground))
    }
    
    private var completeTradeSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    SwiftUI.Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Concludi Trattativa")
                        .font(.system(size: 22, weight: .bold))
                    
                    Text("Valuta la tua esperienza con questo utente")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Star rating
                VStack(spacing: 12) {
                    Text("Quanti punti vuoi assegnare?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { selectedRating = star }) {
                                SwiftUI.Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundColor(star <= selectedRating ? .yellow : .gray.opacity(0.4))
                            }
                        }
                    }
                    
                    Text("\(selectedRating) punti")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 20)
                
                Spacer()
                
                Button(action: completeTrade) {
                    Text("Conferma e Concludi")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        showingCompleteSheet = false
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let content = messageText
        messageText = ""
        Task {
            await chatService.sendMessage(conversationId: conversation.id, content: content)
        }
    }
    
    private func completeTrade() {
        Task {
            let success = await chatService.completeTrade(conversationId: conversation.id, points: selectedRating)
            if success {
                chatService.stopPolling()
                isCompleted = true
                showingCompleteSheet = false
            }
        }
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let maxWidth: CGFloat
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isCurrentUser { Spacer(minLength: maxWidth * 0.15) }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isCurrentUser ?
                            AnyShapeStyle(Color.blue) :
                            AnyShapeStyle(Color(.secondarySystemBackground))
                    )
                    .cornerRadius(18)
                    .cornerRadius(isCurrentUser ? 4 : 18, corners: isCurrentUser ? [.bottomRight] : [.bottomLeft])
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.horizontal, 6)
            }
            
            if !isCurrentUser { Spacer(minLength: maxWidth * 0.15) }
        }
    }
    
    func formatTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            let timeFmt = DateFormatter()
            timeFmt.timeStyle = .short
            return timeFmt.string(from: date)
        }
        // Fallback for different format
        let alternateFormatter = ISO8601DateFormatter()
        alternateFormatter.formatOptions = [.withInternetDateTime]
        if let date = alternateFormatter.date(from: iso) {
            let timeFmt = DateFormatter()
            timeFmt.timeStyle = .short
            return timeFmt.string(from: date)
        }
        return ""
    }
}

