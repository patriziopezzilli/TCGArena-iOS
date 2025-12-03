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
    @Published var currentUser: User? {
        didSet {
            if let user = currentUser {
                do {
                    let data = try JSONEncoder().encode(user)
                    UserDefaults.standard.set(data, forKey: "currentUser")
                } catch {
                    // Handle error silently
                }
                // Salva anche l'ID separatamente per accessi rapidi
                UserDefaults.standard.set(user.id, forKey: "currentUserId")
                currentUserId = user.id
            } else {
                UserDefaults.standard.removeObject(forKey: "currentUser")
                UserDefaults.standard.removeObject(forKey: "currentUserId")
                currentUserId = nil
            }
        }
    }
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var sessionExpired = false // Nuovo flag per sessione scaduta
    
    // Cache dell'ID utente per accessi rapidi
    private(set) var currentUserId: Int64?
    
    init() {
        // Prima carica i dati utente salvati
        if let userData = UserDefaults.standard.data(forKey: "currentUser") {
            do {
                let user = try JSONDecoder().decode(User.self, from: userData)
                self.currentUser = user
            } catch {
                // Handle error silently
            }
        }
        
        // Poi carica l'ID utente
        if let userId = UserDefaults.standard.object(forKey: "currentUserId") as? Int64 {
            self.currentUserId = userId
        } else {
            // Prova a estrarre l'ID dal token JWT solo se abbiamo dati utente
            if currentUser != nil, let userIdFromToken = getUserIdFromToken() {
                self.currentUserId = userIdFromToken
            }
        }
        
        // Infine controlla l'autenticazione
        if APIClient.shared.jwtToken != nil && currentUser != nil && currentUserId != nil {
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }
    
    private func getUserIdFromToken() -> Int64? {
        guard let token = APIClient.shared.jwtToken else { return nil }
        
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        
        let payload = String(parts[1])
        // Aggiungi padding se necessario
        let paddedPayload = payload.padding(toLength: ((payload.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
        
        guard let data = Data(base64Encoded: paddedPayload) else { 
            return nil 
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else { 
            return nil 
        }
        
        // Prova diversi possibili nomi per l'ID utente
        if let userId = json["userId"] as? Int64 ?? json["id"] as? Int64 ?? json["user_id"] as? Int64 {
            return userId
        }
        // Se è una stringa, converti
        if let userIdStr = json["userId"] as? String ?? json["id"] as? String ?? json["user_id"] as? String ?? json["sub"] as? String {
            return Int64(userIdStr)
        }
        return nil
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loginRequest = LoginRequest(username: email, password: password)
            
            let response: AuthResponse = try await APIClient.shared.request(
                "/api/auth/login",
                method: "POST",
                body: loginRequest
            )
            
            // Salva il token JWT
            APIClient.shared.setJWTToken(response.token)
            
            // Salva il refresh token se presente
            if let refreshToken = response.refreshToken {
                APIClient.shared.setRefreshToken(refreshToken)
            }
            
            // Salva l'utente corrente
            currentUser = response.user
            isAuthenticated = true
            
            // Reset session expired flag
            sessionExpired = false
            
            // Registra il device token per le notifiche push
            await registerDeviceToken()
            
        } catch APIError.unauthorized {
            errorMessage = "Credenziali non valide"
        } catch APIError.sessionExpired {
            // Sessione scaduta, logout automatico
            signOut()
            sessionExpired = true
            errorMessage = "Sessione scaduta. Effettua nuovamente il login."
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
                "/api/auth/register",
                method: "POST",
                body: registerRequest
            )
            
            // Salva il token JWT
            APIClient.shared.setJWTToken(response.token)
            
            // Salva il refresh token se presente
            if let refreshToken = response.refreshToken {
                APIClient.shared.setRefreshToken(refreshToken)
            }
            
            // Salva l'utente corrente
            currentUser = response.user
            isAuthenticated = true
            
            // Reset session expired flag
            sessionExpired = false
            
        } catch APIError.serverError(400) {
            errorMessage = "Username o email già esistenti"
        } catch APIError.sessionExpired {
            // Questo non dovrebbe succedere durante il signup, ma per completezza
            signOut()
            sessionExpired = true
            errorMessage = "Sessione scaduta. Effettua nuovamente il login."
        } catch APIError.serverError(let code) {
            errorMessage = "Errore del server (\(code))"
        } catch {
            errorMessage = "Errore di connessione: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func signOut() {
        APIClient.shared.clearJWTToken()
        APIClient.shared.clearRefreshToken()
        currentUser = nil
        // currentUserId viene automaticamente resettato dal didSet
        isAuthenticated = false
        sessionExpired = false
        errorMessage = nil
    }
    
    // Forza logout completo e pulizia di tutti i dati
    func forceLogout() {
        // Pulisce tutto da UserDefaults
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "currentUserId")
        UserDefaults.standard.removeObject(forKey: "jwtToken")
        UserDefaults.standard.removeObject(forKey: "refreshToken")
        
        // Pulisce APIClient
        APIClient.shared.clearJWTToken()
        APIClient.shared.clearRefreshToken()
        
        // Reset stato
        currentUser = nil
        currentUserId = nil
        isAuthenticated = false
        sessionExpired = false
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
            // Handle error silently
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
                "/api/notifications/device-token",
                method: "POST",
                body: payload
            )
            
        } catch {
            // Handle error silently
        }
    }
    
    // Aggiorna il profilo utente dal server
    func refreshCurrentUser() async {
        guard isAuthenticated else { return }
        
        do {
            // TODO: Implementare endpoint per ottenere profilo utente corrente
            // Per ora manteniamo i dati esistenti
        } catch {
            // Handle error silently
        }
    }
    
    // Ricarica i dati utente dal server se necessario
    func reloadUserDataIfNeeded() async {
        guard APIClient.shared.jwtToken != nil else { return }
        
        do {
            let user: User = try await APIClient.shared.request("/api/auth/me", method: "GET")
            self.currentUser = user
        } catch {
            // Handle error silently
        }
    }
}