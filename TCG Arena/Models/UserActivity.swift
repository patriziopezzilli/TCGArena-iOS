//
//  UserActivity.swift
//  TCG Arena
//
//  Created by Assistant on 22/11/2024.
//

import Foundation

struct UserActivity: Codable, Identifiable {
    let id: Int64
    let userId: Int64?
    let username: String?
    let displayName: String?
    let activityType: String
    let description: String
    let metadata: String?
    let timestamp: String
    let userProfile: UserProfile?

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case username
        case displayName
        case activityType
        case description
        case metadata
        case timestamp
        case userProfile
    }
}