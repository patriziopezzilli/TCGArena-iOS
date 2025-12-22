//
//  LoadingComponents.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                }
                
                Text(message)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
            }
            .scaleEffect(0.9)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: true)
        }
    }
}

// MARK: - Shimmer Effect for Cards
struct ShimmerCard: View {
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray5),
                        Color(.systemGray4),
                        Color(.systemGray5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: isAnimating ? 200 : -200)
            )
            .clipped()
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Elegant Button Loading
struct LoadingButton: View {
    let title: String
    let loadingTitle: String
    let isLoading: Bool
    let action: () -> Void
    let isDisabled: Bool
    let color: Color
    
    init(
        title: String,
        loadingTitle: String = "Caricamento...",
        isLoading: Bool,
        isDisabled: Bool = false,
        color: Color = .purple,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.loadingTitle = loadingTitle
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .transition(.scale.combined(with: .opacity))
                } else {
                    SwiftUI.Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .transition(.scale.combined(with: .opacity))
                }
                
                Text(isLoading ? loadingTitle : title)
                    .font(.system(size: 17, weight: .semibold))
                    .transition(.opacity)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(color)
            .cornerRadius(14)
            .shadow(
                color: color.opacity(0.25),
                radius: isLoading ? 2 : 6,
                x: 0,
                y: isLoading ? 1 : 3
            )
            .scaleEffect(isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled && !isLoading ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// MARK: - Smooth Content Transition
struct ContentTransition<Content: View>: View {
    let isLoading: Bool
    let content: () -> Content
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { _ in
                        ShimmerCard()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                content()
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: isLoading)
    }
}

// MARK: - Success Animation
struct SuccessAnimation: View {
    @State private var isVisible = false
    @State private var checkmarkScale = 0.5
    @State private var circleScale = 0.8
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                    .scaleEffect(circleScale)
                
                Circle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .scaleEffect(circleScale)
                
                SwiftUI.Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.green)
                    .scaleEffect(checkmarkScale)
            }
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    isVisible = true
                    circleScale = 1.0
                }
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
                    checkmarkScale = 1.0
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        LoadingButton(
            title: "Add to Collection",
            loadingTitle: "Adding Card...",
            isLoading: true,
            action: {}
        )
        
        ShimmerCard()
        
        LoadingOverlay(message: "Saving your card...")
    }
    .padding()
}