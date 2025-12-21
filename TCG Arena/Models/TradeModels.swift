//
//  TradeModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import Foundation

enum TradeListType: String, Codable {
    case want = "WANT"
    case have = "HAVE"
}

struct TradeListEntry: Codable, Identifiable {
    let id: Int
    let cardTemplateId: Int
    let cardName: String
    let imageUrl: String?
    let type: TradeListType
    let tcgType: String?
    let rarity: String?
}

struct TradeMatch: Codable, Identifiable {
    let id: Int
    let otherUserId: Int
    let otherUserName: String
    let otherUserAvatar: String?
    let distance: Double
    let matchedCards: [TradeListEntry]
    let type: String // "THEY_HAVE_WHAT_I_WANT" etc.
    let status: String?
    
    // Helper for UI
    var userAvatar: String {
        return otherUserAvatar ?? "person.crop.circle"
    }
    
    var userName: String {
        return otherUserName
    }
    
    var matchType: MatchType {
        if type == "THEY_HAVE_WHAT_I_WANT" {
            return .theyHaveWhatIWant
        } else if type == "HISTORY" {
            return .history
        } else {
            return .iHaveWhatTheyWant
        }
    }
    
    enum MatchType {
        case theyHaveWhatIWant
        case iHaveWhatTheyWant
        case history
    }
}

struct TradeListRequest: Codable {
    let cardTemplateId: Int
    let type: String
}

struct TradeMessage: Codable, Identifiable {
    let id: Int
    let content: String
    let senderId: Int
    let senderName: String
    let sentAt: Date
    let isCurrentUser: Bool
}

struct TradeChatResponse: Codable {
    let messages: [TradeMessage]
    let matchStatus: String
}

struct TradeMessageRequest: Codable {
    let content: String
}
