//
//  TournamentUpdatesView.swift
//  TCG Arena
//
//  Live updates view for tournament participants
//  Redesigned with Home-style minimal aesthetic
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
        ZStack {
            // Clean white background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Content
                    if isLoading {
                        loadingState
                    } else if let error = error {
                        errorState(error)
                    } else if updates.isEmpty {
                        emptyState
                    } else {
                        updatesContent
                    }
                }
            }
            .refreshable {
                await refreshUpdates()
            }
        }
        .onAppear {
            loadUpdates()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top bar with close button and refresh
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    SwiftUI.Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(Circle().fill(Color(.secondarySystemBackground)))
                }
                
                Spacer()
                
                // Refresh button
                Button(action: { loadUpdates() }) {
                    SwiftUI.Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(12)
                        .background(Circle().fill(Color(.secondarySystemBackground)))
                }
                
                // Live badge
                if tournament.status == .inProgress {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(16)
                }
            }
            .padding(.top, 16)
            
            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text("Aggiornamenti")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.primary)
                
                Text(tournament.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)
            ProgressView()
                .scaleEffect(1.2)
            Text("Caricamento...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Error State
    private func errorState(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 60)
            
            SwiftUI.Image(systemName: "wifi.slash")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("Errore di caricamento")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { loadUpdates() }) {
                Text("Riprova")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.primary)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer().frame(height: 40)
            
            ZStack {
                Circle()
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 80, height: 80)
                
                SwiftUI.Image(systemName: "megaphone")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Nessun aggiornamento")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Gli organizzatori pubblicheranno qui messaggi e foto durante il torneo")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Updates Content
    private var updatesContent: some View {
        VStack(spacing: 0) {
            ForEach(Array(updates.enumerated()), id: \.element.id) { index, update in
                MinimalUpdateRow(update: update)
                
                if index < updates.count - 1 {
                    Divider()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                }
            }
        }
    }
    
    // MARK: - Data Loading
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
                    self.updates = data.sorted { $0.createdAt > $1.createdAt }
                case .failure(let err):
                    self.error = err.localizedDescription
                }
            }
        }
    }
    
    @MainActor
    private func refreshUpdates() async {
        guard let tournamentId = tournament.id else { return }
        
        do {
            updates = try await tournamentService.getTournamentUpdates(tournamentId: tournamentId)
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Minimal Update Row

struct MinimalUpdateRow: View {
    let update: TournamentUpdate
    @State private var showFullImage = false
    
    private var hasImage: Bool {
        guard let imageBase64 = update.imageBase64 else { return false }
        return !imageBase64.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Timestamp
            Text(update.formattedDate)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            
            // Message
            if let message = update.message, !message.isEmpty {
                Text(message)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Image
            if let imageBase64 = update.imageBase64,
               let imageData = Data(base64Encoded: imageBase64.replacingOccurrences(of: "data:image/[^;]+;base64,", with: "", options: .regularExpression)),
               let uiImage = UIImage(data: imageData) {
                
                SwiftUI.Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .padding(.top, 4)
                    .onTapGesture {
                        showFullImage = true
                    }
                    .fullScreenCover(isPresented: $showFullImage) {
                        MinimalFullImageView(image: uiImage)
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Minimal Full Image View

struct MinimalFullImageView: View {
    let image: UIImage
    @Environment(\.presentationMode) var presentationMode
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
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
                            withAnimation(.spring()) {
                                scale = max(1.0, min(scale, 3.0))
                            }
                        }
                )
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        SwiftUI.Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(14)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                Spacer()
            }
        }
    }
}
