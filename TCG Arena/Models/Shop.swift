//
//  Shop.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import Foundation

struct Shop: Identifiable, Codable {
    let id: Int64
    let name: String
    let description: String?
    let address: String
    let latitude: Double?
    let longitude: Double?
    let phoneNumber: String?
    let email: String?
    let websiteUrl: String?
    let instagramUrl: String?
    let facebookUrl: String?
    let twitterUrl: String?
    let type: ShopType
    let isVerified: Bool
    let active: Bool?
    let ownerId: Int64
    let openingHours: String?
    let openingDays: String?
    let tcgTypes: [TCGType]?
    let services: [String]?
    let inventory: [InventoryItem]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, address, latitude, longitude, phoneNumber, email
        case websiteUrl, instagramUrl, facebookUrl, twitterUrl
        case type, isVerified, active, ownerId, openingHours, openingDays, tcgTypes, services, inventory
    }
}

struct InventoryItem: Codable {
    let id: Int64?
    let cardId: Int64?
    let quantity: Int?
    let price: Double?
}

enum ShopType: String, Codable {
    case localStore = "LOCAL_STORE"
    case onlineStore = "ONLINE_STORE"
    case marketplace = "MARKETPLACE"
}
