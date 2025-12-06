//
//  RewardsMainView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct RewardsMainView: View {
    @EnvironmentObject var rewardsService: RewardsService

    var body: some View {
        RewardsView()
            .environmentObject(rewardsService)
    }
}

#Preview {
    RewardsMainView()
}