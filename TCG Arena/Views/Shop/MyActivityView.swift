//
//  MyActivityView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/17/25.
//
//  Shows user's reservations and requests in the Shops tab.
//

import SwiftUI

struct MyActivityView: View {
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedSegment: ActivitySegment = .reservations
    @State private var isLoading = false
    
    enum ActivitySegment: String, CaseIterable {
        case reservations = "Prenotazioni"
        case requests = "Richieste"
        
        var icon: String {
            switch self {
            case .reservations: return "qrcode"
            case .requests: return "bubble.left.and.bubble.right.fill"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Control
            segmentedControl
            
            // Content
            if isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadData()
        }
    }
    
    // MARK: - Segmented Control
    private var segmentedControl: some View {
        HStack(spacing: 12) {
            ForEach(ActivitySegment.allCases, id: \.self) { segment in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedSegment = segment
                    }
                } label: {
                    HStack(spacing: 8) {
                        SwiftUI.Image(systemName: segment.icon)
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text(segment.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                        
                        // Badge count
                        if segment == .reservations && activeReservationsCount > 0 {
                            Text("\(activeReservationsCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue))
                        } else if segment == .requests && activeRequestsCount > 0 {
                            Text("\(activeRequestsCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange))
                        }
                    }
                    .foregroundColor(selectedSegment == segment ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedSegment == segment ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch selectedSegment {
        case .reservations:
            reservationsContent
        case .requests:
            requestsContent
        }
    }
    
    // MARK: - Reservations Content
    private var reservationsContent: some View {
        Group {
            if reservationService.reservations.isEmpty {
                emptyStateView(
                    icon: "qrcode.viewfinder",
                    title: "Nessuna Prenotazione",
                    subtitle: "Le tue prenotazioni di carte appariranno qui."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(reservationService.reservations) { reservation in
                            ActivityReservationCard(reservation: reservation)
                        }
                    }
                    .padding(20)
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
    }
    
    // MARK: - Requests Content
    private var requestsContent: some View {
        Group {
            if requestService.requests.isEmpty {
                emptyStateView(
                    icon: "bubble.left.and.bubble.right",
                    title: "Nessuna Richiesta",
                    subtitle: "Le tue richieste ai negozi appariranno qui."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(requestService.requests) { request in
                            ActivityRequestCard(request: request)
                        }
                    }
                    .padding(20)
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
    }
    
    // MARK: - Subviews
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Caricamento...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 100)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Helpers
    private var activeReservationsCount: Int {
        reservationService.reservations.filter { $0.isActive }.count
    }
    
    private var activeRequestsCount: Int {
        requestService.requests.filter { $0.status == .pending || $0.status == .accepted }.count
    }
    
    private func loadData() {
        guard authService.isAuthenticated, let userId = authService.currentUserId else { return }
        isLoading = true
        
        Task {
            await reservationService.loadUserReservations()
            do {
                _ = try await requestService.getUserRequests(userId: String(userId))
            } catch {
                // Handle silently
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func refreshData() async {
        await reservationService.loadUserReservations()
        if let userId = authService.currentUserId {
            _ = try? await requestService.getUserRequests(userId: String(userId))
        }
    }
}

// MARK: - Activity Reservation Card
private struct ActivityReservationCard: View {
    let reservation: Reservation
    @State private var showingQR = false
    
    var body: some View {
        Button {
            showingQR = true
        } label: {
            HStack(spacing: 16) {
                // Status indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(statusColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    SwiftUI.Image(systemName: statusIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(statusColor)
                }
                
                // Card Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.card?.name ?? "Carta")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(reservation.shop?.name ?? "Negozio")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(reservation.status.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(timeRemaining)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // QR Icon
                SwiftUI.Image(systemName: "qrcode")
                    .font(.system(size: 24))
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingQR) {
            ReservationQRView(reservation: reservation)
        }
    }
    
    private var statusColor: Color {
        switch reservation.status {
        case .pending: return .orange
        case .validated: return .green
        case .pickedUp: return .blue
        case .expired, .cancelled: return .red
        default: return .gray
        }
    }
    
    private var statusIcon: String {
        switch reservation.status {
        case .pending: return "clock.fill"
        case .validated: return "checkmark.circle.fill"
        case .pickedUp: return "bag.fill"
        case .expired: return "exclamationmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private var timeRemaining: String {
        if reservation.status == .pending {
            let remaining = reservation.expiresAt.timeIntervalSinceNow
            if remaining > 0 {
                let hours = Int(remaining / 3600)
                let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
                if hours > 0 {
                    return "Scade tra \(hours)h \(minutes)m"
                } else {
                    return "Scade tra \(minutes) min"
                }
            } else {
                return "Scaduta"
            }
        } else {
            return reservation.createdAt.formatted(date: .abbreviated, time: .omitted)
        }
    }
}

// MARK: - Request Card
private struct ActivityRequestCard: View {
    let request: CustomerRequest
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: 16) {
                // Type indicator
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    SwiftUI.Image(systemName: request.type.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(typeColor)
                }
                
                // Request Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(request.shopName ?? "Negozio")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(request.status.displayName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(statusColor)
                        
                        if request.hasUnreadMessages {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                
                Spacer()
                
                // Chevron
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            NavigationView {
                PlayerRequestDetailView(request: request) {
                    // Refresh callback
                }
            }
        }
    }
    
    private var typeColor: Color {
        Color(request.type.color)
    }
    
    private var statusColor: Color {
        switch request.status {
        case .pending: return .orange
        case .accepted: return .blue
        case .completed: return .green
        case .rejected, .cancelled: return .red
        }
    }
}

#Preview {
    NavigationView {
        MyActivityView()
            .environmentObject(ReservationService())
            .environmentObject(RequestService())
            .environmentObject(AuthService())
    }
}
