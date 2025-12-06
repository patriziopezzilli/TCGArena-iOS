//
//  Partner+Extensions.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/06/25.
//

import SwiftUI

extension Partner {
    var title: String {
        return name
    }
    
    // MockPartner had 'type' which was an enum with color and icon.
    // We'll define a similar structure or reuse one if available, or just hardcode for now.
    // Since MockPartner is defined inside RewardsView (or used there), let's see.
    // Actually MockPartner seems to be defined elsewhere or I missed it.
    // Let's assume we need to provide these properties.
    
    var type: PartnerType {
        return .store // Default
    }
    
    var tcgTypes: [TCGType] {
        // In a real app this would come from backend.
        return [.pokemon, .magic, .onePiece]
    }
    
    var discount: String? {
        return nil
    }
    
    var actionText: String {
        return "View Details"
    }
}

enum PartnerType {
    case store, online, eventOrganizer
    
    var displayName: String {
        switch self {
        case .store: return "Local Store"
        case .online: return "Online Shop"
        case .eventOrganizer: return "Event Organizer"
        }
    }
    
    var icon: String {
        switch self {
        case .store: return "building.2.fill"
        case .online: return "globe"
        case .eventOrganizer: return "calendar"
        }
    }
    
    var color: Color {
        switch self {
        case .store: return .blue
        case .online: return .purple
        case .eventOrganizer: return .orange
        }
    }
}
