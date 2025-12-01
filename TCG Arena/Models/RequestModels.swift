//
//  RequestModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation

/// Represents a request from a user to a merchant
struct MerchantRequest: Identifiable, Codable {
    let id: String
    let userId: String
    let merchantId: String
    let type: RequestType
    let status: RequestStatus
    let title: String
    let description: String?
    let attachmentUrl: String?
    let createdAt: Date
    let updatedAt: Date
    
    // Optional embedded data
    var user: User?
    var shop: Shop?
    var messages: [RequestMessage]?
    
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
        case merchantId = "merchant_id"
        case type, status, title, description
        case attachmentUrl = "attachment_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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

// MARK: - Hashable/Equatable conformance
extension RequestMessage: Hashable, Equatable {}

// MARK: - Request DTOs
struct CreateRequestRequest: Codable {
    let merchantId: String
    let type: MerchantRequest.RequestType
    let title: String
    let description: String?
    let attachmentUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case merchantId = "merchant_id"
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
    let status: MerchantRequest.RequestStatus
    let message: String? // Optional message when changing status
}

// MARK: - Response DTOs
struct RequestResponse: Codable {
    let request: MerchantRequest
    let messages: [RequestMessage]
}

struct RequestListResponse: Codable {
    let requests: [MerchantRequest]
    let total: Int
}
