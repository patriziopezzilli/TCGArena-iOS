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
    
    init() {
        loadProDecks()
    }
    
    // MARK: - Deck Operations
    
    func getAllDecks(completion: @escaping (Result<[Deck], Error>) -> Void) {
        apiClient.request(endpoint: "/decks", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decks = try JSONDecoder().decode([Deck].self, from: data)
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
        apiClient.request(endpoint: "/decks/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let deck = try JSONDecoder().decode(Deck.self, from: data)
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
            apiClient.request(endpoint: "/decks", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let createdDeck = try JSONDecoder().decode(Deck.self, from: data)
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
            apiClient.request(endpoint: "/decks/\(id)", method: .put, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let updatedDeck = try JSONDecoder().decode(Deck.self, from: data)
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
        apiClient.request(endpoint: "/decks/\(id)", method: .delete) { result in
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
            apiClient.request(endpoint: "/decks/\(deckId)/add-card", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let updatedDeck = try JSONDecoder().decode(Deck.self, from: data)
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
    
    func removeCardFromDeck(deckId: Int64, cardId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        let parameters = ["cardId": cardId] as [String: Any]
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters)
            apiClient.request(endpoint: "/decks/\(deckId)/remove-card", method: .delete, body: data) { result in
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
        apiClient.request(endpoint: "/decks/public", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decks = try JSONDecoder().decode([Deck].self, from: data)
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
    
    func loadUserDecks(userId: Int64, completion: @escaping (Result<[Deck], Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        getAllDecks { result in
            switch result {
            case .success(let allDecks):
                // Filter decks by ownerId (assuming backend returns all decks)
                let userDecks = allDecks.filter { $0.ownerId == userId }
                self.userDecks = userDecks
                completion(.success(userDecks))
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
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
                completion(.success(()))
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
            self.isLoading = false
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
                print("Failed to load pro decks: \(error)")
            }
        }
    }

    func getAllProDecks(completion: @escaping (Result<[ProDeck], Error>) -> Void) {
        apiClient.request(endpoint: "/pro-decks", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let proDecks = try JSONDecoder().decode([ProDeck].self, from: data)
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
        apiClient.request(endpoint: "/pro-decks/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let proDeck = try JSONDecoder().decode(ProDeck.self, from: data)
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
        apiClient.request(endpoint: "/pro-decks/recent", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let proDecks = try JSONDecoder().decode([ProDeck].self, from: data)
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
    }
}