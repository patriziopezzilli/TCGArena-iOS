import SwiftUI

struct DeckDetailView: View {
    let deck: Deck
    @EnvironmentObject var deckService: DeckService
    @EnvironmentObject var authService: AuthService
    @Environment(\.presentationMode) var presentationMode
    @State private var deckCards: [Card] = []
    @State private var isLoadingCards = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var editName = ""
    @State private var editDescription = ""
    @State private var isUpdating = false
    @State private var isDeleting = false
    
    // Computed property for cover image
    private var coverImageUrl: String? {
        // Find the first card with an image
        if let firstCardWithImage = deck.cards.first(where: { $0.cardImageUrl != nil }) {
            var url = firstCardWithImage.cardImageUrl
            if let imageUrl = url, !imageUrl.contains("/high.webp") {
                return "\(imageUrl)/high.webp"
            }
            return url
        }
        return nil
    }
    
    private func loadDeckCards() {
        isLoadingCards = true
        deckCards = []
        
        // Convert deck cards to basic Card objects and enrich with template data
        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "com.tcgarena.deckCardEnrichment")
        var enrichedCards: [Card] = []
        
        for deckCard in deck.cards {
            group.enter()
            // Create basic card from deck card
            let basicCard = convertDeckCardToCard(deckCard)
            
            // Enrich with template data
            CardService.shared.enrichCardWithTemplateData(basicCard) { result in
                serialQueue.async {
                    switch result {
                    case .success(let enrichedCard):
                        enrichedCards.append(enrichedCard)
                    case .failure(let error):
                        print("Failed to enrich card \(deckCard.cardName): \(error.localizedDescription)")
                        // Use basic card if enrichment fails
                        enrichedCards.append(basicCard)
                    }
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // Sort cards by name for consistent ordering
            serialQueue.sync {
                self.deckCards = enrichedCards.sorted { $0.name < $1.name }
            }
            self.isLoadingCards = false
        }
    }
    
    private func convertDeckCardToCard(_ deckCard: Deck.DeckCard) -> Card {
        return Card(
            id: deckCard.id,
            templateId: deckCard.cardId,
            name: deckCard.cardName,
            rarity: .common, // Will be updated from template
            condition: deckCard.condition ?? .nearMint,
            imageURL: deckCard.cardImageUrl,
            isFoil: false,
            quantity: deckCard.quantity,
            ownerId: 1, // Will be updated from auth
            createdAt: Date(),
            updatedAt: Date(),
            tcgType: deck.tcgType,
            set: nil, // Will be updated from template
            cardNumber: nil, // Will be updated from template
            expansion: nil,
            marketPrice: nil,
            description: nil,
            // Copy grading information from deck card
            isGraded: deckCard.isGraded,
            gradingCompany: deckCard.gradingCompany,
            grade: deckCard.grade,
            certificateNumber: deckCard.certificateNumber
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header Section
                VStack(alignment: .leading, spacing: 12) {
                    // TCG Pill
                    HStack(spacing: 8) {
                        TCGIconView(tcgType: deck.tcgType, size: 20)
                        Text(deck.tcgType.displayName.uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(1)
                    }
                    
                    // Title
                    Text(deck.name)
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // Stats
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            SwiftUI.Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 14))
                            Text("\(deck.totalCards) cards")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        
                        if let description = deck.description, !description.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(description)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
                
                Divider()
                    .padding(.leading, 24)
                
                // MARK: - Cards List
                if isLoadingCards {
                    VStack(spacing: 16) {
                        ForEach(0..<6, id: \.self) { _ in
                            CardRowSkeletonView()
                        }
                    }
                    .padding(24)
                } else if deckCards.isEmpty {
                    emptyStateView
                        .padding(.top, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(deckCards) { card in
                            // Card Row in clean style
                            NavigationLink(destination: CardDetailView(card: card, isFromDiscover: false, deckId: deck.id) { updatedCard in
                                // Update local state
                                if let index = deckCards.firstIndex(where: { $0.id == updatedCard.id }) {
                                    deckCards[index] = updatedCard
                                }
                                loadDeckCards()
                            }) {
                                CardRowView(card: card, deckService: deckService)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(24)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: {
                        editName = deck.name
                        editDescription = deck.description ?? ""
                        showingEditSheet = true
                    }) {
                        Label("Modifica", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Elimina", systemImage: "trash")
                    }
                } label: {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 32, height: 32)
                        .overlay(
                            SwiftUI.Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                        )
                }
            }
        }
        .confirmationDialog("Elimina Mazzo", isPresented: $showingDeleteAlert) {
            Button("Elimina", role: .destructive) {
                deleteDeck()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Sei sicuro di voler eliminare \"\(deck.name)\"? Questa azione non può essere annullata.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditDeckView(
                deck: deck,
                name: $editName,
                description: $editDescription,
                isUpdating: $isUpdating,
                onSave: updateDeck
            )
        }
        .onAppear {
            loadDeckCards()
        }
    }
    
    // Removed legacy abstractHeaderBackground and complementaryColor
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 100, height: 100)
                
                SwiftUI.Image(systemName: "rectangle.portrait.on.rectangle.portrait.slash")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("Nessuna Carta")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Questo mazzo è vuoto. Aggiungi carte dalla ricerca o scansionale.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private func updateDeck() {
        guard let deckId = deck.id else { return }
        
        isUpdating = true
        
        deckService.updateDeck(
            id: deckId,
            name: editName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: editDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            userId: deck.ownerId
        ) { result in
            DispatchQueue.main.async {
                isUpdating = false
                switch result {
                case .success:
                    // Close the edit sheet and return to homepage
                    showingEditSheet = false
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    if case APIError.unauthorized = error {
                        ToastManager.shared.showError("La sessione è scaduta. Accedi di nuovo.")
                    } else {
                        ToastManager.shared.showError("Impossibile aggiornare il mazzo. Controlla la connessione e riprova.")
                    }
                }
            }
        }
    }
    
    private func deleteDeck() {
        guard let deckId = deck.id else { return }
        
        isDeleting = true
        
        deckService.deleteDeck(deckId: deckId, userId: deck.ownerId) { result in
            DispatchQueue.main.async {
                isDeleting = false
                switch result {
                case .success:
                    presentationMode.wrappedValue.dismiss()
                case .failure(let error):
                    if case APIError.unauthorized = error {
                        ToastManager.shared.showError("La sessione è scaduta. Accedi di nuovo.")
                    } else {
                        ToastManager.shared.showError("Impossibile eliminare il mazzo. Controlla la connessione e riprova.")
                    }
                }
            }
        }
    }
}

// MARK: - Edit Deck View
struct EditDeckView: View {
    let deck: Deck
    @Binding var name: String
    @Binding var description: String
    @Binding var isUpdating: Bool
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Start of Content
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Modifica Mazzo")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.primary)
                        
                        Text("Aggiorna i dettagli della tua collezione")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Divider()
                        .padding(.leading, 24)
                    
                    // Input Fields
                    VStack(spacing: 24) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NOME")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            
                            TextField("Nome del mazzo", text: $name)
                                .font(.system(size: 18, weight: .medium))
                                .padding(16)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIZIONE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                                .tracking(0.5)
                            
                            ZStack(alignment: .topLeading) {
                                if description.isEmpty {
                                    Text("Aggiungi una breve descrizione...")
                                        .foregroundColor(Color(.tertiaryLabel))
                                        .padding(.top, 16)
                                        .padding(.leading, 16)
                                        .font(.system(size: 16))
                                }
                                
                                TextEditor(text: $description)
                                    .font(.system(size: 16))
                                    .frame(minHeight: 120)
                                    .padding(12)
                                    .scrollContentBackground(.hidden)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 40)
                    
                    // Save Button
                    Button(action: onSave) {
                        HStack {
                            if isUpdating {
                                ProgressView()
                                    .tint(.white)
                                    .padding(.trailing, 8)
                            }
                            Text("Salva Modifiche")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(deck.tcgType.themeColor)
                        .cornerRadius(28)
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUpdating)
                    .opacity(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                    .padding(.horizontal, 24)
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        SwiftUI.Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
            }
            .withToastSupport()
        }
    }
}
