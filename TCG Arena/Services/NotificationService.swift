//
//  NotificationService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private let apiClient = APIClient.shared

    init() {}

    // MARK: - Notification Operations

    func getUserNotifications(completion: @escaping (Result<[Notification], Error>) -> Void) {
        apiClient.request(endpoint: "/api/notifications", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let notifications = try JSONDecoder().decode([Notification].self, from: data)
                    completion(.success(notifications))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getUnreadNotifications(completion: @escaping (Result<[Notification], Error>) -> Void) {
        apiClient.request(endpoint: "/api/notifications/unread", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let notifications = try JSONDecoder().decode([Notification].self, from: data)
                    completion(.success(notifications))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func markAsRead(notificationId: Int, completion: @escaping (Result<[String: String], Error>) -> Void) {
        apiClient.request(endpoint: "/api/notifications/\(notificationId)/read", method: .put) { result in
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

    // MARK: - Device Token Operations

    func registerDeviceToken(token: String, platform: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        let request = DeviceTokenRequest(token: token, platform: platform)
        do {
            let data = try JSONEncoder().encode(request)
            apiClient.request(endpoint: "/api/notifications/device-token", method: .post, body: data) { result in
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
        } catch {
            completion(.failure(error))
        }
    }

    func unregisterDeviceToken(token: String, completion: @escaping (Result<[String: String], Error>) -> Void) {
        apiClient.request(endpoint: "/api/notifications/device-token?token=\(token)", method: .delete) { result in
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

    func sendTestPushNotification(completion: @escaping (Result<[String: String], Error>) -> Void) {
        apiClient.request(endpoint: "/api/notifications/test-push", method: .post) { result in
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