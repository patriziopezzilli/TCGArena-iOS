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
    

    

    

    

    

    

    

    
    


    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // MARK: - 1. Title & Header (Left Aligned)
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.name)
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let tcgType = card.tcgType {
                        HStack(spacing: 8) {
                            Text(tcgType.displayName.uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(tcgType.themeColor)
                                .tracking(1)
                            
                            // Set Pill
                            if let setCode = card.set?.uppercased() {
                                Text(setCode)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // MARK: - 2. Hero Image
                heroSection
                    .padding(.horizontal, 24)
                
                // MARK: - 3. Info Grid
                VStack(alignment: .leading, spacing: 24) {
                    Text("Dettagli Carta")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 0) {
                        infoRow(label: "Set", value: card.set ?? "-")
                        infoRow(label: "Rarità", value: card.rarity.displayName, valueColor: card.rarity.color)
                        infoRow(label: "Numero", value: card.cardNumber ?? "-")
                        infoRow(label: "Condizione", value: card.condition.displayName)
                    }
                    .padding(.horizontal, 8) // Inner padding handled by row
                }
                
                // MARK: - 4. Market Data
                if let price = cardPrice {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mercato")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 24)
                        
                        HStack(spacing: 16) {
                            MarketStatCard(
                                title: "Prezzo Attuale",
                                value: price.formattedPrice,
                                color: .primary
                            )
                            
                            MarketStatCard(
                                title: "Trend 7gg",
                                value: price.formattedChange,
                                color: price.priceChangeColor
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                // MARK: - 5. Grading Info (if graded)
                if card.isGraded == true, let company = card.gradingCompany {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Gradazione")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Grade Badge
                            if let grade = card.grade {
                                Text(grade.displayName)
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(gradeColor(for: grade))
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            infoRow(label: "Ente Gradatore", value: company.displayName)
                            
                            if let grade = card.grade {
                                infoRow(label: "Voto", value: grade.displayName, valueColor: gradeColor(for: grade))
                            }
                            
                            if let certNumber = card.certificateNumber, !certNumber.isEmpty {
                                infoRow(label: "Numero Certificato", value: certNumber)
                            }
                            
                            if let gradingDate = card.gradingDate {
                                infoRow(label: "Data Gradazione", value: formatDate(gradingDate))
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                
                // Description (if exists)
                if let description = card.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Descrizione")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 120) // Space for floating button
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
             actionControls
                 .padding(.bottom, 16)
        }
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

    // MARK: - New Components
    
    private var actionControls: some View {
        HStack(spacing: 16) {
            if isFromDiscover {
                Button(action: { isShowingDeckModal = true }) {
                    Text("Aggiungi al Mazzo")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(card.tcgType?.themeColor ?? .blue)
                        .cornerRadius(28)
                        .shadow(color: (card.tcgType?.themeColor ?? .blue).opacity(0.3), radius: 10, y: 5)
                }
            } else {
                Button(action: { showingEditView = true }) {
                    ZStack {
                         Circle()
                           .fill(Color(.secondarySystemBackground))
                           .frame(width: 56, height: 56)
                         SwiftUI.Image(systemName: "pencil")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
                
                Button(action: { showingDeleteConfirmation = true }) {
                    ZStack {
                         Circle()
                           .fill(Color.red.opacity(0.1))
                           .frame(width: 56, height: 56)
                         SwiftUI.Image(systemName: "trash")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private struct MarketStatCard: View {
        let title: String
        let value: String
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(value)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Subviews
    
    private var heroSection: some View {
        ZStack(alignment: .bottomTrailing) {
            if let imageURL = card.fullImageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 380) // Large Hero
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                            .onTapGesture {
                                showingFullScreenImage = true
                            }
                    default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
            
            // Expand Button (Explicit)
            Button(action: { showingFullScreenImage = true }) {
                SwiftUI.Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Circle().fill(Color.black.opacity(0.7)))
            }
            .padding(16)
        }
    }
    
    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .frame(width: 260, height: 360)
            .overlay(
                SwiftUI.Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            )
    }
    
    private func infoRow(label: String, value: String, valueColor: Color = .primary, valueFont: Font = .system(size: 16)) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(valueFont)
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
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
    
    // MARK: - Helper Functions
    
    private func gradeColor(for grade: CardGrade) -> Color {
        switch grade.numericValue {
        case 10: return .green
        case 9..<10: return Color(red: 0.2, green: 0.7, blue: 0.3)
        case 8..<9: return Color(red: 0.4, green: 0.6, blue: 0.3)
        case 7..<8: return .orange
        case 6..<7: return Color(red: 0.9, green: 0.6, blue: 0.2)
        default: return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
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



