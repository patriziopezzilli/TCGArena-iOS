//
//  TCGRulesView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/6/25.
//

import SwiftUI

struct TCGRulesView: View {
    let tcgType: TCGType
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with TCG branding
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(tcgType.themeColor.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            SwiftUI.Image(systemName: tcgType.systemIcon)
                                .font(.system(size: 36))
                                .foregroundColor(tcgType.themeColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tcgType.displayName)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Regolamento Ufficiale")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Rules content
                    rulesContent
                        .padding(.horizontal, 20)
                    
                    // External links
                    externalLinksSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var rulesContent: some View {
        switch tcgType {
        case .pokemon:
            pokemonRules
        case .magic:
            magicRules
        case .yugioh:
            yugiohRules
        case .onePiece:
            onePieceRules
        case .digimon:
            digimonRules
        case .dragonBallSuper, .dragonBallFusion:
            dragonBallRules
        case .fleshAndBlood:
            fleshAndBloodRules
        case .lorcana:
            lorcanaRules
        }
    }
    
    private var pokemonRules: some View {
        VStack(alignment: .leading, spacing: 20) {
            RuleSection(title: "🎮 Obiettivo del Gioco", content: """
            L'obiettivo è sconfiggere l'avversario in uno di questi modi:
            • Raccogliere tutte e 6 le carte Premio
            • Mettere KO tutti i Pokémon avversari in gioco
            • L'avversario non può pescare all'inizio del turno
            """)
            
            RuleSection(title: "🃏 Composizione del Mazzo", content: """
            • 60 carte esatte
            • Massimo 4 copie di carte con lo stesso nome (escluse energie base)
            • Almeno 1 Pokémon Base
            """)
            
            RuleSection(title: "⚡ Tipi di Carte", content: """
            • Pokémon: Base, Fase 1, Fase 2, Pokémon-ex, V, VMAX, etc.
            • Trainer: Strumenti, Oggetti, Supporter, Stadi
            • Energia: Base e Speciale
            """)
            
            RuleSection(title: "🔄 Fasi del Turno", content: """
            1. Pesca una carta
            2. Azioni (in qualsiasi ordine):
               - Giocare Pokémon Base in panchina
               - Evolvere Pokémon
               - Attaccare Energie
               - Giocare carte Trainer
               - Usare Abilità
               - Ritirata
            3. Attacco (opzionale, termina il turno)
            """)
        }
    }
    
    private var magicRules: some View {
        VStack(alignment: .leading, spacing: 20) {
            RuleSection(title: "🎮 Obiettivo del Gioco", content: """
            Ridurre i punti vita dell'avversario da 20 a 0, oppure farlo pescare da un mazzo vuoto.
            """)
            
            RuleSection(title: "🃏 Composizione del Mazzo", content: """
            • Minimo 60 carte (Constructed)
            • Massimo 4 copie di carte con lo stesso nome (escluse terre base)
            • Commander: 100 carte, singleton
            """)
            
            RuleSection(title: "🌈 Tipi di Carte", content: """
            • Terre: Producono mana
            • Creature: Attaccano e difendono
            • Istantanei: Giocabili in qualsiasi momento
            • Stregonerie: Solo durante il tuo turno principale
            • Artefatti: Permanenti incolori
            • Incantesimi: Effetti persistenti
            • Planeswalker: Alleati potenti
            """)
            
            RuleSection(title: "🔄 Fasi del Turno", content: """
            1. Inizio (STAP, mantenimento, pesca)
            2. Prima fase principale
            3. Combattimento
            4. Seconda fase principale
            5. Fine turno
            """)
        }
    }
    
    private var yugiohRules: some View {
        VStack(alignment: .leading, spacing: 20) {
            RuleSection(title: "🎮 Obiettivo del Gioco", content: """
            Ridurre i Life Points dell'avversario da 8000 a 0.
            """)
            
            RuleSection(title: "🃏 Composizione del Mazzo", content: """
            • Main Deck: 40-60 carte
            • Extra Deck: 0-15 carte (Fusion, Synchro, Xyz, Link)
            • Side Deck: 0-15 carte
            • Massimo 3 copie per carta
            """)
            
            RuleSection(title: "⚔️ Tipi di Carte", content: """
            • Mostri: Normali, Effetto, Ritual, Fusion, Synchro, Xyz, Pendulum, Link
            • Magie: Normali, Continue, di Campo, Equipaggiamento, Quick-Play, Ritual
            • Trappole: Normali, Continue, Counter
            """)
            
            RuleSection(title: "🔄 Fasi del Turno", content: """
            1. Draw Phase
            2. Standby Phase
            3. Main Phase 1
            4. Battle Phase
            5. Main Phase 2
            6. End Phase
            """)
        }
    }
    
    private var onePieceRules: some View {
        VStack(alignment: .leading, spacing: 20) {
            RuleSection(title: "🎮 Obiettivo del Gioco", content: """
            Ridurre la vita del Leader avversario a 0 attaccando con i tuoi personaggi.
            """)
            
            RuleSection(title: "🃏 Composizione del Mazzo", content: """
            • 50 carte + 1 Leader
            • Massimo 4 copie per carta
            • Il mazzo deve avere solo colori compatibili con il Leader
            """)
            
            RuleSection(title: "🏴‍☠️ Tipi di Carte", content: """
            • Leader: Il tuo capitano
            • Personaggi: Attaccano e difendono
            • Eventi: Effetti unici
            • Fasi: Effetti persistenti
            """)
        }
    }
    
    private var digimonRules: some View {
        VStack(alignment: .leading, spacing: 20) {
            RuleSection(title: "🎮 Obiettivo del Gioco", content: """
            Ridurre il Security Stack dell'avversario a 0 e attaccare direttamente.
            """)
            
            RuleSection(title: "🃏 Composizione del Mazzo", content: """
            • 50 carte esatte
            • 0-5 carte Digi-Egg
            • Massimo 4 copie per carta
            """)
            
            RuleSection(title: "📱 Meccaniche Chiave", content: """
            • Digivoluzione: Evolvi i tuoi Digimon per renderli più forti
            • Memory Gauge: Sistema di gestione turni unico
            • Security Check: Le carte difensive vengono pescate dal deck
            """)
        }
    }
    
    private var dragonBallRules: some View {
        VStack(alignment: .leading, spacing: 20) {
            RuleSection(title: "🎮 Obiettivo del Gioco", content: """
            Esaurire le vite del Leader avversario.
            """)
            
            RuleSection(title: "🃏 Composizione del Mazzo", content: """
            • 50 carte + 1 Leader
            • Massimo 4 copie per carta
            """)
            
            RuleSection(title: "🐉 Tipi di Carte", content: """
            • Leader: Si evolve durante la battaglia
            • Battle Cards: Personaggi che combattono
            • Extra Cards: Abilità speciali
            """)
        }
    }
    
    private var lorcanaRules: some View {
        VStack(alignment: .leading, spacing: 20) {
            RuleSection(title: "🎮 Obiettivo del Gioco", content: """
            Essere il primo giocatore a raccogliere 20 Lore.
            """)
            
            RuleSection(title: "🃏 Composizione del Mazzo", content: """
            • 60 carte esatte
            • Massimo 2 colori (inchiostri)
            • Massimo 4 copie per carta
            """)
            
            RuleSection(title: "✨ Tipi di Carte", content: """
            • Personaggi: Esplorano per raccogliere Lore
            • Oggetti: Forniscono abilità
            • Azioni: Effetti immediati
            • Canzoni: Azioni speciali cantate dai personaggi
            """)
            
            RuleSection(title: "🔄 Fasi del Turno", content: """
            1. Ready (STAP delle carte)
            2. Set (Metti una carta Inkable nell'Inkwell)
            3. Draw (Pesca una carta)
            4. Main (Gioca carte, sfida, esplora)
            """)
        }
    }
    
    private var fleshAndBloodRules: some View {
        VStack(alignment: .leading, spacing: 20) {
            RuleSection(title: "🎮 Obiettivo del Gioco", content: """
            Ridurre la vita dell'avversario a 0 usando il tuo eroe e le sue abilità.
            """)
            
            RuleSection(title: "🃏 Composizione del Mazzo", content: """
            • 60+ carte nel mazzo
            • 1 Eroe e equipaggiamenti
            • Massimo 3 copie per carta
            """)
            
            RuleSection(title: "⚔️ Tipi di Carte", content: """
            • Eroe: Il tuo personaggio principale
            • Armi: Permettono di attaccare
            • Equipaggiamenti: Armatura e accessori
            • Azioni: Mosse offensive e difensive
            """)
        }
    }
    
    private var externalLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🔗 Link Utili")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ExternalLinkButton(
                    title: "Regolamento Ufficiale Completo",
                    icon: "doc.text.fill",
                    url: officialRulesURL
                )
                
                ExternalLinkButton(
                    title: "Video Tutorial",
                    icon: "play.circle.fill",
                    url: tutorialURL
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var officialRulesURL: String {
        switch tcgType {
        case .pokemon:
            return "https://www.pokemon.com/it/regole-del-gcc"
        case .magic:
            return "https://magic.wizards.com/it/rules"
        case .yugioh:
            return "https://www.yugioh-card.com/en/rulebook/"
        case .onePiece:
            return "https://en.onepiece-cardgame.com/rule/"
        case .digimon:
            return "https://world.digimoncard.com/rule/"
        case .dragonBallSuper, .dragonBallFusion:
            return "https://www.dbs-cardgame.com/us-en/rule/"
        case .fleshAndBlood:
            return "https://fabtcg.com/resources/rules-and-policy/"
        case .lorcana:
            return "https://www.disneylorcana.com/en-US/resources"
        }
    }
    
    private var tutorialURL: String {
        switch tcgType {
        case .pokemon:
            return "https://www.youtube.com/watch?v=WT8QuTfF3aM"
        case .magic:
            return "https://www.youtube.com/watch?v=wif4Vvn0qzc"
        case .yugioh:
            return "https://www.youtube.com/watch?v=hXfCXS2Kn_A"
        case .onePiece:
            return "https://www.youtube.com/watch?v=t_Q6NV_o6qU"
        case .digimon:
            return "https://www.youtube.com/watch?v=IvXyVcvUJIY"
        case .dragonBallSuper, .dragonBallFusion:
            return "https://www.youtube.com/watch?v=8DqK2I6j0UE"
        case .fleshAndBlood:
            return "https://www.youtube.com/watch?v=N8tCxLvT0Hk"
        case .lorcana:
            return "https://www.youtube.com/watch?v=KeJ9jbhnN_U"
        }
    }
}

// MARK: - Supporting Views

struct RuleSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ExternalLinkButton: View {
    let title: String
    let icon: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                SwiftUI.Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(10)
        }
    }
}

// MARK: - Dismissible Info Banner

struct TCGRulesInfoBanner: View {
    let tcgType: TCGType
    let onDismiss: () -> Void
    let onLearnMore: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(tcgType.themeColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                SwiftUI.Image(systemName: "book.fill")
                    .font(.system(size: 18))
                    .foregroundColor(tcgType.themeColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text("Conosci il regolamento?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Scopri come giocare a \(tcgType.displayName)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            Button(action: onLearnMore) {
                Text("Leggi")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tcgType.themeColor)
                    .cornerRadius(8)
            }
            
            Button(action: onDismiss) {
                SwiftUI.Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(6)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tcgType.themeColor.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(isAnimating ? 1.0 : 0.95)
        .opacity(isAnimating ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - TCG Rules Row for Settings

struct TCGRulesRow: View {
    let tcgType: TCGType
    @State private var showingRules = false
    
    var body: some View {
        Button(action: { showingRules = true }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tcgType.themeColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    SwiftUI.Image(systemName: tcgType.systemIcon)
                        .font(.system(size: 16))
                        .foregroundColor(tcgType.themeColor)
                }
                
                Text(tcgType.displayName)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingRules) {
            TCGRulesView(tcgType: tcgType)
        }
    }
}
