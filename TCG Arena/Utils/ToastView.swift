//
//  ToastView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/3/25.
//

import SwiftUI

struct ToastView: View {
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(message)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.bottom, 40)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct ToastModifier: ViewModifier {
    let message: String
    let icon: String
    let color: Color
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isPresented {
                    ToastView(message: message, icon: icon, color: color)
                }
            }
    }
}

extension View {
    func toast(message: String, icon: String = "checkmark.circle.fill", color: Color = .green, isPresented: Bool) -> some View {
        self.modifier(ToastModifier(message: message, icon: icon, color: color, isPresented: isPresented))
    }
}