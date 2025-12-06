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
        HStack(spacing: 0) {
            // Left Side: Date & Time
            VStack(spacing: 8) {
                VStack(spacing: 0) {
                    Text(monthString(from: tournament.startDate))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.6)) // Dimmed color for past tournaments

                    Text(dayString(from: tournament.startDate))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.secondary) // Dimmed text
                        .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground).opacity(0.5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )
                .frame(width: 60)

                Text(timeString(from: tournament.startDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(16)

            // Right Side: Info
            VStack(alignment: .leading, spacing: 8) {
                // Badges
                HStack(spacing: 8) {
                    Text(tournament.tcgType.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.gray.opacity(0.7)) // Dimmed color
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(4)

                    Text(tournament.type.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground).opacity(0.5))
                        .cornerRadius(4)

                    Spacer()

                    // Price
                    if tournament.entryFee > 0 {
                        Text("€\(tournament.entryFee, specifier: "%.0f")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.7))
                    } else {
                        Text("Free")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green.opacity(0.7))
                    }
                }

                // Title
                Text(tournament.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(2)

                // Location
                if let location = tournament.location {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.7))
                        
                        Text(location.venueName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                
                // Footer: Participants & Status
                HStack {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                        Text("\(tournament.registeredParticipantsCount)/\(tournament.maxParticipants)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary.opacity(0.7))
                    
                    Spacer()

                    // Status badge for past tournaments
                    Text("Completed")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .background(Color(.systemBackground).opacity(0.8))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1) // Lighter shadow
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Helpers
    private func monthString(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    private func dayString(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func timeString(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: dateString)
    }
}