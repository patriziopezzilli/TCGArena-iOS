import Foundation

class CardService: ObservableObject {
    static let shared = CardService()
    private let apiClient = APIClient.shared

    init() {}

    // Helper function to format dates as strings for backend (format: "dd MMM yyyy, HH:mm")
    private func formatDateForBackend(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    // MARK: - Card Template Operations

    func getAllCardTemplates(completion: @escaping (Result<[CardTemplate], Error>) -> Void) {
        apiClient.request(endpoint: "/cards/templates", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let templates = try decoder.decode([CardTemplate].self, from: data)
                    completion(.success(templates))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getCardTemplateById(_ id: Int, completion: @escaping (Result<CardTemplate, Error>) -> Void) {
        apiClient.request(endpoint: "/cards/templates/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let template = try decoder.decode(CardTemplate.self, from: data)
                    completion(.success(template))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func createCardTemplate(_ template: CardTemplate, completion: @escaping (Result<CardTemplate, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(template)
            apiClient.request(endpoint: "/cards/templates", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let createdTemplate = try decoder.decode(CardTemplate.self, from: data)
                        completion(.success(createdTemplate))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func updateCardTemplate(_ template: CardTemplate, completion: @escaping (Result<CardTemplate, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(template)
            apiClient.request(endpoint: "/cards/templates/\(template.id)", method: .put, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let updatedTemplate = try decoder.decode(CardTemplate.self, from: data)
                        completion(.success(updatedTemplate))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func deleteCardTemplate(_ id: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        apiClient.request(endpoint: "/cards/templates/\(id)", method: .delete) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - User Card Collection Operations

    func getUserCardCollection(completion: @escaping (Result<[UserCard], Error>) -> Void) {
        apiClient.request(endpoint: "/cards/collection", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    let decks = try decoder.decode([Deck].self, from: data)

                    // Find the collection deck (LISTA type with name "My Collection")
                    if let collectionDeck = decks.first(where: { $0.name == "My Collection" }) {
                        completion(.success(collectionDeck))
                    } else {
                        completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Collection deck not found"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    @MainActor
    func enrichCardWithTemplateData(_ card: Card, completion: @escaping (Result<Card, Error>) -> Void) {
        getCardTemplateById(Int(card.templateId)) { result in
            switch result {
            case .success(let template):
                // Create enriched card with template data
                var enrichedCard = Card(
                    id: card.id,
                    templateId: card.templateId,
                    name: card.name,
                    rarity: template.rarity,
                    condition: card.condition,
                    imageURL: card.imageURL ?? template.fullImageUrl,
                    isFoil: card.isFoil,
                    quantity: card.quantity,
                    ownerId: card.ownerId,
                    createdAt: card.createdAt,
                    updatedAt: card.updatedAt,
                    tcgType: template.tcgType,
                    set: template.setCode,
                    cardNumber: template.cardNumber,
                    expansion: template.expansion,
                    marketPrice: template.marketPrice,
                    description: template.description,
                    isGraded: card.isGraded,
                    gradingCompany: card.gradingCompany,
                    grade: card.grade,
                    certificateNumber: card.certificateNumber,
                    gradingDate: card.gradingDate
                )

                // Populate deck names by checking which decks contain this card
                enrichedCard.deckNames = self.findDeckNamesForCard(cardId: card.templateId)

                completion(.success(enrichedCard))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func findDeckNamesForCard(cardId: Int64) -> [String]? {
        // Find all decks that contain this card template
        let decksContainingCard = DeckService.shared.userDecks.filter { deck in
            deck.cards.contains { $0.cardId == cardId }
        }

        // Return deck names if any found
        let deckNames = decksContainingCard.map { $0.name }
        return deckNames.isEmpty ? nil : deckNames
    }

    func convertDeckCardToCard(_ deckCard: Deck.DeckCard, deckId: Int64) -> Card {
        // Create a basic Card from deck card info - will be enriched with template data later
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
            tcgType: .pokemon, // Will be updated from template
            set: nil, // Will be updated from template
            cardNumber: nil, // Will be updated from template
            expansion: nil,
            marketPrice: nil,
            description: nil,
            isGraded: deckCard.isGraded,
            gradingCompany: deckCard.gradingCompany,
            grade: deckCard.grade,
            certificateNumber: deckCard.certificateNumber
        )
    }
    @MainActor
    func addCardToCollection(cardTemplateId: Int, condition: CardCondition, quantity: Int, completion: @escaping (Result<Deck, Error>) -> Void) {
        // Get the collection deck and add the card template to it
        getCollectionDeck { deckResult in
            switch deckResult {
            case .success(let deck):
                guard let userId = AuthService.shared.currentUserId else {
                    completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                    return
                }
                self.addCardTemplateToCollectionDeck(deckId: deck.id!, templateId: Int64(cardTemplateId), userId: userId, condition: condition, quantity: quantity, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func addCardTemplateToCollectionDeck(deckId: Int64, templateId: Int64, userId: Int64, condition: CardCondition, quantity: Int, completion: @escaping (Result<Deck, Error>) -> Void) {
        // For now, add one card at a time. TODO: Support quantity parameter in backend
        for _ in 0..<quantity {
            let endpoint = "/api/decks/\(deckId)/add-card-template?templateId=\(templateId)&userId=\(userId)"
            apiClient.request(endpoint: endpoint, method: .post) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        let updatedDeck = try decoder.decode(Deck.self, from: data)

                        // Update local deck cache
                        DeckService.shared.updateLocalDeckCache(updatedDeck)

                        completion(.success(updatedDeck))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Market Price Operations

    func getCardMarketPrice(cardTemplateId: Int, completion: @escaping (Result<Double, Error>) -> Void) {
        apiClient.request(endpoint: "/cards/market-price/\(cardTemplateId)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode([String: Double].self, from: data)
                    if let price = response["price"] {
                        completion(.success(price))
                    } else {
                        completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Price not found in response"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Search Operations

    func searchCards(query: String, tgcType: TCGType? = nil, expansionId: Int? = nil, completion: @escaping (Result<[CardTemplate], Error>) -> Void) {
        var parameters: [String: String] = ["query": query]

        if let tgcType = tgcType {
            parameters["tgcType"] = tgcType.rawValue
        }

        if let expansionId = expansionId {
            parameters["expansionId"] = String(expansionId)
        }

        let queryString = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        let endpoint = "/cards/search?\(queryString)"

        apiClient.request(endpoint: endpoint, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let cards = try decoder.decode([CardTemplate].self, from: data)
                    completion(.success(cards))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func searchCardTemplates(query: String, completion: @escaping (Result<[CardTemplate], Error>) -> Void) {
        // Validate minimum query length
        guard query.count >= 2 else {
            completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Search query must be at least 2 characters"])))
            return
        }

        // URL encode the query
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid search query"])))
            return
        }

        let endpoint = "/api/cards/templates/search?q=\(encodedQuery)"

        apiClient.request(endpoint: endpoint, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let cards = try decoder.decode([CardTemplate].self, from: data)
                    completion(.success(cards))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    @MainActor
    func removeCardFromCollection(userCardId: Int64, deckId: Int64? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        // Direct delete using card ID only
        removeCardFromDeck(deckId: 0, cardId: userCardId, completion: completion)
    }



    @MainActor
    private func removeCardFromDeck(deckId: Int64, cardId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = AuthService.shared.currentUserId else {
            completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        // Direct endpoint using card ID only
        let endpoint = "/api/decks/cards/\(cardId)?userId=\(userId)"
        apiClient.request(endpoint: endpoint, method: .delete) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Update local cache based on deck type
                    if deckId == 0 {
                        // This is a collection card, no local cache to update
                        // CollectionView will refresh by calling getUserCardCollection
                        print("✅ CardService: Collection card removed, UI will refresh")
                    } else {
                        // This is a deck card, update deck cache
                        self.updateLocalDeckCacheAfterCardRemoval(cardId: cardId)
                    }
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    @MainActor
    func updateCard(originalCard: Card, name: String, condition: CardCondition, gradingCompany: GradeService? = nil, grade: CardGrade? = nil, certificateNumber: String? = nil, deckId: Int64? = nil, completion: @escaping (Result<Card, Error>) -> Void) {
        guard let cardId = originalCard.id else {
            completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Card ID is required"])))
            return
        }

        guard let userId = AuthService.shared.currentUserId else {
            completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        // Always use the deck endpoint: /api/decks/cards/{id}?userId={userId}
        updateDeckCard(deckId: deckId ?? 0, deckCardId: cardId, name: name, condition: condition, gradingCompany: gradingCompany, grade: grade, certificateNumber: certificateNumber, originalCard: originalCard, completion: completion)
    }



    @MainActor
    private func updateUserCard(cardId: Int64, name: String, condition: CardCondition, gradingCompany: GradeService?, grade: CardGrade?, certificateNumber: String?, originalCard: Card, completion: @escaping (Result<Card, Error>) -> Void) {
        // Build update data for UserCard
        var updateData: [String: Any] = [:]
        updateData["condition"] = condition.rawValue

        // Handle grading fields
        if gradingCompany != nil || grade != nil {
            // If any grading field is provided, set isGraded
            updateData["isGraded"] = true
            updateData["gradeService"] = gradingCompany?.rawValue ?? NSNull()
            updateData["gradeScore"] = grade != nil ? Int(grade!.numericValue) : NSNull()
        } else if originalCard.gradingCompany != nil && gradingCompany == nil {
            // If user removed grading (selected "None"), explicitly set fields to null
            updateData["isGraded"] = false
            updateData["gradeService"] = NSNull()
            updateData["gradeScore"] = NSNull()
        }
        
        // If no changes, just return success with original card
        let hasChanges = updateData.count > 1
        if !hasChanges {
            completion(.success(originalCard))
            return
        }

        // Use UserCard endpoint
        let endpoint = "/api/cards/collection/\(cardId)"

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: updateData, options: [])
            apiClient.request(endpoint: endpoint, method: .put, body: jsonData) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // Create updated card with new values
                        var updatedCard = originalCard
                        updatedCard.condition = condition

                        // Handle grading fields
                        if gradingCompany != nil || grade != nil {
                            // Grading is being set
                            updatedCard.gradingCompany = gradingCompany
                            updatedCard.grade = grade
                        } else if originalCard.gradingCompany != nil && gradingCompany == nil {
                            // Grading is being removed
                            updatedCard.gradingCompany = nil
                            updatedCard.grade = nil
                        }

                        // CollectionView will refresh by calling getUserCardCollection
                        print("✅ CardService: Collection card updated, UI will refresh")
                        completion(.success(updatedCard))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    @MainActor
    private func updateDeckCard(deckId: Int64, deckCardId: Int64, name: String, condition: CardCondition, gradingCompany: GradeService?, grade: CardGrade?, certificateNumber: String?, originalCard: Card, completion: @escaping (Result<Card, Error>) -> Void) {
        guard let userId = AuthService.shared.currentUserId else {
            completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }

        // Build update data with all fields
        var updateData: [String: Any] = [:]
        updateData["condition"] = condition.rawValue

        // Only include fields that have changed or are provided
        if name != originalCard.name {
            updateData["name"] = name
        }

        // Handle grading fields - always include them if provided
        if gradingCompany != nil || grade != nil || certificateNumber != nil {
            // If any grading field is provided, set isGraded
            updateData["isGraded"] = true
            updateData["gradeService"] = gradingCompany?.rawValue ?? NSNull()
            updateData["grade"] = grade?.rawValue ?? NSNull()
            updateData["certificateNumber"] = certificateNumber ?? NSNull()
        } else if originalCard.gradingCompany != nil && gradingCompany == nil {
            // If user removed grading (selected "None"), explicitly set fields to null
            updateData["isGraded"] = false
            updateData["gradeService"] = NSNull()
            updateData["grade"] = NSNull()
            updateData["certificateNumber"] = NSNull()
        }

        // If no changes, just return success with original card
        // Always include condition, so check if we have more than just condition
        let hasChanges = updateData.count > 1 || (gradingCompany != nil || grade != nil || certificateNumber != nil)
        if !hasChanges {
            completion(.success(originalCard))
            return
        }

        // Direct endpoint using card ID only with JSON body
        let endpoint = "/api/decks/cards/\(deckCardId)?userId=\(userId)"

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: updateData, options: [])
            apiClient.request(endpoint: endpoint, method: .put, body: jsonData) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // Create updated card with new values
                        var updatedCard = originalCard
                        updatedCard.name = name
                        updatedCard.condition = condition

                        // Handle grading fields
                        if gradingCompany != nil || grade != nil || (certificateNumber != nil && !certificateNumber!.isEmpty) {
                            // Grading is being set
                            updatedCard.gradingCompany = gradingCompany
                            updatedCard.grade = grade
                            updatedCard.certificateNumber = certificateNumber
                        } else if originalCard.gradingCompany != nil && gradingCompany == nil {
                            // Grading is being removed
                            updatedCard.gradingCompany = nil
                            updatedCard.grade = nil
                            updatedCard.certificateNumber = nil
                        }

                        // Update local cache based on deck type
                        if deckId == 0 {
                            // This is a collection card, no local cache to update
                            // CollectionView will refresh by calling getUserCardCollection
                            print("✅ CardService: Collection card updated, UI will refresh")
                        } else {
                            // This is a deck card, update deck cache
                            self.updateLocalDeckCacheAfterCardChange(cardId: deckCardId, updatedCard: updatedCard)
                        }

                        completion(.success(updatedCard))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func uploadCardImage(_ imageData: Data) async -> String? {
        // Placeholder implementation - upload image to server and return URL
        // For now, return nil
        return nil
    }

    // MARK: - Local Cache Updates

    private func updateLocalDeckCacheAfterCardChange(cardId: Int64, updatedCard: Card) {
        // Find the deck containing this card and update it locally
        for (deckIndex, deck) in DeckService.shared.userDecks.enumerated() {
            if let cardIndex = deck.cards.firstIndex(where: { $0.id == cardId }) {
                // Update the card in the deck - create new DeckCard with updated condition
                let existingCard = deck.cards[cardIndex]
                var updatedCards = deck.cards
                let updatedDeckCard = Deck.DeckCard(
                    id: existingCard.id,
                    cardId: existingCard.cardId,
                    quantity: existingCard.quantity,
                    cardName: existingCard.cardName,
                    cardImageUrl: existingCard.cardImageUrl,
                    condition: updatedCard.condition,
                    isGraded: updatedCard.gradingCompany != nil ? true : false,
                    gradingCompany: updatedCard.gradingCompany,
                    grade: updatedCard.grade,
                    certificateNumber: updatedCard.certificateNumber
                )
                updatedCards[cardIndex] = updatedDeckCard

                // Create a new Deck with updated cards and dateModified
                let updatedDeck = Deck(
                    id: deck.id,
                    name: deck.name,
                    tcgType: deck.tcgType,
                    deckType: deck.deckType,
                    cards: updatedCards,
                    ownerId: deck.ownerId,
                    dateCreated: deck.dateCreated,
                    dateModified: formatDateForBackend(Date()), // Update modification date
                    isPublic: deck.isPublic,
                    description: deck.description,
                    tags: deck.tags
                )

                // Update the deck in DeckService cache
                DeckService.shared.updateLocalDeckCache(updatedDeck)

                print("✅ CardService: Updated card \(cardId) in local deck cache")
                break
            }
        }
    }

    private func updateLocalDeckCacheAfterCardRemoval(cardId: Int64) {
        // Find the deck containing this card and remove it locally
        for (deckIndex, deck) in DeckService.shared.userDecks.enumerated() {
            if let cardIndex = deck.cards.firstIndex(where: { $0.id == cardId }) {
                // Remove the card from the deck
                var updatedCards = deck.cards
                updatedCards.remove(at: cardIndex)

                // Create a new Deck with updated cards and dateModified
                let updatedDeck = Deck(
                    id: deck.id,
                    name: deck.name,
                    tcgType: deck.tcgType,
                    deckType: deck.deckType,
                    cards: updatedCards,
                    ownerId: deck.ownerId,
                    dateCreated: deck.dateCreated,
                    dateModified: formatDateForBackend(Date()), // Update modification date
                    isPublic: deck.isPublic,
                    description: deck.description,
                    tags: deck.tags
                )

                // Update the deck in DeckService cache
                DeckService.shared.updateLocalDeckCache(updatedDeck)

                print("✅ CardService: Removed card \(cardId) from local deck cache")
                break
            }
        }
    }
}
