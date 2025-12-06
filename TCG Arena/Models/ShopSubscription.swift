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
        case userId
        case shopId
        case subscribedAt
        case isActive
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        userId = try container.decode(Int64.self, forKey: .userId)
        shopId = try container.decode(Int64.self, forKey: .shopId)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        
        // Handle date parsing
        let dateString = try container.decode(String.self, forKey: .subscribedAt)
        
        // 1. Try standard ISO8601 (with timezone)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: dateString) {
            subscribedAt = date
            return
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            subscribedAt = date
            return
        }
        
        // 2. Try specific format from server (no timezone, e.g. "2025-12-03T22:53:02")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Assume UTC if no timezone
        
        if let date = dateFormatter.date(from: dateString) {
            subscribedAt = date
            return
        }
        
        // 3. Try with fractional seconds but no timezone
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let date = dateFormatter.date(from: dateString) {
            subscribedAt = date
            return
        }
        
        throw DecodingError.dataCorruptedError(
            forKey: .subscribedAt,
            in: container,
            debugDescription: "Date string does not match expected format: \(dateString)"
        )
    }
}