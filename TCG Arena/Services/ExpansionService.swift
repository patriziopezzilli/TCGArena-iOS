//
//  ExpansionService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import Foundation

@MainActor
class ExpansionService: ObservableObject {
    @Published var expansions: [Expansion] = []
    @Published var recentExpansions: [Expansion] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "it_IT")
        decoder.dateDecodingStrategy = .formatted(formatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - API Methods
    
    func getAllExpansions(completion: @escaping (Result<[Expansion], Error>) -> Void) {
        apiClient.request(endpoint: "/expansions", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let expansions = try self.decoder.decode([Expansion].self, from: data)
                    print("✅ Successfully decoded \(expansions.count) expansions")
                    completion(.success(expansions))
                } catch {
                    print("❌ Failed to decode expansions: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getRecentExpansions(completion: @escaping (Result<[Expansion], Error>) -> Void) {
        apiClient.request(endpoint: "/expansions/recent", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let expansions = try self.decoder.decode([Expansion].self, from: data)
                    print("✅ Successfully decoded \(expansions.count) recent expansions")
                    completion(.success(expansions))
                } catch {
                    print("❌ Failed to decode recent expansions: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getExpansionById(_ id: Int64, completion: @escaping (Result<Expansion, Error>) -> Void) {
        apiClient.request(endpoint: "/expansions/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let expansion = try self.decoder.decode(Expansion.self, from: data)
                    completion(.success(expansion))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    
    // MARK: - User Interface Methods
    
    func loadExpansions() async {
        isLoading = true
        errorMessage = nil
        
        await withCheckedContinuation { continuation in
            getAllExpansions { result in
                Task { @MainActor in
                    switch result {
                    case .success(let fetchedExpansions):
                        self.expansions = fetchedExpansions
                        continuation.resume()
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        self.expansions = []
                        self.recentExpansions = []
                        continuation.resume()
                    }
                    self.isLoading = false
                }
            }
        }
        
        // Load recent expansions after all expansions are loaded
        await loadRecentExpansions()
    }
    
    func loadRecentExpansions() async {
        await withCheckedContinuation { continuation in
            getRecentExpansions { result in
                Task { @MainActor in
                    switch result {
                    case .success(let recentExpansions):
                        self.recentExpansions = recentExpansions
                    case .failure:
                        // Fallback: filter recent expansions from all expansions
                        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
                        self.recentExpansions = self.expansions.filter { expansion in
                            expansion.sets.contains { $0.releaseDate >= sixMonthsAgo }
                        }
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    func getCardsForExpansion(_ expansion: Expansion, completion: @escaping (Result<[CardTemplate], Error>) -> Void) {
        apiClient.request(endpoint: "/expansions/\(expansion.id)/cards", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let cards = try self.decoder.decode([CardTemplate].self, from: data)
                    completion(.success(cards))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func loadCards(for expansion: Expansion) async -> [CardTemplate] {
        await withCheckedContinuation { continuation in
            getCardsForExpansion(expansion) { result in
                switch result {
                case .success(let cards):
                    continuation.resume(returning: cards)
                case .failure:
                    continuation.resume(returning: [])
                }
            }
        }
    }
}
