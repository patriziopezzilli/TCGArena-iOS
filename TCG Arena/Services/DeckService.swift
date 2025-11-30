//
//  DeckService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation

class DeckService: ObservableObject {
    static let shared = DeckService()
    private let apiClient = APIClient.shared
    
    @Published var userDecks: [Deck] = []
    @Published var proDecks: [ProDeck] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var hasLoadedUserDecks = false
    private var lastLoadedUserId: Int64?
    
    init() {
        loadProDecks()
        loadCachedUserDecks()
    }
    
    // MARK: - Helper Methods
    
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Java LocalDateTime format: "2025-11-26T21:55:29.218488"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }
    
    // MARK: - Deck Operations
    
    func getAllDecks(userId: Int64, completion: @escaping (Result<[Deck], Error>) -> Void) {
        apiClient.request(endpoint: "/api/decks?userId=\(userId)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decks = try self.createDecoder().decode([Deck].self, from: data)
                    completion(.success(decks))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getDeckById(_ id: Int64, completion: @escaping (Result<Deck, Error>) -> Void) {
        apiClient.request(endpoint: "/api/decks/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = self.createDecoder()
                    let deck = try decoder.decode(Deck.self, from: data)
                    completion(.success(deck))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func createDeck(_ deck: Deck, completion: @escaping (Result<Deck, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(deck)
            apiClient.request(endpoint: "/api/decks", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let createdDeck = try self.createDecoder().decode(Deck.self, from: data)
                        completion(.success(createdDeck))
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
    
    func updateDeck(_ id: Int64, deck: Deck, completion: @escaping (Result<Deck, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(deck)
            apiClient.request(endpoint: "/api/decks/\(id)", method: .put, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let updatedDeck = try decoder.decode(Deck.self, from: data)
                        completion(.success(updatedDeck))
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
    
    func deleteDeck(_ id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        apiClient.request(endpoint: "/api/decks/\(id)", method: .delete) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func addCardToDeck(deckId: Int64, cardId: Int64, quantity: Int, completion: @escaping (Result<Deck, Error>) -> Void) {
        let parameters = ["cardId": cardId, "quantity": quantity] as [String: Any]
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters)
            apiClient.request(endpoint: "/api/decks/\(deckId)/add-card", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        let updatedDeck = try decoder.decode(Deck.self, from: data)
                        // Update local cache
                        self.updateLocalDeckCache(updatedDeck)
                        completion(.success(updatedDeck))
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
    
    func addCardTemplateToDeck(deckId: Int64, templateId: Int64, userId: Int64, completion: @escaping (Result<Deck, Error>) -> Void) {
        let urlString = "/api/decks/\(deckId)/add-card-template?templateId=\(templateId)&userId=\(userId)"
        apiClient.request(endpoint: urlString, method: .post) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = self.createDecoder()
                    let updatedDeck = try decoder.decode(Deck.self, from: data)
                    // Update local cache
                    self.updateLocalDeckCache(updatedDeck)
                    completion(.success(updatedDeck))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func removeCardFromDeck(deckId: Int64, cardId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        let parameters = ["cardId": cardId] as [String: Any]
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters)
            apiClient.request(endpoint: "/api/decks/\(deckId)/remove-card", method: .delete, body: data) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func getPublicDecks(completion: @escaping (Result<[Deck], Error>) -> Void) {
        apiClient.request(endpoint: "/api/decks/public", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let decks = try decoder.decode([Deck].self, from: data)
                    completion(.success(decks))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - User Deck Management
    
    func loadUserDecksIfNeeded(userId: Int64, completion: @escaping (Result<[Deck], Error>) -> Void) {
        // Se abbiamo già caricato i deck per questo utente, non ricaricare
        if hasLoadedUserDecks && lastLoadedUserId == userId && !userDecks.isEmpty {
            completion(.success(userDecks))
            return
        }
        
        loadUserDecks(userId: userId, completion: completion)
    }
    
    func loadUserDecks(userId: Int64, completion: @escaping (Result<[Deck], Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        getAllDecks(userId: userId) { result in
            switch result {
            case .success(let userDecks):
                // Backend now filters by ownerId, no client-side filtering needed
                self.userDecks = userDecks
                self.hasLoadedUserDecks = true
                self.lastLoadedUserId = userId
                self.saveUserDecksToCache(userDecks)
                completion(.success(userDecks))
            case .failure(let error):
                if self.useMockData {
                    // Mock data per testing quando l'endpoint non esiste
                    let mockDecks = self.createMockDecks(for: userId)
                    self.userDecks = mockDecks
                    self.hasLoadedUserDecks = true
                    self.lastLoadedUserId = userId
                    self.saveUserDecksToCache(mockDecks)
                    completion(.success(mockDecks))
                } else {
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
            }
            self.isLoading = false
        }
    }
    
    func saveDeck(_ deck: Deck, completion: @escaping (Result<Deck, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        if let id = deck.id {
            updateDeck(id, deck: deck) { result in
                switch result {
                case .success(let updatedDeck):
                    // Update local array
                    if let index = self.userDecks.firstIndex(where: { $0.id == id }) {
                        self.userDecks[index] = updatedDeck
                        self.saveUserDecksToCache(self.userDecks)
                    }
                    completion(.success(updatedDeck))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
                self.isLoading = false
            }
        } else {
            createDeck(deck) { result in
                switch result {
                case .success(let createdDeck):
                    self.userDecks.append(createdDeck)
                    self.saveUserDecksToCache(self.userDecks)
                    completion(.success(createdDeck))
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }
                self.isLoading = false
            }
        }
    }
    
    func deleteDeck(deckId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        
        deleteDeck(deckId) { result in
            switch result {
            case .success:
                self.userDecks.removeAll { $0.id == deckId }
                self.saveUserDecksToCache(self.userDecks)
                completion(.success(()))
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
            self.isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateLocalDeckCache(_ updatedDeck: Deck) {
        // Update the deck in the local cache
        if let index = self.userDecks.firstIndex(where: { $0.id == updatedDeck.id }) {
            self.userDecks[index] = updatedDeck
            self.saveUserDecksToCache(self.userDecks)
        }
    }
    
    // MARK: - Pro Decks

    private func loadProDecks() {
        getAllProDecks { result in
            switch result {
            case .success(let proDecks):
                DispatchQueue.main.async {
                    self.proDecks = proDecks
                }
            case .failure(let error):
                // Handle error silently
                break
            }
        }
    }

    func getAllProDecks(completion: @escaping (Result<[ProDeck], Error>) -> Void) {
        apiClient.request(endpoint: "/api/pro-decks", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let proDecks = try decoder.decode([ProDeck].self, from: data)
                    completion(.success(proDecks))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getProDeckById(_ id: Int64, completion: @escaping (Result<ProDeck, Error>) -> Void) {
        apiClient.request(endpoint: "/api/pro-decks/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let proDeck = try self.createDecoder().decode(ProDeck.self, from: data)
                    completion(.success(proDeck))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getRecentProDecks(completion: @escaping (Result<[ProDeck], Error>) -> Void) {
        apiClient.request(endpoint: "/api/pro-decks/recent", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let proDecks = try decoder.decode([ProDeck].self, from: data)
                    completion(.success(proDecks))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func addDeck(_ deck: Deck) {
        userDecks.append(deck)
        saveUserDecksToCache(userDecks)
    }
    
    // MARK: - Cache Management
    
    func saveUserDecksToCache(_ decks: [Deck]) {
        #if !DEBUG
        // Salva la cache solo in modalità release
        do {
            let data = try JSONEncoder().encode(decks)
            UserDefaults.standard.set(data, forKey: "cachedUserDecks")
        } catch {
            // Handle error silently
        }
        #else
        // In modalità debug, la cache è disabilitata
        print("🔧 DeckService: Cache disabilitata per modalità debug - deck non salvati in cache")
        #endif
    }
    
    private func loadCachedUserDecks() {
        #if !DEBUG
        // Carica dalla cache solo in modalità release
        guard let data = UserDefaults.standard.data(forKey: "cachedUserDecks") else { return }
        do {
            let decks = try createDecoder().decode([Deck].self, from: data)
            self.userDecks = decks
        } catch {
            UserDefaults.standard.removeObject(forKey: "cachedUserDecks")
        }
        #else
        // In modalità debug, la cache è disabilitata
        print("🔧 DeckService: Cache disabilitata per modalità debug - deck non caricati dalla cache")
        #endif
    }
    
    func refreshUserDecks(userId: Int64, completion: @escaping (Result<[Deck], Error>) -> Void) {
        // Forza il ricaricamento ignorando la cache
        hasLoadedUserDecks = false
        loadUserDecks(userId: userId, completion: completion)
    }
    
    func handleUserLogout() {
        clearCache()
    }
    
    func clearCache() {
        hasLoadedUserDecks = false
        lastLoadedUserId = nil
        userDecks = []
        UserDefaults.standard.removeObject(forKey: "cachedUserDecks")
    }
    
    // MARK: - Mock Data for Testing
    // TODO: Rimuovere quando il backend implementerà l'endpoint /api/decks
    // Per disabilitare i mock data, impostare useMockData = false
    
    private let useMockData = true
    
    private func createMockDecks(for userId: Int64) -> [Deck] {
        let mockCards: [Deck.DeckCard] = [
            Deck.DeckCard(id: 1, cardId: 1001, quantity: 4, cardName: "Pikachu", cardImageUrl: nil),
            Deck.DeckCard(id: 2, cardId: 1002, quantity: 4, cardName: "Charizard", cardImageUrl: nil),
            Deck.DeckCard(id: 3, cardId: 1003, quantity: 2, cardName: "Blastoise", cardImageUrl: nil),
            Deck.DeckCard(id: 4, cardId: 1004, quantity: 4, cardName: "Venusaur", cardImageUrl: nil),
        ]
        
        return [
            {
                var deck = Deck(name: "Pikachu Control", tcgType: .pokemon, ownerId: userId, description: "A powerful control deck featuring Pikachu and friends", tags: ["control", "electric", "beginner"])
                deck.cards = Array(mockCards.prefix(4))
                deck.dateCreated = Date().addingTimeInterval(-86400 * 7) // 7 giorni fa
                deck.dateModified = Date().addingTimeInterval(-86400) // 1 giorno fa
                deck.isPublic = true
                return deck
            }(),
            {
                var deck = Deck(name: "Fire Aggro", tcgType: .pokemon, ownerId: userId, description: "Fast aggro deck with fire types", tags: ["aggro", "fire", "competitive"])
                deck.cards = Array(mockCards.dropFirst())
                deck.dateCreated = Date().addingTimeInterval(-86400 * 3) // 3 giorni fa
                deck.dateModified = Date()
                deck.isPublic = false
                return deck
            }(),
            {
                var deck = Deck(name: "Water Control", tcgType: .pokemon, ownerId: userId, description: "Slow but powerful water control deck", tags: ["control", "water", "tournament"])
                deck.cards = [mockCards[2]] // Solo Blastoise
                deck.dateCreated = Date().addingTimeInterval(-86400 * 14) // 2 settimane fa
                deck.dateModified = Date().addingTimeInterval(-86400 * 2) // 2 giorni fa
                deck.isPublic = true
                return deck
            }()
        ]
    }
}
