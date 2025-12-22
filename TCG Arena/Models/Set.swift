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
    let productType: ProductType?
    let parentSetId: Int64?  // For sub-sets (e.g., Shiny Vault → Hidden Fates)
    let cards: [CardTemplate]? // Recent cards (up to 5)
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case setCode
        case imageURL = "imageUrl"
        case releaseDateString = "releaseDate"
        case cardCount = "cardCount"
        case description
        case productType = "productType"
        case parentSetId = "parentSetId"
        case cards
    }
    
    /// Set code formatted as uppercase for display
    var displaySetCode: String {
        setCode.uppercased()
    }
    
    // Computed property per ottenere la data di rilascio come Date
    var releaseDate: Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = formatter.date(from: releaseDateString) {
            return date
        }
        
        // Try ISO8601 without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: releaseDateString) {
            return date
        }
        
        // Try format without timezone: "yyyy-MM-dd'T'HH:mm:ss"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        if let date = dateFormatter.date(from: releaseDateString) {
            return date
        }
        
        // Try alternative format: "yyyy-MM-dd"
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: releaseDateString) {
            return date
        }
        
        // If all parsing fails, return current date as fallback
        print("⚠️ Failed to parse release date: '\(releaseDateString)' for set \(name)")
        return Date()
    }
    
    // Computed properties for display
    // Date is already formatted by backend as "dd MMM yyyy, HH:mm", so use it directly
    var formattedReleaseDate: String {
        return releaseDateString
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