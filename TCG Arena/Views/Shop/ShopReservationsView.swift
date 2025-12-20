//
//  ShopReservationsView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/6/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ShopReservationsView: View {
    @EnvironmentObject var reservationService: ReservationService
    let shopId: String
    
    @State private var reservations: [Reservation] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Caricamento prenotazioni...")
                    .padding()
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Errore Caricamento Prenotazioni")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Riprova") {
                        loadReservations()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.primary)
                }
                .padding()
            } else if reservations.isEmpty {
                VStack(spacing: 16) {
                    SwiftUI.Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Nessuna Prenotazione")
                        .font(.headline)
                    
                    Text("Non hai ancora fatto prenotazioni con questo negozio.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(reservations) { reservation in
                            ReservationCard(reservation: reservation)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color.gray.opacity(0.1))
        .task {
            loadReservations()
        }
    }
    
    private func loadReservations() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                reservations = try await reservationService.getUserReservationsForShop(shopId: shopId)
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isLoading = false
        }
    }
}

struct ReservationCard: View {
    let reservation: Reservation
    
    @State private var showingQRCode = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with status and date
            HStack {
                Text(reservation.status.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(reservation.status.color))
                    )
                
                Spacer()
                
                Text(reservation.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Card info
            HStack(spacing: 12) {
                // Card image
                Group {
                    if let imageURL = reservation.fullImageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 50, height: 70)
                                .overlay(ProgressView())
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 50, height: 70)
                            .overlay(
                                SwiftUI.Image(systemName: "photo")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(reservation.cardName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("Scade: \(reservation.expiresAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // QR Code for active reservations
            if reservation.status == .pending || reservation.status == .validated {
                Button(action: { showingQRCode = true }) {
                    HStack {
                        SwiftUI.Image(systemName: "qrcode")
                            .foregroundColor(.blue)
                        
                        Text("QR Code: \(reservation.qrCode)")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.blue)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        SwiftUI.Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.blue.opacity(0.7))
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingQRCode) {
            QRCodeView(qrCode: reservation.qrCode, cardName: reservation.cardName ?? "Card")
        }
    }
}

#Preview {
    NavigationView {
        ShopReservationsView(shopId: "1")
        // .environmentObject(ReservationService())
    }
}

// MARK: - QR Code View
struct QRCodeView: View {
    let qrCode: String
    let cardName: String
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("QR Code Prenotazione")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(cardName)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                if let qrImage = generateQRCode(from: qrCode) {
                    SwiftUI.Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                } else {
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "qrcode")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("Impossibile generare il QR code")
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(spacing: 8) {
                    Text("Mostra questo QR code al personale del negozio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Code: \(qrCode)")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Fatto") {
                dismiss()
            })
        }
    }
    
    private func generateQRCode(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            let context = CIContext()
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return nil
    }
}