//
//  UserService.swift
//  TCG Arena
//
//  Created by Assistant on 22/11/2024.
//

import Foundation

class UserService {
    static let shared = UserService()
    private let apiClient = APIClient.shared

    private init() {}

    func getUserActivities(userId: Int64) async throws -> [UserActivity] {
        let endpoint = "/api/user-activities/\(userId)"
        let activities: [UserActivity] = try await apiClient.request(endpoint, method: "GET")
        return activities
    }

    func getUserStats(userId: Int64) async throws -> UserStats {
        let endpoint = "/api/users/\(userId)/stats"
        let stats: UserStats = try await apiClient.request(endpoint, method: "GET")
        return stats
    }

    func getLeaderboard(limit: Int = 50) async throws -> [UserStats] {
        let endpoint = "/api/users/leaderboard?limit=\(limit)"
        let leaderboard: [UserStats] = try await apiClient.request(endpoint, method: "GET")
        return leaderboard
    }

    func getActivePlayersLeaderboard(limit: Int = 50) async throws -> [UserStats] {
        let endpoint = "/api/users/leaderboard/active?limit=\(limit)"
        let leaderboard: [UserStats] = try await apiClient.request(endpoint, method: "GET")
        return leaderboard
    }
    
    /// Update user profile with displayName, bio, and favoriteGame
    func updateUserProfile(userId: Int64, displayName: String, bio: String?, favoriteGame: TCGType) async throws {
        let endpoint = "/api/users/\(userId)/profile"
        
        struct UpdateProfileRequest: Codable {
            let displayName: String
            let bio: String?
            let favoriteGame: String
        }
        
        let requestBody = UpdateProfileRequest(
            displayName: displayName,
            bio: bio,
            favoriteGame: favoriteGame.rawValue
        )
        
        let _: User = try await apiClient.request(endpoint, method: "PATCH", body: requestBody)
    }
}