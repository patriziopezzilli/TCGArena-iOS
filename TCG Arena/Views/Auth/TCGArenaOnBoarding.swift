//
//  TCGArenaOnBoarding.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI
import OnBoardingKit

struct TCGArenaOnBoarding: OnBoarding {
    var image: ImageStyle? {
        .icon(SwiftUI.Image(systemName: "gamecontroller.fill"))
    }
    
    var title: Text {
        Text("Welcome to TCG Arena")
    }
    
    var features: [Feature] {
        [
            Feature(
                image: SwiftUI.Image(systemName: "rectangle.stack.fill"),
                label: Text("Build Your Collection"),
                description: Text("Track your cards from Pokémon, Magic, Yu-Gi-Oh!, One Piece and more.")
            ),
            Feature(
                image: SwiftUI.Image(systemName: "square.stack.3d.up.fill"),
                label: Text("Create Powerful Decks"),
                description: Text("Build and share competitive decks with the community.")
            ),
            Feature(
                image: SwiftUI.Image(systemName: "trophy.fill"),
                label: Text("Join Tournaments"),
                description: Text("Find local events and compete with players near you.")
            ),
            Feature(
                image: SwiftUI.Image(systemName: "storefront.fill"),
                label: Text("Discover Local Shops"),
                description: Text("Find TCG stores, check their inventory and get updates.")
            )
        ]
    }
    
    var button: Text {
        Text("Get Started")
    }
}
