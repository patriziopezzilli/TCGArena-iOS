//
//  HowToGetPointsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct HowToGetPointsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.2),
                                        Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        SwiftUI.Image(systemName: "star.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                    }
                    
                    VStack(spacing: 8) {
                        Text("How to Earn Points")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Discover all the ways to earn points and climb the leaderboard!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Tournament Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "🏆 Tournament Performance", icon: "trophy.fill", color: .orange)
                    
                    PointCard(
                        title: "Tournament Victory",
                        description: "Win a tournament",
                        points: "+500",
                        type: .bonus,
                        icon: "crown.fill"
                    )
                    
                    PointCard(
                        title: "Final Table",
                        description: "Reach the final table",
                        points: "+200",
                        type: .bonus,
                        icon: "medal.fill"
                    )
                    
                    PointCard(
                        title: "Top 8 Finish",
                        description: "Finish in top 8",
                        points: "+100",
                        type: .bonus,
                        icon: "star.fill"
                    )
                    
                    PointCard(
                        title: "Early Elimination",
                        description: "Get eliminated in round 1",
                        points: "-50",
                        type: .malus,
                        icon: "xmark.circle.fill"
                    )
                }
                .padding(.horizontal, 20)
                
                // Daily Activities Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "📅 Daily Activities", icon: "calendar.circle.fill", color: .blue)
                    
                    PointCard(
                        title: "Daily Login",
                        description: "Log in every day",
                        points: "+10",
                        type: .bonus,
                        icon: "checkmark.circle.fill"
                    )
                    
                    PointCard(
                        title: "Weekly Streak",
                        description: "7 consecutive days login",
                        points: "+100",
                        type: .bonus,
                        icon: "flame.fill"
                    )
                    
                    PointCard(
                        title: "Card Collection",
                        description: "Add 5 new cards to collection",
                        points: "+25",
                        type: .bonus,
                        icon: "plus.circle.fill"
                    )
                    
                    PointCard(
                        title: "Deck Building",
                        description: "Create a new deck",
                        points: "+50",
                        type: .bonus,
                        icon: "rectangle.stack.fill"
                    )
                }
                .padding(.horizontal, 20)
                
                // Social & Community Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "👥 Social & Community", icon: "person.2.circle.fill", color: .green)
                    
                    PointCard(
                        title: "Profile Completion",
                        description: "Complete your profile (photo, bio, favorite TCG)",
                        points: "+150",
                        type: .bonus,
                        icon: "person.circle.fill"
                    )
                    
                    PointCard(
                        title: "Share Achievement",
                        description: "Share tournament result on social media",
                        points: "+30",
                        type: .bonus,
                        icon: "square.and.arrow.up.fill"
                    )
                    
                    PointCard(
                        title: "Help New Player",
                        description: "Answer questions in community",
                        points: "+20",
                        type: .bonus,
                        icon: "hand.raised.fill"
                    )
                    
                    PointCard(
                        title: "Report Bug",
                        description: "Help improve the app",
                        points: "+75",
                        type: .bonus,
                        icon: "ant.circle.fill"
                    )
                }
                .padding(.horizontal, 20)
                
                // Special Events Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "🎉 Special Events", icon: "party.popper.fill", color: .purple)
                    
                    PointCard(
                        title: "Season Champion",
                        description: "Win the seasonal championship",
                        points: "+2000",
                        type: .bonus,
                        icon: "sparkles"
                    )
                    
                    PointCard(
                        title: "TCG Anniversary",
                        description: "Participate in anniversary event",
                        points: "+300",
                        type: .bonus,
                        icon: "gift.fill"
                    )
                    
                    PointCard(
                        title: "Beta Tester",
                        description: "Help test new features",
                        points: "+500",
                        type: .bonus,
                        icon: "wrench.and.screwdriver.fill"
                    )
                    
                    PointCard(
                        title: "Referral Bonus",
                        description: "Bring a friend to the app",
                        points: "+250",
                        type: .bonus,
                        icon: "person.fill.badge.plus"
                    )
                }
                .padding(.horizontal, 20)
                
                // Rules & Tips Section
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "📋 Rules & Tips", icon: "lightbulb.circle.fill", color: .yellow)
                    
                    VStack(spacing: 12) {
                        RuleCard(
                            title: "Point Multipliers",
                            description: "Points are multiplied during special events and weekends (x2 multiplier)"
                        )
                        
                        RuleCard(
                            title: "Season Reset",
                            description: "Points reset every season, but you keep your redeemed rewards forever"
                        )
                        
                        RuleCard(
                            title: "Fair Play",
                            description: "Cheating or unsportsmanlike behavior results in permanent point deduction"
                        )
                        
                        RuleCard(
                            title: "Leaderboard",
                            description: "Top 10 players each season get exclusive rewards and bragging rights"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Views
struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

struct PointCard: View {
    let title: String
    let description: String
    let points: String
    let type: PointType
    let icon: String
    
    enum PointType {
        case bonus, malus
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(type == .bonus ?
                          Color.green.opacity(0.2) :
                          Color.red.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(type == .bonus ? .green : .red)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Points
            Text(points)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(type == .bonus ? .green : .red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(type == .bonus ?
                              Color.green.opacity(0.1) :
                              Color.red.opacity(0.1))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

struct RuleCard: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationView {
        HowToGetPointsView()
    }
}