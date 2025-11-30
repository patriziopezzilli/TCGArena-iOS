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
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                
                // Java LocalDateTime format: "2025-11-26T21:55:29.218488"
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
            }
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
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
        headers: [String: String] = [:]
    ) async throws -> Data {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Aggiungi JWT token se disponibile
        if let token = jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Aggiungi headers personalizzati
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Aggiungi body se presente
        if let body = body {
            request.httpBody = body
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                // Token scaduto, logout
                // jwtToken = nil  // Commented out to prevent clearing valid token
                throw APIError.unauthorized
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return data
    }
    
    func setJWTToken(_ token: String) {
        jwtToken = token
    }
    
    func clearJWTToken() {
        jwtToken = nil
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
