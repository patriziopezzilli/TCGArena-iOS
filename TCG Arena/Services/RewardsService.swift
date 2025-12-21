//
//  RewardsService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

@MainActor
class RewardsService: ObservableObject {
    static let shared = RewardsService()
    private let apiClient = APIClient.shared

    init() {}

    // MARK: - Reward Operations

    func getAllActiveRewards(completion: @escaping (Result<[Reward], Error>) -> Void) {
        // Check if user is authenticated before making API call
        guard AuthService.shared.isAuthenticated else {
            print("⚠️ RewardsService: User not authenticated, cannot fetch rewards")
            completion(.failure(APIError.unauthorized))
            return
        }
        
        print("🎁 RewardsService: Fetching active rewards for authenticated user")
        apiClient.request(endpoint: "/api/rewards", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let rewards = try JSONDecoder().decode([Reward].self, from: data)
                    completion(.success(rewards))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }    
    func getWalletPass(completion: @escaping (Result<Data, Error>) -> Void) {
        guard AuthService.shared.isAuthenticated else {
            completion(.failure(APIError.unauthorized))
            return
        }
        
        // Endpoint placeholder - Backend needs to implement this
        apiClient.request(endpoint: "/api/wallet/pass", method: .get) { result in
            completion(result)
        }
    }
    func getAllPartners(completion: @escaping (Result<[Partner], Error>) -> Void) {
        guard AuthService.shared.isAuthenticated else {
            completion(.failure(APIError.unauthorized))
            return
        }
        
        apiClient.request(endpoint: "/api/partners", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let partners = try JSONDecoder().decode([Partner].self, from: data)
                    completion(.success(partners))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getRewardsByPartner(partnerId: Int, completion: @escaping (Result<[Reward], Error>) -> Void) {
        guard AuthService.shared.isAuthenticated else {
            completion(.failure(APIError.unauthorized))
            return
        }
        
        apiClient.request(endpoint: "/api/rewards/partner/\(partnerId)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let rewards = try JSONDecoder().decode([Reward].self, from: data)
                    completion(.success(rewards))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getRewardById(_ id: Int, completion: @escaping (Result<Reward, Error>) -> Void) {
        // Check if user is authenticated before making API call
        guard AuthService.shared.isAuthenticated else {
            print("⚠️ RewardsService: User not authenticated, cannot fetch reward")
            completion(.failure(APIError.unauthorized))
            return
        }
        
        apiClient.request(endpoint: "/api/rewards/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let reward = try JSONDecoder().decode(Reward.self, from: data)
                    completion(.success(reward))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func redeemReward(_ rewardId: Int, completion: @escaping (Result<[String: String], Error>) -> Void) {
        // Check if user is authenticated before making API call
        guard AuthService.shared.isAuthenticated else {
            print("⚠️ RewardsService: User not authenticated, cannot redeem reward")
            completion(.failure(APIError.unauthorized))
            return
        }
        
        apiClient.request(endpoint: "/api/rewards/\(rewardId)/redeem", method: .post) { result in
            switch result {
            case .success(let data):
                do {
                    let response = try JSONDecoder().decode([String: String].self, from: data)
                    completion(.success(response))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Points Operations

    func getUserPoints(completion: @escaping (Result<UserPoints, Error>) -> Void) {
        // Check if user is authenticated before making API call
        guard AuthService.shared.isAuthenticated else {
            print("⚠️ RewardsService: User not authenticated, cannot fetch user points")
            completion(.failure(APIError.unauthorized))
            return
        }
        
        apiClient.request(endpoint: "/api/rewards/points", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let points = try JSONDecoder().decode(UserPoints.self, from: data)
                    completion(.success(points))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Transaction History

    func getTransactionHistory(completion: @escaping (Result<[RewardTransaction], Error>) -> Void) {
        // Check if user is authenticated before making API call
        guard AuthService.shared.isAuthenticated else {
            print("⚠️ RewardsService: User not authenticated, cannot fetch transaction history")
            completion(.failure(APIError.unauthorized))
            return
        }
        
        apiClient.request(endpoint: "/api/rewards/history", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let transactions = try JSONDecoder().decode([RewardTransaction].self, from: data)
                    completion(.success(transactions))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}