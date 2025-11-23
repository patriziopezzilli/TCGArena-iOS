//
//  RewardsMainView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct RewardsMainView: View {
    @State private var selectedSegment = 0
    @EnvironmentObject var rewardsService: RewardsService

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clean Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rewards")
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Earn points and redeem rewards")
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Clean segment picker
                HStack(spacing: 0) {
                    ForEach([(0, "Rewards", "gift.fill"), (1, "Partners", "building.2.fill"), (2, "Earn Points", "questionmark.circle.fill")], id: \.0) { index, title, icon in
                        Button(action: {
                            selectedSegment = index
                        }) {
                            VStack(spacing: 8) {
                                SwiftUI.Image(systemName: icon)
                                    .font(.system(size: 16, weight: .medium))

                                Text(title)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(selectedSegment == index ? .white : .primary)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedSegment == index ?
                                        Color(red: 0.56, green: 0.60, blue: 0.63) :
                                        Color.clear
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                TabView(selection: $selectedSegment) {
                    RewardsView()
                        .environmentObject(rewardsService)
                        .tag(0)

                    PartnersView()
                        .tag(1)
                    
                    HowToGetPointsView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    RewardsMainView()
}