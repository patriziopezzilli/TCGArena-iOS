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
        apiClient.request(endpoint: "/api/expansions", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let expansions = try self.decoder.decode([Expansion].self, from: data)
                    // print("✅ Successfully decoded \(expansions.count) expansions")
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
        apiClient.request(endpoint: "/api/expansions/recent", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let expansions = try self.decoder.decode([Expansion].self, from: data)
                    // print("✅ Successfully decoded \(expansions.count) recent expansions")
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
        apiClient.request(endpoint: "/api/expansions/\(id)", method: .get) { result in
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
    
    func getCardsForSet(_ setId: Int64, page: Int = 1, limit: Int = 20, completion: @escaping (Result<[CardTemplate], Error>) -> Void) {
        #if DEBUG
        // print("🔄 [DEBUG] Cache disabled for set cards - fetching from API")
        // Skip cache in debug mode
        let apiPage = max(0, page - 1)
        let endpoint = "/api/sets/\(setId)/cards?page=\(apiPage)&limit=\(limit)"
        // print("🌐 [DEBUG] API request: \(endpoint)")
        apiClient.request(endpoint: endpoint, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let pagedResponse = try JSONDecoder().decode(PagedResponse<CardTemplate>.self, from: data)
                    // print("✅ [DEBUG] API response: \(pagedResponse.content.count) cards")
                    completion(.success(pagedResponse.content))
                } catch {
                    print("❌ [DEBUG] JSON decode error: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                print("❌ [DEBUG] API request failed: \(error)")
                completion(.failure(error))
            }
        }
        #else
        // Check cache first
        let cacheKey = "cachedSetCards_\(setId)_page\(page)_limit\(limit)"
        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
           let cachedCards = try? JSONDecoder().decode([CardTemplate].self, from: cachedData) {
            print("💾 [RELEASE] Using cached cards: \(cachedCards.count) cards")
            completion(.success(cachedCards))
            return
        }

        // Fetch from API and cache
        let apiPage = max(0, page - 1)
        let endpoint = "/api/sets/\(setId)/cards?page=\(apiPage)&limit=\(limit)"
        print("🌐 [RELEASE] API request: \(endpoint)")
        apiClient.request(endpoint: endpoint, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let pagedResponse = try self.decoder.decode(PagedResponse<CardTemplate>.self, from: data)
                    // Cache the result
                    if let cacheData = try? JSONEncoder().encode(pagedResponse.content) {
                        UserDefaults.standard.set(cacheData, forKey: cacheKey)
                    }
                    print("✅ [RELEASE] API response: \(pagedResponse.content.count) cards")
                    completion(.success(pagedResponse.content))
                } catch {
                    print("❌ [RELEASE] JSON decode error: \(error)")
                    completion(.failure(error))
                }
            case .failure(let error):
                print("❌ [RELEASE] API request failed: \(error)")
                completion(.failure(error))
            }
        }
        #endif
    }

    func getCardsForExpansion(_ expansion: Expansion, completion: @escaping (Result<[CardTemplate], Error>) -> Void) {
        // print("🔍 Checking for pre-loaded cards in expansion \(expansion.title)")

        // First, try to get cards from the sets that are already loaded
        let existingCards = expansion.sets.compactMap { $0.cards }.flatMap { $0 }
        if !existingCards.isEmpty {
            // print("💾 Found \(existingCards.count) pre-loaded cards for expansion \(expansion.title)")
            completion(.success(existingCards))
            return
        }

        // print("⚠️ No pre-loaded cards found - consider loading cards only when needed")
        // For now, return empty array to avoid unnecessary API calls
        completion(.success([]))

        // Old implementation commented out to avoid automatic loading
        /*
        let group = DispatchGroup()
        var allCards: [CardTemplate] = []
        var firstError: Error?
        let accessQueue = DispatchQueue(label: "com.tcgarena.expansion.cards.access")

        for set in sets {
            group.enter()
            print("📦 Loading cards for set \(set.name) (ID: \(set.id))")
            // Load more cards per set for expansion preview (50 instead of 10)
            getCardsForSet(set.id, page: 1, limit: 50) { result in
                accessQueue.async {
                    switch result {
                    case .success(let cards):
                        print("✅ Loaded \(cards.count) cards for set \(set.name)")
                        allCards.append(contentsOf: cards)
                    case .failure(let error):
                        print("❌ Failed to load cards for set \(set.name): \(error.localizedDescription)")
                        if firstError == nil {
                            firstError = error
                        }
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            if let error = firstError, allCards.isEmpty {
                print("❌ All set loading failed for expansion \(expansion.title)")
                completion(.failure(error))
            } else {
                // Shuffle and limit total cards for preview - increase limit
                let shuffledCards = allCards.shuffled()
                let limitedCards = Array(shuffledCards.prefix(100)) // Max 100 cards for expansion preview
                print("🎉 Total loaded \(allCards.count) cards, showing \(limitedCards.count) for expansion \(expansion.title)")
                completion(.success(limitedCards))
            }
        }
        */
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

    // MARK: - Cache Management

    func clearSetCardsCache() {
        #if DEBUG
        print("🗑️ [DEBUG] Clearing set cards cache")
        #endif

        let keys = UserDefaults.standard.dictionaryRepresentation().keys.filter { $0.hasPrefix("cachedSetCards_") }
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }
}
