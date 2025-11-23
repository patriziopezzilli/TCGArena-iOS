//
//  WelcomeView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/19/25.
//

import SwiftUI

struct WelcomeView: View {
    @State private var currentPage = 0
    @State private var showOnboarding = false

    let pages = [
        WelcomePage(
            title: "Esplora l'Universo TCG",
            subtitle: "Pokemon, Magic, Yu-Gi-Oh! e oltre",
            description: "Scopri migliaia di carte rare, espansioni esclusive e contenuti ufficiali dai tuoi giochi preferiti.",
            imageName: "sparkles",
            backgroundColor: Color.blue.opacity(0.1),
            accentColor: Color.blue,
            pattern: "card.pattern"
        ),
        WelcomePage(
            title: "Costruisci Deck Potenti",
            subtitle: "Organizza e Ottimizza la Tua Collezione",
            description: "Crea deck vincenti, traccia il valore delle tue carte e scopri nuove strategie con l'aiuto della community.",
            imageName: "rectangle.stack.fill.badge.plus",
            backgroundColor: Color.purple.opacity(0.1),
            accentColor: Color.purple,
            pattern: "deck.pattern"
        ),
        WelcomePage(
            title: "Combatti nei Tornei",
            subtitle: "Sfida Giocatori e Scala Classifiche",
            description: "Partecipa a eventi locali e online, sfida amici e diventa un maestro delle carte.",
            imageName: "trophy.fill",
            backgroundColor: Color.orange.opacity(0.1),
            accentColor: Color.orange,
            pattern: "tournament.pattern"
        ),
        WelcomePage(
            title: "Guadagna e Scambia",
            subtitle: "Ricompense Esclusive e Marketplace",
            description: "Ottieni punti community, sblocca contenuti speciali e scambia carte nel nostro marketplace sicuro.",
            imageName: "gift.fill",
            backgroundColor: Color.green.opacity(0.1),
            accentColor: Color.green,
            pattern: "reward.pattern"
        )
    ]

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Dynamic header with step-specific animations
                VStack(spacing: 32) {
                    ZStack {
                        // Outer glow effect
                        Circle()
                            .fill(pages[currentPage].accentColor.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .blur(radius: 25)

                        // Main icon circle with enhanced styling
                        Circle()
                            .fill(pages[currentPage].backgroundColor.opacity(0.8))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(pages[currentPage].accentColor.opacity(0.3), lineWidth: 2)
                            )

                        // Step-specific animated content
                        getStepAnimation()
                    }

                    // Dynamic decorative element
                }
                .padding(.top, 80)

                Spacer()

                // Enhanced page content with TCG theming
                VStack(spacing: 40) {
                    VStack(spacing: 24) {
                        Text(pages[currentPage].title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)

                        Text(pages[currentPage].subtitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(pages[currentPage].accentColor)
                            .multilineTextAlignment(.center)

                        Text(pages[currentPage].description)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(6)
                            .padding(.horizontal, 32)
                    }
                }
                .frame(height: 320)

                Spacer()

                // Enhanced page indicators with TCG styling
                HStack(spacing: 12) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        ZStack {
                            // Card-like indicator
                            RoundedRectangle(cornerRadius: 4)
                                .fill(index == currentPage ?
                                     pages[currentPage].accentColor :
                                     Color.gray.opacity(0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .scaleEffect(index == currentPage ? 1.0 : 0.8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)

                            // Glow effect for active indicator
                            if index == currentPage {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(pages[currentPage].accentColor.opacity(0.3))
                                    .frame(width: 32, height: 12)
                                    .blur(radius: 4)
                            }
                        }
                    }
                }
                .padding(.bottom, 60)

                // Enhanced action buttons with TCG theming
                VStack(spacing: 24) {
                    if currentPage == pages.count - 1 {
                        // Final page - show enhanced login/register buttons
                        VStack(spacing: 20) {
                            Button(action: {
                                showOnboarding = true
                            }) {
                                HStack(spacing: 16) {
                                    SwiftUI.Image(systemName: "sparkles")
                                        .font(.system(size: 20, weight: .medium))
                                    Text("Get Started")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [pages[currentPage].accentColor, pages[currentPage].accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .shadow(color: pages[currentPage].accentColor.opacity(0.3), radius: 10, x: 0, y: 6)
                            }

                            Button(action: {
                                showOnboarding = true
                            }) {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(pages[currentPage].accentColor)
                            }
                        }
                    } else {
                        // Enhanced navigation button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        }) {
                            HStack(spacing: 12) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .semibold))

                                SwiftUI.Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [pages[currentPage].accentColor, pages[currentPage].accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                        endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 27))
                            .shadow(color: pages[currentPage].accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 80)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }

    // Simple icon display
    @ViewBuilder
    private func getStepAnimation() -> some View {
        SwiftUI.Image(systemName: pages[currentPage].imageName)
            .font(.system(size: 60, weight: .light))
            .foregroundColor(pages[currentPage].accentColor.opacity(0.8))
    }
}

struct WelcomePage {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let backgroundColor: Color
    let accentColor: Color
    let pattern: String
}