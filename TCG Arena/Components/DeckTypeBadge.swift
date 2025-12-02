//
//  DeckTypeBadge.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/30/25.
//

import SwiftUI

struct DeckTypeBadge: View {
    let deckType: DeckType
    
    var body: some View {
        Text(deckType.displayName)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(deckType == .deck ? Color.blue : Color.green)
            )
    }
}

#Preview {
    HStack {
        DeckTypeBadge(deckType: .deck)
        DeckTypeBadge(deckType: .lista)
    }
}