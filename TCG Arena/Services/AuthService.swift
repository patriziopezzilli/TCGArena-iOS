//
//  AuthService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Controlla se c'è un token salvato all'avvio
        if APIClient.shared.jwtToken != nil {
            isAuthenticated = true
            // TODO: Carica profilo utente dal backend
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loginRequest = LoginRequest(username: email, password: password)
            let response: AuthResponse = try await APIClient.shared.request(
                "/auth/login",
                method: "POST",
                body: loginRequest
            )
            
            // Salva il token JWT
            APIClient.shared.setJWTToken(response.token)
            
            // Salva l'utente corrente
            currentUser = response.user
            isAuthenticated = true
            
            // Registra il device token per le notifiche push
            await registerDeviceToken()
            
        } catch APIError.unauthorized {
            errorMessage = "Credenziali non valide"
        } catch APIError.serverError(let code) {
            errorMessage = "Errore del server (\(code))"
        } catch {
            errorMessage = "Errore di connessione: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, username: String, displayName: String, favoriteGames: [TCGType]? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let registerRequest = RegisterRequest(
                email: email,
                username: username,
                displayName: displayName,
                password: password,
                favoriteGames: favoriteGames
            )
            
            let response: AuthResponse = try await APIClient.shared.request(
                "/auth/register",
                method: "POST",
                body: registerRequest
            )
            
            // Salva il token JWT
            APIClient.shared.setJWTToken(response.token)
            
            // Salva l'utente corrente
            currentUser = response.user
            isAuthenticated = true
            
        } catch APIError.serverError(400) {
            errorMessage = "Username o email già esistenti"
        } catch APIError.serverError(let code) {
            errorMessage = "Errore del server (\(code))"
        } catch {
            errorMessage = "Errore di connessione: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signOut() {
        APIClient.shared.clearJWTToken()
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }
    
    func resetPassword(email: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Il backend non ha ancora implementato reset password
            // Per ora mostriamo un messaggio
            errorMessage = "Funzionalità reset password non ancora implementata"
            
        } catch {
            errorMessage = "Errore nell'invio dell'email: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // Metodo per verificare se l'utente è ancora autenticato
    func validateToken() async -> Bool {
        guard APIClient.shared.jwtToken != nil else { return false }
        
        do {
            // TODO: Implementare endpoint per validare token
            // Per ora assumiamo che sia valido se presente
            return true
        } catch {
            signOut()
            return false
        }
    }
    
    // Registra il device token per le notifiche push
    func registerDeviceToken() async {
        guard let user = currentUser else { return }
        
        // Richiedi autorizzazione per le notifiche
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                // Ottieni il device token
                await UIApplication.shared.registerForRemoteNotifications()
                
                // Il token verrà ricevuto in AppDelegate e poi registrato qui
                // Per ora, simuliamo con un token di test
                let deviceToken = "test-device-token-\(user.id)"
                await registerDeviceTokenOnServer(deviceToken)
            }
        } catch {
            print("Failed to request notification authorization: \(error)")
        }
    }
    
    // Registra il device token sul server
    func registerDeviceTokenOnServer(_ token: String) async {
        guard let user = currentUser else { return }
        
        do {
            let payload: [String: String] = [
                "token": token,
                "platform": "ios"
            ]
            
            let _: [String: String] = try await APIClient.shared.request(
                "/notifications/device-token",
                method: "POST",
                body: payload
            )
            
            print("Device token registered successfully")
        } catch {
            print("Failed to register device token: \(error)")
        }
    }
    
    // Aggiorna il profilo utente dal server
    func refreshCurrentUser() async {
        guard isAuthenticated else { return }
        
        do {
            // TODO: Implementare endpoint per ottenere profilo utente corrente
            // Per ora manteniamo i dati esistenti
        } catch {
            print("Failed to refresh user profile: \(error)")
        }
    }
}