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
    
    // Helper function to format dates as strings for backend (format: "dd MMM yyyy, HH:mm")
    private func formatDateForBackend(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
    
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
    
    func updateDeck(id: Int64, name: String, description: String?, userId: Int64, completion: @escaping (Result<Deck, Error>) -> Void) {
        // First, fetch the existing deck to get all its properties
        getDeckById(id) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(var deck):
                // Create an updated copy of the deck with new name and description
                // We need to use a mutable variable since Deck properties might be let
                // Create a new Deck using the existing data but with updated name/description
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .custom { date, encoder in
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    let dateString = formatter.string(from: date)
                    var container = encoder.singleValueContainer()
                    try container.encode(dateString)
                }
                
                let decoder = self.createDecoder()
                
                do {
                    // Instead of modifying the JSON, create a new Deck instance with updated properties
                    let updatedDeck = Deck(
                        id: deck.id,
                        name: name,
                        tcgType: deck.tcgType,
                        deckType: deck.deckType,
                        cards: deck.cards,
                        ownerId: deck.ownerId,
                        dateCreated: deck.dateCreated,
                        dateModified: formatDateForBackend(Date()), // Update modification date
                        isPublic: deck.isPublic,
                        description: description,
                        tags: deck.tags
                    )
                    
                    // Now use the existing updateDeck method that uses the correct endpoint
                    self.updateDeck(id, deck: updatedDeck) { updateResult in
                        completion(updateResult)
                    }
                } catch {
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        // Dates are now formatted as strings by the backend, so no custom decoding needed
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
    
    func createDeck(name: String, description: String?, tcgType: TCGType, deckType: DeckType, userId: Int64, completion: @escaping (Result<Deck, Error>) -> Void) {
        let urlString = "/api/decks/create?name=\(name.urlEncoded())&description=\(description?.urlEncoded() ?? "")&tcgType=\(tcgType.rawValue)&deckType=\(deckType.rawValue)&userId=\(userId)"
        print("📤 DeckService: Creating new deck '\(name)'")
        apiClient.request(endpoint: urlString, method: .post) { result in
            switch result {
            case .success(let data):
                do {
                    let createdDeck = try self.createDecoder().decode(Deck.self, from: data)
                    // Add to local cache on main thread
                    DispatchQueue.main.async {
                        self.userDecks.append(createdDeck)
                        self.saveUserDecksToCache(self.userDecks)
                        print("✅ DeckService: Deck '\(name)' created and added to cache")
                    }
                    completion(.success(createdDeck))
                } catch {
                    print("🔴 DeckService: Failed to decode created deck: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                print("🔴 DeckService: Failed to create deck: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func updateDeck(_ id: Int64, deck: Deck, completion: @escaping (Result<Deck, Error>) -> Void) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .custom { date, encoder in
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                let dateString = formatter.string(from: date)
                var container = encoder.singleValueContainer()
                try container.encode(dateString)
            }
            
            let data = try encoder.encode(deck)
            print("📤 DeckService: Updating deck \(id)")
            apiClient.request(endpoint: "/api/decks/\(id)", method: .put, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let updatedDeck = try self.createDecoder().decode(Deck.self, from: data)
                        print("✅ DeckService: Deck \(id) updated successfully")
                        // Update local cache
                        self.updateLocalDeckCache(updatedDeck)
                        completion(.success(updatedDeck))
                    } catch {
                        print("🔴 DeckService: Failed to decode updated deck: \(error)")
                        completion(.failure(error))
                    }
                case .failure(let error):
                    print("🔴 DeckService: Failed to update deck: \(error)")
                    completion(.failure(error))
                }
            }
        } catch {
            print("🔴 DeckService: Failed to encode deck: \(error)")
            completion(.failure(error))
        }
    }
    
    func deleteDeck(_ id: Int64, userId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlString = "/api/decks/\(id)?userId=\(userId)"
        print("🗑️ DeckService: Deleting deck \(id) for user \(userId)")
        apiClient.request(endpoint: urlString, method: .delete) { result in
            switch result {
            case .success:
                print("✅ DeckService: Deck \(id) deleted successfully")
                completion(.success(()))
            case .failure(let error):
                print("🔴 DeckService: Failed to delete deck \(id): \(error)")
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
    
    func loadUserDecks(userId: Int64, saveToCache: Bool = true, completion: @escaping (Result<[Deck], Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        getAllDecks(userId: userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let userDecks):
                    // Backend now filters by ownerId, no client-side filtering needed
                    self.userDecks = userDecks
                    self.hasLoadedUserDecks = true
                    self.lastLoadedUserId = userId
                    if saveToCache {
                        self.saveUserDecksToCache(userDecks)
                    }
                    completion(.success(userDecks))
                case .failure(let error):
                    if self.useMockData {
                        // Mock data per testing quando l'endpoint non esiste
                        let mockDecks = self.createMockDecks(for: userId)
                        self.userDecks = mockDecks
                        self.hasLoadedUserDecks = true
                        self.lastLoadedUserId = userId
                        if saveToCache {
                            self.saveUserDecksToCache(mockDecks)
                        }
                        completion(.success(mockDecks))
                    } else {
                        self.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    }
                }
                self.isLoading = false
            }
        }
    }
    
    func saveDeck(_ deck: Deck, completion: @escaping (Result<Deck, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        if let id = deck.id {
            updateDeck(id, deck: deck) { result in
                DispatchQueue.main.async {
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
            }
        } else {
            createDeck(deck) { result in
                DispatchQueue.main.async {
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
    }
    
func deleteDeck(deckId: Int64, userId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
    isLoading = true
    
    deleteDeck(deckId, userId: userId) { result in
        DispatchQueue.main.async {
            switch result {
            case .success:
                // Remove from local cache on main thread
                self.userDecks.removeAll { $0.id == deckId }
                self.saveUserDecksToCache(self.userDecks)
                print("✅ DeckService: Deck \(deckId) removed from cache")
                completion(.success(()))
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
            self.isLoading = false
        }
    }
}
    
    // MARK: - Helper Methods
    
    func updateLocalDeckCache(_ updatedDeck: Deck) {
        // Update the deck in the local cache - MUST be on main thread for @Published to work
        DispatchQueue.main.async {
            if let index = self.userDecks.firstIndex(where: { $0.id == updatedDeck.id }) {
                self.userDecks[index] = updatedDeck
                self.saveUserDecksToCache(self.userDecks)
                print("✅ DeckService: Updated deck \(updatedDeck.id ?? 0) in local cache")
            } else {
                print("⚠️ DeckService: Deck \(updatedDeck.id ?? 0) not found in local cache for update")
            }
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
        DispatchQueue.main.async {
            self.userDecks.append(deck)
            self.saveUserDecksToCache(self.userDecks)
        }
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
        // Forza il ricaricamento invalidando completamente la cache e ricarica senza salvare
        clearCache()
        hasLoadedUserDecks = false
        lastLoadedUserId = userId
        loadUserDecks(userId: userId, saveToCache: false, completion: completion)
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
            Deck.DeckCard(id: 1, cardId: 1001, quantity: 4, cardName: "Pikachu", cardImageUrl: nil, condition: .nearMint, isGraded: nil, gradingCompany: nil, grade: nil, certificateNumber: nil),
            Deck.DeckCard(id: 2, cardId: 1002, quantity: 4, cardName: "Charizard", cardImageUrl: nil, condition: .nearMint, isGraded: nil, gradingCompany: nil, grade: nil, certificateNumber: nil),
            Deck.DeckCard(id: 3, cardId: 1003, quantity: 2, cardName: "Blastoise", cardImageUrl: nil, condition: .nearMint, isGraded: nil, gradingCompany: nil, grade: nil, certificateNumber: nil),
            Deck.DeckCard(id: 4, cardId: 1004, quantity: 4, cardName: "Venusaur", cardImageUrl: nil, condition: .nearMint, isGraded: nil, gradingCompany: nil, grade: nil, certificateNumber: nil),
        ]
        
        return [
            Deck(
                id: nil,
                name: "Pikachu Control",
                tcgType: .pokemon,
                deckType: .deck,
                cards: Array(mockCards.prefix(4)),
                ownerId: userId,
                dateCreated: formatDateForBackend(Date().addingTimeInterval(-86400 * 7)), // 7 giorni fa
                dateModified: formatDateForBackend(Date().addingTimeInterval(-86400)), // 1 giorno fa
                isPublic: true,
                description: "A powerful control deck featuring Pikachu and friends",
                tags: ["control", "electric", "beginner"]
            ),
            Deck(
                id: nil,
                name: "Fire Aggro",
                tcgType: .pokemon,
                deckType: .deck,
                cards: Array(mockCards.dropFirst()),
                ownerId: userId,
                dateCreated: formatDateForBackend(Date().addingTimeInterval(-86400 * 3)), // 3 giorni fa
                dateModified: formatDateForBackend(Date()),
                isPublic: false,
                description: "Fast aggro deck with fire types",
                tags: ["aggro", "fire", "competitive"]
            ),
            Deck(
                id: nil,
                name: "Water Control",
                tcgType: .pokemon,
                deckType: .deck,
                cards: [mockCards[2]], // Solo Blastoise
                ownerId: userId,
                dateCreated: formatDateForBackend(Date().addingTimeInterval(-86400 * 14)), // 2 settimane fa
                dateModified: formatDateForBackend(Date().addingTimeInterval(-86400 * 2)), // 2 giorni fa
                isPublic: true,
                description: "Slow but powerful water control deck",
                tags: ["control", "water", "tournament"]
            )
        ]
    }
}

// MARK: - String Extension for URL Encoding
extension String {
    func urlEncoded() -> String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
