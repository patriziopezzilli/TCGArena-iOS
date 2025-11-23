//
//  AuthModels.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/22/25.
//

import Foundation

// Modello per la richiesta di login
struct LoginRequest: Codable {
    let username: String
    let password: String
}

// Modello per la richiesta di registrazione
struct RegisterRequest: Codable {
    let email: String
    let username: String
    let displayName: String
    let password: String
    let favoriteGame: TCGType?
    
    enum CodingKeys: String, CodingKey {
        case email
        case username
        case displayName = "display_name"
        case password
        case favoriteGame = "favorite_game"
    }
}

// Modello per la risposta di autenticazione
struct AuthResponse: Codable {
    let token: String
    let user: User
}