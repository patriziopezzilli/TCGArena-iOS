import Foundation

class CardService: ObservableObject {
    static let shared = CardService()
    private let apiClient = APIClient.shared
    
    @Published var userCards: [Card] = []

    init() {}

    // MARK: - Card Template Operations

    func getAllCardTemplates(completion: @escaping (Result<[CardTemplate], Error>) -> Void) {
        apiClient.request(endpoint: "/api/cards/templates", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let templates = try JSONDecoder().decode([CardTemplate].self, from: data)
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
        apiClient.request(endpoint: "/api/cards/templates/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let template = try JSONDecoder().decode(CardTemplate.self, from: data)
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
            apiClient.request(endpoint: "/api/cards/templates", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let createdTemplate = try JSONDecoder().decode(CardTemplate.self, from: data)
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
            apiClient.request(endpoint: "/api/cards/templates/\(template.id)", method: .put, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let updatedTemplate = try JSONDecoder().decode(CardTemplate.self, from: data)
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
        apiClient.request(endpoint: "/api/cards/templates/\(id)", method: .delete) { result in
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
        apiClient.request(endpoint: "/api/cards/collection", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let collection = try JSONDecoder().decode([UserCard].self, from: data)
                    completion(.success(collection))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func addCardToCollection(cardTemplateId: Int, condition: CardCondition, quantity: Int, completion: @escaping (Result<UserCard, Error>) -> Void) {
        // For now, add one card at a time. TODO: Support quantity parameter in backend
        for _ in 0..<quantity {
            apiClient.request(endpoint: "/api/cards/\(cardTemplateId)/add-to-collection?condition=\(condition.rawValue)", method: .post) { result in
                switch result {
                case .success(let data):
                    do {
                        let userCard = try JSONDecoder().decode(UserCard.self, from: data)
                        completion(.success(userCard))
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
        apiClient.request(endpoint: "/api/cards/market-price/\(cardTemplateId)", method: .get) { result in
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
        let endpoint = "/api/cards/search?\(queryString)"

        apiClient.request(endpoint: endpoint, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let cards = try JSONDecoder().decode([CardTemplate].self, from: data)
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
                    let cards = try JSONDecoder().decode([CardTemplate].self, from: data)
                    completion(.success(cards))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func removeCardFromCollection(userCardId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        apiClient.request(endpoint: "/api/cards/collection/\(userCardId)", method: .delete) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func updateCard(originalCard: Card, name: String, condition: Card.CardCondition, completion: @escaping (Result<Card, Error>) -> Void) {
        guard let cardId = originalCard.id else {
            completion(.failure(NSError(domain: "CardService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Card ID is required"])))
            return
        }
        
        let updatedCard = Card(
            id: originalCard.id,
            templateId: originalCard.templateId,
            name: name,
            rarity: originalCard.rarity,
            condition: condition,
            imageURL: originalCard.imageURL,
            isFoil: originalCard.isFoil,
            quantity: originalCard.quantity,
            ownerId: originalCard.ownerId,
            createdAt: originalCard.createdAt,
            updatedAt: Date(),
            tcgType: originalCard.tcgType,
            set: originalCard.set,
            cardNumber: originalCard.cardNumber,
            expansion: originalCard.expansion,
            marketPrice: originalCard.marketPrice,
            description: originalCard.description
        )
        
        do {
            let data = try JSONEncoder().encode(updatedCard)
            apiClient.request(endpoint: "/api/cards/\(cardId)", method: .put, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let card = try JSONDecoder().decode(Card.self, from: data)
                        completion(.success(card))
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
    
    func uploadCardImage(_ imageData: Data) async -> String? {
        // Placeholder implementation - upload image to server and return URL
        // For now, return nil
        return nil
    }
}