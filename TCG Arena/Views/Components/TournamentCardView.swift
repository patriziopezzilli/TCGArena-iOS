//
//  TournamentCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct TournamentCardView: View {
    let tournament: Tournament
    let userRegistrationStatus: ParticipantStatus?  // nil = not registered, .REGISTERED, .WAITING_LIST, etc.
    let onRegisterTap: () -> Void
    @EnvironmentObject var authService: AuthService
    
    // Computed properties for display
    private var isRegistered: Bool {
        userRegistrationStatus == .REGISTERED || userRegistrationStatus == .CHECKED_IN
    }
    
    private var isWaitingList: Bool {
        userRegistrationStatus == .WAITING_LIST
    }
    
    private var buttonText: String {
        if isRegistered {
            return "Registered"
        } else if isWaitingList {
            return "Waiting"
        } else if tournament.isFull {
            return "Join Waitlist"
        } else {
            return "Join"
        }
    }
    
    private var buttonColor: Color {
        if isRegistered {
            return .green
        } else if isWaitingList {
            return .orange
        } else {
            return tournament.tcgType.themeColor
        }
    }
    
    private var buttonBackgroundColor: Color {
        if isRegistered {
            return Color.green.opacity(0.1)
        } else if isWaitingList {
            return Color.orange.opacity(0.1)
        } else {
            return tournament.tcgType.themeColor
        }
    }
    
    private var buttonForegroundColor: Color {
        if isRegistered || isWaitingList {
            return buttonColor
        } else {
            return .white
        }
    }
    
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
                badgesSection

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
                
                // Footer: Participants & Button/Badge
                HStack {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: "person.2.fill")
                            .font(.system(size: 12))
                        if let maxParticipants = tournament.maxParticipants {
                            Text("\(tournament.registeredParticipantsCount)/\(maxParticipants)")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()

                    // Show pending approval badge in footer
                    if tournament.status == .pendingApproval {
                        pendingApprovalBadge
                    } else if (tournament.status == .registrationOpen || tournament.status == .upcoming) && authService.isAuthenticated && authService.currentUserId != nil {
                        Button(action: onRegisterTap) {
                            Text(buttonText)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(buttonForegroundColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(buttonBackgroundColor)
                                )
                        }
                        .buttonStyle(BounceButtonStyle())
                        .disabled(isRegistered)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .background(
            Group {
                if tournament.isRanked == true {
                    // Premium gold gradient overlay for ranked tournaments
                    ZStack {
                        Color(.systemBackground)
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.6).opacity(0.15), Color.clear]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                } else {
                    Color(.systemBackground)
                }
            }
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    tournament.isRanked == true ? Color(red: 0.85, green: 0.65, blue: 0.2) : Color.clear,
                    lineWidth: tournament.isRanked == true ? 2 : 0
                )
        )
        .shadow(color: tournament.isRanked == true ? Color(red: 0.85, green: 0.65, blue: 0.2).opacity(0.3) : Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Badge Section
    private var badgesSection: some View {
        HStack(spacing: 8) {
            if tournament.status == .inProgress {
                LiveBadgeView()
            }
            
            if tournament.status == .rejected {
                rejectedBadge
            }
            
            if tournament.isRanked == true {
                officialBadge
            }
            
            tcgTypeBadge
            
            if tournament.isRanked != true, let type = tournament.type {
                tournamentTypeBadge(type)
            }

            Spacer()

            priceBadge
        }
    }
    
    private var pendingApprovalBadge: some View {
        HStack(spacing: 4) {
            SwiftUI.Image(systemName: "clock.fill")
                .font(.system(size: 8))
            Text("In Approvazione")
                .fontWeight(.bold)
        }
        .font(.system(size: 10))
        .foregroundColor(Color.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.orange.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(6)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var rejectedBadge: some View {
        HStack(spacing: 4) {
            SwiftUI.Image(systemName: "xmark.circle.fill")
                .font(.system(size: 8))
            Text("Rifiutato")
                .fontWeight(.bold)
        }
        .font(.system(size: 10))
        .foregroundColor(Color.red)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.red.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.red.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(6)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var officialBadge: some View {
        HStack(spacing: 4) {
            Text("🏆")
            Text("Ufficiale")
                .fontWeight(.bold)
        }
        .font(.system(size: 10))
        .foregroundColor(Color(red: 0.6, green: 0.45, blue: 0.1))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.3))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(red: 0.85, green: 0.65, blue: 0.2), lineWidth: 1)
        )
        .cornerRadius(6)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private var tcgTypeBadge: some View {
        Text(tournament.tcgType.displayName)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(tournament.tcgType.themeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tournament.tcgType.themeColor.opacity(0.1))
            .cornerRadius(4)
    }
    
    private func tournamentTypeBadge(_ type: Tournament.TournamentType) -> some View {
        Text(type.rawValue)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(4)
    }
    
    @ViewBuilder
    private var priceBadge: some View {
        if let entryFee = tournament.entryFee, entryFee > 0 {
            Text("€\(entryFee, specifier: "%.0f")")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
        } else if tournament.entryFee != nil {
            Text("Free")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.green)
        }
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

// MARK: - Live Badge Component
struct LiveBadgeView: View {
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.2 : 0.8)
                .opacity(isPulsing ? 1.0 : 0.5)
            
            Text("LIVE")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.orange]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .shadow(color: Color.red.opacity(0.4), radius: isPulsing ? 6 : 2, x: 0, y: 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
