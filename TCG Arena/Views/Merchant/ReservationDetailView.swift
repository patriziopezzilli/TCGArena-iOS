//
//  ReservationDetailView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct ReservationDetailView: View {
    @EnvironmentObject var reservationService: ReservationService
    @EnvironmentObject var inventoryService: InventoryService
    @Environment(\.dismiss) var dismiss
    
    let reservation: Reservation
    
    @State private var showConfirmPickup = false
    @State private var showCancelConfirmation = false
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Header
                    statusHeader
                    
                    // Card Details
                    cardDetails
                    
                    // Customer Info
                    customerInfo
                    
                    // Timeline
                    reservationTimeline
                    
                    // QR Code (if validated or pending)
                    if reservation.status == .pending || reservation.status == .validated {
                        qrCodeSection
                    }
                    
                    // Actions
                    if reservation.canBeValidated {
                        Button(action: { validateReservation() }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                Text("Validate Reservation")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.brandPrimary)
                            )
                        }
                        .disabled(isProcessing)
                    }
                    
                    if reservation.canBePickedUp {
                        Button(action: { showConfirmPickup = true }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Confirm Pickup")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.success)
                            )
                        }
                        .disabled(isProcessing)
                    }
                    
                    if reservation.canBeCancelled {
                        Button(action: { showCancelConfirmation = true }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Annulla Prenotazione")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AdaptiveColors.error)
                            )
                        }
                        .disabled(isProcessing)
                    }
                }
                .padding(20)
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("Reservation Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Confirm Pickup", isPresented: $showConfirmPickup, titleVisibility: .visible) {
                Button("Confirm") {
                    confirmPickup()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Has the customer picked up this card?")
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
    private var statusHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(reservation.status.color).opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: reservation.status.icon)
                    .font(.system(size: 36))
                    .foregroundColor(Color(reservation.status.color))
            }
            
            Text(reservation.status.displayName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            
            if reservation.status == .pending, let timeRemaining = reservation.timeRemaining {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                    Text(reservation.formattedTimeRemaining)
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(timeRemaining < 600 ? AdaptiveColors.error : AdaptiveColors.warning)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill((timeRemaining < 600 ? AdaptiveColors.error : AdaptiveColors.warning).opacity(0.1))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
    
    // MARK: - Card Details
    private var cardDetails: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card Details")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                // Card Image - Only show for non-expired reservations
                if reservation.status != .expired, let imageUrl = reservation.card?.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(AdaptiveColors.backgroundSecondary)
                    }
                    .frame(width: 80, height: 112) // Reduced from 100x140
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(reservation.card?.name ?? "Unknown Card")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let setName = reservation.card?.setName {
                        Text(setName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 8) {
                        if let tcgType = reservation.card?.tcgType {
                            Text(tcgType.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AdaptiveColors.brandPrimary))
                        }
                        
                        if let condition = reservation.card?.condition {
                            Text(condition.displayName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(condition.color)))
                        }
                    }
                    
                    Text(reservation.card?.formattedPrice ?? "€0.00")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AdaptiveColors.brandPrimary)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
    
    // MARK: - Customer Info
    private var customerInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customer Information")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                InfoRow(icon: "person.fill", title: "Nome", value: reservation.user?.displayName ?? "Sconosciuto")
                InfoRow(icon: "envelope.fill", title: "Email", value: reservation.user?.email ?? "Sconosciuto")
                InfoRow(icon: "phone.fill", title: "Telefono", value: reservation.user?.phone ?? "Non fornito")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
    
    // MARK: - Timeline
    private var reservationTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                TimelineItem(
                    title: "Created",
                    date: reservation.createdAt,
                    isCompleted: true
                )
                
                if let validatedAt = reservation.validatedAt {
                    TimelineItem(
                        title: "Validated",
                        date: validatedAt,
                        isCompleted: true
                    )
                }
                
                if let pickedUpAt = reservation.pickedUpAt {
                    TimelineItem(
                        title: "Picked Up",
                        date: pickedUpAt,
                        isCompleted: true
                    )
                }
                
                if let expiresAt = reservation.expiresAt, reservation.status == .pending {
                    TimelineItem(
                        title: "Expires",
                        date: expiresAt,
                        isCompleted: false,
                        isFuture: true
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
    
    // MARK: - QR Code Section
    private var qrCodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QR Code")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Generate and display QR code
                Image(systemName: "qrcode")
                    .font(.system(size: 100)) // Reduced from 120
                    .foregroundColor(AdaptiveColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20) // Reduced from 30
                
                Text(reservation.qrCode)
                    .font(.system(size: 16, weight: .mono, design: .monospaced))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AdaptiveColors.backgroundSecondary)
        )
    }
    
    // MARK: - Actions
    private func validateReservation() {
        isProcessing = true
        
        Task {
            do {
                let validatedReservation = try await reservationService.validateReservation(code: reservation.qrCode)
                
                // Update inventory quantity after successful validation
                try await inventoryService.updateQuantity(cardId: validatedReservation.cardId, delta: -1)
                
                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    ToastManager.shared.showError("Failed to validate reservation: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func confirmPickup() {
        isProcessing = true
        
        Task {
            do {
                try await reservationService.confirmPickup(reservationId: reservation.id)
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    ToastManager.shared.showError("Failed to confirm pickup: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func cancelReservation() {
        isProcessing = true
        
        Task {
            do {
                try await reservationService.cancelReservation(reservationId: reservation.id)
                await MainActor.run {
                    isProcessing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    ToastManager.shared.showError("Failed to cancel reservation: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AdaptiveColors.brandPrimary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Timeline Item
struct TimelineItem: View {
    let title: String
    let date: Date
    let isCompleted: Bool
    var isFuture: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? AdaptiveColors.success : (isFuture ? AdaptiveColors.warning : AdaptiveColors.backgroundPrimary))
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else if isFuture {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    ReservationDetailView(reservation: Reservation(
        id: "1",
        userId: "user1",
        cardId: "card1",
        shopId: "shop1",
        status: .validated,
        qrCode: "RES-12345",
        expiresAt: Date().addingTimeInterval(3600),
        createdAt: Date().addingTimeInterval(-1800),
        validatedAt: Date().addingTimeInterval(-900),
        pickedUpAt: nil,
        cancelledAt: nil
    ))
    .environmentObject(ReservationService())
}
