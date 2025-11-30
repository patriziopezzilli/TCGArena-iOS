//
//  ImageService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

class ImageService: ObservableObject {
    static let shared = ImageService()
    private let apiClient = APIClient.shared

    init() {}

    // MARK: - Image Operations

    func uploadImage(file: Data, filename: String, entityType: String?, entityId: Int?, completion: @escaping (Result<Image, Error>) -> Void) {
        // Create multipart form data
        let boundary = UUID().uuidString
        var body = Data()

        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(file)
        body.append("\r\n".data(using: .utf8)!)

        // Add entityType if provided
        if let entityType = entityType {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"entityType\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(entityType)\r\n".data(using: .utf8)!)
        }

        // Add entityId if provided
        if let entityId = entityId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"entityId\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(entityId)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        apiClient.request(endpoint: "/api/images/upload", method: .post, body: body, headers: ["Content-Type": "multipart/form-data; boundary=\(boundary)"]) { result in
            switch result {
            case .success(let data):
                do {
                    let image = try JSONDecoder().decode(Image.self, from: data)
                    completion(.success(image))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getImagesByEntity(entityType: String, entityId: Int, completion: @escaping (Result<[Image], Error>) -> Void) {
        apiClient.request(endpoint: "/api/images/entity/\(entityType)/\(entityId)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let images = try JSONDecoder().decode([Image].self, from: data)
                    completion(.success(images))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getUserImages(completion: @escaping (Result<[Image], Error>) -> Void) {
        apiClient.request(endpoint: "/api/images/user", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let images = try JSONDecoder().decode([Image].self, from: data)
                    completion(.success(images))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func deleteImage(imageId: Int, completion: @escaping (Result<[String: String], Error>) -> Void) {
        apiClient.request(endpoint: "/api/images/\(imageId)", method: .delete) { result in
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

    func uploadProfileImage(imageData: Data, filename: String, completion: @escaping (Result<Image, Error>) -> Void) {
        // For profile images, use entityType "user" and current user ID
        Task {
            let userId = await MainActor.run { AuthService.shared.currentUserId }
            guard let userId = userId else {
                completion(.failure(NSError(domain: "ImageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
                return
            }
            
            uploadImage(file: imageData, filename: filename, entityType: "user", entityId: Int(userId), completion: completion)
        }
    }
}
