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
    @State private var selectedType: CustomerRequest.RequestType = .availability
    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    @State private var showingShopPicker = false
    
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
                                SwiftUI.Image(systemName: type.icon)
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
                    Button("Annulla") {
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
                                
                                SwiftUI.Image(systemName: "checkmark.circle.fill")
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
        case .availability:
            return "Descrivi le carte che stai cercando. Includi nome, edizione, condizione e lingua."
        case .evaluation:
            return "Fornisci dettagli sulle carte di cui vuoi una valutazione."
        case .sell:
            return "Descrivi la collezione che vuoi vendere. Includi quantità approssimativa e condizioni."
        case .buy:
            return "Descrivi cosa vuoi acquistare dal negozio."
        case .trade:
            return "Elenca le carte che vuoi scambiare e cosa cerchi in cambio."
        case .general:
            return "Descrivi la tua domanda o richiesta."
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
                    description: description.isEmpty ? "Nessun dettaglio aggiuntivo" : description,
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
                shop.address.localizedCaseInsensitiveContains(searchText)
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
                            
                            Text(shop.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Cerca negozi")
            .navigationTitle("Seleziona Negozio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annulla") {
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
