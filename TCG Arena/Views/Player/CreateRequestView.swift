//
//  CreateRequestView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI

struct CreateRequestView: View {
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    let onComplete: (Bool) -> Void
    
    @State private var selectedShop: Shop?
    @State private var selectedType: CustomerRequest.RequestType = .cardSearch
    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
    // Mock shops - in real app, fetch from API
    @State private var availableShops: [Shop] = []
    
    var isValid: Bool {
        selectedShop != nil && !title.isEmpty && !description.isEmpty
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Request Type", selection: $selectedType) {
                        ForEach(CustomerRequest.RequestType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                } header: {
                    Text("Type")
                }
                
                Section {
                    Button(action: { showingShopPicker = true }) {
                        HStack {
                            Text("Shop")
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if let shop = selectedShop {
                                Text(shop.name)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Select shop")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Destination")
                } footer: {
                    Text("Choose which shop you want to send this request to")
                }
                
                Section {
                    TextField("Request Title", text: $title)
                        .autocapitalization(.sentences)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(5...10)
                        .autocapitalization(.sentences)
                } header: {
                    Text("Details")
                } footer: {
                    Text(typeHelpText)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        submitRequest()
                    }
                    .disabled(!isValid || isSubmitting)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingShopPicker) {
                ShopPickerView(selectedShop: $selectedShop, shops: availableShops)
            }
        }
        .onAppear {
            loadShops()
        }
        .overlay(
            Group {
                if showSuccessMessage {
                    ZStack {
                        Color.black.opacity(0.6)
                            .edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                // Allow tapping to dismiss
                                withAnimation {
                                    showSuccessMessage = false
                                }
                            }
                        
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text(successMessage)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Your request has been sent successfully!")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(40)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showSuccessMessage = false
                            }
                        }
                    }
                }
            }
        )
    }
    
    private var typeHelpText: String {
        switch selectedType {
        case .cardSearch:
            return "Describe the card(s) you're looking for. Include name, edition, condition, and language if specific."
        case .priceCheck:
            return "Provide details about the cards you want price information for."
        case .bulkSale:
            return "Describe the collection you want to sell. Include approximate quantity and general condition."
        case .tradeIn:
            return "List the cards you want to trade in and what you're looking for in exchange."
        case .repairService:
            return "Describe the repair or restoration service you need for your cards."
        case .customOrder:
            return "Explain your custom request in detail (deck building, sealed product orders, etc.)."
        case .general:
            return "Describe your question or request."
        }
    }
    
    private func loadShops() {
        // In real app, fetch from API
        // For now, using mock data
        availableShops = []
    }
    
    private func submitRequest() {
        guard let shopId = selectedShop?.id else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                let request = CreateRequestRequest(
                    shopId: String(shopId),
                    type: CustomerRequest.RequestType(rawValue: selectedType.rawValue) ?? .general,
                    title: title,
                    description: description.isEmpty ? "No additional details" : description,
                    attachmentUrl: nil
                )
                _ = try await requestService.createRequest(request)
                
                await MainActor.run {
                    successMessage = "Request Sent!"
                    showSuccessMessage = true
                    isSubmitting = false
                    
                    // Close after showing success message
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        onComplete(true)
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to create request: \(error.localizedDescription)"
                    isSubmitting = false
                }
            }
        }
    }
}

struct ShopPickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedShop: Shop?
    let shops: [Shop]
    
    @State private var searchText = ""
    
    var filteredShops: [Shop] {
        if searchText.isEmpty {
            return shops
        } else {
            return shops.filter { shop in
                shop.name.localizedCaseInsensitiveContains(searchText) ||
                shop.city.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredShops) { shop in
                    Button(action: {
                        selectedShop = shop
                        dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shop.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if !shop.city.isEmpty {
                                Text("\(shop.city), \(shop.country)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search shops")
            .navigationTitle("Select Shop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CreateRequestView { _ in }
        .environmentObject(RequestService(apiClient: APIClient.shared))
        .environmentObject(AuthService())
}
