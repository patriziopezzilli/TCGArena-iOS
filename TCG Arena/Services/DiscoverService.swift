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
    // MARK: - User Interface Methods
    
    func loadData() {
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
        }
    }
    
    private func processUsers(_ users: [User], leaderboardUsers: [User]) {
        // Sort users by join date for new users (most recent first)
        // Sort by dateJoined string (already formatted by backend)
        let sortedByJoinDate = users.sorted { $0.dateJoined > $1.dateJoined }
        self.newUsers = Array(sortedByJoinDate.prefix(5))
        
        // Use leaderboard users as featured users
        self.featuredUsers = Array(leaderboardUsers.prefix(3))
        
        // For active users, sort by some criteria (mock for now since backend doesn't have lastActive)
        // In a real implementation, backend would need to provide last active date
        self.activeUsers = Array(users.shuffled().prefix(10))
    }
    
    func refreshData() {
        loadData()
    }
    
    private func loadLeaderboards() {
        // For now, create mock leaderboards based on real users
        // In future, backend can provide different leaderboard types
        // Mock leaderboard entries using featured users
        let mockUsers = featuredUsers.isEmpty ? activeUsers : featuredUsers
        
        let tournamentEntries = mockUsers.enumerated().map { index, user in
            LeaderboardEntry(id: "tournament-\(index)", userProfile: user.toUserProfile(), rank: index + 1, score: 100 - index, change: nil)
        }
        let collectionEntries = mockUsers.enumerated().map { index, user in
            LeaderboardEntry(id: "collection-\(index)", userProfile: user.toUserProfile(), rank: index + 1, score: 100 - index, change: nil)
        }
        let achievementEntries = mockUsers.enumerated().map { index, user in
            LeaderboardEntry(id: "achievement-\(index)", userProfile: user.toUserProfile(), rank: index + 1, score: 100 - index, change: nil)
        }
        
        leaderboards[.tournaments] = tournamentEntries
        leaderboards[.collection] = collectionEntries
        leaderboards[.community] = achievementEntries
        leaderboards[.level] = tournamentEntries // Mock level leaderboard
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
