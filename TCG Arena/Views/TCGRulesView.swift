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
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Header
                    heroHeaderView
                    
                    // Main content
                    VStack(alignment: .leading, spacing: 32) {
                        // Quick Stats
                        quickStatsView
                        
                        // Rules content
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Come si gioca")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            rulesContent
                        }
                        
                        // External links
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Risorse Ufficiali")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.primary)
                            
                            externalLinksSection
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    hasAppeared = true
                }
            }
        }
    }
    
    // MARK: - Hero Header
    private var heroHeaderView: some View {
        VStack(spacing: 20) {
            // TCG Icon
            ZStack {
                Circle()
                    .fill(tcgType.themeColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                TCGIconView(tcgType: tcgType, size: 38, color: tcgType.themeColor)
            }
            .scaleEffect(hasAppeared ? 1.0 : 0.8)
            .opacity(hasAppeared ? 1.0 : 0)
            
            // Title
            VStack(spacing: 8) {
                Text(tcgType.displayName)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.primary)
                
                Text("Regolamento Ufficiale")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .offset(y: hasAppeared ? 0 : 10)
            .opacity(hasAppeared ? 1.0 : 0)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Quick Stats
    private var quickStatsView: some View {
        HStack(spacing: 12) {
            QuickStatCard(value: deckSize, label: "Carte", icon: "rectangle.stack.fill", color: tcgType.themeColor)
            QuickStatCard(value: maxCopies, label: "Max Copie", icon: "doc.on.doc.fill", color: tcgType.themeColor)
            QuickStatCard(value: "1v1", label: "Formato", icon: "person.2.fill", color: tcgType.themeColor)
        }
    }
    
    private var deckSize: String {
        switch tcgType {
        case .pokemon, .magic, .lorcana: return "60"
        case .yugioh: return "40-60"
        case .onePiece, .digimon, .dragonBallSuper, .dragonBallFusion: return "50"
        case .fleshAndBlood: return "60+"
        }
    }
    
    private var maxCopies: String {
        switch tcgType {
        case .lorcana: return "4"
        default: return "4"
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
        VStack(spacing: 12) {
            ExternalLinkButton(
                title: "Regolamento Ufficiale",
                icon: "doc.text.fill",
                url: officialRulesURL,
                color: tcgType.themeColor
            )
            
            ExternalLinkButton(
                title: "Video Tutorial",
                icon: "play.circle.fill",
                url: tutorialURL,
                color: .red
            )
        }
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

struct QuickStatCard: View {
    let value: String
    let label: String
    let icon: String
    var color: Color = .blue
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct RuleSection: View {
    let title: String
    let content: String
    var number: Int? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Number badge (opzionale)
            if let num = number {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 32, height: 32)
                    
                    Text("\(num)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.blue)
                }
                .padding(.top, 2)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct ExternalLinkButton: View {
    let title: String
    let icon: String
    let url: String
    let color: Color
    
    init(title: String, icon: String, url: String, color: Color = .blue) {
        self.title = title
        self.icon = icon
        self.url = url
        self.color = color
    }
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)
                    
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Apri link esterno")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                SwiftUI.Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
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
                .fill(Color(.secondarySystemGroupedBackground))
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
    @State private var selectedTCGType: TCGType?
    
    var body: some View {
        Button(action: { selectedTCGType = tcgType }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tcgType.themeColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    TCGIconView(tcgType: tcgType, size: 16, color: tcgType.themeColor)
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
        .sheet(item: $selectedTCGType) { type in
            TCGRulesView(tcgType: type)
        }
    }
}

// MARK: - Rules List Card for Collection Tab

struct RulesListCard: View {
    let tcgType: TCGType
    let action: () -> Void
    @State private var isPressed = false
    
    private var rulesPreview: String {
        switch tcgType {
        case .pokemon:
            return "Raccogli 6 carte Premio per vincere"
        case .magic:
            return "Riduci i punti vita dell'avversario a 0"
        case .yugioh:
            return "Riduci i Life Points avversari da 8000 a 0"
        case .onePiece:
            return "Sconfiggi il Leader avversario"
        case .digimon:
            return "Attacca il Security Stack per vincere"
        case .dragonBallSuper, .dragonBallFusion:
            return "Esaurisci le vite del Leader nemico"
        case .fleshAndBlood:
            return "Abbatti l'eroe avversario in combattimento"
        case .lorcana:
            return "Raccogli 20 Lore esplorando"
        }
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // TCG Icon with minimal themed background (same as DeckRowView)
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(tcgType.themeColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    TCGIconView(tcgType: tcgType, size: 24, color: tcgType.themeColor)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(tcgType.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(rulesPreview)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Arrow
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Keep TCGRulesCard for backward compatibility if needed elsewhere
struct TCGRulesCard: View {
    let tcgType: TCGType
    let action: () -> Void
    
    var body: some View {
        RulesListCard(tcgType: tcgType, action: action)
    }
}

// MARK: - Press Events Modifier
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}
