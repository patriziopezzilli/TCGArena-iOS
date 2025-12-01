//
//  ReservationListView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct ReservationListView: View {
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedStatus: ReservationStatus?
    @State private var showQRScanner = false
    @State private var selectedReservation: Reservation?
    
    var filteredReservations: [Reservation] {
        guard let status = selectedStatus else {
            return reservationService.merchantReservations
        }
        return reservationService.merchantReservations.filter { $0.status == status }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with QR Scan Button
            HStack {
                Text("\(filteredReservations.count) Reservations")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showQRScanner = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scan QR")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AdaptiveColors.brandPrimary)
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Status Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    StatusFilterButton(
                        title: "All",
                        count: reservationService.merchantReservations.count,
                        isSelected: selectedStatus == nil
                    ) {
                        selectedStatus = nil
                    }
                    
                    ForEach([ReservationStatus.pending, .validated, .pickedUp, .expired, .cancelled], id: \.self) { status in
                        let count = reservationService.merchantReservations.filter { $0.status == status }.count
                        StatusFilterButton(
                            title: status.displayName,
                            count: count,
                            isSelected: selectedStatus == status,
                            color: Color(status.color)
                        ) {
                            selectedStatus = status
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(AdaptiveColors.backgroundSecondary)
            
            Divider()
            
            // Reservations List
            if filteredReservations.isEmpty {
                EmptyStateView(
                    icon: "qrcode.viewfinder",
                    title: selectedStatus == nil ? "No Reservations" : "No \(selectedStatus!.displayName) Reservations",
                    message: "Customer reservations will appear here"
                )
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredReservations) { reservation in
                            ReservationRow(reservation: reservation) {
                                selectedReservation = reservation
                            }
                        }
                    }
                    .padding(20)
                }
            }
        }
        .background(AdaptiveColors.backgroundPrimary)
        .sheet(isPresented: $showQRScanner) {
            QRScannerView { code in
                handleQRCode(code)
            }
        }
        .sheet(item: $selectedReservation) { reservation in
            ReservationDetailView(reservation: reservation)
        }
        .onAppear {
            loadReservations()
        }
    }
    
    private func loadReservations() {
        guard let shopId = authService.currentUser?.shopId else { return }
        
        Task {
            await reservationService.loadMerchantReservations(shopId: shopId)
        }
    }
    
    private func handleQRCode(_ code: String) {
        // Validate QR code
        Task {
            do {
                try await reservationService.validateReservation(code: code)
                // Show success and load reservation details
                if let reservation = reservationService.merchantReservations.first(where: { $0.qrCode == code }) {
                    selectedReservation = reservation
                }
            } catch {
                // Show error
            }
        }
    }
}

// MARK: - Status Filter Button
struct StatusFilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    var color: Color = AdaptiveColors.brandPrimary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Reservation Row
struct ReservationRow: View {
    let reservation: Reservation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Card Image
                    if let imageUrl = reservation.card?.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(AdaptiveColors.backgroundSecondary)
                        }
                        .frame(width: 60, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Reservation Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reservation.card?.name ?? "Unknown Card")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 11))
                            
                            Text(reservation.user?.displayName ?? "Unknown User")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            // Status Badge
                            Text(reservation.status.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(reservation.status.color))
                                )
                            
                            // Time Info
                            if reservation.status == .pending {
                                if let timeRemaining = reservation.timeRemaining {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock.fill")
                                            .font(.system(size: 10))
                                        
                                        Text(reservation.formattedTimeRemaining)
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(timeRemaining < 600 ? AdaptiveColors.error : AdaptiveColors.warning)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Price
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(reservation.card?.formattedPrice ?? "€0.00")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AdaptiveColors.brandPrimary)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Quick Actions
                if reservation.status == .validated {
                    Divider()
                    
                    Button(action: { confirmPickup() }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Confirm Pickup")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(AdaptiveColors.success)
                        )
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AdaptiveColors.backgroundSecondary)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func confirmPickup() {
        // Implement pickup confirmation
    }
}

#Preview {
    ReservationListView()
        .environmentObject(ReservationService())
        .environmentObject(AuthService())
}
