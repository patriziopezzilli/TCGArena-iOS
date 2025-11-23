//
//  ImageModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

struct Image: Codable, Identifiable {
    let id: Int
    let filename: String
    let originalFilename: String
    let contentType: String
    let size: Int
    let url: String
    let uploadedBy: Int
    let uploadedAt: String
    let entityType: String?
    let entityId: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case filename
        case originalFilename = "original_filename"
        case contentType = "content_type"
        case size
        case url
        case uploadedBy = "uploaded_by"
        case uploadedAt = "uploaded_at"
        case entityType = "entity_type"
        case entityId = "entity_id"
    }
}