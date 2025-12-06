//
//  PartnerModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/06/25.
//

import Foundation

struct Partner: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let logoUrl: String?
    let websiteUrl: String?
    let isActive: Bool
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case logoUrl
        case websiteUrl
        case isActive
        case createdAt
    }
}
