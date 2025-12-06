//
//  ShopNews.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import Foundation

struct ShopNews: Identifiable, Codable {
    let id: Int64
    let shopID: Int64
    let title: String
    let content: String
    let newsType: NewsType
    let publishedDate: Date
    let expiryDate: Date?
    let imageURL: String?
    let isPinned: Bool
    
    enum NewsType: String, CaseIterable, Codable {
        case announcement = "ANNOUNCEMENT"
        case newStock = "NEW_STOCK"
        case tournament = "TOURNAMENT"
        case sale = "SALE"
        case event = "EVENT"
        case general = "GENERAL"
        
        var icon: String {
            switch self {
            case .announcement: return "megaphone.fill"
            case .newStock: return "shippingbox.fill"
            case .tournament: return "trophy.fill"
            case .sale: return "tag.fill"
            case .event: return "calendar"
            case .general: return "newspaper.fill"
            }
        }
        
        var color: String {
            switch self {
            case .announcement: return "blue"
            case .newStock: return "green"
            case .tournament: return "orange"
            case .sale: return "red"
            case .event: return "purple"
            case .general: return "gray"
            }
        }
        
        var displayName: String {
            switch self {
            case .announcement: return "Announcement"
            case .newStock: return "New Stock"
            case .tournament: return "Tournament"
            case .sale: return "Sale"
            case .event: return "Event"
            case .general: return "General"
            }
        }
    }
    
    // Full initializer for API response
    init(id: Int64 = 0, shopID: Int64, title: String, content: String, newsType: NewsType, publishedDate: Date = Date(), expiryDate: Date? = nil, imageURL: String? = nil, isPinned: Bool = false) {
        self.id = id
        self.shopID = shopID
        self.title = title
        self.content = content
        self.newsType = newsType
        self.publishedDate = publishedDate
        self.expiryDate = expiryDate
        self.imageURL = imageURL
        self.isPinned = isPinned
    }
}
