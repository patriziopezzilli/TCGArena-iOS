//
//  TCGButton.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct TCGButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    let isLoading: Bool
    
    enum ButtonStyle {
        case primary
        case secondary
        case destructive
        case plain
        case accent
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Color(red: 0.1, green: 0.1, blue: 0.15)
            case .secondary: return Color(red: 0.15, green: 0.15, blue: 0.2)
            case .accent: return Color(red: 0.3, green: 0.6, blue: 1.0)
            case .destructive: return Color(red: 0.85, green: 0.2, blue: 0.2)
            case .plain: return .clear
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .accent, .destructive: return .white
            case .plain: return TCGTheme.Colors.accent
            }
        }
        
        var borderColor: Color {
            switch self {
            case .plain: return Color(red: 0.3, green: 0.6, blue: 1.0)
            default: return .clear
            }
        }
    }
    
    init(_ title: String, style: ButtonStyle = .primary, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor, lineWidth: style == .plain ? 2 : 0)
            )
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.12), radius: style == .plain ? 0 : 4, x: 0, y: 2)
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        TCGButton("Primary Button") { }
        TCGButton("Secondary Button", style: .secondary) { }
        TCGButton("Destructive Button", style: .destructive) { }
        TCGButton("Plain Button", style: .plain) { }
        TCGButton("Loading Button", isLoading: true) { }
    }
    .padding()
}