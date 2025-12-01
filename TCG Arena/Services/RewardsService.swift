//
//  RewardsService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

class RewardsService: ObservableObject {
    static let shared = RewardsService()
    private let apiClient = APIClient.shared

    init() {}

    // MARK: - Reward Operations

    func getAllActiveRewards(completion: @escaping (Result<[Reward], Error>) -> Void) {
        apiClient.request(endpoint: "/rewards", method: .get) { result in
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
        apiClient.request(endpoint: "/rewards/\(id)", method: .get) { result in
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
        apiClient.request(endpoint: "/rewards/\(rewardId)/redeem", method: .post) { result in
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
        apiClient.request(endpoint: "/rewards/points", method: .get) { result in
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
        apiClient.request(endpoint: "/rewards/history", method: .get) { result in
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