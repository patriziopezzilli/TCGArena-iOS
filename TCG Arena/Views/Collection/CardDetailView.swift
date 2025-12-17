//
//  CardDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import TCG_Arena

struct CardDetailView: View {
    @State var card: Card
    let isFromDiscover: Bool
    var deckId: Int64? = nil
    var onCardUpdated: ((Card) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    @EnvironmentObject var marketService: MarketDataService
    @EnvironmentObject var authService: AuthService
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @State private var isShowingDeckModal = false
    @State private var isAddingToDeck = false
    @State private var showingFullScreenImage = false
    
    private var cardPrice: CardPrice? {
        return marketService.getPriceForCard(card.name.lowercased().replacingOccurrences(of: " ", with: "-"))
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.name)
                .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Text(card.tcgType?.displayName ?? "Unknown TCG")
                .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    private var cardDetailsCard: some View {
        InfoCard(title: "Panoramica Carta") {
            HStack(spacing: 20) {
                cardImageView
                cardInfoView
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var cardImageView: some View {
        Group {
            if let imageURL = card.fullImageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                            .fill(Color(.systemGray6))
                            .frame(width: 120, height: 170)
                            .overlay(ProgressView())
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: UIConstants.cornerRadius))
                            .overlay(
                                // Expand icon overlay
                                VStack {
                                    HStack {
                                        Spacer()
                                        ZStack {
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: 24, height: 24)
                                            SwiftUI.Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        .padding(6)
                                    }
                                    Spacer()
                                }
                            )
                            .onTapGesture {
                                showingFullScreenImage = true
                            }
                    case .failure(_):
                        RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                            .fill(Color(.systemGray6))
                            .frame(width: 120, height: 170)
                            .overlay(
                                VStack(spacing: 8) {
                                    Group {
                                        if let tcgType = card.tcgType {
                                            TCGIconView(tcgType: tcgType, size: 40)
                                        } else {
                                            SwiftUI.Image(systemName: "questionmark.circle")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .opacity(0.6)
                                    
                                    Text("Image Error")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                            .fill(Color(.systemGray6))
                            .frame(width: 120, height: 170)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .fill(Color(.systemGray6))
                    .frame(width: 120, height: 170)
                    .overlay(
                        VStack(spacing: 8) {
                            Group {
                                if let tcgType = card.tcgType {
                                    TCGIconView(tcgType: tcgType, size: 24)
                                } else {
                                    SwiftUI.Image(systemName: "questionmark.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gray)
                                }
                            }
                            .opacity(0.6)
                            
                            Text("Card Image")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
    }
    
    private var cardInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            InfoRow(label: "Set", value: card.set?.uppercased() ?? "Unknown", color: .secondary)
            InfoRow(label: "Number", value: card.cardNumber ?? "N/A", color: .secondary)
            InfoRow(label: "Rarity", value: card.rarity.displayName, color: card.rarity.color)
        
        // Mostra sempre la condizione
        InfoRow(label: "Condition", value: card.condition.displayName, color: card.condition.color)
        
        if let cardPrice = cardPrice {
                InfoRow(label: "Price", value: "€\(String(format: "%.2f", cardPrice.currentPrice))", color: card.tcgType?.themeColor ?? Color.gray)
            }
            
            // Show "Found in" section if card has deck names
            if let deckNames = card.deckNames, !deckNames.isEmpty {
                InfoRow(label: "Found in", value: deckNames.joined(separator: ", "), color: .secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var additionalInfoCards: some View {
        Group {
            if !isFromDiscover {
                VStack(spacing: 20) {
                    additionalInfoCard
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var additionalInfoCard: some View {
        InfoCard(title: "Info Aggiuntive") {
            VStack(spacing: 12) {
                // Graded status badge
                HStack {
                    Spacer()
                    Text(card.isGraded == true ? "Gradata" : "Non Gradata")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(card.isGraded == true ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(card.isGraded == true ? Color.green : Color.gray.opacity(0.3))
                        )
                }
                
                // Show grading information
                if card.isGraded == true {
                    if let gradingCompany = card.gradingCompany {
                        InfoRow(label: "Grading Company", value: gradingCompany.rawValue, color: .primary)
                    }
                    if let grade = card.grade {
                        InfoRow(label: "Grade", value: grade.rawValue, color: .primary)
                    }
                    if let certificateNumber = card.certificateNumber, !certificateNumber.isEmpty {
                        InfoRow(label: "Certificate #", value: certificateNumber, color: .primary)
                    }
                } else {
                    InfoRow(label: "Grade", value: "Ungraded", color: .secondary)
                }
                
                InfoRow(label: "Added", value: card.createdAt.formatted(date: .abbreviated, time: .omitted), color: .secondary)
            }
        }
    }
    
    private var marketValueCard: some View {
        InfoCard(title: "Valore di Mercato") {
            if let price = cardPrice {
                marketPriceContent(price: price)
            } else {
                noPriceContent
            }
        }
    }
    
    private func marketPriceContent(price: CardPrice) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prezzo Attuale")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(price.formattedPrice)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        SwiftUI.Image(systemName: price.weeklyChangePercent >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption)
                        Text(price.formattedChange)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(price.priceChangeColor)
                    
                    Text("7 days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            marketPriceDetails(price: price)
        }
    }
    
    private func marketPriceDetails(price: CardPrice) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Settimana Precedente")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "$%.2f", price.previousPrice))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Variazione Prezzo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "$%.2f", price.weeklyChange))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(price.priceChangeColor)
            }
            
            HStack {
                Text("Ultimo Aggiornamento")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(price.lastUpdated.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var noPriceContent: some View {
        VStack(spacing: 12) {
            HStack {
                SwiftUI.Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prezzo Non Disponibile")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("I dati di mercato per questa carta non sono disponibili")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button("Richiedi Dati Prezzo") {
                // TODO: Richiedi dati di prezzo
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if isFromDiscover {
                addToDeckButton
            } else {
                editButton
                deleteButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    private var addToDeckButton: some View {
        Button(action: {
            isShowingDeckModal = true
        }) {
            HStack {
                SwiftUI.Image(systemName: "plus.circle")
                    .font(.system(size: 16, weight: .semibold))
                Text("Aggiungi al Mazzo")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(card.tcgType?.themeColor ?? Color.gray)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.1))
            )
        }
    }
    
    private var editButton: some View {
        Button(action: {
            showingEditView = true
        }) {
            HStack {
                SwiftUI.Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                Text("Modifica Carta")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(card.tcgType?.themeColor ?? Color.gray)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .fill((card.tcgType?.themeColor ?? Color.gray).opacity(0.1))
            )
        }
    }

    private var deleteButton: some View {
        Button(action: {
            showingDeleteConfirmation = true
        }) {
            HStack {
                SwiftUI.Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                Text("Elimina Carta")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .fill(Color.red.opacity(0.1))
            )
        }
    }
    
    private var descriptionCard: AnyView {
        if let description = card.description, !description.isEmpty {
            AnyView(
                InfoCard(title: "Descrizione Carta") {
                    Text(description)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
            )
        } else {
            AnyView(EmptyView())
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // MARK: - Hero Card Section
                heroCardSection
                    .padding(.bottom, 24)
                
                // MARK: - Main Content
                VStack(spacing: 20) {
                    // Card Info Row (Set, Rarity, Condition)
                    cardInfoChipsSection
                        .padding(.horizontal, 20)
                    
                    // Price Card (if available)
                    if cardPrice != nil {
                        marketValueCard
                            .padding(.horizontal, 20)
                    }
                    
                    // Additional Info
                    additionalInfoCards
                    
                    // Description
                    descriptionCard
                    
                    // Actions
                    actionButtons
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditView) {
            EditCardView(card: card, deckId: deckId) { updatedCard in
                self.card = updatedCard
                onCardUpdated?(updatedCard)
            }
        }
        .sheet(isPresented: $isShowingDeckModal) {
            DeckSelectionModal(cardName: card.name, tcgType: card.tcgType) { selectedDeck in
                addCardToSelectedDeck(selectedDeck)
            }
            .environmentObject(deckService)
        }
        .fullScreenCover(isPresented: $showingFullScreenImage) {
            FullScreenImageView(imageURL: card.fullImageURL, cardName: card.name)
        }
        .confirmationDialog("Elimina Carta", isPresented: $showingDeleteConfirmation) {
            Button("Elimina", role: .destructive) {
                deleteCard()
            }
            Button("Annulla", role: .cancel) { }
        } message: {
            Text("Sei sicuro di voler eliminare '\(card.name)'? Questa azione non può essere annullata.")
        }
        .onAppear {
            marketService.loadMarketData()
        }
    }
    
    // MARK: - Hero Card Section
    private var heroCardSection: some View {
        VStack(spacing: 16) {
            // Large Card Image with 3D effect
            ZStack {
                // Shadow layer for depth
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 180, height: 255)
                    .offset(y: 8)
                    .blur(radius: 12)
                
                // Card Image
                Group {
                    if let imageURL = card.fullImageURL, let url = URL(string: imageURL) {
                        CachedAsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                cardPlaceholder
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 180, height: 255)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .shadow(color: (card.tcgType?.themeColor ?? .gray).opacity(0.4), radius: 20, x: 0, y: 10)
                            case .failure(_):
                                cardPlaceholder
                            @unknown default:
                                cardPlaceholder
                            }
                        }
                    } else {
                        cardPlaceholder
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showingFullScreenImage = true
                    }
                }
                
                // Expand indicator
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 32, height: 32)
                            SwiftUI.Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                .frame(width: 180, height: 255)
                .padding(8)
            }
            .padding(.top, 20)
            
            // Card Name & TCG
            VStack(spacing: 6) {
                Text(card.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let tcgType = card.tcgType {
                        Circle()
                            .fill(tcgType.themeColor)
                            .frame(width: 8, height: 8)
                        
                        Text(tcgType.displayName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(tcgType.themeColor)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray5))
            .frame(width: 180, height: 255)
            .overlay(
                VStack(spacing: 12) {
                    if let tcgType = card.tcgType {
                        TCGIconView(tcgType: tcgType, size: 48)
                            .opacity(0.5)
                    } else {
                        SwiftUI.Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    Text("Immagine non disponibile")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
            )
    }
    
    // MARK: - Card Info Chips
    private var cardInfoChipsSection: some View {
        ZStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Set chip
                    if let set = card.set {
                        InfoChip(icon: "square.stack.3d.up", label: "Set", value: set.uppercased(), color: card.tcgType?.themeColor ?? .gray)
                    }
                    
                    // Rarity chip
                    InfoChip(icon: "sparkles", label: "Rarità", value: card.rarity.displayName, color: card.rarity.color)
                    
                    // Condition chip
                    InfoChip(icon: "shield.checkered", label: "Condizione", value: card.condition.displayName, color: card.condition.color)
                    
                    // Card number chip
                    if let cardNumber = card.cardNumber {
                        InfoChip(icon: "number", label: "Numero", value: cardNumber, color: .secondary)
                    }
                    
                    // Price chip (if available)
                    if let price = cardPrice {
                        InfoChip(icon: "eurosign.circle", label: "Prezzo", value: price.formattedPrice, color: .green)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
            }
            
            // Fade masks on edges
            HStack {
                // Left fade
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGroupedBackground), Color(.systemGroupedBackground).opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 24)
                
                Spacer()
                
                // Right fade
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGroupedBackground).opacity(0), Color(.systemGroupedBackground)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 24)
            }
            .allowsHitTesting(false)
        }
    }
    
    private func deleteCard() {
        guard let cardId = card.id else { return }
        
        cardService.removeCardFromCollection(userCardId: cardId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Card deleted successfully from backend
                    // No need to remove from local arrays since we load fresh data from backend
                    dismiss()
                case .failure(let error):
                    // Handle error - show toast
                    ToastManager.shared.showError("Failed to delete card: \(error.localizedDescription)")
                    // For now, just dismiss anyway
                    dismiss()
                }
            }
        }
    }
    
    private func addCardToSelectedDeck(_ deck: Deck) {
        guard let deckId = deck.id else { return }
        guard let userId = authService.currentUserId else { return }
        
        isAddingToDeck = true
        
        // Use different API based on the source
        if isFromDiscover {
            // From discover: use card template API
            let templateId = card.templateId
            
            deckService.addCardTemplateToDeck(deckId: deckId, templateId: templateId, userId: userId) { result in
                DispatchQueue.main.async {
                    self.isAddingToDeck = false
                    switch result {
                    case .success:
                        // Success - dismiss
                        self.dismiss()
                    case .failure(let error):
                        // Handle error - show toast
                        ToastManager.shared.showError("Error adding card template to deck: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // From collection: use regular card API
            guard let cardId = card.id else { return }
            
            deckService.addCardToDeck(deckId: deckId, cardId: cardId, quantity: 1) { result in
                DispatchQueue.main.async {
                    self.isAddingToDeck = false
                    switch result {
                    case .success:
                        // Success - dismiss
                        self.dismiss()
                    case .failure(let error):
                        // Handle error - show toast
                        ToastManager.shared.showError("Error adding card to deck: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
    
    // MARK: - Full Screen Image View
    struct FullScreenImageView: View {
        let imageURL: String?
        let cardName: String
        @Environment(\.dismiss) private var dismiss
        
        var body: some View {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if let imageURL = imageURL, let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .scaleEffect(1.5)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        case .failure(_):
                            VStack(spacing: 16) {
                                SwiftUI.Image(systemName: "photo")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray)
                                Text("Failed to load image")
                                    .foregroundColor(.white)
                            }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "photo")
                            .font(.system(size: 64))
                            .foregroundColor(.gray)
                        Text("No image available")
                            .foregroundColor(.white)
                    }
                }
                
                // Close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            SwiftUI.Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 20)
                    }
                    Spacer()
                }
            }
            .navigationTitle(cardName)
            .navigationBarHidden(true)
        }
    }

// MARK: - Info Chip Component
struct InfoChip: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
    }
}
