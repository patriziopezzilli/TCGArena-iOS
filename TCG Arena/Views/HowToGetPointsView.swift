//
//  HowToGetPointsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct HowToGetPointsView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                
                // MARK: - Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("GUIDA PUNTI")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    Text("Scala la vetta.")
                        .font(.system(size: 34, weight: .heavy, design: .default))
                        .foregroundColor(.primary)
                    
                    Text("Guadagna punti partecipando alla vita della community.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // MARK: - Sections
                
                // Tournaments
                VStack(alignment: .leading, spacing: 16) {
                    PremiumSectionHeader(title: "Tornei", icon: "trophy.fill")
                    
                    VStack(spacing: 1) {
                        MinimalPointRow(title: "Vittoria 1° Posto", points: "+100", type: .bonus)
                        MinimalPointRow(title: "2° Posto", points: "+50", type: .bonus)
                        MinimalPointRow(title: "3° Posto", points: "+25", type: .bonus)
                        MinimalPointRow(title: "Check-in", points: "+25", type: .bonus)
                        MinimalPointRow(title: "Registrazione", points: "+15", type: .bonus)
                        MinimalPointRow(title: "Ritiro Iscrizione", points: "-10", type: .malus, isLast: true)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                
                // Collection
                VStack(alignment: .leading, spacing: 16) {
                    PremiumSectionHeader(title: "Collezione", icon: "square.stack.3d.up.fill")
                    
                    VStack(spacing: 1) {
                        MinimalPointRow(title: "Crea Primo Deck", points: "+50", type: .bonus)
                        MinimalPointRow(title: "Nuovi Deck", points: "+10", type: .bonus, isLast: true)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                
                // Shop
                VStack(alignment: .leading, spacing: 16) {
                    PremiumSectionHeader(title: "Negozi", icon: "storefront.fill")
                    
                    VStack(spacing: 1) {
                        MinimalPointRow(title: "Prenotazione Prodotto", points: "+10", type: .bonus, isLast: true)
                    }
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                
                // Info Box
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        SwiftUI.Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.secondary)
                        
                        Text("I punti vengono assegnati automaticamente al completamento dell'azione. Usa i punti accumulati per riscattare premi esclusivi nella sezione Premi.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Components

struct PremiumSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
            Text(title)
                .font(.system(size: 18, weight: .bold))
        }
        .foregroundColor(.primary)
    }
}

struct MinimalPointRow: View {
    let title: String
    let points: String
    let type: PointType
    var isLast: Bool = false
    
    enum PointType {
        case bonus, malus
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(points)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(type == .bonus ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (type == .bonus ? Color.green : Color.red).opacity(0.1)
                )
                .cornerRadius(6)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        
        if !isLast {
            Divider().padding(.leading, 16)
        }
    }
}

#Preview {
    HowToGetPointsView()
}