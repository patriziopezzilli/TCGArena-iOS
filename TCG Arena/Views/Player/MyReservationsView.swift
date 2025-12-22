//
//  MyReservationsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//  Redesigned with Home-style minimal aesthetic
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
                return [.pending]
            case .history:
                return [.validated, .pickedUp, .expired, .cancelled]
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
            
            Divider()
            
            // Content
            if isLoading {
                loadingView
            } else if filteredReservations.isEmpty {
                emptyStateView
            } else {
                reservationsListView
            }
        }
        .background(Color(.systemBackground))
        .sheet(item: $selectedReservation) { reservation in
            MinimalReservationDetailView(reservation: reservation)
                .environmentObject(reservationService)
        }
        .onAppear {
            loadReservations()
        }
    }
    
    // MARK: - Header View (Minimal Style)
    private var headerView: some View {
        VStack(spacing: 20) {
            // Title row with close button
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Prenotazioni")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.primary)
                    
                    Text("\(reservationService.reservations.count) totali")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh button
                Button(action: { loadReservations() }) {
                    SwiftUI.Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                        )
                }
                
                // Close button
                Button(action: { dismiss() }) {
                    SwiftUI.Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(.secondarySystemBackground))
                        )
                }
            }
            
            // Filter tabs (minimal style)
            HStack(spacing: 0) {
                ForEach(ReservationFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(filter.rawValue)
                                .font(.system(size: 15, weight: selectedFilter == filter ? .semibold : .regular))
                                .foregroundColor(selectedFilter == filter ? .primary : .secondary)
                            
                            Rectangle()
                                .fill(selectedFilter == filter ? Color.primary : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Caricamento...")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Empty State (Centered Style)
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon with subtle background
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 100, height: 100)
                
                SwiftUI.Image(systemName: selectedFilter == .active ? "qrcode.viewfinder" : "clock.arrow.circlepath")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text(selectedFilter == .active ? "Nessuna prenotazione attiva" : "Nessuno storico")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(selectedFilter == .active ?
                    "Prenota carte dai negozi per vederle qui." :
                    "Le prenotazioni completate appariranno qui.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Reservations List (Minimal Style)
    private var reservationsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredReservations) { reservation in
                    MinimalReservationRow(reservation: reservation) {
                        selectedReservation = reservation
                    }
                    
                    if reservation.id != filteredReservations.last?.id {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
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

// MARK: - Minimal Reservation Row
struct MinimalReservationRow: View {
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
            HStack(spacing: 16) {
                // Card image or placeholder
                if let imageURL = reservation.fullImageURL, let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 56, height: 78)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            cardPlaceholder
                        }
                    }
                } else {
                    cardPlaceholder
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Card name
                    Text(reservation.displayCardName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Shop name
                    Text(reservation.displayShopName)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    // Status and time
                    HStack(spacing: 8) {
                        Text(reservation.status.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                        
                        if reservation.status == .pending {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(reservation.formattedTimeRemaining)
                                .font(.system(size: 12))
                                .foregroundColor(reservation.timeRemaining < 600 ? .red : .secondary)
                        }
                        
                        Spacer()
                        
                        Text(formattedDate(reservation.createdAt))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Chevron
                SwiftUI.Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(.secondarySystemBackground))
            .frame(width: 56, height: 78)
            .overlay(
                SwiftUI.Image(systemName: "rectangle.stack")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            )
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "it_IT")
        return formatter.string(from: date)
    }
}

// MARK: - Minimal Reservation Detail View
struct MinimalReservationDetailView: View {
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
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // QR Code Section (for active reservations)
                    if reservation.status == .pending || reservation.status == .validated {
                        qrCodeSection
                        
                        Divider()
                            .padding(.horizontal, 20)
                    }
                    
                    // Card Details
                    cardDetailsSection
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Shop Info
                    shopInfoSection
                    
                    // Cancel button
                    if reservation.canBeCancelled {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        cancelSection
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
        .confirmationDialog("Annulla Prenotazione", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
            Button("Annulla Prenotazione", role: .destructive) {
                cancelReservation()
            }
            Button("Mantieni", role: .cancel) {}
        } message: {
            Text("Sei sicuro di voler annullare questa prenotazione?")
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dettaglio")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(reservation.status.displayName)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Close button
            Button(action: { dismiss() }) {
                SwiftUI.Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(.secondarySystemBackground))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - QR Code Section
    private var qrCodeSection: some View {
        VStack(spacing: 20) {
            // Time remaining (for pending)
            if reservation.status == .pending {
                VStack(spacing: 4) {
                    Text("Tempo rimanente")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(reservation.formattedTimeRemaining)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(reservation.timeRemaining < 600 ? .red : .primary)
                }
            }
            
            // QR Code
            if let qrImage = generateQRCode(from: reservation.qrCode) {
                VStack(spacing: 12) {
                    SwiftUI.Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator), lineWidth: 1)
                        )
                    
                    Text("Mostra al negozio")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text(reservation.qrCode)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Card Details Section
    private var cardDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Carta")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 16) {
                // Card image
                if let imageURL = reservation.fullImageURL, let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 70, height: 98)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        default:
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.secondarySystemBackground))
                                .frame(width: 70, height: 98)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(reservation.displayCardName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let cardSet = reservation.displayCardSet {
                        Text(cardSet)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    if let rarity = reservation.cardRarity {
                        Text(rarity.capitalized)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
    }
    
    // MARK: - Shop Info Section
    private var shopInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Negozio")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(reservation.displayShopName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                if !reservation.displayShopLocation.isEmpty {
                    HStack(spacing: 6) {
                        SwiftUI.Image(systemName: "mappin")
                            .font(.system(size: 12))
                        Text(reservation.displayShopLocation)
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
    
    // MARK: - Cancel Section
    private var cancelSection: some View {
        Button(action: { showCancelConfirmation = true }) {
            HStack {
                if isCancelling {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Annulla prenotazione")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .disabled(isCancelling)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
    
    // MARK: - Helpers
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
    MyReservationsView()
        .environmentObject(ReservationService())
        .environmentObject(AuthService())
}
