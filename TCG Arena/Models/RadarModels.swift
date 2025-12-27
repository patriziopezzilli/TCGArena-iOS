import Foundation

struct RadarTradeEntry: Identifiable, Codable {
    let id: Int64
    let cardTemplateId: Int64
    let cardName: String
    let imageUrl: String?
    let tcgType: TCGType?
    let rarity: String?
}

struct RadarUserCard: Identifiable, Codable {
    let cardId: Int64
    let cardName: String
    let imageUrl: String?
    let tcgType: TCGType?
    let rarity: String?
    let setName: String?
    let quantity: Int
    let condition: String?
    
    var id: Int64 { cardId }
}
