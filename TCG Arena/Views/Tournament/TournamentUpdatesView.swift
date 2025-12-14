//
//  TournamentUpdatesView.swift
//  TCG Arena
//
//  Live updates view for tournament participants
//

import SwiftUI

struct TournamentUpdatesView: View {
    let tournament: Tournament
    @EnvironmentObject var tournamentService: TournamentService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var updates: [TournamentUpdate] = []
    @State private var isLoading = true
    @State private var error: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Caricamento aggiornamenti...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let error = error {
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Riprova") {
                            loadUpdates()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if updates.isEmpty {
                    VStack(spacing: 16) {
                        SwiftUI.Image(systemName: "megaphone")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("Nessun aggiornamento")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Gli organizzatori pubblicheranno qui\nmessaggi e foto durante il torneo")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(updates) { update in
                                UpdateCard(update: update)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await refreshUpdates()
                    }
                }
            }
            .navigationTitle("Aggiornamenti Live")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        loadUpdates()
                    } label: {
                        SwiftUI.Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            loadUpdates()
        }
    }
    
    private func loadUpdates() {
        isLoading = true
        error = nil
        
        guard let tournamentId = tournament.id else {
            error = "ID torneo non valido"
            isLoading = false
            return
        }
        
        tournamentService.getTournamentUpdates(tournamentId: tournamentId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let data):
                    self.updates = data
                case .failure(let err):
                    self.error = "Errore nel caricamento: \(err.localizedDescription)"
                }
            }
        }
    }
    
    @MainActor
    private func refreshUpdates() async {
        guard let tournamentId = tournament.id else {
            error = "ID torneo non valido"
            return
        }
        
        do {
            updates = try await tournamentService.getTournamentUpdates(tournamentId: tournamentId)
        } catch {
            self.error = "Errore nel caricamento: \(error.localizedDescription)"
        }
    }
}

// MARK: - Update Card

struct UpdateCard: View {
    let update: TournamentUpdate
    @State private var showFullImage = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with timestamp
            HStack {
                SwiftUI.Image(systemName: "megaphone.fill")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Text(update.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Message
            if let message = update.message, !message.isEmpty {
                Text(message)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Image
            if let imageBase64 = update.imageBase64,
               let imageData = Data(base64Encoded: imageBase64.replacingOccurrences(of: "data:image/[^;]+;base64,", with: "", options: .regularExpression)),
               let uiImage = UIImage(data: imageData) {
                
                SwiftUI.Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .cornerRadius(12)
                    .onTapGesture {
                        showFullImage = true
                    }
                    .sheet(isPresented: $showFullImage) {
                        FullImageView(image: uiImage)
                    }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Full Image View

struct FullImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                SwiftUI.Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = value.magnitude
                            }
                            .onEnded { _ in
                                withAnimation {
                                    scale = max(1.0, min(scale, 3.0))
                                }
                            }
                    )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}
