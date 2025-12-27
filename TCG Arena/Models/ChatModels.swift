import Foundation

enum ChatType: String, Codable {
    case free = "FREE"
    case trade = "TRADE"
}

struct ChatConversation: Identifiable, Codable {
    let id: Int64
    let participants: [RadarUser]
    let lastMessageAt: String // ISO string
    let type: ChatType
    let contextJson: String?
    let lastMessagePreview: String?
    let status: String? // ACTIVE, COMPLETED
    let isReadOnly: Bool?
    
    // Helper to get the "other" participant
    func otherParticipant(currentUserId: Int64) -> RadarUser? {
        return participants.first { $0.id != currentUserId }
    }
    
    var isCompleted: Bool {
        return status == "COMPLETED"
    }
    
    var isLocked: Bool {
        return isReadOnly == true || isCompleted
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: Int64
    let conversationId: Int64
    let senderId: Int64
    let content: String
    let timestamp: String // ISO string from backend
    let isRead: Bool?
    
    // Parsed date helper
    var date: Date {
        let formatter = ISO8601DateFormatter()
        // Handle common backend formats inc. fractional seconds if needed
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp) ?? Date()
    }
}

struct CreateChatRequest: Encodable {
    let targetUserId: Int64
    let type: String // "FREE" or "TRADE"
    let contextJson: String?
}

struct ChatSendMessageRequest: Encodable {
    let content: String
}
