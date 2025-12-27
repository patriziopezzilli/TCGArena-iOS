import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var chatService = ChatService()
    @State private var hasAppeared = false
    
    var body: some View {
        ZStack {
            // Clean background that extends to edges
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - Home style
                headerView
                
                if chatService.isLoading && chatService.conversations.isEmpty {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else if chatService.conversations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(chatService.conversations) { conv in
                                NavigationLink(destination: ChatDetailView(conversation: conv, currentUserId: Int64(authService.currentUserId ?? 0)).environmentObject(authService)) {
                                    ModernChatRow(conversation: conv, currentUserId: Int64(authService.currentUserId ?? 0))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if conv.id != chatService.conversations.last?.id {
                                    Divider()
                                        .padding(.leading, 80)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                Task {
                    await chatService.loadConversations()
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("MESSAGGI")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .tracking(2)
                Spacer()
            }
            
            Text("Le tue chat")
                .font(.system(size: 28, weight: .heavy))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 100, height: 100)
                
                SwiftUI.Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.6))
            }
            
            VStack(spacing: 8) {
                Text("Nessuna conversazione")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Inizia una chat dalla mappa\no dal profilo di un giocatore")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

struct ModernChatRow: View {
    let conversation: ChatConversation
    let currentUserId: Int64
    
    var otherUser: RadarUser? {
        conversation.otherParticipant(currentUserId: currentUserId)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar with activity indicator
            ZStack(alignment: .bottomTrailing) {
                if let user = otherUser {
                    if let urlString = user.profileImageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 56, height: 56)
                            .overlay(
                                SwiftUI.Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 56, height: 56)
                        .overlay(
                            SwiftUI.Image(systemName: "person.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(otherUser?.displayName ?? "Utente")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let date = ISO8601DateFormatter().date(from: conversation.lastMessageAt) {
                        Text(timeAgo(date))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 8) {
                    if conversation.type == .trade {
                        if conversation.isCompleted {
                            // Completed trade badge
                            HStack(spacing: 4) {
                                SwiftUI.Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text("CONCLUSO")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)
                        } else {
                            // Active trade badge
                            HStack(spacing: 4) {
                                SwiftUI.Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 9, weight: .bold))
                                Text("SCAMBIO")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }
                    
                    Text(validPreview)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Chevron
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(UIColor.quaternaryLabel))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }
    
    var validPreview: String {
        return conversation.lastMessagePreview ?? "Nuova conversazione"
    }
    
    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
