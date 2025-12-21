//
//  SuggestShopSheet.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI
import CoreLocation

struct SuggestShopRequest: Encodable {
    let shopName: String
    let city: String
    let latitude: Double
    let longitude: Double
}

struct SuggestShopResponse: Decodable {
    let message: String
    let suggestionId: Int
}

struct SuggestShopSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    
    @State private var shopName = ""
    @State private var city = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggerisci un negozio")
                                .font(.system(size: 28, weight: .bold))
                            
                            Text("Aiutaci ad espandere la rete di negozi TCG nella tua zona")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                        
                        // Form
                        VStack(alignment: .leading, spacing: 20) {
                            // Shop Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nome del negozio")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
                                TextField("Es. Games & Comics", text: $shopName)
                                    .textFieldStyle(ModernTextFieldStyle())
                            }
                            
                            // City (auto-filled from GPS)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Città")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    if city.isEmpty {
                                        HStack(spacing: 4) {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                            Text("Rilevamento...")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                TextField("Città", text: $city)
                                    .textFieldStyle(ModernTextFieldStyle())
                            }
                            
                            // Info box
                            HStack(spacing: 12) {
                                SwiftUI.Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 20))
                                
                                Text("La città viene rilevata automaticamente dalla tua posizione. Puoi modificarla se necessario.")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Submit Button
                        Button {
                            Task {
                                await submitSuggestion()
                            }
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    SwiftUI.Image(systemName: "paperplane.fill")
                                    Text("Invia Suggerimento")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isFormValid ? Color.primary : Color.gray)
                        .cornerRadius(14)
                        .disabled(!isFormValid || isSubmitting)
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Chiudi") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            locationManager.requestLocationPermission()
            loadCityFromLocation()
        }
        .alert("Suggerimento inviato!", isPresented: $showSuccess) {
            Button("OK", action: { dismiss() })
        } message: {
            Text("Grazie per il suggerimento! Lo esamineremo presto e contatteremo il negozio.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Functions
    
    private func loadCityFromLocation() {
        guard let location = locationManager.location else {
            // Retry after a delay if location not yet available
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                loadCityFromLocation()
            }
            return
        }
        
        let geocoder = CLGeocoder()
        let clLocation = CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.city = placemark.locality ?? placemark.administrativeArea ?? ""
                }
            }
        }
    }
    
    private func submitSuggestion() async {
        // Check if user is authenticated
        guard APIClient.shared.jwtToken != nil else {
            await MainActor.run {
                isSubmitting = false
                ToastManager.shared.showError("Devi essere loggato per inviare un suggerimento")
            }
            return
        }
        
        let request = SuggestShopRequest(
            shopName: shopName.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: locationManager.location?.coordinate.latitude ?? 0.0,
            longitude: locationManager.location?.coordinate.longitude ?? 0.0
        )
        
        do {
            let response: SuggestShopResponse = try await APIClient.shared.request(
                "/api/shops/suggest",
                method: "POST",
                body: request
            )
            
            await MainActor.run {
                isSubmitting = false
                showSuccess = true
            }
        } catch {
            await MainActor.run {
                isSubmitting = false
                ToastManager.shared.showError("Errore nell'invio del suggerimento")
            }
        }
    }
}

// MARK: - Modern Text Field Style

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
    }
}

struct SuggestShopSheet_Previews: PreviewProvider {
    static var previews: some View {
        SuggestShopSheet()
    }
}
