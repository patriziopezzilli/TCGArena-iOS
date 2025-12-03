//
//  ShopSubscription.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/3/25.
//

import Foundation

struct ShopSubscription: Codable {
    let id: Int64
    let userId: Int64
    let shopId: Int64
    let subscribedAt: Date
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case shopId = "shop_id"
        case subscribedAt = "subscribed_at"
        case isActive = "is_active"
    }
}