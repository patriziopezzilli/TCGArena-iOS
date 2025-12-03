//
//  InventoryService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation
import Combine

@MainActor
class InventoryService: ObservableObject {
    @Published var inventory: [InventoryCard] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Get Inventory
    func loadInventory(shopId: String, filters: InventoryFilters? = nil) async {
        do {
            inventory = try await getInventory(merchantId: shopId, filters: filters)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func getInventory(merchantId: String, filters: InventoryFilters? = nil) async throws -> [InventoryCard] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        var endpoint = "/api/inventory"
        
        var queryParams = ["shopId": merchantId]
        
        if let filters = filters {
            for (key, value) in filters.queryParameters {
                queryParams[key] = value
            }
        }
        
        let queryString = queryParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        if !queryString.isEmpty {
            endpoint += "?\(queryString)"
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: endpoint, method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let cards = try decoder.decode([InventoryCard].self, from: data)
                        Task { @MainActor in
                            self.inventory = cards
                        }
                        continuation.resume(returning: cards)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to decode inventory: \(error.localizedDescription)"
                        }
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Get Card by ID
    func getCard(id: String) async throws -> InventoryCard {
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/inventory/\(id)", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let card = try JSONDecoder().decode(InventoryCard.self, from: data)
                        continuation.resume(returning: card)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Create Card
    func createCard(_ request: CreateInventoryCardRequest) async throws -> InventoryCard {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/inventory", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let card = try decoder.decode(InventoryCard.self, from: data)
                        
                        Task { @MainActor in
                            self.inventory.append(card)
                        }
                        continuation.resume(returning: card)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to create card: \(error.localizedDescription)"
                        }
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Update Card
    func updateCard(id: String, request: UpdateInventoryCardRequest) async throws -> InventoryCard {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/inventory/\(id)", method: .patch, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let card = try decoder.decode(InventoryCard.self, from: data)
                        
                        Task { @MainActor in
                            if let index = self.inventory.firstIndex(where: { $0.id == id }) {
                                self.inventory[index] = card
                            }
                        }
                        continuation.resume(returning: card)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to update card: \(error.localizedDescription)"
                        }
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Delete Card
    func deleteCard(id: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/inventory/\(id)", method: .delete) { result in
                switch result {
                case .success:
                    Task { @MainActor in
                        self.inventory.removeAll { $0.id == id }
                    }
                    continuation.resume()
                case .failure(let error):
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Update Quantity
    func updateQuantity(cardId: String, delta: Int) async throws -> InventoryCard {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let update = InventoryQuantityUpdate(delta: delta)
        let body = try JSONEncoder().encode(update)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/inventory/\(cardId)/quantity", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let card = try decoder.decode(InventoryCard.self, from: data)
                        
                        Task { @MainActor in
                            if let index = self.inventory.firstIndex(where: { $0.id == cardId }) {
                                self.inventory[index] = card
                            }
                        }
                        continuation.resume(returning: card)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to update quantity: \(error.localizedDescription)"
                        }
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Search
    func searchInventory(query: String, merchantId: String) async throws -> [InventoryCard] {
        var filters = InventoryFilters()
        filters.searchQuery = query
        return try await getInventory(merchantId: merchantId, filters: filters)
    }
    
    // MARK: - Helper Methods
    func clearError() {
        errorMessage = nil
    }
}
