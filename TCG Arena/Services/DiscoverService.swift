//
//  DiscoverService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import Foundation
import SwiftUI

class DiscoverService: ObservableObject {
    @Published var leaderboards: [LeaderboardType: [LeaderboardEntry]] = [:]
    @Published var featuredUsers: [User] = []
    @Published var newUsers: [User] = []
    @Published var activeUsers: [User] = []
    @Published var recentActivities: [UserActivity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
        loadData()
    }
    
    // MARK: - API Methods
    
    func getAllUsers(completion: @escaping (Result<[User], Error>) -> Void) {
        apiClient.request(endpoint: "/api/users", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let users = try JSONDecoder().decode([User].self, from: data)
                    completion(.success(users))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getUserLeaderboard(completion: @escaping (Result<[User], Error>) -> Void) {
        apiClient.request(endpoint: "/api/users/leaderboard", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let users = try JSONDecoder().decode([User].self, from: data)
                    completion(.success(users))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getRecentActivities(completion: @escaping (Result<[UserActivity], Error>) -> Void) {
        apiClient.request(endpoint: "/api/user-activities/recent/global", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let activities = try JSONDecoder().decode([UserActivity].self, from: data)
                    completion(.success(activities))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getUserActivities(userId: Int64, limit: Int = 20, completion: @escaping (Result<[UserActivity], Error>) -> Void) {
        apiClient.request(endpoint: "/api/user-activities/\(userId)?limit=\(limit)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let activities = try JSONDecoder().decode([UserActivity].self, from: data)
                    completion(.success(activities))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    // MARK: - User Interface Methods
    
    func loadData(completion: (() -> Void)? = nil) {
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        var users: [User] = []
        var leaderboardUsers: [User] = []
        
        // Load all users
        group.enter()
        getAllUsers { result in
            switch result {
            case .success(let fetchedUsers):
                users = fetchedUsers
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
            group.leave()
        }
        
        // Load leaderboard
        group.enter()
        getUserLeaderboard { result in
            switch result {
            case .success(let fetchedUsers):
                leaderboardUsers = fetchedUsers
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            // Process users for different categories
            self.processUsers(users, leaderboardUsers: leaderboardUsers)
            self.loadLeaderboards() // Load real leaderboards
            self.loadRecentActivities() // Load real activities
            self.isLoading = false
            completion?()
        }
    }
    
    private func processUsers(_ users: [User], leaderboardUsers: [User]) {
        // Filter out merchant and private users from community sections
        let publicUsers = users.filter { !$0.isMerchant && !$0.isPrivate }
        let publicLeaderboardUsers = leaderboardUsers.filter { !$0.isMerchant && !$0.isPrivate }
        
        // Sort users by join date for new users (most recent first)
        // Sort by dateJoined string (already formatted by backend)
        let sortedByJoinDate = publicUsers.sorted { $0.dateJoined > $1.dateJoined }
        self.newUsers = Array(sortedByJoinDate.prefix(5))
        
        // Use leaderboard users as featured users
        self.featuredUsers = Array(publicLeaderboardUsers.prefix(3))
        
        // For active users, sort by some criteria (mock for now since backend doesn't have lastActive)
        // In a real implementation, backend would need to provide last active date
        self.activeUsers = Array(publicUsers.shuffled().prefix(10))
    }
    
    func refreshData(completion: (() -> Void)? = nil) {
        loadData(completion: completion)
    }
    
    func getLeaderboard(type: LeaderboardType, completion: @escaping (Result<[UserStats], Error>) -> Void) {
        let endpoint: String
        switch type {
        case .tournaments:
            endpoint = "/api/users/leaderboard/tournaments"
        case .collection:
            endpoint = "/api/users/leaderboard/collection"
        }
        
        apiClient.request(endpoint: endpoint, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let stats = try JSONDecoder().decode([UserStats].self, from: data)
                    completion(.success(stats))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func loadLeaderboards() {
        let group = DispatchGroup()
        
        for type in LeaderboardType.allCases {
            group.enter()
            getLeaderboard(type: type) { result in
                switch result {
                case .success(let stats):
                    // Convert UserStats to LeaderboardEntry
                    let entries = stats.enumerated().map { index, stat in
                        LeaderboardEntry(
                            id: "\(type.rawValue)-\(stat.id)",
                            userProfile: stat.user.toUserProfile(),
                            rank: index + 1,
                            score: self.getScore(for: type, stat: stat),
                            change: nil
                        )
                    }
                    DispatchQueue.main.async {
                        self.leaderboards[type] = entries
                    }
                case .failure(let error):
                    print("Error loading \(type) leaderboard: \(error)")
                }
                group.leave()
            }
        }
    }
    
    private func getScore(for type: LeaderboardType, stat: UserStats) -> Int {
        switch type {
        case .tournaments: return stat.totalWins * 10
        case .collection: return stat.totalCards
        }
    }
    
    private func loadRecentActivities() {
        getRecentActivities { result in
            switch result {
            case .success(let activities):
                self.recentActivities = activities
            case .failure(let error):
                // Handle error silently
                break
            }
        }
    }
}
