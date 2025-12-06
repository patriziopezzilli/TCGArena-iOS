//
//  ReservationService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation
import Combine

@MainActor
class ReservationService: ObservableObject {
    @Published var reservations: [Reservation] = []
    @Published var activeReservations: [Reservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Create Reservation
    func createReservation(cardId: String, quantity: Int = 1, availableQuantity: Int? = nil) async throws -> Reservation {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Check available quantity if provided
        if let availableQuantity = availableQuantity {
            do {
                // Get active reservations for this card
                let activeReservationsForCard = try await getReservationsByCardId(cardId: cardId)
                    .filter { $0.isActive }
                
                let activeReservationCount = activeReservationsForCard.count
                
                // Check if we have enough available quantity
                if activeReservationCount >= availableQuantity {
                    throw NSError(domain: "ReservationError", code: 1, 
                                userInfo: [NSLocalizedDescriptionKey: "All available copies are already reserved. Please try again later."])
                }
            } catch {
                // If we can't check reservations (e.g., due to auth issues), allow the reservation
                // The backend will handle the validation
                print("⚠️ Could not check existing reservations: \(error.localizedDescription)")
                print("📝 Allowing reservation - backend will validate availability")
            }
        }
        
        let request = CreateReservationRequest(cardId: cardId, quantity: quantity)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/reservations", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        
                        let response = try decoder.decode(ReservationResponse.self, from: data)
                        
                        Task { @MainActor in
                            self.reservations.insert(response.reservation, at: 0)
                            self.updateActiveReservations()
                        }
                        continuation.resume(returning: response.reservation)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to create reservation: \(error.localizedDescription)"
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
    
    // MARK: - Get User Reservations
    func getUserReservations() async throws -> [Reservation] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/reservations/my", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        
                        let response = try decoder.decode(ReservationListResponse.self, from: data)
                        
                        Task { @MainActor in
                            self.reservations = response.reservations
                            self.updateActiveReservations()
                        }
                        continuation.resume(returning: response.reservations)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to load reservations: \(error.localizedDescription)"
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
    
    // MARK: - Load User Reservations (convenience method)
    func loadUserReservations() async {
        do {
            _ = try await getUserReservations()
        } catch {
            self.errorMessage = "Failed to load reservations: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Get User Reservations for Shop
    func getUserReservationsForShop(shopId: String) async throws -> [Reservation] {
        let endpoint = "/api/reservations/my?shopId=\(shopId)"
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: endpoint, method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        
                        let response = try decoder.decode(ReservationListResponse.self, from: data)
                        continuation.resume(returning: response.reservations)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to load reservations for shop: \(error.localizedDescription)"
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
    
    // MARK: - Get Reservations by Card ID
    func getReservationsByCardId(cardId: String, merchantId: String? = nil) async throws -> [Reservation] {
        var endpoint = "/api/reservations?cardId=\(cardId)"
        if let merchantId = merchantId {
            endpoint += "&merchantId=\(merchantId)"
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: endpoint, method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        
                        let response = try decoder.decode(ReservationListResponse.self, from: data)
                        continuation.resume(returning: response.reservations)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Validate Reservation (QR Scan)
    func validateReservation(qrCode: String) async throws -> Reservation {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = ValidateReservationRequest(qrCode: qrCode)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/reservations/validate", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        
                        let response = try decoder.decode(ReservationResponse.self, from: data)
                        
                        Task { @MainActor in
                            if let index = self.reservations.firstIndex(where: { $0.id == response.reservation.id }) {
                                self.reservations[index] = response.reservation
                            } else {
                                self.reservations.insert(response.reservation, at: 0)
                            }
                            self.updateActiveReservations()
                        }
                        continuation.resume(returning: response.reservation)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to validate reservation: \(error.localizedDescription)"
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
    
    // MARK: - Validate Reservation by ID (QR Scan)
    func validateReservation(id: String, qrCode: String) async throws -> Reservation {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = ValidateReservationRequest(qrCode: qrCode)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/reservations/\(id)/validate", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        
                        let response = try decoder.decode(ReservationResponse.self, from: data)
                        
                        Task { @MainActor in
                            if let index = self.reservations.firstIndex(where: { $0.id == id }) {
                                self.reservations[index] = response.reservation
                            }
                            self.updateActiveReservations()
                        }
                        continuation.resume(returning: response.reservation)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to validate reservation: \(error.localizedDescription)"
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
    
    // MARK: - Confirm Pickup
    func confirmPickup(id: String) async throws -> Reservation {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/reservations/\(id)/pickup", method: .post) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        
                        let response = try decoder.decode(ReservationResponse.self, from: data)
                        
                        Task { @MainActor in
                            if let index = self.reservations.firstIndex(where: { $0.id == id }) {
                                self.reservations[index] = response.reservation
                            }
                            self.updateActiveReservations()
                        }
                        continuation.resume(returning: response.reservation)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to confirm pickup: \(error.localizedDescription)"
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
    
    // MARK: - Cancel Reservation
    func cancelReservation(id: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/reservations/\(id)/cancel", method: .put) { result in
                switch result {
                case .success:
                    Task { @MainActor in
                        self.reservations.removeAll { $0.id == id }
                        self.updateActiveReservations()
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
    
    // MARK: - Helper Methods
    private func updateActiveReservations() {
        activeReservations = reservations.filter { $0.isActive }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // Check for expired reservations
    func checkExpiredReservations() {
        let now = Date()
        for reservation in reservations where reservation.status == .pending && reservation.expiresAt < now {
            // Mark as expired locally (backend should handle this via scheduled job)
            if let index = reservations.firstIndex(where: { $0.id == reservation.id }) {
                // In a real app, we'd refresh from the server
                // For now, just update the active list
                updateActiveReservations()
            }
        }
    }
}
