//
//  Set.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import Foundation

struct TCGSet: Identifiable, Codable {
    let id: Int64
    let name: String
    let setCode: String // e.g., "SV3PT5" for Pokemon 151, "SV3" for Adventures Together
    let imageURL: String?
    let releaseDate: Date
    let cardCount: Int
    let description: String?
    
    // Computed properties for display
    var formattedReleaseDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: releaseDate)
    }
    
    var isRecent: Bool {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return releaseDate >= sixMonthsAgo
    }
    
    init(id: Int64, name: String, setCode: String, imageURL: String? = nil, releaseDate: Date, cardCount: Int, description: String? = nil) {
        self.id = id
        self.name = name
        self.setCode = setCode
        self.imageURL = imageURL
        self.releaseDate = releaseDate
        self.cardCount = cardCount
        self.description = description
    }
}