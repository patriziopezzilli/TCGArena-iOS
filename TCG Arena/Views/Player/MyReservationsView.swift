//
//  MyReservationsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct MyReservationsView: View {
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFilter: ReservationFilter = .active
    @State private var selectedReservation: Reservation?
    @State private var isLoading = false
    
    enum ReservationFilter: String, CaseIterable {
        case active = "Attive"
        case history = "Storico"
        
        var statuses: [Reservation.ReservationStatus] {
            switch self {
            case .active:
                return [.pending]  // Only pending is "active" - validated means ready for pickup (past)
            case .history:
                return [.validated, .pickedUp, .expired, .cancelled]  // Validated goes to history
            }
        }
        
        var icon: String {
            switch self {
            case .active: return "clock.badge.checkmark"
            case .history: return "clock.arrow.circlepath"
            }
        }
    }
    
    var filteredReservations: [Reservation] {
        reservationService.reservations.filter { reservation in
            selectedFilter.statuses.contains(reservation.status)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Filter Tabs
            filterTabsView
            
            // Content
            if isLoading {
                loadingView
            } else if filteredReservations.isEmpty {
                emptyStateView
            } else {
                reservationsListView
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Le mie Prenotazioni")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Chiudi") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(item: $selectedReservation) { reservation in
            ReservationQRView(reservation: reservation)
                .environmentObject(reservationService)
        }
        .onAppear {
            loadReservations()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prenotazioni")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(reservationService.reservations.count) totali • \(reservationService.activeReservations.count) attive")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh button
                Button(action: { loadReservations() }) {
                    SwiftUI.Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.orange)
                        )
                        .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Filter Tabs
    private var filterTabsView: some View {
        HStack(spacing: 12) {
            ForEach(ReservationFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedFilter = filter
                    }
                }) {
                    HStack(spacing: 8) {
                        SwiftUI.Image(systemName: filter.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(filter.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(selectedFilter == filter ? .white : .primary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(selectedFilter == filter ? Color.orange : Color(.systemGray5))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Caricamento...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                SwiftUI.Image(systemName: selectedFilter == .active ? "qrcode.viewfinder" : "clock.arrow.circlepath")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 8) {
                Text(selectedFilter == .active ? "Nessuna Prenotazione Attiva" : "Nessuno Storico")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(selectedFilter == .active ?
                    "Prenota carte dai negozi per vederle qui" :
                    "Le prenotazioni completate appariranno qui")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Reservations List
    private var reservationsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredReservations) { reservation in
                    ReservationCardView(reservation: reservation) {
                        selectedReservation = reservation
                    }
                }
            }
            .padding(20)
        }
        .refreshable {
            await refreshReservations()
        }
    }
    
    // MARK: - Actions
    private func loadReservations() {
        isLoading = true
        Task {
            await reservationService.loadUserReservations()
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func refreshReservations() async {
        await reservationService.loadUserReservations()
    }
}

// MARK: - Reservation Card View (Redesigned)
struct ReservationCardView: View {
    let reservation: Reservation
    let onTap: () -> Void
    
    private var statusColor: Color {
        switch reservation.status {
        case .pending: return .orange
        case .validated: return .blue
        case .pickedUp: return .green
        case .expired: return .gray
        case .cancelled: return .red
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Main content
                HStack(spacing: 16) {
                    // Status indicator
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(statusColor.opacity(0.15))
                            .frame(width: 56, height: 72)
                        
                        VStack(spacing: 6) {
                            SwiftUI.Image(systemName: reservation.status.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(statusColor)
                            
                            Text(reservation.status == .pending ? "QR" : "")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(statusColor)
                        }
                    }
                    
                    // Card info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reservation.displayCardName)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if let cardSet = reservation.displayCardSet {
                            Text(cardSet)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 8) {
                            // Shop name
                            HStack(spacing: 4) {
                                SwiftUI.Image(systemName: "storefront")
                                    .font(.system(size: 11))
                                Text(reservation.displayShopName)
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        }
                        
                        // Status badge
                        HStack(spacing: 8) {
                            Text(reservation.status.displayName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(statusColor)
                                )
                            
                            if reservation.status == .pending {
                                let timeRemaining = reservation.timeRemaining
                                HStack(spacing: 4) {
                                    SwiftUI.Image(systemName: "clock.fill")
                                        .font(.system(size: 10))
                                    Text(reservation.formattedTimeRemaining)
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(timeRemaining < 600 ? .red : .orange)
                            }
                            
                            Spacer()
                            
                            // Created date
                            Text(formattedDate(reservation.createdAt))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Chevron
                    SwiftUI.Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(16)
                
                // Action hint for active reservations
                if reservation.status == .pending || reservation.status == .validated {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    HStack {
                        SwiftUI.Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 14))
                        Text("Tocca per mostrare il QR Code")
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                    }
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(statusColor.opacity(0.05))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}

// MARK: - Reservation QR View (Redesigned)
struct ReservationQRView: View {
    @EnvironmentObject var reservationService: ReservationService
    @Environment(\.dismiss) var dismiss
    
    let reservation: Reservation
    
    @State private var showCancelConfirmation = false
    @State private var isCancelling = false
    
    private var statusColor: Color {
        switch reservation.status {
        case .pending: return .orange
        case .validated: return .blue
        case .pickedUp: return .green
        case .expired: return .gray
        case .cancelled: return .red
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Header
                    statusHeaderView
                    
                    // QR Code Section
                    if reservation.status == .pending || reservation.status == .validated {
                        qrCodeSectionView
                    }
                    
                    // Card Details
                    cardDetailsSectionView
                    
                    // Shop Info
                    shopInfoSectionView
                    
                    // Cancel button
                    if reservation.canBeCancelled {
                        cancelButtonView
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Annulla Prenotazione", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
                Button("Annulla Prenotazione", role: .destructive) {
                    cancelReservation()
                }
                Button("Mantieni", role: .cancel) {}
            } message: {
                Text("Sei sicuro di voler annullare questa prenotazione?")
            }
        }
    }
    
    // MARK: - Status Header
    private var statusHeaderView: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(reservation.status.displayName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                if reservation.status == .pending {
                    let timeRemaining = reservation.timeRemaining
                    VStack(spacing: 4) {
                        Text("Tempo Rimanente")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Text(reservation.formattedTimeRemaining)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(timeRemaining < 600 ? .red : statusColor)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - QR Code Section
    private var qrCodeSectionView: some View {
        VStack(spacing: 16) {
            HStack {
                SwiftUI.Image(systemName: "qrcode")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(statusColor)
                Text("Mostra questo QR al negozio")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if let qrImage = generateQRCode(from: reservation.qrCode) {
                SwiftUI.Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            
            Text(reservation.qrCode)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Card Details Section
    private var cardDetailsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SwiftUI.Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.purple)
                Text("Dettagli Carta")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                detailRow(label: "Nome", value: reservation.displayCardName)
                
                if let cardSet = reservation.displayCardSet {
                    detailRow(label: "Set", value: cardSet)
                }
                
                if let rarity = reservation.cardRarity {
                    detailRow(label: "Rarità", value: rarity.capitalized)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Shop Info Section
    private var shopInfoSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SwiftUI.Image(systemName: "storefront.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
                Text("Negozio")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(reservation.displayShopName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                
                if !reservation.displayShopLocation.isEmpty {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                        Text(reservation.displayShopLocation)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Cancel Button
    private var cancelButtonView: some View {
        Button(action: { showCancelConfirmation = true }) {
            HStack {
                if isCancelling {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    SwiftUI.Image(systemName: "xmark.circle.fill")
                    Text("Annulla Prenotazione")
                }
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red)
            )
        }
        .disabled(isCancelling)
    }
    
    // MARK: - Helpers
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary)
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
    
    private func cancelReservation() {
        isCancelling = true
        
        Task {
            do {
                try await reservationService.cancelReservation(id: reservation.id)
                await MainActor.run {
                    isCancelling = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCancelling = false
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        MyReservationsView()
            .environmentObject(ReservationService())
            .environmentObject(AuthService())
    }
}
