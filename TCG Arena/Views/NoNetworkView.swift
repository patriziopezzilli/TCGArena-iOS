//
//  NoNetworkView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/17/25.
//
//  Full-screen overlay shown when the app has no network connectivity.
//

import SwiftUI

/// A blocking overlay that appears when the device has no network connectivity.
/// Displays a "Retry" button and prevents any navigation while offline.
struct NoNetworkView: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @State private var isRetrying = false
    
    var body: some View {
        ZStack {
            // Solid background to block all interaction
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    SwiftUI.Image(systemName: "wifi.slash")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.red)
                }
                
                // Title
                Text("Nessuna Connessione")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                // Subtitle
                Text("Controlla la tua connessione internet e riprova.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Retry Button
                Button(action: retryConnection) {
                    HStack(spacing: 10) {
                        if isRetrying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            SwiftUI.Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        Text("Riprova")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.blue)
                    )
                }
                .disabled(isRetrying)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .transition(.opacity)
    }
    
    private func retryConnection() {
        isRetrying = true
        
        // Give user visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            networkMonitor.checkConnectivity()
            isRetrying = false
        }
    }
}

#Preview {
    NoNetworkView()
        .environmentObject(NetworkMonitor.shared)
}
