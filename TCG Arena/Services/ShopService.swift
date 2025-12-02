//
//  ShopService.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import Foundation
import CoreLocation
import Combine

@MainActor
class ShopService: ObservableObject {
    @Published var shops: [Shop] = []
    @Published var nearbyShops: [Shop] = []
    @Published var shopNews: [String: [ShopNews]] = [:] // ShopID -> News (mock for now)
    @Published var subscribedShops: Set<String> = [] // ShopIDs user is subscribed to (mock for now)
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient.shared) {
        self.apiClient = apiClient
        loadShops()
    }
    
    // MARK: - API Methods
    
    func getAllShops(completion: @escaping (Result<[Shop], Error>) -> Void) {
        apiClient.request(endpoint: "/api/shops", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let shops = try JSONDecoder().decode([Shop].self, from: data)
                    completion(.success(shops))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getShopById(_ id: Int64, completion: @escaping (Result<Shop, Error>) -> Void) {
        apiClient.request(endpoint: "/api/shops/\(id)", method: .get) { result in
            switch result {
            case .success(let data):
                do {
                    let shop = try JSONDecoder().decode(Shop.self, from: data)
                    completion(.success(shop))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func createShop(_ shop: Shop, completion: @escaping (Result<Shop, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(shop)
            apiClient.request(endpoint: "/api/shops", method: .post, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let createdShop = try JSONDecoder().decode(Shop.self, from: data)
                        completion(.success(createdShop))
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
    
    func updateShop(_ id: Int64, _ shop: Shop, completion: @escaping (Result<Shop, Error>) -> Void) {
        do {
            let data = try JSONEncoder().encode(shop)
            apiClient.request(endpoint: "/api/shops/\(id)", method: .put, body: data) { result in
                switch result {
                case .success(let data):
                    do {
                        let updatedShop = try JSONDecoder().decode(Shop.self, from: data)
                        completion(.success(updatedShop))
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
    
    func deleteShop(_ id: Int64, completion: @escaping (Result<Void, Error>) -> Void) {
        apiClient.request(endpoint: "/api/shops/\(id)", method: .delete) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - User Interface Methods
    
    func loadShops() {
        isLoading = true
        errorMessage = nil
        
        getAllShops { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let shops):
                    self.shops = shops
                    self.nearbyShops = shops // Initialize nearbyShops with all shops
                    if shops.isEmpty {
                        self.setupMockData()
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.setupMockData() // Load mock data on failure
                }
                self.isLoading = false
            }
        }
    }
    
    func loadNearbyShops(userLocation: CLLocation, radius: Double = 50000) {
        isLoading = true
        errorMessage = nil
        
        getAllShops { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let shops):
                    // Filter shops within radius (only those with valid coordinates)
                    self.nearbyShops = shops.compactMap { shop in
                        guard let latitude = shop.latitude, let longitude = shop.longitude else { return nil }
                        let shopLocation = CLLocation(latitude: latitude, longitude: longitude)
                        let distance = userLocation.distance(from: shopLocation)
                        return distance <= radius ? shop : nil
                    }.sorted { shop1, shop2 in
                        guard let lat1 = shop1.latitude, let lon1 = shop1.longitude,
                              let lat2 = shop2.latitude, let lon2 = shop2.longitude else { return false }
                        let location1 = CLLocation(latitude: lat1, longitude: lon1)
                        let location2 = CLLocation(latitude: lat2, longitude: lon2)
                        return userLocation.distance(from: location1) < userLocation.distance(from: location2)
                    }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
    
    // Async version for SwiftUI tasks
    @MainActor
    func loadNearbyShops(userLocation: CLLocation, radius: Double = 50000) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let shops: [Shop] = try await apiClient.request("/api/shops", method: "GET")
            
            // Filter shops within radius (only those with valid coordinates)
            self.nearbyShops = shops.compactMap { shop in
                guard let latitude = shop.latitude, let longitude = shop.longitude else { return nil }
                let shopLocation = CLLocation(latitude: latitude, longitude: longitude)
                let distance = userLocation.distance(from: shopLocation)
                return distance <= radius ? shop : nil
            }.sorted { shop1, shop2 in
                guard let lat1 = shop1.latitude, let lon1 = shop1.longitude,
                      let lat2 = shop2.latitude, let lon2 = shop2.longitude else { return false }
                let location1 = CLLocation(latitude: lat1, longitude: lon1)
                let location2 = CLLocation(latitude: lat2, longitude: lon2)
                return userLocation.distance(from: location1) < userLocation.distance(from: location2)
            }
            
            print("Loaded \(self.nearbyShops.count) nearby shops")
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error loading nearby shops: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Shop News (Mock for now - backend may not have this endpoint)
    
    func loadShopNews() {
        // Mock shop news for now
        shopNews = [
            "1": [
                ShopNews(shopID: Int64("1")!, title: "New Pokemon Set Available!", content: "Scarlet & Violet - Paldea Evolved is now in stock!", newsType: .newStock, publishedDate: Date(), expiryDate: nil, imageURL: nil, isPinned: false),
                ShopNews(shopID: Int64("1")!, title: "Weekly Tournament This Saturday", content: "Join us for our weekly Standard tournament with prizes!", newsType: .tournament, publishedDate: Date().addingTimeInterval(-86400), expiryDate: nil, imageURL: nil, isPinned: false)
            ],
            "2": [
                ShopNews(shopID: Int64("2")!, title: "Magic: The Gathering Pre-orders", content: "Pre-order your copies of the latest MTG set now!", newsType: .announcement, publishedDate: Date(), expiryDate: nil, imageURL: nil, isPinned: false)
            ]
        ]
    }
    
    // MARK: - Shop Subscription (Mock for now - backend may not have this endpoint)
    
    func subscribeToShop(_ shopId: String) {
        subscribedShops.insert(shopId)
    }
    
    func unsubscribeFromShop(_ shopId: String) {
        subscribedShops.remove(shopId)
    }
    
    func isSubscribedToShop(_ shopId: String) -> Bool {
        return subscribedShops.contains(shopId)
    }
    
    // MARK: - Mock Data Setup
    private func setupMockData() {
        var shop1 = Shop(
            id: 1,
            name: "Magic Castle Games",
            description: "Your premier destination for Trading Card Games in Milano. We host weekly tournaments and offer a wide selection of cards from all major TCGs.",
            address: "Via Paolo Sarpi, 42, Milano, Italy",
            latitude: 45.4773,
            longitude: 9.1815,
            phoneNumber: "+39 02 1234 5678",
            email: "info@magiccastlegames.it",
            websiteUrl: "www.magiccastlegames.it",
            instagramUrl: "@magiccastlegames",
            facebookUrl: "facebook.com/magiccastlegames",
            twitterUrl: "@magiccastlegames",
            type: .localStore,
            isVerified: true,
            active: true,
            ownerId: 1,
            openingHours: "10:00-20:00",
            openingDays: "Mon-Sun",
            tcgTypes: [.pokemon, .yugioh, .magic],
            services: ["Card Sales", "Buy Cards", "Tournaments", "Play Area", "Accessories", "Pre-orders"],
            inventory: nil
        )
        
        var shop2 = Shop(
            id: 2,
            name: "TCG Hub Milano",
            description: "Modern gaming store specializing in Pokémon and Yu-Gi-Oh! cards. Professional grading service available.",
            address: "Corso Buenos Aires, 15, Milano, Italy",
            latitude: 45.4794,
            longitude: 9.2038,
            phoneNumber: "+39 02 9876 5432",
            email: "contact@tcghubmilano.com",
            websiteUrl: "www.tcghubmilano.com",
            instagramUrl: "@tcghubmilano",
            facebookUrl: "facebook.com/tcghubmilano",
            twitterUrl: "@tcghubmilano",
            type: .localStore,
            isVerified: true,
            active: true,
            ownerId: 2,
            openingHours: "10:00-20:00",
            openingDays: "Mon-Sat",
            tcgTypes: [.pokemon, .yugioh],
            services: ["Card Sales", "Buy Cards", "Grading", "Accessories", "Online Store"],
            inventory: nil
        )
        
        var shop3 = Shop(
            id: 3,
            name: "Giochi di Carte",
            description: "Family-owned card shop with 20 years of experience. Extensive collection of rare and vintage cards.",
            address: "Via Torino, 28, Milano, Italy",
            latitude: 45.4628,
            longitude: 9.1859,
            phoneNumber: "+39 02 5555 4444",
            email: "info@giochidicarte.it",
            websiteUrl: nil,
            instagramUrl: nil,
            facebookUrl: nil,
            twitterUrl: nil,
            type: .localStore,
            isVerified: false,
            active: true,
            ownerId: 3,
            openingHours: "09:30-19:30",
            openingDays: "Mon-Sat",
            tcgTypes: [.pokemon, .yugioh, .magic, .onePiece],
            services: ["Card Sales", "Buy Cards", "Accessories"],
            inventory: nil
        )
        
        var shop4 = Shop(
            id: 4,
            name: "Dragon's Lair Gaming",
            description: "Large gaming center with dedicated play areas for each TCG. Regular tournament schedule and competitive scene.",
            address: "Via Melchiorre Gioia, 82, Milano, Italy",
            latitude: 45.4898,
            longitude: 9.2061,
            phoneNumber: "+39 02 3333 2222",
            email: "contact@dragonslairgaming.it",
            websiteUrl: "www.dragonslairgaming.it",
            instagramUrl: "@dragonslairgaming",
            facebookUrl: "facebook.com/dragonslairgaming",
            twitterUrl: "@dragonslairgaming",
            type: .localStore,
            isVerified: true,
            active: true,
            ownerId: 4,
            openingHours: "10:00-24:00",
            openingDays: "Mon-Sun",
            tcgTypes: [.pokemon, .yugioh, .magic, .onePiece, .digimon],
            services: ["Card Sales", "Tournaments", "Play Area", "Accessories", "Pre-orders"],
            inventory: nil
        )
        
        shops = [shop1, shop2, shop3, shop4]
        
        loadMockNews()
    }
    
    private func loadMockNews() {
        let calendar = Calendar.current
        let now = Date()
        
        // News for Magic Castle Games (shop1)
        shopNews["1"] = [
            ShopNews(
                shopID: Int64("1")!,
                title: "New Pokémon Scarlet & Violet Booster Box Arrived!",
                content: "We just received the latest Pokémon Scarlet & Violet booster boxes! Limited stock available. First come, first served!",
                newsType: .newStock,
                publishedDate: calendar.date(byAdding: .day, value: -2, to: now)!,
                expiryDate: nil,
                imageURL: nil,
                isPinned: true
            ),
            ShopNews(
                shopID: Int64("1")!,
                title: "Weekly Yu-Gi-Oh! Tournament - This Saturday",
                content: "Join us this Saturday at 3 PM for our weekly Yu-Gi-Oh! tournament. Entry fee: €10. Prize pool: €100 in store credit!",
                newsType: .tournament,
                publishedDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                expiryDate: calendar.date(byAdding: .day, value: 5, to: now)!,
                imageURL: nil,
                isPinned: true
            ),
            ShopNews(
                shopID: Int64("1")!,
                title: "Black Friday Sale - 20% Off All Singles",
                content: "Special Black Friday offer! Get 20% off on all single cards. Valid until end of November.",
                newsType: .sale,
                publishedDate: calendar.date(byAdding: .day, value: -5, to: now)!,
                expiryDate: calendar.date(byAdding: .day, value: 14, to: now)!,
                imageURL: nil,
                isPinned: false
            ),
            ShopNews(
                shopID: Int64("1")!,
                title: "Store Hours Update",
                content: "Starting next month, we'll be open on Sundays from 10 AM to 8 PM!",
                newsType: .announcement,
                publishedDate: calendar.date(byAdding: .day, value: -7, to: now)!,
                expiryDate: nil,
                imageURL: nil,
                isPinned: false
            )
        ]
        
        // News for TCG Hub Milano (shop2)
        shopNews["2"] = [
            ShopNews(
                shopID: Int64("2")!,
                title: "PSA Grading Service Now Available",
                content: "We're now offering PSA grading services! Bring your cards and get them professionally graded. Special launch price for the first 50 submissions.",
                newsType: .announcement,
                publishedDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                expiryDate: nil,
                imageURL: nil,
                isPinned: true
            ),
            ShopNews(
                shopID: Int64("2")!,
                title: "One Piece Card Game Pre-Release Event",
                content: "Join us for the One Piece Card Game pre-release event next Friday! Entry includes 6 booster packs and exclusive promo cards.",
                newsType: .event,
                publishedDate: calendar.date(byAdding: .day, value: -3, to: now)!,
                expiryDate: calendar.date(byAdding: .day, value: 10, to: now)!,
                imageURL: nil,
                isPinned: true
            )
        ]
        
        // News for Giochi di Carte (shop3)
        shopNews["3"] = [
            ShopNews(
                shopID: Int64("3")!,
                title: "Rare Vintage Cards Just Added",
                content: "Check out our new collection of vintage cards including 1st Edition Base Set Charizard and other rare finds!",
                newsType: .newStock,
                publishedDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                expiryDate: nil,
                imageURL: nil,
                isPinned: true
            )
        ]
        
        // News for Dragon's Lair Gaming (shop4)
        shopNews["4"] = [
            ShopNews(
                shopID: Int64("4")!,
                title: "Magic: The Gathering Modern Tournament Series",
                content: "Starting next month: 4-week Modern tournament series! Winner gets a full box of the latest set.",
                newsType: .tournament,
                publishedDate: now,
                expiryDate: nil,
                imageURL: nil,
                isPinned: true
            ),
            ShopNews(
                shopID: Int64("4")!,
                title: "New Play Area Opened!",
                content: "We've expanded! Our new play area can now accommodate 50+ players. Come check it out!",
                newsType: .announcement,
                publishedDate: calendar.date(byAdding: .day, value: -4, to: now)!,
                expiryDate: nil,
                imageURL: nil,
                isPinned: false
            )
        ]
    }
    
    func getNews(for shopID: String) -> [ShopNews] {
        return shopNews[shopID]?.sorted { news1, news2 in
            // Pinned news first, then by date
            if news1.isPinned != news2.isPinned {
                return news1.isPinned
            }
            return news1.publishedDate > news2.publishedDate
        } ?? []
    }
    
    func toggleSubscription(for shopID: String) {
        if subscribedShops.contains(shopID) {
            subscribedShops.remove(shopID)
            // TODO: Unregister for push notifications
        } else {
            subscribedShops.insert(shopID)
            // TODO: Register for push notifications
        }
    }
    
    func isSubscribed(to shopID: String) -> Bool {
        return subscribedShops.contains(shopID)
    }
}
