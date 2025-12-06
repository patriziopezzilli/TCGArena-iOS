//
//  APIClient.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

class APIClient: NSObject {
    static let shared = APIClient()
    private let baseURL = "http://80.211.236.249:8080"
    
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
    private var _refreshToken: String?
    private var refreshTask: Task<Bool, Error>? // Task per deduplicare le richieste di refresh

    // JSON Decoder configurato per gestire le date dal backend
    private lazy var jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Prova diversi formati di data
            let formatters = [
                ISO8601DateFormatter(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd MMM yyyy"
                    formatter.locale = Locale(identifier: "it_IT")
                    return formatter
                }(),
                {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    return formatter
                }()
            ]

            for formatter in formatters {
                if let isoFormatter = formatter as? ISO8601DateFormatter,
                   let date = isoFormatter.date(from: dateString) {
                    return date
                }
                if let dateFormatter = formatter as? DateFormatter,
                   let date = dateFormatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        return decoder
    }()

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
    
    var refreshToken: String? {
        get {
            if _refreshToken == nil {
                _refreshToken = UserDefaults.standard.string(forKey: "refreshToken")
            }
            return _refreshToken
        }
        set {
            _refreshToken = newValue
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: "refreshToken")
            } else {
                UserDefaults.standard.removeObject(forKey: "refreshToken")
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
        let (data, response) = try await rawRequestWithResponse(endpoint, method: method, body: bodyData, headers: headers)

        // Handle empty responses (204 No Content) for EmptyResponse type
        if T.self == EmptyResponse.self && data.isEmpty {
            return EmptyResponse() as! T
        }

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
                let (data, _) = try await rawRequestWithResponse(endpoint, method: method.rawValue, body: body, headers: headers)
                // Ensure completion is called on main thread
                DispatchQueue.main.async {
                    completion(.success(data))
                }
            } catch {
                // Ensure completion is called on main thread
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func rawRequestWithResponse(
        _ endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        headers: [String: String] = [:],
        retryCount: Int = 0
    ) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: baseURL + endpoint) else {
            print("🔴 APIClient: Invalid URL - \(baseURL + endpoint)")
            throw APIError.invalidURL
        }
        
        print("🌐 APIClient: Making \(method) request to: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Aggiungi JWT token se disponibile e l'endpoint non è pubblico
        let publicEndpoints = ["/api/auth/register", "/api/auth/login", "/api/auth/refresh-token"]
        if let token = jwtToken, !publicEndpoints.contains(where: { endpoint.hasPrefix($0) }) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let tokenPrefix = token.prefix(20)
            print("🔑 APIClient: Using JWT token (prefix: \(tokenPrefix)...)")
        } else {
            print("⚠️ APIClient: No JWT token available or endpoint is public")
            // Debug: Check if token exists in UserDefaults
            if let savedToken = UserDefaults.standard.string(forKey: "jwtToken"), !publicEndpoints.contains(where: { endpoint.hasPrefix($0) }) {
                print("⚠️ APIClient: Token found in UserDefaults but _jwtToken is nil!")
                print("⚠️ APIClient: Forcing reload from UserDefaults")
                _jwtToken = savedToken
                request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")
                let tokenPrefix = savedToken.prefix(20)
                print("🔑 APIClient: Recovered JWT token (prefix: \(tokenPrefix)...)")
            } else {
                print("⚠️ APIClient: No token in UserDefaults either or endpoint is public")
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
                print("Request body: \(bodyString)")
            }
        }

        print("Making request to: \(url.absoluteString)")
        print("Method: \(method)")

        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Log per debug
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response (\(httpResponse.statusCode)): \(responseString)")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                // Prova a refreshare il token se non è già un tentativo di retry
                if retryCount == 0 {
                    print("🔄 APIClient: Token expired, attempting refresh...")
                    do {
                        if try await refreshToken() {
                            print("✅ APIClient: Token refreshed, retrying request...")
                            return try await rawRequestWithResponse(endpoint, method: method, body: body, headers: headers, retryCount: 1)
                        }
                    } catch {
                        print("🔴 APIClient: Token refresh failed with error: \(error.localizedDescription)")
                    }
                }
                // Token scaduto e refresh fallito, logout
                jwtToken = nil
                throw APIError.sessionExpired
            }
            throw APIError.serverError(httpResponse.statusCode)
        }

        return (data, httpResponse)
    }

    func setJWTToken(_ token: String) {
        jwtToken = token
    }
    
    func setRefreshToken(_ token: String) {
        refreshToken = token
    }
    
    func clearJWTToken() {
        jwtToken = nil
    }
    
    func clearRefreshToken() {
        refreshToken = nil
    }

    private func refreshToken() async throws -> Bool {
        // Se c'è già un refresh in corso, attendi il suo risultato
        if let existingTask = refreshTask {
            print("🔄 APIClient: Waiting for existing refresh task...")
            return try await existingTask.value
        }
        
        // Avvia un nuovo task di refresh
        let task = Task<Bool, Error> {
            guard let currentRefreshToken = refreshToken else {
                print("🔴 APIClient: No refresh token available")
                return false
            }

            guard let url = URL(string: baseURL + "/api/auth/refresh-token") else {
                print("🔴 APIClient: Invalid refresh URL")
                return false
            }

            print("🔄 APIClient: Attempting to refresh token")

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let refreshBody = ["refreshToken": currentRefreshToken]
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

                let decoder = JSONDecoder()
                let refreshResponse = try decoder.decode([String: String].self, from: data)

                if let newToken = refreshResponse["accessToken"], let newRefreshToken = refreshResponse["refreshToken"] {
                    jwtToken = newToken
                    refreshToken = newRefreshToken
                    print("✅ APIClient: Tokens refreshed successfully")
                    return true
                } else {
                    print("🔴 APIClient: Refresh response missing accessToken or refreshToken")
                    return false
                }
            } catch {
                print("🔴 APIClient: Refresh request failed - \(error.localizedDescription)")
                return false
            }
        }
        
        self.refreshTask = task
        
        // Attendi il risultato e poi pulisci il task
        do {
            let result = try await task.value
            self.refreshTask = nil
            return result
        } catch {
            self.refreshTask = nil
            throw error
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case sessionExpired // Nuovo errore per sessione scaduta
    case serverError(Int)
    case decodingError
}
