//
//  TCGTypeBadge.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import SwiftUI

struct TCGTypeBadge: View {
    let tcgTypeString: String
    
    private var tcgType: TCGType? {
        TCGType(rawValue: tcgTypeString)
    }
    
    // Convenience init for direct TCGType
    init(tcgType: TCGType) {
        self.tcgTypeString = tcgType.rawValue
    }
    
    // Init for String (from backend)
    init(tcgTypeString: String) {
        self.tcgTypeString = tcgTypeString
    }
    
    var body: some View {
        if let tcg = tcgType {
            Text(tcg.displayName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(tcg.themeColor)
                )
        } else {
            // Fallback for unknown types
            Text(tcgTypeString)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.gray)
                )
        }
    }
}
