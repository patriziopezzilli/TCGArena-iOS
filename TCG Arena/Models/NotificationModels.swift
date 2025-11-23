//
//  NotificationModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

struct Notification: Codable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: String
    let type: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case message
        case isRead = "is_read"
        case createdAt = "created_at"
        case type
    }
}

struct DeviceTokenRequest: Codable {
    let token: String
    let platform: String
}