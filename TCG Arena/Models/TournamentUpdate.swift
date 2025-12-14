//
//  TournamentUpdate.swift
//  TCG Arena
//
//  Tournament live updates model
//

import Foundation

struct TournamentUpdate: Codable, Identifiable {
    let id: Int
    let tournamentId: Int
    let message: String?
    let imageBase64: String?
    let createdAt: String
    let createdBy: Int
    
    var createdAtDate: Date? {
        let formatters: [DateFormatter] = [
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                f.timeZone = TimeZone(identifier: "Europe/Rome")
                return f
            }(),
            {
                let f = DateFormatter()
                f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                f.timeZone = TimeZone(identifier: "Europe/Rome")
                return f
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: createdAt) {
                return date
            }
        }
        return nil
    }
    
    var formattedDate: String {
        guard let date = createdAtDate else { return createdAt }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "it_IT")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter.string(from: date)
    }
}
