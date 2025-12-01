//
//  TournamentMapView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct TournamentMapView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900), // Milano center
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedTournament: Tournament?
    @State private var showingTournamentDetail = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Full screen map
            Map(coordinateRegion: $region, annotationItems: tournamentService.nearbyTournaments) { tournament in
                MapAnnotation(coordinate: tournament.location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)) {
                    TournamentMapPin(tournament: tournament) {
                        selectedTournament = tournament
                        showingTournamentDetail = true
                    }
                }
            }
            .ignoresSafeArea()
            
            // Top controls overlay
            VStack {
                HStack {
                    Spacer()
                    
                    Button(action: {
                        locationManager.requestLocationPermission()
                    }) {
                        SwiftUI.Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
            }
            
            // Bottom tournament slider
            VStack(spacing: 0) {
                // Subtle handle
                Capsule()
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(tournamentService.nearbyTournaments) { tournament in
                            MinimalTournamentCard(
                                tournament: tournament,
                                isSelected: selectedTournament?.id == tournament.id,
                                onTap: {
                                    selectedTournament = tournament
                                    if let coordinate = tournament.location?.coordinate {
                                        withAnimation(.easeInOut(duration: 0.5)) {
                                            region.center = coordinate
                                        }
                                    }
                                },
                                onDetailTap: {
                                    selectedTournament = tournament
                                    showingTournamentDetail = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(
                Rectangle()
                    .fill(Color.white.opacity(0.95))
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .task {
            await tournamentService.loadTournaments()
            
            // Always load nearby tournaments regardless of user location for mock data
            if let userLocation = locationManager.location {
                await tournamentService.loadNearbyTournaments(userLocation: userLocation)
                region.center = userLocation.coordinate
            } else {
                // Load nearby tournaments with Milano center for demo
                let milanCenter = CLLocation(latitude: 45.4642, longitude: 9.1900)
                await tournamentService.loadNearbyTournaments(userLocation: milanCenter)
            }
        }
        .sheet(item: $selectedTournament) { tournament in
            TournamentMapDetailView(tournament: tournament)
        }
    }
    
    private func centerOnUserLocation() {
        if let location = locationManager.location {
            withAnimation {
                region.center = location.coordinate
            }
        }
    }
}

// MARK: - Tournament Map Pin
struct TournamentMapPin: View {
    let tournament: Tournament
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 3)
                
                SwiftUI.Image(systemName: iconName)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .bold))
            }
        }
    }
    
    private var pinColor: Color {
        switch tournament.status {
        case .registrationOpen: return .green
        case .upcoming: return .blue
        case .registrationClosed: return .orange
        case .inProgress: return .purple
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
    
    private var iconName: String {
        switch tournament.tcgType {
        case .pokemon: return "p.circle.fill"
        case .magic: return "m.circle.fill"
        case .yugioh: return "y.circle.fill"
        case .onePiece: return "o.circle.fill"
        case .digimon: return "d.circle.fill"
        }
    }
}

// MARK: - Tournament List Bottom Sheet
struct TournamentListBottomSheet: View {
    let tournaments: [Tournament]
    let onTournamentSelect: (Tournament) -> Void
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            // Header
            HStack {
                Text("Nearby Tournaments")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(tournaments.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { 
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    SwiftUI.Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            
            if isExpanded {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tournaments) { tournament in
                            TournamentRowView(tournament: tournament) {
                                onTournamentSelect(tournament)
                                withAnimation(.spring()) {
                                    isExpanded = false
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .frame(maxHeight: 300)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
        .gesture(
            DragGesture()
                .onEnded { gesture in
                    withAnimation(.spring()) {
                        if gesture.translation.height > 50 {
                            isExpanded = false
                        } else if gesture.translation.height < -50 {
                            isExpanded = true
                        }
                    }
                }
        )
    }
}

// MARK: - Tournament Row View
struct TournamentRowView: View {
    let tournament: Tournament
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Tournament Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    SwiftUI.Image(systemName: "trophy")
                        .foregroundColor(statusColor)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                // Tournament Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    HStack {
                        Text(tournament.location?.venueName ?? "Unknown Location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(tournament.startDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                Text(tournament.status.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case .upcoming: return .blue
        case .registrationOpen: return .green
        case .registrationClosed: return .orange
        case .inProgress: return .purple
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

// MARK: - Minimal Tournament Card
struct MinimalTournamentCard: View {
    let tournament: Tournament
    let isSelected: Bool
    let onTap: () -> Void
    let onDetailTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with TCG type and status
                HStack {
                    // TCG Icon with bright color
                    ZStack {
                        Circle()
                            .fill(tcgColor(tournament.tcgType))
                            .frame(width: 32, height: 32)
                        
                        SwiftUI.Image(systemName: tcgIcon(tournament.tcgType))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Status dot
                    Circle()
                        .fill(statusColor)
                        .frame(width: 12, height: 12)
                }
                
                // Title and venue
                VStack(alignment: .leading, spacing: 6) {
                    Text(tournament.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(tournament.location?.venueName ?? "Unknown Location")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Date and entry fee
                HStack {
                    Text(DateFormatter.shortDate.string(from: tournament.startDate))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("€\(Int(tournament.entryFee))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(tcgColor(tournament.tcgType))
                }
                
                // Participants progress
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(tournament.participants.count)/\(tournament.maxParticipants)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button(action: onDetailTap) {
                            SwiftUI.Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(tcgColor(tournament.tcgType))
                        }
                    }
                    
                    // Clean progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tcgColor(tournament.tcgType))
                                .frame(
                                    width: geometry.size.width * (Double(tournament.currentParticipants) / Double(tournament.maxParticipants)),
                                    height: 6
                                )
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(16)
        }
        .frame(width: 260, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: isSelected ? tcgColor(tournament.tcgType).opacity(0.3) : Color.black.opacity(0.1),
                    radius: isSelected ? 12 : 6,
                    x: 0,
                    y: isSelected ? 6 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isSelected ? tcgColor(tournament.tcgType) : Color.clear,
                    lineWidth: 2
                )
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case .upcoming: return Color(red: 0.0, green: 0.7, blue: 1.0) // Bright Blue
        case .registrationOpen: return Color(red: 0.0, green: 1.0, blue: 0.4) // Bright Green
        case .registrationClosed: return Color(red: 1.0, green: 0.6, blue: 0.0) // Bright Orange
        case .inProgress: return Color(red: 1.0, green: 0.0, blue: 0.6) // Bright Pink
        case .completed: return Color.gray
        case .cancelled: return Color.red
        }
    }
    
    private func tcgIcon(_ tcgType: TCGType) -> String {
        switch tcgType {
        case .pokemon: return "bolt.fill"
        case .onePiece: return "sailboat.fill"
        case .magic: return "sparkles"
        case .yugioh: return "eye.fill"
        case .digimon: return "shield.fill"
        }
    }
    
    private func tcgColor(_ tcgType: TCGType) -> Color {
        switch tcgType {
        case .pokemon: return Color(red: 1.0, green: 0.9, blue: 0.0) // Bright Yellow
        case .onePiece: return Color(red: 0.0, green: 0.7, blue: 1.0) // Bright Blue
        case .magic: return Color(red: 1.0, green: 0.5, blue: 0.0) // Bright Orange
        case .yugioh: return Color(red: 0.8, green: 0.0, blue: 1.0) // Bright Purple
        case .digimon: return Color.cyan // Cyan
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        requestLocationPermission()
    }
    
    func requestLocationPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    TournamentMapView()
}
