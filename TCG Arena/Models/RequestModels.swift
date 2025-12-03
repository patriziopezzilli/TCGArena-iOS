//
//  RequestModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation

/// Represents a request from a user to a merchant
struct CustomerRequest: Identifiable, Codable {
    let id: String
    let userId: Int64?
    let shopId: Int64?
    let type: RequestType
    let status: RequestStatus
    let title: String
    let description: String?
    let hasUnreadMessages: Bool
    let messageCount: Int
    let createdAt: Date
    let updatedAt: Date
    let resolvedAt: Date?
    
    // Shop info (from DTO)
    let shopName: String?
    let shopAddress: String?
    
    // User info (from DTO)
    let userName: String?
    let userAvatar: String?
    
    enum RequestType: String, Codable, CaseIterable {
        case availability = "AVAILABILITY"
        case evaluation = "EVALUATION"
        case sell = "SELL"
        case buy = "BUY"
        case trade = "TRADE"
        case general = "GENERAL"
        
        var displayName: String {
            switch self {
            case .availability: return "Card Availability"
            case .evaluation: return "Card Evaluation"
            case .sell: return "Sell Cards"
            case .buy: return "Buy Request"
            case .trade: return "Trade Proposal"
            case .general: return "General Inquiry"
            }
        }
        
        var icon: String {
            switch self {
            case .availability: return "magnifyingglass"
            case .evaluation: return "dollarsign.circle"
            case .sell: return "arrow.up.circle"
            case .buy: return "cart"
            case .trade: return "arrow.left.arrow.right"
            case .general: return "questionmark.circle"
            }
        }
        
        var color: String {
            switch self {
            case .availability: return "blue"
            case .evaluation: return "green"
            case .sell: return "orange"
            case .buy: return "purple"
            case .trade: return "cyan"
            case .general: return "gray"
            }
        }
    }
    
    enum RequestStatus: String, Codable, CaseIterable {
        case pending = "PENDING"
        case accepted = "ACCEPTED"
        case rejected = "REJECTED"
        case completed = "COMPLETED"
        case cancelled = "CANCELLED"
        
        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .accepted: return "In Progress"
            case .rejected: return "Rejected"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "orange"
            case .accepted: return "blue"
            case .rejected: return "red"
            case .completed: return "green"
            case .cancelled: return "gray"
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .accepted: return "checkmark.circle.fill"
            case .rejected: return "xmark.circle.fill"
            case .completed: return "checkmark.seal.fill"
            case .cancelled: return "trash.fill"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case shopId = "shop_id"
        case type, status, title, description
        case hasUnreadMessages = "has_unread_messages"
        case messageCount = "message_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case resolvedAt = "resolved_at"
        case shopName = "shop_name"
        case shopAddress = "shop_address"
        case userName = "user_name"
        case userAvatar = "user_avatar"
    }
    
    // Custom decoder to handle date parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decodeIfPresent(Int64.self, forKey: .userId)
        shopId = try container.decodeIfPresent(Int64.self, forKey: .shopId)
        type = try container.decode(RequestType.self, forKey: .type)
        status = try container.decode(RequestStatus.self, forKey: .status)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        hasUnreadMessages = try container.decode(Bool.self, forKey: .hasUnreadMessages)
        messageCount = try container.decode(Int.self, forKey: .messageCount)
        
        // Custom date parsing
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtDate = dateFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
        createdAt = createdAtDate
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        guard let updatedAtDate = dateFormatter.date(from: updatedAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
        updatedAt = updatedAtDate
        
        // Handle nullable resolvedAt
        if let resolvedAtString = try container.decodeIfPresent(String.self, forKey: .resolvedAt) {
            resolvedAt = dateFormatter.date(from: resolvedAtString)
        } else {
            resolvedAt = nil
        }
        
        shopName = try container.decodeIfPresent(String.self, forKey: .shopName)
        shopAddress = try container.decodeIfPresent(String.self, forKey: .shopAddress)
        userName = try container.decodeIfPresent(String.self, forKey: .userName)
        userAvatar = try container.decodeIfPresent(String.self, forKey: .userAvatar)
    }
    
    var isActive: Bool {
        status == .pending || status == .accepted
    }
    
    var canBeCancelled: Bool {
        status == .pending || status == .accepted
    }
    
    var canBeAccepted: Bool {
        status == .pending
    }
    
    var canBeRejected: Bool {
        status == .pending
    }
    
    var canBeCompleted: Bool {
        status == .accepted
    }
}

/// Represents a message in a request thread
struct RequestMessage: Identifiable, Codable, Hashable {
    let id: String
    let requestId: String
    let senderId: String
    let senderType: SenderType
    let content: String
    let attachmentUrl: String?
    let createdAt: Date
    
    // Optional embedded data
    var senderName: String?
    var senderAvatar: String?
    
    enum SenderType: String, Codable {
        case user = "USER"
        case merchant = "MERCHANT"
        case system = "SYSTEM"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case requestId = "request_id"
        case senderId = "sender_id"
        case senderType = "sender_type"
        case content
        case attachmentUrl = "attachment_url"
        case createdAt = "created_at"
    }
    
    // Custom decoder to handle date parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        requestId = try container.decode(String.self, forKey: .requestId)
        senderId = try container.decode(String.self, forKey: .senderId)
        senderType = try container.decode(SenderType.self, forKey: .senderType)
        content = try container.decode(String.self, forKey: .content)
        attachmentUrl = try container.decodeIfPresent(String.self, forKey: .attachmentUrl)
        
        // Custom date parsing
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        guard let createdAtDate = dateFormatter.date(from: createdAtString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
        createdAt = createdAtDate
    }
    
    var isFromCurrentUser: Bool {
        // This should be checked against actual current user ID
        // For now, just a placeholder
        senderType == .user
    }
    
    // Manual Hashable/Equatable implementation
    static func == (lhs: RequestMessage, rhs: RequestMessage) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Request DTOs
struct CreateRequestRequest: Codable {
    let shopId: String
    let type: CustomerRequest.RequestType
    let title: String
    let description: String
    let attachmentUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case shopId = "shop_id"
        case type, title, description
        case attachmentUrl = "attachment_url"
    }
}

struct SendMessageRequest: Codable {
    let content: String
    let attachmentUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case attachmentUrl = "attachment_url"
    }
}

struct UpdateRequestStatusRequest: Codable {
    let status: CustomerRequest.RequestStatus
    let message: String? // Optional message when changing status
}

// MARK: - Response DTOs
struct RequestResponse: Codable {
    let request: CustomerRequest
    let messages: [RequestMessage]
}

struct RequestListResponse: Codable {
    let requests: [CustomerRequest]
    let total: Int
}
