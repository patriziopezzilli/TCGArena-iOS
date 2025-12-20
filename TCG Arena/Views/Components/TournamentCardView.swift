//
//  TournamentCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct TournamentCardView: View {
    let tournament: Tournament
    let userRegistrationStatus: ParticipantStatus?
    let onRegisterTap: () -> Void
    @EnvironmentObject var authService: AuthService
    
    // MARK: - Computed Properties
    private var isRegistered: Bool {
        userRegistrationStatus == .REGISTERED || userRegistrationStatus == .CHECKED_IN
    }
    
    private var isWaitingList: Bool {
        userRegistrationStatus == .WAITING_LIST
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Left: Clean Date Box
            VStack(spacing: 0) {
                Text(monthString(from: tournament.startDate).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background(tournament.tcgType.themeColor)
                
                Text(dayString(from: tournament.startDate))
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .frame(width: 54)
            
            // Middle: Info
            VStack(alignment: .leading, spacing: 6) {
                Text(tournament.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Location & Time
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                        Text(timeString(from: tournament.startDate))
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    if let location = tournament.location {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 10))
                            Text(location.city)
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                }
                .foregroundColor(.secondary)
                
                // Badges Row
                HStack(spacing: 6) {
                    // Type Badge
                    Text(tournament.type?.displayName ?? "Torneo")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.secondarySystemFill))
                        .cornerRadius(4)
                        .foregroundColor(.primary)
                    
                    // Status Badge (if registered or pending)
                    if tournament.status == .pendingApproval {
                        Text("IN APPROVAZIONE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    } else if isRegistered {
                        Text("ISCRITTO")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    } else if isWaitingList {
                        Text("LISTA D'ATTESA")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
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
    
    private func timeString(from dateString: String) -> String {
        guard let date = parseDate(dateString) else { return "00:00" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
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
