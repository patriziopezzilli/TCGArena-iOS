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
    
    @State private var selectedFilter: ReservationFilter = .active
    @State private var selectedReservation: Reservation?
    
    enum ReservationFilter: String, CaseIterable {
        case active = "Active"
        case history = "History"
        
        var statuses: [ReservationStatus] {
            switch self {
            case .active:
                return [.pending, .validated]
            case .history:
                return [.pickedUp, .expired, .cancelled]
            }
        }
    }
    
    var filteredReservations: [Reservation] {
        reservationService.userReservations.filter { reservation in
            selectedFilter.statuses.contains(reservation.status)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Tabs
                HStack(spacing: 0) {
                    ForEach(ReservationFilter.allCases, id: \.self) { filter in
                        Button(action: {
                            withAnimation {
                                selectedFilter = filter
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(filter.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedFilter == filter ? AdaptiveColors.brandPrimary : .secondary)
                                
                                Rectangle()
                                    .fill(selectedFilter == filter ? AdaptiveColors.brandPrimary : Color.clear)
                                    .frame(height: 3)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .background(AdaptiveColors.backgroundSecondary)
                
                Divider()
                
                // Reservations List
                if filteredReservations.isEmpty {
                    EmptyStateView(
                        icon: selectedFilter == .active ? "qrcode.viewfinder" : "clock.arrow.circlepath",
                        title: selectedFilter == .active ? "No Active Reservations" : "No History",
                        message: selectedFilter == .active ?
                            "Reserve cards from shops to see them here" :
                            "Your completed reservations will appear here"
                    )
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredReservations) { reservation in
                                MyReservationCard(reservation: reservation) {
                                    selectedReservation = reservation
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("My Reservations")
            .sheet(item: $selectedReservation) { reservation in
                ReservationQRView(reservation: reservation)
            }
            .onAppear {
                loadReservations()
            }
        }
    }
    
    private func loadReservations() {
        guard let userId = authService.currentUser?.id else { return }
        
        Task {
            await reservationService.loadUserReservations(userId: userId)
        }
    }
}

// MARK: - My Reservation Card
struct MyReservationCard: View {
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
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(reservation.card?.name ?? "Unknown Card")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(reservation.shop?.name ?? "Unknown Shop")
                            .font(.system(size: 13))
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
                            
                            // Timer for active reservations
                            if reservation.status == .pending, let timeRemaining = reservation.timeRemaining {
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
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(reservation.card?.formattedPrice ?? "€0.00")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AdaptiveColors.brandPrimary)
                        
                        if reservation.status == .pending || reservation.status == .validated {
                            Image(systemName: "qrcode")
                                .font(.system(size: 20))
                                .foregroundColor(AdaptiveColors.brandPrimary)
                        }
                    }
                }
                
                // Quick Actions
                if reservation.status == .pending {
                    Divider()
                    
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            HStack(spacing: 6) {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 14))
                                Text("Show QR Code")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AdaptiveColors.brandPrimary)
                            )
                        }
                        
                        if reservation.canBeCancelled {
                            Button(action: {}) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 14))
                                    Text("Cancel")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(AdaptiveColors.error)
                                .padding(.horizontal, 16)
                                .padding(.vertical: 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AdaptiveColors.error, lineWidth: 1.5)
                                )
                            }
                        }
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
}

// MARK: - Reservation QR View
struct ReservationQRView: View {
    @EnvironmentObject var reservationService: ReservationService
    @Environment(\.dismiss) var dismiss
    
    let reservation: Reservation
    
    @State private var showCancelConfirmation = false
    @State private var isCancelling = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Status Header
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
                            VStack(spacing: 4) {
                                Text("Time Remaining")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                
                                Text(reservation.formattedTimeRemaining)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(timeRemaining < 600 ? AdaptiveColors.error : AdaptiveColors.brandPrimary)
                            }
                        }
                    }
                    
                    // QR Code
                    if reservation.status == .pending || reservation.status == .validated {
                        VStack(spacing: 16) {
                            Text("Show this QR code at the shop")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            // Generate QR Code
                            if let qrImage = generateQRCode(from: reservation.qrCode) {
                                Image(uiImage: qrImage)
                                    .interpolation(.none)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 250, height: 250)
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.white)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            }
                            
                            Text(reservation.qrCode)
                                .font(.system(size: 16, weight: .mono, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AdaptiveColors.backgroundSecondary)
                        )
                    }
                    
                    // Card Details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Card Details")
                            .font(.system(size: 18, weight: .bold))
                        
                        HStack(spacing: 12) {
                            if let imageUrl = reservation.card?.imageUrl {
                                AsyncImage(url: URL(string: imageUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(AdaptiveColors.backgroundSecondary)
                                }
                                .frame(width: 100, height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(reservation.card?.name ?? "Unknown")
                                    .font(.system(size: 18, weight: .bold))
                                
                                if let setName = reservation.card?.setName {
                                    Text(setName)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                
                                if let condition = reservation.card?.condition {
                                    Text(condition.displayName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical: 5)
                                        .background(Capsule().fill(Color(condition.color)))
                                }
                                
                                Text(reservation.card?.formattedPrice ?? "€0.00")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AdaptiveColors.brandPrimary)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                    
                    // Shop Info
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Shop Location")
                            .font(.system(size: 18, weight: .bold))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(reservation.shop?.name ?? "Unknown Shop")
                                .font(.system(size: 16, weight: .semibold))
                            
                            if let address = reservation.shop?.address {
                                Text(address)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                    
                    // Cancel Button
                    if reservation.canBeCancelled {
                        Button(action: { showCancelConfirmation = true }) {
                            HStack {
                                if isCancelling {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                    Text("Cancel Reservation")
                                }
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
                        .disabled(isCancelling)
                    }
                }
                .padding(20)
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("Reservation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .confirmationDialog("Cancel Reservation", isPresented: $showCancelConfirmation, titleVisibility: .visible) {
                Button("Cancel Reservation", role: .destructive) {
                    cancelReservation()
                }
                Button("Keep Reservation", role: .cancel) {}
            } message: {
                Text("Are you sure you want to cancel this reservation?")
            }
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
                try await reservationService.cancelReservation(reservationId: reservation.id)
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
