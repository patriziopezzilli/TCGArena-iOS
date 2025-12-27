import SwiftUI
import MapKit

struct ExploreMapView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var inventoryService: InventoryService
    
    @StateObject private var shopService = ShopService()
    @StateObject private var tournamentService = TournamentService()
    @StateObject private var radarService = RadarService()
    @StateObject private var locationManager = LocationManager()
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.9028, longitude: 12.4964), // Default Rome
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var selectedContent: MapContent?
    @State private var showingShopDetail = false
    @State private var showingTournamentDetail = false
    @State private var hasSetInitialRegion = false
    @State private var isRadarActive = false
    
    // Radar Pulse Animation
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.5
    
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect() // Sync every 30s
    
    enum MapContent: Identifiable {
        case shop(Shop)
        case tournament(Tournament)
        case user(RadarUser)
        
        var id: String {
            switch self {
            case .shop(let shop): return "shop-\(shop.id)"
            case .tournament(let tournament): return "tournament-\(tournament.id ?? 0)"
            case .user(let user): return "user-\(user.id)"
            }
        }
    }
    
    struct MapLocation: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let contents: [MapContent]
    }
    
    var mapLocations: [MapLocation] {
        var locations: [String: [MapContent]] = [:]
        
        // Group Shops
        for shop in shopService.shops {
            if let lat = shop.latitude, let lon = shop.longitude {
                let key = "\(String(format: "%.4f", lat)),\(String(format: "%.4f", lon))"
                if locations[key] == nil { locations[key] = [] }
                locations[key]?.append(.shop(shop))
            }
        }
        
        // Group Tournaments
        for tournament in tournamentService.tournaments {
            if let location = tournament.location, let coordinate = location.coordinate {
                let key = "\(String(format: "%.4f", coordinate.latitude)),\(String(format: "%.4f", coordinate.longitude))"
                if locations[key] == nil { locations[key] = [] }
                locations[key]?.append(.tournament(tournament))
            }
        }
        
        // Group Radar Users
        for user in radarService.nearbyUsers {
            let key = "\(String(format: "%.4f", user.latitude ?? 0)),\(String(format: "%.4f", user.longitude ?? 0))"
            if locations[key] == nil { locations[key] = [] }
            locations[key]?.append(.user(user))
        }
        
        return locations.map { key, contents in
            let coords = key.split(separator: ",").map { Double($0)! }
            return MapLocation(coordinate: CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1]), contents: contents)
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Map
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: mapLocations) { location in
                MapAnnotation(coordinate: location.coordinate) {
                    HStack(spacing: 4) {
                        ForEach(location.contents) { content in
                            Button(action: {
                                withAnimation {
                                    selectedContent = content
                                }
                            }) {
                                ZStack {
                                    // Shop/Tournament Marker
                                    if case .shop = content {
                                        // Safe Zone Halo
                                        Circle()
                                            .fill(Color.green.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                            )
                                    }
                                    
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 36, height: 36)
                                        .shadow(radius: 2)
                                    
                                    switch content {
                                    case .shop:
                                        SwiftUI.Image(systemName: "building.2.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .foregroundColor(.blue)
                                    case .tournament:
                                        SwiftUI.Image(systemName: "trophy.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                            .foregroundColor(.orange)
                                    case .user(let user):
                                        if let urlString = user.profileImageUrl, let url = URL(string: urlString) {
                                            AsyncImage(url: url) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                SwiftUI.Image(systemName: "person.circle.fill")
                                                    .foregroundColor(.gray)
                                            }
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                        } else {
                                            // Anonymous User Icon
                                            ZStack {
                                                Circle()
                                                    .fill(Color.purple)
                                                    .frame(width: 32, height: 32)
                                                SwiftUI.Image(systemName: "face.smiling.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 20, height: 20)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                .scaleEffect(selectedContent?.id == content.id ? 1.2 : 1.0)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation {
                    selectedContent = nil
                }
            }
            
            // Radar Overlay
            if isRadarActive {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                                pulseScale = 2.0
                                pulseOpacity = 0.0
                            }
                        }
                }
                .frame(width: 100, height: 100)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2) // Approximate center
                .allowsHitTesting(false)
            }
            
            // Top Controls
            VStack {
                 // Back Button
                 HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        SwiftUI.Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(12)
                            .background(Color(.systemBackground).opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    // Radar Toggle
                    Button(action: {
                        isRadarActive.toggle()
                        if isRadarActive {
                            syncRadar()
                        }
                    }) {
                        HStack(spacing: 8) {
                            SwiftUI.Image(systemName: isRadarActive ? "person.2.fill" : "person.slash.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(isRadarActive ? .green : .gray)
                            
                            Text(isRadarActive ? "Online" : "Offline")
                                .font(.caption).bold()
                                .foregroundColor(isRadarActive ? .green : .gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground).opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(radius: 4)
                    }
                 }
                 .padding(.horizontal, 20)
                 .padding(.top, 50)
                 
                 Spacer()
            }
            
            // Summary Card Overlay
            if let content = selectedContent {
                VStack {
                    Spacer()
                    if case .user(let user) = content {
                        RadarUserProfileCard(user: user) {
                            radarService.pingUser(userId: user.id)
                        }
                        .padding(.bottom, 30)
                        .padding(.horizontal, 16)
                    } else {
                        MapSummaryCard(content: content, radarService: radarService) {
                            switch content {
                            case .shop:
                                showingShopDetail = true
                            case .tournament:
                                showingTournamentDetail = true
                            case .user: break // Handled above
                            }
                        }
                        .transition(.move(edge: .bottom))
                        .padding(.bottom, 30)
                        .padding(.horizontal, 16)
                    }
                }
                .zIndex(1)
            }
            
            // Navigation Links
            NavigationLink(isActive: $showingShopDetail) {
                if case .shop(let shop) = selectedContent {
                    ShopDetailView(shop: shop)
                        .environmentObject(shopService)
                        .environmentObject(authService)
                        .environmentObject(inventoryService)
                }
            } label: { EmptyView() }
            
            NavigationLink(isActive: $showingTournamentDetail) {
                if case .tournament(let tournament) = selectedContent {
                    TournamentDetailView(tournament: tournament)
                        .environmentObject(tournamentService)
                        .environmentObject(authService)
                }
            } label: { EmptyView() }
        }
        .navigationBarHidden(true)
        .onAppear {
            locationManager.requestLocationPermission()
            shopService.loadShops()
            Task {
                await tournamentService.loadTournaments()
            }
        }
        .onReceive(timer) { _ in
            if isRadarActive {
                syncRadar()
            }
        }
        .onReceive(locationManager.$location) { location in
            if let location = location {
                if !hasSetInitialRegion {
                    region.center = location.coordinate
                    region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    hasSetInitialRegion = true
                }
                // Sync location if radar active
                if isRadarActive {
                    // Reverse geocode to get city implied or use CLGeocoder within LocationManager
                    // For MVP passing generic strings or implementing reverse geocode in LM
                     // radarService.updateLocation(...) - moved to syncRadar to prevent rapid updates
                }
            }
        }
    }
    
    private func syncRadar() {
        guard let loc = locationManager.location else { return }
        
        // Update Location
        // Note: Ideally LocationManager should provide city/country. 
        // For MVP we can pass "Unknown" as backend might resolve lat/lon or simple city
        radarService.updateLocation(
            latitude: loc.coordinate.latitude, 
            longitude: loc.coordinate.longitude, 
            city: "UserCity", // Real implementation needs CLGeocoder
            country: "Italy"
        )
        
        // Fetch Nearby
        Task {
            await radarService.fetchNearbyUsers(
                latitude: loc.coordinate.latitude,
                longitude: loc.coordinate.longitude
            )
        }
    }
}

struct MapSummaryCard: View {
    let content: ExploreMapView.MapContent
    let radarService: RadarService
    let action: () -> Void
    
    @State private var hasPinged = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    switch content {
                    case .shop(let shop):
                        Text(shop.name).font(.headline)
                        Text(shop.address).font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                    case .tournament(let tournament):
                        Text(tournament.title).font(.headline)
                        Text(tournament.location?.displayName ?? "Luogo sconosciuto").font(.subheadline).foregroundColor(.secondary).lineLimit(1)
                    case .user(let user):
                        Text(user.displayName).font(.headline)
                        Text(user.favoriteTCG?.rawValue ?? "Player").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                Button(action: {
                    action()
                    if case .user = content { hasPinged = true }
                }) {
                    switch content {
                    case .shop, .tournament:
                         SwiftUI.Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    case .user:
                         ZStack {
                             Circle().fill(hasPinged ? Color.gray : Color.purple).frame(width: 40, height: 40)
                             SwiftUI.Image(systemName: hasPinged ? "checkmark" : "antenna.radiowaves.left.and.right")
                                .foregroundColor(.white)
                         }
                    }
                }
                .disabled(hasPinged)
            }
            
            switch content {
            case .shop:
                HStack {
                    Label("Safe Zone", systemImage: "shield.fill")
                        .font(.caption).padding(6)
                        .background(Color.green.opacity(0.1)).foregroundColor(.green).cornerRadius(8)
                }
            case .tournament(let tournament):
                 HStack {
                    Label("Torneo", systemImage: "trophy.fill")
                        .font(.caption).padding(6)
                        .background(Color.orange.opacity(0.1)).foregroundColor(.orange).cornerRadius(8)
                    Text(tournament.formattedStartDate).font(.caption).foregroundColor(.secondary)
                }
            case .user:
                HStack {
                    Label("Live Ping", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption).padding(6)
                        .background(Color.purple.opacity(0.1)).foregroundColor(.purple).cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct RadarUserProfileCard: View {
    let user: RadarUser
    let onPing: () -> Void
    
    @EnvironmentObject var authService: AuthService
    @StateObject private var chatService = ChatService()
    @State private var isChatActive = false
    @State private var activeConversation: ChatConversation?
    
    @State private var selectedTab = 0 // 0: Cerco, 1: Offro, 2: Carte
    @State private var selectedTCGType: TCGType?
    @State private var searchText = ""
    @State private var isExpanded = false
    // hasPinged removed
    
    // Filtered lists based on TCG type and search
    var filteredWantList: [RadarTradeEntry] {
        let list = user.wantList ?? []
        return list.filter { entry in
            let matchesTCG = selectedTCGType == nil || entry.tcgType == selectedTCGType
            let matchesSearch = searchText.isEmpty || entry.cardName.localizedCaseInsensitiveContains(searchText)
            return matchesTCG && matchesSearch
        }
    }
    
    var filteredHaveList: [RadarTradeEntry] {
        let list = user.haveList ?? []
        return list.filter { entry in
            let matchesTCG = selectedTCGType == nil || entry.tcgType == selectedTCGType
            let matchesSearch = searchText.isEmpty || entry.cardName.localizedCaseInsensitiveContains(searchText)
            return matchesTCG && matchesSearch
        }
    }
    
    var filteredCards: [RadarUserCard] {
        let list = user.cards ?? []
        return list.filter { entry in
            let matchesTCG = selectedTCGType == nil || entry.tcgType == selectedTCGType
            let matchesSearch = searchText.isEmpty || entry.cardName.localizedCaseInsensitiveContains(searchText)
            return matchesTCG && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Hidden Link
            chatNavigationLink
            
            // Header (Always visible)
            headerView
            
            if isExpanded {
                VStack(spacing: 12) {
                    // Search & Filters
                    searchAndFilters
                    
                    // Tab Picker
                    tabPicker
                    
                    // Content
                    contentView
                        .frame(maxHeight: 300)
                }
                .padding(.top, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .animation(.spring(), value: isExpanded)
    }
    
    private var headerView: some View {
        HStack {
            if let urlString = user.profileImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    SwiftUI.Image(systemName: "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        SwiftUI.Image(systemName: "person.fill")
                            .foregroundColor(.purple)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.headline)
                    .blur(radius: 4) // Obfuscate for privacy as requested
                Text(user.favoriteTCG?.displayName ?? "Allenatore")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation { isExpanded.toggle() }
                }) {
                    SwiftUI.Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.gray.opacity(0.3))
                }
            }
        }
    }
    
    // Hidden Navigation Link
    private var chatNavigationLink: some View {
        NavigationLink(isActive: $isChatActive) {
            if let conv = activeConversation {
                ChatDetailView(conversation: conv, currentUserId: Int64(authService.currentUserId ?? 0))
                    .environmentObject(authService)
            }
        } label: { EmptyView() }
    }
    
    private var searchAndFilters: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                SwiftUI.Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Cerca carta...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // TCG Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterBadge(title: "Tutti", isSelected: selectedTCGType == nil) {
                        selectedTCGType = nil
                    }
                    
                    ForEach(TCGType.allCases) { type in
                        FilterBadge(title: type.displayName, isSelected: selectedTCGType == type) {
                            selectedTCGType = type
                        }
                    }
                }
            }
        }
    }
    
    private var tabPicker: some View {
        HStack(spacing: 0) {
            MapTabButton(title: "CERCO", isSelected: selectedTab == 0) { selectedTab = 0 }
            MapTabButton(title: "OFFRO", isSelected: selectedTab == 1) { selectedTab = 1 }
            MapTabButton(title: "CARTE", isSelected: selectedTab == 2) { selectedTab = 2 }
        }
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal, 4)
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 8) {
                if selectedTab == 0 {
                    if filteredWantList.isEmpty {
                        emptyState(text: "Nessuna carta trovata")
                    } else {
                        ForEach(filteredWantList) { entry in
                            cardRow(name: entry.cardName, sub: entry.rarity ?? "", imageUrl: entry.imageUrl, tcg: entry.tcgType)
                        }
                    }
                } else if selectedTab == 1 {
                    if filteredHaveList.isEmpty {
                        emptyState(text: "Nessuna carta trovata")
                    } else {
                        ForEach(filteredHaveList) { entry in
                            cardRow(name: entry.cardName, sub: entry.rarity ?? "", imageUrl: entry.imageUrl, tcg: entry.tcgType)
                        }
                    }
                } else {
                    if filteredCards.isEmpty {
                        emptyState(text: "Nessuna carta trovata")
                    } else {
                        ForEach(filteredCards) { card in
                            cardRow(name: card.cardName, sub: "\(card.setName ?? "") • Qty: \(card.quantity)", imageUrl: card.imageUrl, tcg: card.tcgType)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    private func cardRow(name: String, sub: String, imageUrl: String?, tcg: TCGType?) -> some View {
        HStack(spacing: 12) {
            if let urlString = imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Color.gray.opacity(0.1)
                }
                .frame(width: 40, height: 56)
                .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 56)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let tcg = tcg {
                        Text(tcg.displayName)
                            .font(.system(size: 10))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(tcg.themeColor.opacity(0.1))
                            .foregroundColor(tcg.themeColor)
                            .cornerRadius(4)
                    }
                    
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Chat Button
            Button(action: {
                startChat(cardName: name)
            }) {
                SwiftUI.Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(8)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(10)
    }
    
    private func startChat(cardName: String) {
        let typeString = selectedTab == 0 ? "Cerco" : (selectedTab == 1 ? "Offro" : "Collezione")
        let context = "\(typeString): \(cardName)"
        
        chatService.startChat(targetUserId: user.id, type: .trade, context: context) { conversation in
             DispatchQueue.main.async {
                 if let conv = conversation {
                     self.activeConversation = conv
                     self.isChatActive = true
                 }
             }
        }
    }
    
    private func emptyState(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
    }
}

struct FilterBadge: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct MapTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.white : Color.clear)
                .foregroundColor(isSelected ? .primary : .secondary)
                .cornerRadius(8)
                .shadow(color: isSelected ? Color.black.opacity(0.1) : Color.clear, radius: 2)
        }
        .padding(2)
    }
}
