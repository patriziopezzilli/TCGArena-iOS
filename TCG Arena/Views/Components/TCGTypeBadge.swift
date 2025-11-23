//
//  TCGTypeBadge.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import SwiftUI

struct TCGTypeBadge: View {
    let tcgType: TCGType
    
    var body: some View {
        Text(tcgType.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(tcgType.themeColor)
            )
    }
}
