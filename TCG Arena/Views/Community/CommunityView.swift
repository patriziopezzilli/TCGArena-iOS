//
//  CommunityView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct CommunityView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clean Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Community")
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Discover players and content")
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Tab selector
                HStack(spacing: 0) {
                    TabButton(title: "Discover", isSelected: selectedTab == 0) {
                        selectedTab = 0
                    }
                    TabButton(title: "Notifications", isSelected: selectedTab == 1) {
                        selectedTab = 1
                    }
                    TabButton(title: "Achievements", isSelected: selectedTab == 2) {
                        selectedTab = 2
                    }
                    TabButton(title: "Leaderboard", isSelected: selectedTab == 3) {
                        selectedTab = 3
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                TabView(selection: $selectedTab) {
                    DiscoverView()
                        .tag(0)
                    
                    NotificationView()
                        .tag(1)
                    
                    AchievementView()
                        .tag(2)

                    LeaderboardView()
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.clear)
                )
        }
    }
}

#Preview {
    CommunityView()
}
