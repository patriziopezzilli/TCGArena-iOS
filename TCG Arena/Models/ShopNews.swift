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
        case announcement = "Announcement"
        case newStock = "New Stock"
        case tournament = "Tournament"
        case sale = "Sale"
        case event = "Event"
        case general = "General"
        
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
    }
    
    init(shopID: Int64, title: String, content: String, newsType: NewsType, publishedDate: Date = Date(), expiryDate: Date? = nil, imageURL: String? = nil, isPinned: Bool = false) {
        self.id = 0 // Mock ID
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
