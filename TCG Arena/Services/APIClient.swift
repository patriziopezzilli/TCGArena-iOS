//
//  APIClient.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

class APIClient: NSObject {
    static let shared = APIClient()
    private let baseURL = "http://localhost:8080"
    
    // URLSession con configurazione basata sulla modalità (debug/disabilita cache)
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        
        #if DEBUG
        // In modalità debug, disabilita completamente la cache per vedere sempre i dati più recenti
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        print("🔧 APIClient: Cache disabilitata per modalità debug")
        #endif
        
        return URLSession(configuration: configuration)
    }()
    
    private var _jwtToken: String?
    
    var jwtToken: String? {
        get {
            if _jwtToken == nil {
                _jwtToken = UserDefaults.standard.string(forKey: "jwtToken")
            }
            return _jwtToken
        }
        set {
            _jwtToken = newValue
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: "jwtToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "jwtToken")
            }
            UserDefaults.standard.synchronize() // Force save
        }
    }
    
    private override init() {
        super.init()
    }
    
    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
        let bodyData = body != nil ? try JSONEncoder().encode(body!) : nil
        let data = try await rawRequest(endpoint, method: method, body: bodyData, headers: headers)
        
        do {
            let decoder = JSONDecoder()
            // Dates are now formatted as strings by the backend, so no custom decoding needed
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch let decodingError as DecodingError {
            print("🔴 APIClient: JSON Decoding error - \(decodingError.localizedDescription)")
            print("🔴 APIClient: Error details: \(decodingError)")
            throw decodingError
        } catch {
            print("🔴 APIClient: Unexpected decoding error - \(error.localizedDescription)")
            throw error
        }
    }
    
    // Versione con completion handler per compatibilità
    func request(endpoint: String, method: HTTPMethod, body: Data? = nil, headers: [String: String] = [:], completion: @escaping (Result<Data, Error>) -> Void) {
        Task {
            do {
                let data = try await rawRequest(endpoint, method: method.rawValue, body: body, headers: headers)
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func rawRequest(
        _ endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:],
        retryCount: Int = 0
    ) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            print("🔴 APIClient: Invalid URL - \(baseURL + endpoint)")
            throw APIError.invalidURL
        }
        
        print("🌐 APIClient: Making \(method) request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Aggiungi JWT token se disponibile
        if let token = jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let tokenPrefix = token.prefix(20)
            print("🔑 APIClient: Using JWT token (prefix: \(tokenPrefix)...)")
        } else {
            print("⚠️ APIClient: No JWT token available")
            // Debug: Check if token exists in UserDefaults
            if let savedToken = UserDefaults.standard.string(forKey: "jwtToken") {
                print("⚠️ APIClient: Token found in UserDefaults but _jwtToken is nil!")
                print("⚠️ APIClient: Forcing reload from UserDefaults")
                _jwtToken = savedToken
                request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")
                let tokenPrefix = savedToken.prefix(20)
                print("🔑 APIClient: Recovered JWT token (prefix: \(tokenPrefix)...)")
            } else {
                print("⚠️ APIClient: No token in UserDefaults either")
            }
        }
        
        // Aggiungi headers personalizzati
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Aggiungi body se presente
        if let body = body {
            request.httpBody = body
            if let bodyString = String(data: body, encoding: .utf8) {
                print("📦 APIClient: Request body: \(bodyString)")
            }
        }
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔴 APIClient: Invalid response type")
                throw APIError.invalidResponse
            }
            
            print("📡 APIClient: Response status code: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("🔴 APIClient: Server error with status code: \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    if retryCount < 1 {
                        print("🔄 APIClient: Token expired, attempting refresh and retry")
                        let refreshed = try await refreshToken()
                        if refreshed {
                            // Retry the request with the new token
                            return try await rawRequest(endpoint, method: method, body: body, headers: headers, retryCount: retryCount + 1)
                        } else {
                            print("🔄 APIClient: Refresh failed, but keeping token for manual re-auth")
                            // Don't clear token immediately - let user re-authenticate manually
                            // jwtToken = nil  // Commented out to prevent logout
                            throw APIError.unauthorized
                        }
                    } else {
                        print("🔴 APIClient: Token expired and refresh failed - clearing JWT token")
                        jwtToken = nil
                        throw APIError.unauthorized
                    }
                }
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 APIClient: Response data: \(responseString)")
            }
            
            return data
        } catch {
            print("🔴 APIClient: Network error - \(error.localizedDescription)")
            // Se è un errore di rete, rilancia come serverError con codice speciale
            throw APIError.serverError(3)
        }
    }
    
    func setJWTToken(_ token: String) {
        jwtToken = token
    }
    
    func clearJWTToken() {
        jwtToken = nil
    }
    
    private func refreshToken() async throws -> Bool {
        guard let currentToken = jwtToken else { return false }
        
        guard let url = URL(string: baseURL + "/api/auth/refresh-token") else {
            print("🔴 APIClient: Invalid refresh URL")
            return false
        }
        
        print("🔄 APIClient: Attempting to refresh token")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // NON includere nell'header Authorization per endpoint pubblici
        // Includi solo nel body
        let refreshBody = ["token": currentToken]
        request.httpBody = try? JSONEncoder().encode(refreshBody)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("🔴 APIClient: Invalid refresh response type")
                return false
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("🔴 APIClient: Refresh failed with status code: \(httpResponse.statusCode)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("🔴 APIClient: Refresh error response: \(responseString)")
                }
                return false
            }
            
            // Parse the response to get new token
            let decoder = JSONDecoder()
            let refreshResponse = try decoder.decode([String: String].self, from: data)
            
            if let newToken = refreshResponse["token"] {
                jwtToken = newToken
                print("✅ APIClient: Token refreshed successfully")
                return true
            } else {
                print("🔴 APIClient: Refresh response missing token")
                return false
            }
        } catch {
            print("🔴 APIClient: Refresh request failed - \(error.localizedDescription)")
            return false
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError
}
