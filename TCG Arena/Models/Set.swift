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
    let releaseDateString: String
    let cardCount: Int
    let description: String?
    let cards: [CardTemplate]? // Recent cards (up to 5)
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case setCode
        case imageURL = "imageUrl"
        case releaseDateString = "releaseDate"
        case cardCount = "cardCount"
        case description
        case cards
    }
    
    // Computed property per ottenere la data di rilascio come Date
    var releaseDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: releaseDateString) {
            return date
        }
        
        // Try alternative format: "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: releaseDateString) {
            return date
        }
        
        // If all parsing fails, return current date as fallback
        print("⚠️ Failed to parse release date: '\(releaseDateString)' for set \(name)")
        return Date()
    }
    
    // Computed properties for display
    var formattedReleaseDate: String {
        let parsedDate = releaseDate
        
        // Check if parsing failed by comparing with current date
        // If it's exactly the current date, parsing likely failed
        let now = Date()
        let calendar = Calendar.current
        if calendar.isDate(parsedDate, inSameDayAs: now) {
            // Additional check: if the original string doesn't match today's date format
            let todayString = ISO8601DateFormatter().string(from: now)
            if releaseDateString != String(todayString.prefix(releaseDateString.count)) {
                // Parsing likely failed, try to show original string in readable format
                if releaseDateString.contains("-") {
                    // Try to extract date part (yyyy-MM-dd)
                    let components = releaseDateString.split(separator: "-")
                    if components.count >= 3 {
                        return "\(components[2].prefix(2))/\(components[1])/\(components[0])"
                    }
                }
                // Fallback to showing original string
                return releaseDateString
            }
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: parsedDate)
    }
    
    var isRecent: Bool {
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        return releaseDate >= sixMonthsAgo
    }
    
    // Computed property per ottenere l'URL completo del logo
    var logoUrl: String? {
        guard let baseUrl = imageURL else { return nil }
        // L'URL base già finisce con il path del logo, basta aggiungere l'estensione
        return "\(baseUrl).webp"
    }
    
    // Versione con parametri personalizzabili
    func logoUrl(format: String = "webp") -> String? {
        guard let baseUrl = imageURL else { return nil }
        return "\(baseUrl).\(format)"
    }
}