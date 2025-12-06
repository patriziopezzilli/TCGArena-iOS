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
    @Published var requests: [CustomerRequest] = []
    @Published var merchantRequests: [CustomerRequest] = []
    @Published var activeRequests: [CustomerRequest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var unreadCount: Int = 0
    
    private let apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
    }
    
    // MARK: - Helper Methods
    private func createConfiguredDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        return decoder
    }
    
    // MARK: - Create Request
    func createRequest(_ request: CreateRequestRequest) async throws -> CustomerRequest {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/requests", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = self.createConfiguredDecoder()
                        let createdRequest = try decoder.decode(CustomerRequest.self, from: data)
                        
                        Task { @MainActor in
                            self.requests.insert(createdRequest, at: 0)
                            self.updateActiveRequests()
                        }
                        continuation.resume(returning: createdRequest)
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
    func getUserRequests(userId: String) async throws -> [CustomerRequest] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/requests?userId=\(userId)", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = self.createConfiguredDecoder()
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
    func getMerchantRequests(merchantId: String, status: CustomerRequest.RequestStatus? = nil) async throws -> [CustomerRequest] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        var endpoint = "/api/requests?merchantId=\(merchantId)"
        if let status = status {
            endpoint += "&status=\(status.rawValue)"
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: endpoint, method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = self.createConfiguredDecoder()
                        let response = try decoder.decode(RequestListResponse.self, from: data)
                        
                        Task { @MainActor in
                            self.merchantRequests = response.requests
                            self.updateActiveRequests()
                            self.updateUnreadCount()
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
    func getRequestDetail(id: String) async throws -> CustomerRequest {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/requests/\(id)", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = self.createConfiguredDecoder()
                        let request = try decoder.decode(CustomerRequest.self, from: data)
                        continuation.resume(returning: request)
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
    
    // MARK: - Get Messages
    func getMessages(requestId: String) async throws -> [RequestMessage] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/requests/\(requestId)/messages", method: .get) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = self.createConfiguredDecoder()
                        let response = try decoder.decode(MessageListResponse.self, from: data)
                        continuation.resume(returning: response.messages)
                    } catch {
                        Task { @MainActor in
                            self.errorMessage = "Failed to load messages: \(error.localizedDescription)"
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
    
    // MARK: - Mark as Read
    func markAsRead(requestId: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/requests/\(requestId)/read", method: .post) { result in
                switch result {
                case .success:
                    continuation.resume(returning: ())
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
    func sendMessage(requestId: String, content: String) async throws -> RequestMessage {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = SendMessageRequest(message: content, attachmentUrl: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/requests/\(requestId)/messages", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = self.createConfiguredDecoder()
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
    
    // MARK: - Send Message as Merchant
    func sendMessageAsMerchant(requestId: String, content: String) async throws -> RequestMessage {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = SendMessageRequest(message: content, attachmentUrl: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/requests/\(requestId)/messages/merchant", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = self.createConfiguredDecoder()
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
    func updateRequestStatus(id: String, status: CustomerRequest.RequestStatus, message: String? = nil) async throws -> CustomerRequest {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        let request = UpdateRequestStatusRequest(status: status, message: message)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)
        
        return try await withCheckedThrowingContinuation { continuation in
            apiClient.request(endpoint: "/api/requests/\(id)/status", method: .patch, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = self.createConfiguredDecoder()
                        let updatedRequest = try decoder.decode(CustomerRequest.self, from: data)
                        
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
    func acceptRequest(id: String, message: String? = nil) async throws -> CustomerRequest {
        return try await updateRequestStatus(id: id, status: .accepted, message: message)
    }
    
    // MARK: - Reject Request
    func rejectRequest(id: String, message: String? = nil) async throws -> CustomerRequest {
        return try await updateRequestStatus(id: id, status: .rejected, message: message)
    }
    
    // MARK: - Complete Request
    func completeRequest(id: String, message: String? = nil) async throws -> CustomerRequest {
        return try await updateRequestStatus(id: id, status: .completed, message: message)
    }
    
    // MARK: - Cancel Request
    func cancelRequest(id: String) async throws -> CustomerRequest {
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
    func updateUnreadCount() {
        unreadCount = merchantRequests.filter { $0.hasUnreadMessages }.count
    }
}
