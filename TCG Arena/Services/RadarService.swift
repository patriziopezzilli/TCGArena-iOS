import Foundation
import Combine
import CoreLocation

struct RadarUser: Identifiable, Codable {
    let id: Int64
    let username: String
    let displayName: String
    let latitude: Double
    let longitude: Double
    let favoriteTCG: TCGType?
    let profileImageUrl: String?
    let isOnline: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class RadarService: ObservableObject {
    @Published var nearbyUsers: [RadarUser] = []
    
    private let apiClient = APIClient.shared
    
    func updateLocation(latitude: Double, longitude: Double, city: String?, country: String?) {
        guard let city = city, let country = country else { return }
        
        let body: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "city": city,
            "country": country
        ]
        
        // Wrap async call in Task since this method is called synchronously
        Task {
            do {
                // We define a transient struct for the body to be Encodable, or use Dictionary if JSONSerialization handled it, 
                // but APIClient expects Encodable. [String: Any] is NOT Encodable.
                // We should use a struct.
                let request = LocationUpdateRequest(city: city, country: country, latitude: latitude, longitude: longitude)
                
                let _: EmptyResponse = try await apiClient.request("/api/radar/location", method: "PUT", body: request)
                print("📍 Location updated for Radar")
            } catch {
                print("❌ Failed to update Radar location: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchNearbyUsers(latitude: Double, longitude: Double, radiusKm: Double = 10.0) async {
        // Construct query string manually since APIClient doesn't support query params dict
        let endpoint = "/api/radar/nearby?latitude=\(latitude)&longitude=\(longitude)&radiusKm=\(radiusKm)"
        
        do {
            let users: [RadarUser] = try await apiClient.request(endpoint, method: "GET")
            DispatchQueue.main.async {
                self.nearbyUsers = users
            }
        } catch {
            print("❌ Failed to fetch nearby users: \(error.localizedDescription)")
        }
    }
    
    func pingUser(userId: Int64) {
        Task {
            do {
                let _: EmptyResponse = try await apiClient.request("/api/radar/ping/\(userId)", method: "POST")
                print("📡 Ping sent to user \(userId)")
            } catch {
                print("❌ Failed to ping user: \(error.localizedDescription)")
            }
        }
    }
}

// Local wrapper for LocationUpdateRequest to ensure Encodable conformance for use in body
private struct LocationUpdateRequest: Encodable {
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
}
