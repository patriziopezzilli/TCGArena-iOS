//
//  TournamentService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import Foundation
import CoreLocation

class TournamentService: ObservableObject {
    static let shared = TournamentService()
    private let apiClient = APIClient.shared
    
    @Published var tournaments: [Tournament] = []
    @Published var nearbyTournaments: [Tournament] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Load initial data
        loadTournaments()
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
    
    func loadTournaments() {
        isLoading = true
        errorMessage = nil
        
        getAllTournaments { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tournaments):
                    self.tournaments = tournaments
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
    
    func loadNearbyTournaments(userLocation: CLLocation, radius: Double = 50) {
        isLoading = true
        errorMessage = nil
        
        getNearbyTournaments(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, radiusKm: radius) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tournaments):
                    self.nearbyTournaments = tournaments
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    // Fallback to all tournaments if nearby fails
                    self.nearbyTournaments = self.tournaments
                }
                self.isLoading = false
            }
        }
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
                // Then get participants
                self.getTournamentParticipants(tournamentId: tournamentId) { participantsResult in
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
}
