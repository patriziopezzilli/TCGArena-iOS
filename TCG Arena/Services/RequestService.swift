//
//  RequestService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import Foundation
import Combine

@MainActor
class RequestService: ObservableObject {
    @Published var requests: [MerchantRequest] = []
    @Published var activeRequests: [MerchantRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Create Request
    func createRequest(_ request: CreateRequestRequest) async throws -> MerchantRequest {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/requests", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let response = try decoder.decode(RequestResponse.self, from: data)
                        
                        Task { @MainActor in
                            self.requests.insert(response.request, at: 0)
                            self.updateActiveRequests()
                        }
                        continuation.resume(returning: response.request)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to create request: \(error.localizedDescription)"
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
    
    // MARK: - Get User Requests
    func getUserRequests(userId: String) async throws -> [MerchantRequest] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/requests?userId=\(userId)", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let response = try decoder.decode(RequestListResponse.self, from: data)
                        
                        Task { @MainActor in
                            self.requests = response.requests
                            self.updateActiveRequests()
                        }
                        continuation.resume(returning: response.requests)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to load requests: \(error.localizedDescription)"
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
    
    // MARK: - Get Merchant Requests
    func getMerchantRequests(merchantId: String, status: MerchantRequest.RequestStatus? = nil) async throws -> [MerchantRequest] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        var endpoint = "/requests?merchantId=\(merchantId)"
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
                        
                        let response = try decoder.decode(RequestListResponse.self, from: data)
                        
                        Task { @MainActor in
                            self.requests = response.requests
                            self.updateActiveRequests()
                        }
                        continuation.resume(returning: response.requests)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to load requests: \(error.localizedDescription)"
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
    
    // MARK: - Get Request Detail with Messages
    func getRequestDetail(id: String) async throws -> RequestResponse {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/requests/\(id)", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let response = try decoder.decode(RequestResponse.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to load request: \(error.localizedDescription)"
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
    
    // MARK: - Send Message
    func sendMessage(requestId: String, content: String, attachmentUrl: String? = nil) async throws -> RequestMessage {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = SendMessageRequest(content: content, attachmentUrl: attachmentUrl)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/requests/\(requestId)/message", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let message = try decoder.decode(RequestMessage.self, from: data)
                        continuation.resume(returning: message)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to send message: \(error.localizedDescription)"
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
    
    // MARK: - Update Request Status
    func updateRequestStatus(id: String, status: MerchantRequest.RequestStatus, message: String? = nil) async throws -> MerchantRequest {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = UpdateRequestStatusRequest(status: status, message: message)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/requests/\(id)/status", method: .patch, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        
                        let updatedRequest = try decoder.decode(MerchantRequest.self, from: data)
                        
                        Task { @MainActor in
                            if let index = self.requests.firstIndex(where: { $0.id == id }) {
                                self.requests[index] = updatedRequest
                            }
                            self.updateActiveRequests()
                        }
                        continuation.resume(returning: updatedRequest)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to update status: \(error.localizedDescription)"
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
    
    // MARK: - Accept Request
    func acceptRequest(id: String, message: String? = nil) async throws -> MerchantRequest {
        return try await updateRequestStatus(id: id, status: .accepted, message: message)
    }
    
    // MARK: - Reject Request
    func rejectRequest(id: String, message: String? = nil) async throws -> MerchantRequest {
        return try await updateRequestStatus(id: id, status: .rejected, message: message)
    }
    
    // MARK: - Complete Request
    func completeRequest(id: String, message: String? = nil) async throws -> MerchantRequest {
        return try await updateRequestStatus(id: id, status: .completed, message: message)
    }
    
    // MARK: - Cancel Request
    func cancelRequest(id: String) async throws -> MerchantRequest {
        return try await updateRequestStatus(id: id, status: .cancelled)
    }
    
    // MARK: - Helper Methods
    private func updateActiveRequests() {
        activeRequests = requests.filter { $0.isActive }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // Get unread count for notifications
    func getUnreadCount(for merchantId: String) -> Int {
        // This would need to be enhanced with actual unread tracking
        return activeRequests.count
    }
}
