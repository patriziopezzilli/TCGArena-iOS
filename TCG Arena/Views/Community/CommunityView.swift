//
//  CommunityView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct CommunityView: View {

    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Premium Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Community")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Connect with players")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Profile/Settings placeholder
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(
                                SwiftUI.Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .background(Color(.systemBackground))
                    
                    // Content
                    DiscoverView()
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
}



#Preview {
    CommunityView()
}
