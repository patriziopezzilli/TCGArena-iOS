//
//  TournamentCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct TournamentCardView: View {
    let tournament: Tournament
    let isUserRegistered: Bool
    let onRegisterTap: () -> Void
    
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
                        .background(tournament.tcgType.themeColor)

                    Text(dayString(from: tournament.startDate))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
                )
                .frame(width: 60)

                Text(timeString(from: tournament.startDate))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(16)

            // Right Side: Info
            VStack(alignment: .leading, spacing: 8) {
                // Badges
                HStack(spacing: 8) {
                    Text(tournament.tcgType.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(tournament.tcgType.themeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tournament.tcgType.themeColor.opacity(0.1))
                        .cornerRadius(4)

                    Text(tournament.type.rawValue)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(4)

                    Spacer()

                    // Price
                    if tournament.entryFee > 0 {
                        Text("€\(tournament.entryFee, specifier: "%.0f")")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                    } else {
                        Text("Free")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green)
                    }
                }

                // Title
                Text(tournament.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Location
                if let location = tournament.location {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text(location.venueName)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Footer: Participants & Button
                HStack {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                        Text("\(tournament.currentParticipants)/\(tournament.maxParticipants)")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()

                    if tournament.status == .registrationOpen {
                        Button(action: onRegisterTap) {
                            Text(isUserRegistered ? "Registered" : "Join")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isUserRegistered ? .green : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(isUserRegistered ? Color.green.opacity(0.1) : tournament.tcgType.themeColor)
                                )
                        }
                        .buttonStyle(BounceButtonStyle())
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helpers
    private func monthString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }

    private func dayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
