//
//  NewAddCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI
import Vision
import VisionKit
import PhotosUI

struct NewAddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button(action: { dismiss() }) {
                            SwiftUI.Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 30) {
                            // Title Section
                            VStack(spacing: 4) {
                                Text("Nuova Carta")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .primary.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text("Scegli come vuoi aggiungere la tua prossima carta alla collezione")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 10)
                            
                            // Options Grid
                            VStack(spacing: 20) {
                                // Manual Entry
                                NavigationLink(destination: ManualAddCardView()
                                    .environmentObject(cardService)
                                    .environmentObject(deckService)
                                ) {
                                    NewAddCardOptionView(
                                        icon: "keyboard.fill",
                                        title: "Manuale",
                                        subtitle: "Cerca per nome, set o numero",
                                        accentColor: .blue,
                                        badge: "Consigliato"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Scan Entry (Disabled)
                                NewAddCardOptionView(
                                    icon: "camera.viewfinder",
                                    title: "Scansiona",
                                    subtitle: "Usa la fotocamera per identificare",
                                    accentColor: .purple,
                                    badge: "Presto disponibile",
                                    isDisabled: true
                                )
                            }
                            .padding(.horizontal, 24)
                            
                            // Pro Tips
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    SwiftUI.Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("Consigli Pro")
                                        .font(.headline)
                                }
                                .padding(.bottom, 4)
                                
                                NewAddCardTipRow(icon: "magnifyingglass", text: "Usa il codice del set (es. OP01-001) per risultati precisi")
                                NewAddCardTipRow(icon: "square.stack.3d.up.fill", text: "Puoi aggiungere più copie della stessa carta")
                                NewAddCardTipRow(icon: "star.fill", text: "Specifica la condizione per tracciare il valore reale")
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                            )
                            .padding(.horizontal, 24)
                            
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct NewAddCardOptionView: View {
    let icon: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let badge: String?
    var isDisabled: Bool = false
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.1))
                            .clipShape(Capsule())
                            .foregroundColor(accentColor)
                    }
                }
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            if !isDisabled {
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(accentColor.opacity(0.3), lineWidth: 1.5)
        )
        .opacity(isDisabled ? 0.6 : 1.0)
        .scaleEffect(isDisabled ? 0.98 : 1.0)
    }
}

struct NewAddCardTipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
