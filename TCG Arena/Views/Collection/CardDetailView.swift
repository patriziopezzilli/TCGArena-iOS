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
        InfoCard(title: "Card Overview") {
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
        InfoCard(title: "Additional Info") {
            VStack(spacing: 12) {
                // Graded status badge
                HStack {
                    Spacer()
                    Text(card.isGraded == true ? "Graded" : "Ungraded")
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
        InfoCard(title: "Market Value") {
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
                    Text("Current Price")
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
                Text("Previous Week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "$%.2f", price.previousPrice))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Price Change")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "$%.2f", price.weeklyChange))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(price.priceChangeColor)
            }
            
            HStack {
                Text("Last Updated")
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
                    Text("Price Not Available")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Market data for this card is currently unavailable")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button("Request Price Data") {
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
                Text("Add to My Deck")
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
                Text("Edit Card")
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
                Text("Delete Card")
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
                InfoCard(title: "Card Description") {
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
            VStack(spacing: 24) {
                headerSection
                cardDetailsCard
                additionalInfoCards
                descriptionCard
                actionButtons
            }
            .padding(.bottom, 32)
        }
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
        .confirmationDialog("Delete Card", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteCard()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(card.name)'? This action cannot be undone.")
        }
        .onAppear {
            marketService.loadMarketData()
            // Debug logging for image loading - removed prints
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
