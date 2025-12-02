//
//  AchievementService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

class AchievementService: ObservableObject {
    static let shared = AchievementService()
    private let apiClient = APIClient.shared

    init() {}

    // MARK: - Achievement Operations

    func getAllActiveAchievements(completion: @escaping (Result<[Achievement], Error>) -> Void) {
        apiClient.request(endpoint: "/api/achievements", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let achievements = try JSONDecoder().decode([Achievement].self, from: data)
                    completion(.success(achievements))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getAchievementById(_ id: Int, completion: @escaping (Result<Achievement, Error>) -> Void) {
        apiClient.request(endpoint: "/api/achievements/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let achievement = try JSONDecoder().decode(Achievement.self, from: data)
                    completion(.success(achievement))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getUserAchievements(completion: @escaping (Result<[UserAchievement], Error>) -> Void) {
        apiClient.request(endpoint: "/api/achievements/user", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let userAchievements = try JSONDecoder().decode([UserAchievement].self, from: data)
                    completion(.success(userAchievements))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func unlockAchievement(_ achievementId: Int, completion: @escaping (Result<[String: String], Error>) -> Void) {
        apiClient.request(endpoint: "/api/achievements/\(achievementId)/unlock", method: .post) { result in
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
}