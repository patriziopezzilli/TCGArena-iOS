//
//  LocationInputView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/14/25.
//

import SwiftUI
import CoreLocation
import MapKit

struct LocationInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var locationText: String
    var onLocationSet: ((CLLocation) -> Void)? = nil
    
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 45.4642, longitude: 9.1900), // Milano default
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var searchResults: [MKMapItem] = []
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Cerca posizione...", text: $searchText)
                        .font(.system(size: 16))
                        .submitLabel(.search)
                        .onSubmit {
                            searchLocation()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                        }) {
                            SwiftUI.Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // GPS Button
                Button(action: useCurrentLocation) {
                    HStack(spacing: 8) {
                        SwiftUI.Image(systemName: "location.fill")
                            .font(.system(size: 14))
                        
                        Text("Use Current Location")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Search Results or Map
                if !searchResults.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(searchResults, id: \.self) { item in
                                Button(action: {
                                    selectSearchResult(item)
                                }) {
                                    HStack(spacing: 12) {
                                        SwiftUI.Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.red)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name ?? "Unknown")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            if let address = item.placemark.title {
                                                Text(address)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        SwiftUI.Image(systemName: "chevron.right")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(16)
                                }
                                
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                } else {
                    // Map
                    ZStack {
                        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: selectedLocation != nil ? [IdentifiableCoordinate(coordinate: selectedLocation!)] : []) { item in
                            MapMarker(coordinate: item.coordinate, tint: .blue)
                        }
                        
                        if selectedLocation == nil {
                            VStack {
                                Spacer()
                                Text("Cerca o usa il GPS per selezionare una posizione")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemBackground).opacity(0.9))
                                    )
                                    .padding(.bottom, 40)
                            }
                        }
                    }
                }
                
                // Confirm Button
                if selectedLocation != nil || !searchText.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                        
                        Button(action: confirmLocation) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Text("Confirm Location")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                        }
                        .disabled(isLoading)
                    }
                }
            }
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func searchLocation() {
        guard !searchText.isEmpty else { return }
        isLoading = true
        
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let response = response {
                    searchResults = response.mapItems
                }
            }
        }
    }
    
    private func selectSearchResult(_ item: MKMapItem) {
        selectedLocation = item.placemark.coordinate
        region.center = item.placemark.coordinate
        searchResults = []
        
        if let name = item.name {
            searchText = name
        } else if let locality = item.placemark.locality {
            searchText = locality
        }
    }
    
    private func useCurrentLocation() {
        guard let location = locationManager.location else {
            // Request location permission if needed
            return
        }
        
        selectedLocation = location.coordinate
        region.center = location.coordinate
        
        // Reverse geocode to get city name
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let placemark = placemarks?.first {
                let city = placemark.locality ?? ""
                let country = placemark.country ?? ""
                searchText = "\(city), \(country)"
            }
        }
    }
    
    private func confirmLocation() {
        guard let coordinate = selectedLocation else { return }
        
        locationText = searchText
        onLocationSet?(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
        dismiss()
    }
}

// Helper struct for map annotations
struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
