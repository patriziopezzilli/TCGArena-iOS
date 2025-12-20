//
//  PastTournamentCard.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct PastTournamentCard: View {
    let tournament: Tournament
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Left: Clean Date Box (Greyscale)
            VStack(spacing: 0) {
                Text(monthString(from: tournament.startDate).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(Color.gray)
                
                Text(dayString(from: tournament.startDate))
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
            .background(Color(.secondarySystemBackground)) // Slightly processed look
            .cornerRadius(10)
            .frame(width: 54)
            .opacity(0.8)
            
            // Middle: Info
            VStack(alignment: .leading, spacing: 6) {
                Text(tournament.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary) // Greyed out title
                    .lineLimit(2)
                
                // Location & Time
                HStack(spacing: 12) {
                    if let location = tournament.location {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10))
                            Text(location.city)
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    
                    Text("Concluso")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Right: Chevron
            SwiftUI.Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(16)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.separator).opacity(0.5)),
            alignment: .bottom
        )
    }
    
    // MARK: - Date Formatting Helpers
    private func monthString(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "OCT" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
    
    private func dayString(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "01" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        // Try multiple formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "dd MMM yyyy, HH:mm",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}
