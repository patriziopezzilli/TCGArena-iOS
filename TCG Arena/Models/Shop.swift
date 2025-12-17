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
    let photoBase64: String?
    let type: ShopType
    let isVerified: Bool
    let active: Bool?
    let ownerId: Int64
    let openingHours: String? // Legacy - deprecated
    let openingDays: String?  // Legacy - deprecated
    let openingHoursStructured: OpeningHours? // New structured opening hours
    let tcgTypes: [String]?
    let services: [String]?
    let inventory: [InventoryItem]?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, address, latitude, longitude, phoneNumber, email
        case websiteUrl, instagramUrl, facebookUrl, twitterUrl, photoBase64
        case type, isVerified, active, ownerId, openingHours, openingDays
        case openingHoursStructured, tcgTypes, services, inventory
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int64.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        address = try container.decode(String.self, forKey: .address)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        websiteUrl = try container.decodeIfPresent(String.self, forKey: .websiteUrl)
        instagramUrl = try container.decodeIfPresent(String.self, forKey: .instagramUrl)
        facebookUrl = try container.decodeIfPresent(String.self, forKey: .facebookUrl)
        twitterUrl = try container.decodeIfPresent(String.self, forKey: .twitterUrl)
        photoBase64 = try container.decodeIfPresent(String.self, forKey: .photoBase64)
        type = try container.decode(ShopType.self, forKey: .type)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        active = try container.decodeIfPresent(Bool.self, forKey: .active)
        ownerId = try container.decode(Int64.self, forKey: .ownerId)
        openingHours = try container.decodeIfPresent(String.self, forKey: .openingHours)
        openingDays = try container.decodeIfPresent(String.self, forKey: .openingDays)
        openingHoursStructured = try container.decodeIfPresent(OpeningHours.self, forKey: .openingHoursStructured)
        inventory = try container.decodeIfPresent([InventoryItem].self, forKey: .inventory)
        
        // Parse tcgTypes: can be comma-separated string or array
        if let tcgTypesString = try? container.decode(String.self, forKey: .tcgTypes) {
            tcgTypes = tcgTypesString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        } else if let tcgTypesArray = try? container.decode([String].self, forKey: .tcgTypes) {
            tcgTypes = tcgTypesArray
        } else {
            tcgTypes = nil
        }
        
        // Parse services: can be comma-separated string or array
        if let servicesString = try? container.decode(String.self, forKey: .services) {
            services = servicesString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        } else if let servicesArray = try? container.decode([String].self, forKey: .services) {
            services = servicesArray
        } else {
            services = nil
        }
    }
    
    // Helper computed properties for display
    var tcgTypesList: [TCGType] {
        (tcgTypes ?? []).compactMap { TCGType(rawValue: $0) }
    }
    
    var servicesList: [ShopServiceType] {
        (services ?? []).compactMap { ShopServiceType(rawValue: $0) }
    }
    
    /// Check if the shop is currently open based on openingHours and openingDays
    var isOpenNow: Bool {
        // Prefer structured opening hours if available
        if let structured = openingHoursStructured {
            return structured.isOpenNow
        }
        
        // Fallback to legacy logic
        guard let hours = openingHours else { return true } // If no hours set, assume open
        
        // First check if today is an open day
        if let days = openingDays, !isDayOpen(days) {
            return false
        }
        
        // Parse format "10:00-19:00" or "10:00 - 19:00"
        let cleanHours = hours.replacingOccurrences(of: " ", with: "")
        let parts = cleanHours.split(separator: "-")
        guard parts.count == 2 else { return true } // Invalid format, assume open
        
        let openTime = String(parts[0])
        let closeTime = String(parts[1])
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let openDate = formatter.date(from: openTime),
              let closeDate = formatter.date(from: closeTime) else { return true } // Invalid time, assume open
        
        let now = Date()
        let calendar = Calendar.current
        
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let openComponents = calendar.dateComponents([.hour, .minute], from: openDate)
        let closeComponents = calendar.dateComponents([.hour, .minute], from: closeDate)
        
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let openMinutes = (openComponents.hour ?? 0) * 60 + (openComponents.minute ?? 0)
        let closeMinutes = (closeComponents.hour ?? 0) * 60 + (closeComponents.minute ?? 0)
        
        // Handle overnight hours (e.g., 22:00-02:00)
        if closeMinutes < openMinutes {
            return nowMinutes >= openMinutes || nowMinutes <= closeMinutes
        }
        
        // Normal hours - use <= for close time to include the closing hour
        return nowMinutes >= openMinutes && nowMinutes <= closeMinutes
    }
    
    /// Check if today is an open day based on openingDays string
    private func isDayOpen(_ daysString: String) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        // Map weekday (1=Sunday, 2=Monday, ... 7=Saturday) to Italian day names
        let dayMap: [Int: [String]] = [
            1: ["dom", "sun", "domenica", "sunday"],
            2: ["lun", "mon", "lunedì", "lunedi", "monday"],
            3: ["mar", "tue", "martedì", "martedi", "tuesday"],
            4: ["mer", "wed", "mercoledì", "mercoledi", "wednesday"],
            5: ["gio", "thu", "giovedì", "giovedi", "thursday"],
            6: ["ven", "fri", "venerdì", "venerdi", "friday"],
            7: ["sab", "sat", "sabato", "saturday"]
        ]
        
        let lowercaseDays = daysString.lowercased()
        
        // Check for range format like "Lun-Sab" or "Mon-Sat"
        if lowercaseDays.contains("-") {
            let parts = lowercaseDays.split(separator: "-").map { String($0).trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                var startDay: Int?
                var endDay: Int?
                
                for (day, aliases) in dayMap {
                    if aliases.contains(where: { parts[0].contains($0) }) {
                        startDay = day
                    }
                    if aliases.contains(where: { parts[1].contains($0) }) {
                        endDay = day
                    }
                }
                
                if let start = startDay, let end = endDay {
                    // Handle wrap-around (e.g., Sat-Sun)
                    if start <= end {
                        return weekday >= start && weekday <= end
                    } else {
                        return weekday >= start || weekday <= end
                    }
                }
            }
        }
        
        // Check if current day is mentioned
        if let aliases = dayMap[weekday] {
            return aliases.contains(where: { lowercaseDays.contains($0) })
        }
        
        return true // Default to open if can't parse
    }
    
    /// Get status text for display
    var openStatusText: String {
        if openingHours == nil {
            return "Orari non disponibili"
        }
        return isOpenNow ? "Aperto" : "Chiuso"
    }
    
    // Standard init for programmatic creation (used in Previews)
    init(
        id: Int64,
        name: String,
        description: String? = nil,
        address: String,
        latitude: Double? = nil,
        longitude: Double? = nil,
        phoneNumber: String? = nil,
        email: String? = nil,
        websiteUrl: String? = nil,
        instagramUrl: String? = nil,
        facebookUrl: String? = nil,
        twitterUrl: String? = nil,
        photoBase64: String? = nil,
        type: ShopType,
        isVerified: Bool,
        active: Bool? = nil,
        ownerId: Int64,
        openingHours: String? = nil,
        openingDays: String? = nil,
        openingHoursStructured: OpeningHours? = nil,
        tcgTypes: [String]? = nil,
        services: [String]? = nil,
        inventory: [InventoryItem]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.phoneNumber = phoneNumber
        self.email = email
        self.websiteUrl = websiteUrl
        self.instagramUrl = instagramUrl
        self.facebookUrl = facebookUrl
        self.twitterUrl = twitterUrl
        self.photoBase64 = photoBase64
        self.type = type
        self.isVerified = isVerified
        self.active = active
        self.ownerId = ownerId
        self.openingHours = openingHours
        self.openingDays = openingDays
        self.openingHoursStructured = openingHoursStructured
        self.tcgTypes = tcgTypes
        self.services = services
        self.inventory = inventory
    }
    
    // Preview helper
    static var preview: Shop {
        Shop(
            id: 1,
            name: "Magic Castle Games",
            description: "Il miglior negozio di carte collezionabili di Milano",
            address: "Via Paolo Sarpi, 42, Milano",
            latitude: 45.4773,
            longitude: 9.1815,
            phoneNumber: "+39 02 1234567",
            email: "info@magiccastle.it",
            websiteUrl: "https://magiccastle.it",
            instagramUrl: "https://instagram.com/magiccastle",
            facebookUrl: nil,
            twitterUrl: nil,
            photoBase64: nil,
            type: .physicalStore,
            isVerified: true,
            active: true,
            ownerId: 1,
            openingHours: "10:00-19:00",
            openingDays: "Lun-Sab",
            tcgTypes: ["POKEMON", "MAGIC", "YUGIOH"],
            services: ["CARD_SALES", "TOURNAMENTS", "PLAY_AREA"],
            inventory: nil
        )
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
    case physicalStore = "PHYSICAL_STORE"
    case onlineStore = "ONLINE_STORE"
    case marketplace = "MARKETPLACE"
    case hybrid = "HYBRID"
}

enum ShopServiceType: String, CaseIterable, Codable {
    case cardSales = "CARD_SALES"
    case buyCards = "BUY_CARDS"
    case tournaments = "TOURNAMENTS"
    case playArea = "PLAY_AREA"
    case grading = "GRADING"
    case accessories = "ACCESSORIES"
    case preorders = "PREORDERS"
    case onlineStore = "ONLINE_STORE"
    case cardEvaluation = "CARD_EVALUATION"
    case tradeIn = "TRADE_IN"
    
    var displayName: String {
        switch self {
        case .cardSales: return "Vendita Carte"
        case .buyCards: return "Acquisto Carte"
        case .tournaments: return "Tornei"
        case .playArea: return "Area Gioco"
        case .grading: return "Grading"
        case .accessories: return "Accessori"
        case .preorders: return "Preordini"
        case .onlineStore: return "Store Online"
        case .cardEvaluation: return "Valutazione Carte"
        case .tradeIn: return "Permuta"
        }
    }
    
    var icon: String {
        switch self {
        case .cardSales: return "cart.fill"
        case .buyCards: return "dollarsign.circle.fill"
        case .tournaments: return "trophy.fill"
        case .playArea: return "gamecontroller.fill"
        case .grading: return "star.fill"
        case .accessories: return "bag.fill"
        case .preorders: return "calendar.badge.plus"
        case .onlineStore: return "globe"
        case .cardEvaluation: return "magnifyingglass"
        case .tradeIn: return "arrow.triangle.2.circlepath"
        }
    }
}
