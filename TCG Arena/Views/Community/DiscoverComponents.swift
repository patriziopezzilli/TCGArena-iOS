//
//  DiscoverComponents.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

// MARK: - Leaderboard Row
struct DiscoverLeaderboardRow: View {
    let entry: LeaderboardEntry
    let position: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Rank Badge
                ZStack {
                    Circle()
                        .fill(rankColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text("\(entry.rank)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(rankColor)
                }
                
                // User Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [entry.userProfile.preferredTCG?.themeColor ?? .gray, entry.userProfile.preferredTCG?.themeColor.opacity(0.7) ?? .gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                    
                    Text(String(entry.userProfile.displayName.prefix(2)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    if entry.userProfile.isVerified {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                SwiftUI.Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.blue)
                                    .background(Circle().fill(.white).scaleEffect(1.2))
                            }
                        }
                        .frame(width: 44, height: 44)
                    }
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.userProfile.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("@\(entry.userProfile.username)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Score and Change
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(entry.score)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let change = entry.change, !change.isNew {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: change.changeType.icon)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(change.changeType.color)
                            
                            Text("\(abs(change.rankChange))")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(change.changeType.color)
                        }
                    } else if let change = entry.change, change.isNew {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.blue)
                            
                            Text("NEW")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.5))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }
}

// MARK: - Activity Card
struct ActivityCard: View {
    let activity: UserActivity
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    SwiftUI.Image(systemName: "star.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
                
                // User Avatar (Small)
                ZStack {
                    Circle()
                        .fill(activity.userProfile?.preferredTCG?.themeColor ?? .gray)
                        .frame(width: 32, height: 32)
                    
                    Text(String(activity.userProfile?.displayName.prefix(1) ?? "").uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Activity Details
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(activity.userProfile?.displayName ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if activity.userProfile?.isVerified == true {
                            SwiftUI.Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Text(activity.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Timestamp
                if let date = ISO8601DateFormatter().date(from: activity.timestamp) {
                    Text(timeAgoString(from: date))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Text("Unknown")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d"
        }
    }
}

// MARK: - New User Card
struct NewUserCard: View {
    let user: UserProfile
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [user.preferredTCG?.themeColor ?? .blue, user.preferredTCG?.themeColor.opacity(0.7) ?? .blue.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Text(String(user.displayName.prefix(2)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    // New badge
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(.green)
                                    .frame(width: 16, height: 16)
                                
                                Text("N")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                    }
                    .frame(width: 50, height: 50)
                }
                
                VStack(spacing: 2) {
                    Text(user.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Level \(user.level)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Join date
                Text("Joined \(joinedAgoString(from: user.joinDate))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green)
            }
            .padding(12)
            .frame(width: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func joinedAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        
        if days < 7 {
            return "\(days)d ago"
        } else {
            let weeks = days / 7
            return "\(weeks)w ago"
        }
    }
}