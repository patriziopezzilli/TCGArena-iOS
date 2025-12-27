//
//  TradeService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import Foundation
import Combine

class TradeService: ObservableObject {
    static let shared = TradeService()
    private let apiClient = APIClient.shared
    
    @Published var matches: [TradeMatch] = []
    @Published var wantList: [TradeListEntry] = []
    @Published var haveList: [TradeListEntry] = []
    @Published var isLoading = false
    
    func fetchMatches(radius: Double = 50) {
        isLoading = true
        Task {
            do {
                let fetchedMatches: [TradeMatch] = try await apiClient.request("/api/trade/matches?radius=\(radius)")
                DispatchQueue.main.async {
                    self.matches = fetchedMatches
                    self.isLoading = false
                }
            } catch {
                print("Error fetching matches: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    
    func fetchList(type: TradeListType) {
        Task {
            do {
                let list: [TradeListEntry] = try await apiClient.request("/api/trade/list?type=\(type.rawValue)")
                DispatchQueue.main.async {
                    if type == .want {
                        self.wantList = list
                    } else {
                        self.haveList = list
                    }
                }
            } catch {
                print("Error fetching list \(type): \(error)")
            }
        }
    }
    
    // Fetch trade list for a specific user (for viewing other users' profiles)
    func fetchUserList(userId: Int64, type: TradeListType) async throws -> [TradeListEntry] {
        return try await apiClient.request("/api/trade/list/\(userId)?type=\(type.rawValue)")
    }
    
    func addCardToList(cardId: Int, type: TradeListType, completion: @escaping (Bool) -> Void) {
        let payload = TradeListRequest(cardTemplateId: cardId, type: type.rawValue)
        Task {
            do {
                let _: EmptyResponse = try await apiClient.request("/api/trade/list/add", method: "POST", body: payload)
                DispatchQueue.main.async {
                    self.fetchList(type: type) // Refresh list
                    completion(true)
                }
            } catch {
                print("Error adding card to list: \(error)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    func removeCardFromList(cardId: Int, type: TradeListType) {
        let payload = TradeListRequest(cardTemplateId: cardId, type: type.rawValue)
        Task {
            do {
                let _: EmptyResponse = try await apiClient.request("/api/trade/list/remove", method: "POST", body: payload)
                DispatchQueue.main.async {
                    self.fetchList(type: type) // Refresh list
                }
            } catch {
                print("Error removing card from list: \(error)")
            }
        }
    }
    
    func fetchMessages(matchId: Int) async throws -> TradeChatResponse {
        return try await apiClient.request("/api/trade/chat/\(matchId)")
    }
    
    func sendMessage(matchId: Int, content: String) async throws {
        let payload = TradeMessageRequest(content: content)
        let _: EmptyResponse = try await apiClient.request("/api/trade/chat/\(matchId)", method: "POST", body: payload)
    }
    
    func completeTrade(matchId: Int) async throws {
        let _: EmptyResponse = try await apiClient.request("/api/trade/complete/\(matchId)", method: "POST")
    }
    
    func cancelTrade(matchId: Int) async throws {
        let _: EmptyResponse = try await apiClient.request("/api/trade/cancel/\(matchId)", method: "POST")
    }
    
    func startChat(matchId: Int) async throws {
        let _: EmptyResponse = try await apiClient.request("/api/trade/chat/\(matchId)/start", method: "POST")
    }
}
