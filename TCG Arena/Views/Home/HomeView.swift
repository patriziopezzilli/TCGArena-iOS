
import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var viewModel = HomeDashboardService()
    @StateObject private var locationManager = LocationManager()
    @State private var hasAppeared = false
    
    // Grid layout
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background - Clean and minimal
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // MARK: - Header Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("TCG Arena")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(2)
                                Spacer()
                                // Profile Icon Helper
                                Button(action: { selectedTab = 4 }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(.secondarySystemBackground))
                                            .frame(width: 40, height: 40)
                                        SwiftUI.Image(systemName: "person.fill")
                                            .foregroundColor(.primary)
                                            .font(.system(size: 16))
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Il tuo mondo TCG,")
                                    .font(.system(size: 32, weight: .heavy, design: .default))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text("in un tocco.")
                                    .font(.system(size: 32, weight: .heavy, design: .default))
                                    .foregroundColor(Color(UIColor.label).opacity(0.4)) // Subtle secondary text
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // MARK: - Discover Card (New CTA)
                        Button(action: { selectedTab = 1 }) { // Go to Collection
                            HStack {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Scopri Nuove Carte")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Esplora le ultime espansioni e trova le carte perfette per il tuo mazzo.")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack {
                                        Text("Esplora ora")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.black)
                                        SwiftUI.Image(systemName: "arrow.right")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.black)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .cornerRadius(20)
                                    .padding(.top, 4)
                                }
                                Spacer()
                                // Decorative Icon
                                SwiftUI.Image(systemName: "sparkles.rectangle.stack.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.white.opacity(0.2))
                                    .rotationEffect(.degrees(-15))
                                    .offset(x: 10, y: 10)
                            }
                            .padding(24)
                            .background(Color.black) // Premium Black styling
                            .cornerRadius(24)
                            // Subtle shadow
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                        
                        
                        // MARK: - Dashboard Grid
                        if let data = viewModel.dashboardData {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Panoramica")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal, 24)
                                
                                LazyVGrid(columns: columns, spacing: 16) {
                                    // Shows large numbers, minimal text
                                    StatTile(
                                        value: "\(data.nearbyShopsCount)",
                                        label: "Negozi Vicini",
                                        icon: "storefront.fill"
                                    ) { selectedTab = 2 }
                                    
                                    StatTile(
                                        value: "\(data.upcomingTournamentsCount)",
                                        label: "Tornei",
                                        icon: "trophy.fill"
                                    ) { selectedTab = 2 }
                                    
                                    StatTile(
                                        value: "\(data.collectionCount)",
                                        label: "Collezione",
                                        icon: "rectangle.stack.fill"
                                    ) { selectedTab = 1 }
                                    
                                    StatTile(
                                        value: "\(data.deckCount)",
                                        label: "Decks",
                                        icon: "rectangle.stack.badge.plus"
                                    ) { selectedTab = 1 }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // MARK: - News Carousel
                            NewsCarouselSection()
                            
                            // MARK: - Actions (Reservations / Requests)
                            if data.pendingReservationsCount > 0 || data.activeRequestsCount > 0 {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Attività")
                                        .font(.system(size: 20, weight: .bold))
                                        .padding(.horizontal, 24)
                                    
                                    VStack(spacing: 12) {
                                        if data.pendingReservationsCount > 0 {
                                            MinimalActionRow(
                                                title: "Prenotazioni da ritirare",
                                                count: data.pendingReservationsCount,
                                                icon: "bag.fill",
                                                color: .orange
                                            ) { selectedTab = 4 }
                                        }
                                        
                                        if data.activeRequestsCount > 0 {
                                            MinimalActionRow(
                                                title: "Richieste aperte",
                                                count: data.activeRequestsCount,
                                                icon: "bubble.left.and.bubble.right.fill",
                                                color: .blue
                                            ) { selectedTab = 4 }
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                            
                        } else if viewModel.isLoading {
                            // MARK: - Skeleton Loading State
                            VStack(alignment: .leading, spacing: 16) {
                                // Skeleton Header
                                Text("Panoramica")
                                    .font(.system(size: 20, weight: .bold))
                                    .padding(.horizontal, 24)
                                
                                // Skeleton Grid
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(0..<4) { _ in
                                        SkeletonStatTile()
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                // Skeleton News Section
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("News")
                                        .font(.system(size: 20, weight: .bold))
                                        .padding(.horizontal, 24)
                                    
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.secondarySystemBackground))
                                        .frame(height: 120)
                                        .padding(.horizontal, 24)
                                        .shimmering()
                                }
                                .padding(.top, 16)
                            }
                        } else {
                            // Error State
                             VStack(spacing: 12) {
                                SwiftUI.Image(systemName: "exclamationmark.triangle")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Nessun dato")
                                    .font(.headline)
                                Button("Ricarica") {
                                    viewModel.fetchDashboardData(
                                        latitude: locationManager.location?.coordinate.latitude,
                                        longitude: locationManager.location?.coordinate.longitude
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if !hasAppeared {
                    locationManager.requestLocationPermission()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.fetchDashboardData(
                            latitude: locationManager.location?.coordinate.latitude,
                            longitude: locationManager.location?.coordinate.longitude
                        )
                    }
                    hasAppeared = true
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.maximumFractionDigits = 0 // Clean look, no cents for large values if possible? Or keep for precision.
        return formatter.string(from: value as NSNumber) ?? "€0"
    }
}

// MARK: - Premium Minimum Components

struct StatTile: View {
    let value: String
    let label: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.primary.opacity(0.7))
                    Spacer()
                    SwiftUI.Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .padding(.bottom, 16)
                
                Text(value)
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(24) // Soft rounded corners
            // Very subtle border instead of heavy shadow
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MinimalActionRow: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 48, height: 48)
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(count) aggiornamenti")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Skeleton Loading Components

struct SkeletonStatTile: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 24, height: 24)
                Spacer()
            }
            .padding(.bottom, 16)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
                .frame(width: 60, height: 28)
            
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.tertiarySystemBackground))
                .frame(width: 80, height: 14)
                .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(.separator).opacity(0.4), lineWidth: 0.5)
        )
        .shimmering()
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.white.opacity(0.3)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.clear, .white.opacity(0.5), .clear]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .rotationEffect(.degrees(70))
                                .offset(x: isAnimating ? geometry.size.width * 2 : -geometry.size.width * 2)
                        )
                }
            )
            .clipped()
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
