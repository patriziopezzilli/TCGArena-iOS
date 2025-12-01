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
        VStack(alignment: .leading, spacing: 0) {
            // Header with flat color
            tournament.tcgType.themeColor
                .frame(height: 90)
                .overlay(
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tournament.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Label(tournament.tcgType.displayName, systemImage: tournament.tcgType.icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                            
                            Text("•")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 11))
                            
                            Text(tournament.type.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.95))
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading),
                    alignment: .bottomLeading
                )
            
            // Info section
            VStack(spacing: 12) {
                // Location and Date
                HStack(alignment: .top, spacing: 16) {
                    // Location
                    if let location = tournament.location {
                        HStack(alignment: .top, spacing: 8) {
                            SwiftUI.Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(tournament.tcgType.themeColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(location.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(location.city)
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Date
                    HStack(alignment: .top, spacing: 8) {
                        SwiftUI.Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(tournament.tcgType.themeColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tournament.formattedStartDate)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(tournament.formattedStartDate)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Participants and Entry Fee
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "person.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("\(tournament.currentParticipants)/\(tournament.maxParticipants)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    if tournament.entryFee > 0 {
                        HStack(spacing: 6) {
                            SwiftUI.Image(systemName: "eurosign.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            Text("€\(tournament.entryFee, specifier: "%.0f")")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    } else {
                        HStack(spacing: 6) {
                            SwiftUI.Image(systemName: "gift.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                            Text("Free")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                }
                
                // Registration Button
                if tournament.status == .registrationOpen {
                    Button(action: onRegisterTap) {
                        HStack(spacing: 8) {
                            SwiftUI.Image(systemName: isUserRegistered ? "checkmark.circle.fill" : "person.badge.plus.fill")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Text(isUserRegistered ? "Registered" : "Register Now")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isUserRegistered ? Color.green : tournament.tcgType.themeColor)
                        )
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
