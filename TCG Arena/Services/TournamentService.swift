//
//  TournamentService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation
import CoreLocation

// Empty response for DELETE operations
struct EmptyResponse: Codable {}

class TournamentService: ObservableObject {
    static let shared = TournamentService()
    private let apiClient = APIClient.shared
    
    @Published var tournaments: [Tournament] = [] {
        didSet {
            print("TournamentService: tournaments changed from \(oldValue.count) to \(tournaments.count)")
        }
    }
    @Published var nearbyTournaments: [Tournament] = [] {
        didSet {
            print("TournamentService: nearbyTournaments changed from \(oldValue.count) to \(nearbyTournaments.count)")
        }
    }
    @Published var pastTournaments: [Tournament] = [] {
        didSet {
            print("TournamentService: pastTournaments changed from \(oldValue.count) to \(pastTournaments.count)")
        }
    }
    @Published var isLoading = false {
        didSet {
            print("TournamentService: isLoading changed from \(oldValue) to \(isLoading)")
        }
    }
    @Published var errorMessage: String?
    @Published var hasLoadedInitialData = false
    
    init() {
        // Don't load data here - let views control when to load
    }
    
    // MARK: - Tournament Operations
    
    func getAllTournaments(completion: @escaping (Result<[Tournament], Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let tournaments = try JSONDecoder().decode([Tournament].self, from: data)
                    completion(.success(tournaments))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getTournamentById(_ id: Int64, completion: @escaping (Result<Tournament, Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let tournament = try JSONDecoder().decode(Tournament.self, from: data)
                    completion(.success(tournament))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Async version for SwiftUI
    @MainActor
    func getTournamentById(_ id: Int64) async throws -> Tournament {
        return try await apiClient.request("/api/tournaments/\(id)", method: "GET")
    }
    
    func getUpcomingTournaments(completion: @escaping (Result<[Tournament], Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/upcoming", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let tournaments = try JSONDecoder().decode([Tournament].self, from: data)
                    completion(.success(tournaments))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getNearbyTournaments(latitude: Double, longitude: Double, radiusKm: Double = 50, completion: @escaping (Result<[Tournament], Error>) -> Void) {
        let endpoint = "/api/tournaments/nearby?latitude=\(latitude)&longitude=\(longitude)&radiusKm=\(radiusKm)"
        apiClient.request(endpoint: endpoint, method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let tournaments = try JSONDecoder().decode([Tournament].self, from: data)
                    completion(.success(tournaments))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func createTournament(_ tournament: Tournament, completion: @escaping (Result<Tournament, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(tournament)
            apiClient.request(endpoint: "/api/tournaments", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let createdTournament = try JSONDecoder().decode(Tournament.self, from: data)
                        completion(.success(createdTournament))
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
    
    func updateTournament(_ id: Int64, tournament: Tournament, completion: @escaping (Result<Tournament, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(tournament)
            apiClient.request(endpoint: "/api/tournaments/\(id)", method: .put, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let updatedTournament = try JSONDecoder().decode(Tournament.self, from: data)
                        completion(.success(updatedTournament))
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
    
    func deleteTournament(_ id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(id)", method: .delete) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - User Interface Methods
    
    // Async/await version for modern SwiftUI views
    func getTournaments(tcgType: TCGType? = nil, status: Tournament.TournamentStatus? = nil, shopId: Int64? = nil) async throws -> (tournaments: [Tournament], total: Int) {
        let tournaments: [Tournament] = try await apiClient.request("/api/tournaments", method: "GET")
        
        // Apply filters if provided
        var filtered = tournaments
        if let tcgType = tcgType {
            filtered = filtered.filter { $0.tcgType == tcgType }
        }
        if let status = status {
            filtered = filtered.filter { $0.status == status }
        }
        if let shopId = shopId {
            filtered = filtered.filter { $0.organizerId == shopId }
        }
        
        return (tournaments: filtered, total: filtered.count)
    }
    
    func loadTournaments() {
        isLoading = true
        errorMessage = nil
        
        getAllTournaments { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tournaments):
                    self.tournaments = tournaments
                case .failure(let error):
                    // Check if this is a cancelled request (not a real error)
                    if let urlError = error as? URLError, urlError.code == .cancelled {
                        print("Tournaments request was cancelled")
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                }
                self.isLoading = false
            }
        }
    }
    
    // Async version for SwiftUI tasks
    @MainActor
    func loadTournaments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await getTournaments()
            self.tournaments = result.tournaments
            print("Loaded \(result.tournaments.count) tournaments from /api/tournaments")
        } catch {
            // Check if this is a cancelled request (not a real error)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("Tournaments request was cancelled")
            } else {
                self.errorMessage = error.localizedDescription
                print("Error loading tournaments: \(error)")
            }
        }
        
        isLoading = false
    }
    
    func loadNearbyTournaments(userLocation: CLLocation, radius: Double = 50) {
        isLoading = true
        errorMessage = nil
        
        getNearbyTournaments(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, radiusKm: radius) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tournaments):
                    print("Loaded \(tournaments.count) nearby tournaments (or all tournaments sorted by distance)")
                    self.nearbyTournaments = tournaments
                case .failure(let error):
                    // Check if this is a cancelled request (not a real error)
                    if let urlError = error as? URLError, urlError.code == .cancelled {
                        print("Nearby tournaments request was cancelled, using all tournaments as fallback")
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    // Fallback to all tournaments if nearby fails
                    self.nearbyTournaments = self.tournaments
                }
                self.isLoading = false
            }
        }
    }
    
    // Async version for SwiftUI tasks
    @MainActor
    func loadNearbyTournaments(userLocation: CLLocation, radius: Double = 50) async {
        isLoading = true
        errorMessage = nil
        
        // Assume tournaments are already loaded by the view
        // If not, the fallback will handle it
        
        // Try to get nearby ones
        do {
            let nearbyResult = try await apiClient.request("/api/tournaments/nearby?latitude=\(userLocation.coordinate.latitude)&longitude=\(userLocation.coordinate.longitude)&radiusKm=\(radius)", method: "GET") as [Tournament]
            
            print("Loaded \(nearbyResult.count) nearby tournaments from /api/tournaments/nearby")
            self.nearbyTournaments = nearbyResult
        } catch {
            // Check if this is a cancelled request (not a real error)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("Nearby tournaments request was cancelled, using all tournaments as fallback")
            } else {
                print("Error loading nearby tournaments: \(error), using all tournaments as fallback")
                self.errorMessage = error.localizedDescription
            }
            // Fallback to all tournaments if nearby fails
            self.nearbyTournaments = self.tournaments
            print("Using \(self.nearbyTournaments.count) tournaments as fallback")
        }
        
        isLoading = false
    }
    
    // Async version for SwiftUI tasks
    @MainActor
    func loadPastTournaments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let pastResult = try await apiClient.request("/api/tournaments/past", method: "GET") as [Tournament]
            
            print("Loaded \(pastResult.count) past tournaments from /api/tournaments/past")
            self.pastTournaments = pastResult
        } catch {
            // Check if this is a cancelled request (not a real error)
            if let urlError = error as? URLError, urlError.code == .cancelled {
                print("Past tournaments request was cancelled")
            } else {
                print("Error loading past tournaments: \(error)")
                self.errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func createTournament(_ tournament: Tournament) {
        isLoading = true
        errorMessage = nil
        
        createTournament(tournament) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let createdTournament):
                    self.tournaments.append(createdTournament)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Tournament Registration
    
    func registerForTournament(tournamentId: Int64, completion: @escaping (Result<TournamentParticipant, Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/register", method: .post) { result in
            switch result {
            case .success(let data):
                do {
                    let participant = try JSONDecoder().decode(TournamentParticipant.self, from: data)
                    completion(.success(participant))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Async version for SwiftUI
    @MainActor
    func registerForTournament(tournamentId: Int64) async throws -> TournamentParticipant {
        let participant: TournamentParticipant = try await apiClient.request("/api/tournaments/\(tournamentId)/register", method: "POST")
        print("Successfully registered for tournament \(tournamentId)")
        return participant
    }
    
    func unregisterFromTournament(tournamentId: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/register", method: .delete) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Async version for SwiftUI
    @MainActor
    func unregisterFromTournament(tournamentId: Int64) async throws {
        let _: EmptyResponse = try await apiClient.request("/api/tournaments/\(tournamentId)/register", method: "DELETE")
        print("Successfully unregistered from tournament \(tournamentId)")
    }
    
    func getTournamentParticipants(tournamentId: Int64, completion: @escaping (Result<[TournamentParticipant], Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/participants", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let participants = try JSONDecoder().decode([TournamentParticipant].self, from: data)
                    completion(.success(participants))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getRegisteredParticipants(tournamentId: Int64, completion: @escaping (Result<[TournamentParticipant], Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/participants/registered", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let participants = try JSONDecoder().decode([TournamentParticipant].self, from: data)
                    completion(.success(participants))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getWaitingList(tournamentId: Int64, completion: @escaping (Result<[TournamentParticipant], Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/participants/waiting", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let participants = try JSONDecoder().decode([TournamentParticipant].self, from: data)
                    completion(.success(participants))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func isUserRegistered(tournamentId: Int64, completion: @escaping (Result<TournamentParticipant?, Error>) -> Void) {
        getTournamentParticipants(tournamentId: tournamentId) { result in
            switch result {
            case .success(let participants):
                // In a real implementation, we would get the current user ID from auth service
                // For now, we'll return nil (not registered)
                completion(.success(nil))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getTournamentWithParticipants(tournamentId: Int64, completion: @escaping (Result<Tournament, Error>) -> Void) {
        // First get the tournament
        getTournamentById(tournamentId) { tournamentResult in
            switch tournamentResult {
            case .success(var tournament):
                // Then get participants with details
                self.getTournamentParticipantsWithDetails(tournamentId: tournamentId) { participantsResult in
                    switch participantsResult {
                    case .success(let participants):
                        tournament.tournamentParticipants = participants
                        completion(.success(tournament))
                    case .failure(let error):
                        // Return tournament without participants if participants fail to load
                        completion(.success(tournament))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Tournament Management (Merchant)
    
    /// Start tournament and generate first round pairings
    func startTournament(tournamentId: String, completion: @escaping (Result<TournamentRound, Error>) -> Void) {
        let request = StartTournamentRequest(tournamentId: tournamentId)
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let body = try encoder.encode(request)
            
            apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/start", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let round = try decoder.decode(TournamentRound.self, from: data)
                        completion(.success(round))
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
    
    /// Create next round with matchmaking
    func createNextRound(tournamentId: String, completion: @escaping (Result<TournamentRound, Error>) -> Void) {
        let request = CreateRoundRequest(tournamentId: tournamentId)
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let body = try encoder.encode(request)
            
            apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/round/matchmaking", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let round = try decoder.decode(TournamentRound.self, from: data)
                        completion(.success(round))
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
    
    /// Submit match result
    func submitMatchResult(matchId: String, result: Match.MatchResult, score: String?, completion: @escaping (Result<Match, Error>) -> Void) {
        let request = CreateMatchResultRequest(matchId: matchId, result: result, score: score)
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let body = try encoder.encode(request)
            
            apiClient.request(endpoint: "/api/matches/\(matchId)/result", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let match = try decoder.decode(Match.self, from: data)
                        completion(.success(match))
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
    
    // MARK: - Tournament Player Actions
    
    /// Register for tournament with optional decklist
    func registerWithCheckin(tournamentId: String, decklistUrl: String?, completion: @escaping (Result<TournamentRegistration, Error>) -> Void) {
        let request = CheckInRequest(decklistUrl: decklistUrl)
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let body = try encoder.encode(request)
            
            apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/register", method: .post, body: body) { result in
                switch result {
                case .success(let data):
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        decoder.dateDecodingStrategy = .iso8601
                        let registration = try decoder.decode(TournamentRegistration.self, from: data)
                        completion(.success(registration))
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
    
    /// Drop from tournament
    func dropFromTournament(tournamentId: String, reason: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let request = DropFromTournamentRequest(reason: reason)
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let body = try encoder.encode(request)
            
            apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/drop", method: .post, body: body) { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Tournament Data
    
    /// Get tournament detail with all data
    func getTournamentDetail(tournamentId: String, completion: @escaping (Result<TournamentDetailResponse, Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/detail", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    let detail = try decoder.decode(TournamentDetailResponse.self, from: data)
                    completion(.success(detail))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get current user's match pairing
    func getUserPairing(tournamentId: String, completion: @escaping (Result<MatchPairingResponse, Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/my-match", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    let pairing = try decoder.decode(MatchPairingResponse.self, from: data)
                    completion(.success(pairing))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get tournament standings
    func getStandings(tournamentId: String, completion: @escaping (Result<StandingsResponse, Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/standings", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    let standings = try decoder.decode(StandingsResponse.self, from: data)
                    completion(.success(standings))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Get tournament bracket (for single elimination)
    func getBracket(tournamentId: String, completion: @escaping (Result<[TournamentRound], Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/bracket", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    let bracket = try decoder.decode([TournamentRound].self, from: data)
                    completion(.success(bracket))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Tournament Check-in
    
    /// Check-in participant using QR code
    func checkInParticipant(checkInCode: String, completion: @escaping (Result<TournamentParticipant, Error>) -> Void) {
        let parameters = ["code": checkInCode]
        do {
            let data = try JSONSerialization.data(withJSONObject: parameters)
            apiClient.request(endpoint: "/api/tournaments/checkin", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let participant = try JSONDecoder().decode(TournamentParticipant.self, from: data)
                        completion(.success(participant))
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
    
    /// Async version for check-in
    @MainActor
    func checkInParticipant(checkInCode: String) async throws -> TournamentParticipant {
        let participant: TournamentParticipant = try await apiClient.request("/api/tournaments/checkin?code=\(checkInCode)", method: "POST")
        return participant
    }
    
    /// Self check-in - allows user to check themselves in for a tournament
    @MainActor
    func checkIn(tournamentId: Int64) async throws {
        let _: TournamentParticipant = try await apiClient.request("/api/tournaments/\(tournamentId)/self-checkin", method: "POST")
        print("Successfully checked in for tournament \(tournamentId)")
    }
    
    /// Get tournament participants with user details (for organizers)
    func getTournamentParticipantsWithDetails(tournamentId: Int64, completion: @escaping (Result<[TournamentParticipantWithUser], Error>) -> Void) {
        apiClient.request(endpoint: "/api/tournaments/\(tournamentId)/participants/detailed", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let participants = try JSONDecoder().decode([TournamentParticipantWithUser].self, from: data)
                    completion(.success(participants))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Async version for getting participants with details
    @MainActor
    func getTournamentParticipantsWithDetails(tournamentId: Int64) async throws -> [TournamentParticipantWithUser] {
        let participants: [TournamentParticipantWithUser] = try await apiClient.request("/api/tournaments/\(tournamentId)/participants/detailed", method: "GET")
        return participants
    }
    
    // MARK: - Shop Tournament Management
    
    /// Load tournaments for a specific shop (merchant)
    @MainActor
    func loadShopTournaments(shopId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let shopIdInt = Int64(shopId) else {
                self.errorMessage = "Invalid shop ID format"
                isLoading = false
                return
            }
            let result = try await getTournaments(shopId: shopIdInt)
            self.tournaments = result.tournaments
            print("Loaded \(result.tournaments.count) shop tournaments")
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error loading shop tournaments: \(error)")
        }
        
        isLoading = false
    }
    // MARK: - Manual Registration
    
    struct ManualRegistrationRequest: Encodable {
        let firstName: String
        let lastName: String
        let email: String?
    }
    
    @MainActor
    func registerManualParticipant(tournamentId: Int64, firstName: String, lastName: String, email: String? = nil) async throws -> TournamentParticipant {
        let request = ManualRegistrationRequest(firstName: firstName, lastName: lastName, email: email)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(request)
        
        let participant: TournamentParticipant = try await apiClient.request("/api/tournaments/\(tournamentId)/participants/manual", method: "POST", body: data)
        return participant
    }
}
