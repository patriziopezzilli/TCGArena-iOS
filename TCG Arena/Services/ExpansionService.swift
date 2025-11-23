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
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
        loadExpansions()
    }
    
    // MARK: - API Methods
    
    func getAllExpansions(completion: @escaping (Result<[Expansion], Error>) -> Void) {
        apiClient.request(endpoint: "/api/expansions", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let expansions = try JSONDecoder().decode([Expansion].self, from: data)
                    completion(.success(expansions))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getRecentExpansions(completion: @escaping (Result<[Expansion], Error>) -> Void) {
        apiClient.request(endpoint: "/api/expansions/recent", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let expansions = try JSONDecoder().decode([Expansion].self, from: data)
                    completion(.success(expansions))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getExpansionById(_ id: Int64, completion: @escaping (Result<Expansion, Error>) -> Void) {
        apiClient.request(endpoint: "/api/expansions/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let expansion = try JSONDecoder().decode(Expansion.self, from: data)
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
    
    func loadExpansions() {
        isLoading = true
        errorMessage = nil
        
        getAllExpansions { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedExpansions):
                    self.expansions = fetchedExpansions
                    // Load recent expansions as well
                    self.loadRecentExpansions()
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    // Fallback to empty arrays
                    self.expansions = []
                    self.recentExpansions = []
                }
                self.isLoading = false
            }
        }
    }
    
    func loadRecentExpansions() {
        getRecentExpansions { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recentExpansions):
                    self.recentExpansions = recentExpansions
                case .failure:
                    // Fallback: filter recent expansions from all expansions
                    // Since backend provides recent endpoint, this shouldn't happen
                    self.recentExpansions = self.expansions.filter { expansion in
                        // Consider recent if any set was released in last 6 months
                        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
                        return expansion.sets.contains { $0.releaseDate >= sixMonthsAgo }
                    }
                }
            }
        }
    }
    
    func getCardsForExpansion(_ expansion: Expansion, completion: @escaping (Result<[CardTemplate], Error>) -> Void) {
        apiClient.request(endpoint: "/api/expansions/\(expansion.id)/cards", method: .get) { result in
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
