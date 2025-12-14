//
//  RewardModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

struct Reward: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let costPoints: Int
    let imageUrl: String?
    let isActive: Bool
    let createdAt: String
    let partner: Partner?
    let type: RewardType

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case costPoints
        case imageUrl
        case isActive
        case createdAt
        case partner
        case type
    }
}

enum RewardType: String, Codable {
    case physical = "PHYSICAL"
    case digital = "DIGITAL"
    
    var displayName: String {
        switch self {
        case .physical: return "Physical"
        case .digital: return "Digital"
        }
    }
    
    var icon: String {
        switch self {
        case .physical: return "shippingbox.fill"
        case .digital: return "wifi"
        }
    }
}

struct RewardTransaction: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let pointsChange: Int
    let description: String
    let rewardId: Int?
    let timestamp: String
    let voucherCode: String?
    let trackingNumber: String?
    let status: FulfillmentStatus?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case pointsChange
        case description
        case rewardId
        case timestamp
        case voucherCode
        case trackingNumber
        case status
    }
    
    enum FulfillmentStatus: String, Codable {
        case PENDING
        case PROCESSING
        case SHIPPED
        case DELIVERED
        case COMPLETED
        
        var displayName: String {
            switch self {
            case .PENDING: return "In preparazione"
            case .PROCESSING: return "In lavorazione"
            case .SHIPPED: return "Spedito"
            case .DELIVERED: return "Consegnato"
            case .COMPLETED: return "Completato"
            }
        }
        
        var color: String {
            switch self {
            case .PENDING, .PROCESSING: return "orange"
            case .SHIPPED: return "blue"
            case .DELIVERED, .COMPLETED: return "green"
            }
        }
        
        var icon: String {
            switch self {
            case .PENDING: return "clock.fill"
            case .PROCESSING: return "gear"
            case .SHIPPED: return "shippingbox.fill"
            case .DELIVERED, .COMPLETED: return "checkmark.circle.fill"
            }
        }
    }
}

struct UserPoints: Codable {
    let points: Int
}