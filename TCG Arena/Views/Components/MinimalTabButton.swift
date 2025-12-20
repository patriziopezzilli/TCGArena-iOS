//
//  MinimalTabButton.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct MinimalTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .heavy : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                if isSelected {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
