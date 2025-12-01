//
//  APIClient.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

class APIClient: NSObject {
    static let shared = APIClient()
    private let baseURL = "http://localhost:8080/api"
    
    // URLSession che ignora la validazione SSL per problemi con proxy aziendale
    // TODO: Rimuovere in produzione e usare certificati validi
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
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
        get { UserDefaults.standard.string(forKey: "jwtToken") }
        set { UserDefaults.standard.set(newValue, forKey: "jwtToken") }
    }
    
    private override init() {}
    
    func request<T: Decodable>(
        _ endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        headers: [String: String] = [:]
    ) async throws -> T {
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
            request.httpBody = try JSONEncoder().encode(body)
            if let bodyString = String(data: request.httpBody!, encoding: .utf8) {
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
                // Token scaduto, logout
                jwtToken = nil
                throw APIError.unauthorized
            }
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            if let decodingError = error as? DecodingError {
                print("Decoding error details: \(decodingError)")
            }
            throw APIError.decodingError
        }
    }
    
    // Versione con completion handler per compatibilità
    func request(endpoint: String, method: HTTPMethod, body: Data? = nil, headers: [String: String] = [:], completion: @escaping (Result<Data, Error>) -> Void) {
        Task {
            do {
                guard let url = URL(string: baseURL + endpoint) else {
                    throw APIError.invalidURL
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = method.rawValue
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
                    if let bodyString = String(data: body, encoding: .utf8) {
                        print("Request body: \(bodyString)")
                    }
                }
                
                print("Making request to: \(url.absoluteString)")
                print("Method: \(method.rawValue)")
                
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
                        // Token scaduto, logout
                        jwtToken = nil
                        throw APIError.unauthorized
                    }
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                completion(.success(data))
            } catch {
                completion(.failure(error))
            }
        }
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
    case patch = "PATCH"
    case delete = "DELETE"
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverError(Int)
    case decodingError
}

// MARK: - URLSessionDelegate per gestire SSL
extension APIClient: URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Accetta tutti i certificati SSL (temporaneo per proxy aziendale)
        // TODO: Rimuovere in produzione per sicurezza
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}