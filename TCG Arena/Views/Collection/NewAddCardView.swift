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
    
    @State private var showingScanner = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nuova Carta")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        Text("Scegli come vuoi aggiungere la tua prossima carta alla collezione")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    // MARK: - Options
                    VStack(spacing: 0) {
                        // Manual Entry
                        NavigationLink(destination: ManualAddCardView()
                            .environmentObject(cardService)
                            .environmentObject(deckService)
                        ) {
                            AddOptionRow(
                                icon: "keyboard",
                                title: "Ricerca Manuale",
                                subtitle: "Cerca per nome, set o numero",
                                badge: "Consigliato"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Divider().padding(.leading, 64)
                        
                        // Scan Entry
                        Button(action: { showingScanner = true }) {
                            AddOptionRow(
                                icon: "camera.viewfinder",
                                title: "Scansiona Carta",
                                subtitle: "Scansiona con fotocamera",
                                isDisabled: false
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .sheet(isPresented: $showingScanner) {
                            CardScannerView(isPresented: $showingScanner)
                        }
                    }
                    .background(Color(.systemBackground))
                    
                    // MARK: - Pro Tips
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CONSIGLI PRO")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            TipRow(icon: "magnifyingglass", text: "Usa il codice set (es. OP01-001) per precisione")
                            TipRow(icon: "square.stack.3d.up", text: "Aggiungi più copie della stessa carta")
                            TipRow(icon: "star", text: "Specifica la condizione per il valore reale")
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Color(.systemBackground))
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(action: { dismiss() }) {
                    ZStack {
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 36, height: 36)
                        
                        SwiftUI.Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
            }
        }
    }
}

// MARK: - Components
struct AddOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var badge: String? = nil
    var isDisabled: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                if isDisabled {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 40, height: 40)
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(Color(.tertiaryLabel))
                } else {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 40, height: 40)
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(isDisabled ? .secondary : .primary)
                    
                    if let badge = badge {
                        Text(badge.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .cornerRadius(4)
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if !isDisabled {
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
        .opacity(isDisabled ? 0.6 : 1)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
        }
    }
}
