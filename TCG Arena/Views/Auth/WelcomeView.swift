//
//  WelcomeView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void
    
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Pure White Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                
                // MARK: - Hero Text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Giocatori.")
                        .font(.system(size: 60, weight: .heavy))
                        .foregroundColor(.primary)
                        .opacity(animateTitle ? 1 : 0)
                        .offset(y: animateTitle ? 0 : 20)
                    
                    Text("Negozi.")
                        .font(.system(size: 60, weight: .heavy))
                        .foregroundColor(.primary)
                        .opacity(animateTitle ? 1 : 0)
                        .offset(y: animateTitle ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateTitle)
                    
                    Text("Un'unica arena.")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                        .opacity(animateSubtitle ? 1 : 0)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // MARK: - Action
                Button(action: onStart) {
                    HStack {
                        Text("Inizia")
                            .font(.system(size: 20, weight: .bold))
                        SwiftUI.Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Color.primary)
                    .cornerRadius(32)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
                .opacity(animateButton ? 1 : 0)
                .offset(y: animateButton ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateTitle = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                animateSubtitle = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.2)) {
                animateButton = true
            }
        }
    }
}

#Preview {
    WelcomeView(onStart: {})
}
