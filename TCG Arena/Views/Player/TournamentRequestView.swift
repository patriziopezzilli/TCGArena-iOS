//
//  TournamentRequestView.swift
//  TCG Arena
//
//  Customer form to request a tournament at a shop
//

import SwiftUI

struct TournamentRequestView: View {
    let shop: Shop
    
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    // Form Fields
    @State private var title = ""
    @State private var description = ""
    @State private var tcgType: TCGType = .pokemon
    @State private var tournamentType: Tournament.TournamentType = .casual
    @State private var startDate = Date().addingTimeInterval(86400 * 7)
    
    // Participants (Free input, must be even)
    @State private var maxParticipantsString = ""
    
    @State private var entryFee: Double = 0.0
    @State private var prizePool = ""
    
    // State
    @State private var isSubmitting = false
    
    // Validation Helpers
    var participantsCount: Int? {
        return Int(maxParticipantsString)
    }
    
    var isParticipantsEven: Bool {
        guard let count = participantsCount else { return false }
        return count > 0 && count % 2 == 0
    }
    
    var isFormValid: Bool {
        !title.isEmpty &&
        title.count >= 3 &&
        isParticipantsEven
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Shop Header Info
                    shopHeaderCard
                    
                    // Main Form
                    VStack(spacing: 20) {
                        // Basic Info
                        inputGroup(title: "Dettagli Evento") {
                            customTextField(
                                icon: "trophy",
                                placeholder: "Titolo del Torneo",
                                text: $title
                            )
                            
                            customTextEditor(
                                icon: "text.alignleft",
                                placeholder: "Descrizione (opzionale)",
                                text: $description
                            )
                        }
                        
                        // Game Settings
                        inputGroup(title: "Configurazione") {
                            // TCG Type Selector
                            customPicker(
                                icon: "gamecontroller",
                                title: "Gioco",
                                selection: $tcgType,
                                options: [
                                    .pokemon: "Pokémon",
                                    .magic: "Magic",
                                    .yugioh: "Yu-Gi-Oh!",
                                    .onePiece: "One Piece",
                                    .digimon: "Digimon"
                                ]
                            )
                            
                            Divider().padding(.leading, 44)
                            
                            // Tournament Type Selector
                            customPicker(
                                icon: "flag",
                                title: "Tipo",
                                selection: $tournamentType,
                                options: [
                                    .casual: "Casual",
                                    .competitive: "Competitivo",
                                    .championship: "Championship"
                                ]
                            )
                        }
                        
                        // Schedule & Participants
                        inputGroup(title: "Data e Partecipanti") {
                            // Date
                            HStack(spacing: 12) {
                                ImageItem(icon: "calendar", color: .blue)
                                DatePicker(
                                    "",
                                    selection: $startDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .labelsHidden()
                                Spacer()
                            }
                            .padding()
                            
                            Divider().padding(.leading, 44)
                            
                            // Participants
                            VStack(alignment: .leading, spacing: 4) {
                                customTextField(
                                    icon: "person.2",
                                    placeholder: "Max Partecipanti (es. 16)",
                                    text: $maxParticipantsString,
                                    keyboardType: .numberPad
                                )
                                
                                // Validation Message
                                if !maxParticipantsString.isEmpty && !isParticipantsEven {
                                    Text("Il numero di partecipanti deve essere pari")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 44)
                                        .padding(.bottom, 8)
                                }
                            }
                        }
                        
                        // Entry & Prizes
                        inputGroup(title: "Quota e Premi") {
                            HStack(spacing: 12) {
                                ImageItem(icon: "eurosign.circle", color: .orange)
                                Text("Quota Iscrizione")
                                    .foregroundColor(.primary)
                                Spacer()
                                TextField("0", value: $entryFee, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                Text("€")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            
                            Divider().padding(.leading, 44)
                            
                            customTextField(
                                icon: "gift",
                                placeholder: "Montepremi (opzionale)",
                                text: $prizePool
                            )
                        }
                    }
                    
                    // Action Button
                    submitButton
                        .padding(.top, 10)
                }
                .padding(20)
            }
            .navigationTitle("Nuova Richiesta")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var shopHeaderCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                SwiftUI.Image(systemName: "storefront.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Richiesta per")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(shop.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func inputGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private func customTextField(icon: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            ImageItem(icon: icon)
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
        }
        .padding()
    }
    
    private func customTextEditor(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ImageItem(icon: icon)
                .padding(.top, 8)
            
            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color(UIColor.placeholderText))
                        .padding(.top, 8)
                }
                TextEditor(text: text)
                    .frame(height: 100)
                    .scrollContentBackground(.hidden)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private func customPicker<T: Hashable>(icon: String, title: String, selection: Binding<T>, options: [T: String]) -> some View {
        HStack(spacing: 12) {
            ImageItem(icon: icon)
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Picker("", selection: selection) {
                ForEach(Array(options.keys.sorted(by: { options[$0]! < options[$1]! })), id: \.self) { key in
                    Text(options[key]!).tag(key)
                }
            }
            .labelsHidden()
            .accentColor(.blue)
        }
        .padding()
    }
    
    private var submitButton: some View {
        Button(action: submitRequest) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Invia Richiesta")
                        .fontWeight(.bold)
                    SwiftUI.Image(systemName: "paperplane.fill")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isSubmitting)
    }
    
    private func submitRequest() {
        guard isFormValid, let participants = participantsCount else { return }
        
        isSubmitting = true
        
        // Prepare Data with LocalDateTime format (without timezone)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Europe/Rome") // Use Italy timezone
        
        let requestDTO: [String: Any] = [
            "title": title,
            "description": description.isEmpty ? nil : description,
            "tcgType": tcgType.rawValue.uppercased(),
            "type": tournamentType.rawValue.uppercased(),
            "startDate": formatter.string(from: startDate),
            "maxParticipants": participants,
            "entryFee": entryFee,
            "prizePool": prizePool.isEmpty ? nil : prizePool,
            "shopId": shop.id
        ].compactMapValues { $0 }
        
        print("📤 Sending tournament request:")
        print("   URL: https://api.tcgarena.it/api/tournaments/request")
        print("   Shop ID: \(shop.id)")
        print("   Title: \(title)")
        print("   Participants: \(participants)")
        print("   Start Date: \(formatter.string(from: startDate))")
        print("   Token present: \(APIClient.shared.jwtToken != nil)")
        
        Task {
            do {
                try await sendRequest(data: requestDTO)
                await MainActor.run {
                    isSubmitting = false
                    // Success feedback
                    HapticManager.shared.success()
                    ToastManager.shared.showToast(
                        "Richiesta inviata con successo! Il negozio riceverà la tua proposta.",
                        type: .success
                    )
                    // Wait a moment for toast to show, then dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                    }
                }
            } catch {
                print("❌ Tournament request error: \(error)")
                print("   Error details: \(error.localizedDescription)")
                await MainActor.run {
                    isSubmitting = false
                    // Error feedback
                    HapticManager.shared.error()
                    ToastManager.shared.showToast(
                        "Errore durante l'invio: \(error.localizedDescription)",
                        type: .error
                    )
                }
            }
        }
    }
    
    private func sendRequest(data: [String: Any]) async throws {
        let apiBaseURL = "https://api.tcgarena.it"
        guard let url = URL(string: "\(apiBaseURL)/api/tournaments/request") else {
            print("❌ Invalid URL")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL non valido"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = APIClient.shared.jwtToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("   ✅ Authorization header added")
        } else {
            print("   ⚠️ No JWT token available")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: data)
        print("   📦 Request body prepared")
        
        let (responseData, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "Risposta non valida dal server"])
        }
        
        print("   📥 Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            print("   ✅ Request successful")
        } else {
            // Try to parse error message from response
            if let errorString = String(data: responseData, encoding: .utf8) {
                print("   ❌ Server error response: \(errorString)")
            }
            
            let errorMessage: String
            switch httpResponse.statusCode {
            case 400:
                errorMessage = "Dati non validi. Controlla tutti i campi."
            case 401:
                errorMessage = "Non autenticato. Effettua di nuovo il login."
            case 403:
                errorMessage = "Non hai i permessi per questa operazione."
            case 404:
                errorMessage = "Negozio non trovato."
            case 500...599:
                errorMessage = "Errore del server. Riprova più tardi."
            default:
                errorMessage = "Errore durante l'invio (codice: \(httpResponse.statusCode))"
            }
            
            throw NSError(domain: "Network", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
    }
}

// MARK: - Subviews

struct ImageItem: View {
    let icon: String
    var color: Color = .gray
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
                .frame(width: 32, height: 32)
            
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
    }
}
