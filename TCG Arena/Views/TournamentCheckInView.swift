//
//  TournamentCheckInView.swift
//  TCG Arena
//
//  Created by Assistant on 22/11/2024.
//

import SwiftUI

struct TournamentCheckInView: View {
    @EnvironmentObject var tournamentService: TournamentService
    @Environment(\.dismiss) var dismiss
    
    let tournament: Tournament
    
    @State private var showQRScanner = false
    @State private var isProcessing = false
    @State private var checkInResult: CheckInResult?
    
    enum CheckInResult {
        case success(message: String)
        case alreadyCheckedIn(message: String)
        case error(message: String)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Tournament Info
                VStack(spacing: 16) {
                    Text("Tournament Check-in")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 12) {
                        Text(tournament.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 8) {
                            Text(tournament.format.displayName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(AdaptiveColors.brandPrimary))
                            
                            Text(tournament.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Check-in Info
                VStack(alignment: .leading, spacing: 16) {
                    Text("Check-in Information")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        CheckInInfoRow(
                            icon: "clock.fill",
                            title: "Check-in opens",
                            value: "1 hour before tournament start"
                        )
                        
                        CheckInInfoRow(
                            icon: "qrcode.viewfinder",
                            title: "How to check-in",
                            value: "Scan the QR code provided by the organizer"
                        )
                        
                        CheckInInfoRow(
                            icon: "checkmark.circle.fill",
                            title: "What happens",
                            value: "You'll be marked as present for the tournament"
                        )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AdaptiveColors.backgroundSecondary)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Check-in Button
                VStack(spacing: 16) {
                    if let result = checkInResult {
                        CheckInResultView(result: result)
                    }
                    
                    Button(action: { showQRScanner = true }) {
                        HStack(spacing: 12) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 20))
                            }
                            
                            Text(isProcessing ? "Processing..." : "Scan Check-in QR Code")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isProcessing ? Color.gray : AdaptiveColors.brandPrimary)
                        )
                    }
                    .disabled(isProcessing)
                    .padding(.horizontal, 20)
                }
            }
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showQRScanner) {
                QRScannerView { code in
                    handleQRCode(code: code)
                }
            }
        }
    }
    
    private func handleQRCode(code: String) {
        isProcessing = true
        
        Task {
            do {
                let participant = try await tournamentService.checkInParticipant(checkInCode: code)
                
                await MainActor.run {
                    isProcessing = false
                    
                    if participant.status == .checkedIn {
                        checkInResult = .success(message: "Successfully checked in! You're ready for the tournament.")
                    } else {
                        checkInResult = .alreadyCheckedIn(message: "You are already checked in for this tournament.")
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    checkInResult = .error(message: error.localizedDescription)
                    ToastManager.shared.showError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Check-in Info Row
struct CheckInInfoRow: View {
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Check-in Result View
struct CheckInResultView: View {
    let result: TournamentCheckInView.CheckInResult
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(resultColor.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: resultIcon)
                    .font(.system(size: 30))
                    .foregroundColor(resultColor)
            }
            
            Text(resultMessage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(resultColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
    }
    
    private var resultColor: Color {
        switch result {
        case .success: return AdaptiveColors.success
        case .alreadyCheckedIn: return AdaptiveColors.warning
        case .error: return AdaptiveColors.error
        }
    }
    
    private var resultIcon: String {
        switch result {
        case .success: return "checkmark.circle.fill"
        case .alreadyCheckedIn: return "info.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        }
    }
    
    private var resultMessage: String {
        switch result {
        case .success(let message): return message
        case .alreadyCheckedIn(let message): return message
        case .error(let message): return message
        }
    }
}

#Preview {
    TournamentCheckInView(tournament: Tournament(
        id: "1",
        shopId: "shop1",
        name: "Weekly Pokemon Tournament",
        description: "Standard format tournament",
        tcgType: .pokemon,
        format: .swiss,
        date: Date().addingTimeInterval(3600), // 1 hour from now
        maxParticipants: 16,
        currentParticipants: 8,
        status: .registrationOpen,
        entryFee: 10.0,
        prizePool: "Booster Box",
        rules: nil,
        createdAt: Date()
    ))
    .environmentObject(TournamentService.shared)
}
.withToastSupport()
