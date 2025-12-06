//
//  HowToGetPointsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/15/25.
//

import SwiftUI

struct HowToGetPointsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero Section
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.2),
                                        Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.0).opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        SwiftUI.Image(systemName: "star.circle.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                    }
                    
                    VStack(spacing: 8) {
                        Text("Come Guadagnare Punti")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("Scopri tutti i modi per accumulare punti e riscattare premi!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Tournament Section
                VStack(alignment: .leading, spacing: 16) {
                    PointsSectionHeader(title: "🏆 Tornei", icon: "trophy.fill", color: .orange)
                    
                    PointCard(
                        title: "Registrazione Torneo",
                        description: "Iscriviti a un torneo",
                        points: "+15",
                        type: .bonus,
                        icon: "ticket.fill"
                    )
                    
                    PointCard(
                        title: "Check-in Torneo",
                        description: "Effettua il check-in il giorno del torneo",
                        points: "+25",
                        type: .bonus,
                        icon: "checkmark.circle.fill"
                    )
                    
                    PointCard(
                        title: "1° Posto",
                        description: "Vinci il torneo",
                        points: "+100",
                        type: .bonus,
                        icon: "crown.fill"
                    )
                    
                    PointCard(
                        title: "2° Posto",
                        description: "Arrivi secondo nel torneo",
                        points: "+50",
                        type: .bonus,
                        icon: "medal.fill"
                    )
                    
                    PointCard(
                        title: "3° Posto",
                        description: "Arrivi terzo nel torneo",
                        points: "+25",
                        type: .bonus,
                        icon: "star.fill"
                    )
                    
                    PointCard(
                        title: "Cancellazione Iscrizione",
                        description: "Annulli l'iscrizione al torneo",
                        points: "-10",
                        type: .malus,
                        icon: "xmark.circle.fill"
                    )
                }
                .padding(.horizontal, 20)
                
                // Collection Section
                VStack(alignment: .leading, spacing: 16) {
                    PointsSectionHeader(title: "📦 Collezione", icon: "square.stack.3d.up.fill", color: .blue)
                    
                    PointCard(
                        title: "Primo Deck",
                        description: "Crea il tuo primo deck",
                        points: "+50",
                        type: .bonus,
                        icon: "rectangle.stack.fill"
                    )
                    
                    PointCard(
                        title: "Nuovi Deck",
                        description: "Crea altri deck dopo il primo",
                        points: "+10",
                        type: .bonus,
                        icon: "plus.rectangle.on.rectangle"
                    )
                }
                .padding(.horizontal, 20)
                
                // Shop & Reservations Section
                VStack(alignment: .leading, spacing: 16) {
                    PointsSectionHeader(title: "🏪 Negozi", icon: "storefront.fill", color: .green)
                    
                    PointCard(
                        title: "Prenotazione Prodotto",
                        description: "Prenota un prodotto in un negozio",
                        points: "+10",
                        type: .bonus,
                        icon: "calendar.badge.plus"
                    )
                }
                .padding(.horizontal, 20)
                
                // Info Section
                VStack(alignment: .leading, spacing: 16) {
                    PointsSectionHeader(title: "ℹ️ Info", icon: "info.circle.fill", color: .gray)
                    
                    VStack(spacing: 12) {
                        RuleCard(
                            title: "Punti Reali",
                            description: "I punti mostrati sono quelli effettivamente guadagnati nel sistema"
                        )
                        
                        RuleCard(
                            title: "Riscatta Premi",
                            description: "Usa i punti per riscattare sconti, gadget e premi esclusivi"
                        )
                        
                        RuleCard(
                            title: "Trasparenza",
                            description: "Ogni azione che ti fa guadagnare punti mostra una notifica con l'importo esatto"
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Supporting Views
struct PointsSectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
            
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

struct PointCard: View {
    let title: String
    let description: String
    let points: String
    let type: PointType
    let icon: String
    
    enum PointType {
        case bonus, malus
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(type == .bonus ?
                          Color.green.opacity(0.2) :
                          Color.red.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(type == .bonus ? .green : .red)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Points
            Text(points)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(type == .bonus ? .green : .red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(type == .bonus ?
                              Color.green.opacity(0.1) :
                              Color.red.opacity(0.1))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
        )
    }
}

struct RuleCard: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(description)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    NavigationView {
        HowToGetPointsView()
    }
}