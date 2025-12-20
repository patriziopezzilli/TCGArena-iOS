
import Foundation
import Combine
import CoreLocation

// MARK: - Models

struct HomeDashboardData: Codable {
    let nearbyShopsCount: Int
    let upcomingTournamentsCount: Int
    let collectionCount: Int
    let deckCount: Int
    let totalCollectionValue: Decimal
    let unreadNewsCount: Int
    let pendingReservationsCount: Int
    let activeRequestsCount: Int
    
    enum CodingKeys: String, CodingKey {
        case nearbyShopsCount
        case upcomingTournamentsCount
        case collectionCount
        case deckCount
        case totalCollectionValue
        case unreadNewsCount
        case pendingReservationsCount
        case activeRequestsCount
    }
}

// MARK: - Service


// MARK: - Service

class HomeDashboardService: ObservableObject {
    @Published var dashboardData: HomeDashboardData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @MainActor
    func fetchDashboardData(latitude: Double? = nil, longitude: Double? = nil) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                var endpoint = "/api/home/dashboard"
                
                // Manually construct query string since APIClient doesn't have a helper
                var queryItems: [String] = []
                if let lat = latitude {
                    queryItems.append("latitude=\(lat)")
                }
                if let lon = longitude {
                    queryItems.append("longitude=\(lon)")
                }
                
                if !queryItems.isEmpty {
                    endpoint += "?" + queryItems.joined(separator: "&")
                }
                
                let data: HomeDashboardData = try await APIClient.shared.request(endpoint)
                self.dashboardData = data
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("❌ HomeDashboardService Error: \(error)")
            }
        }
    }
}
