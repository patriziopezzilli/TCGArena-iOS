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
    func createReservation(cardId: String, quantity: Int = 1) async throws -> Reservation {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = CreateReservationRequest(cardId: cardId, quantity: quantity)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/reservations", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
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
    func getUserReservations(userId: String) async throws -> [Reservation] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/reservations?userId=\(userId)", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
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
    
    // MARK: - Get Merchant Reservations
    func getMerchantReservations(merchantId: String, status: Reservation.ReservationStatus? = nil) async throws -> [Reservation] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        var endpoint = "/reservations?merchantId=\(merchantId)"
        if let status = status {
            endpoint += "&status=\(status.rawValue)"
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: endpoint, method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
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
    
    // MARK: - Validate Reservation (QR Scan)
    func validateReservation(id: String, qrCode: String) async throws -> Reservation {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = ValidateReservationRequest(qrCode: qrCode)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/reservations/\(id)/validate", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
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
            apiClient.request(endpoint: "/reservations/\(id)/pickup", method: .post) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
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
            apiClient.request(endpoint: "/reservations/\(id)/cancel", method: .post) { result in
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
