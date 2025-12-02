//
//  AddCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import PhotosUI

struct AddCardView: View {
    @EnvironmentObject var cardService: CardService
    @Environment(\.dismiss) private var dismiss
    
    // Form Fields
    @State private var cardName = ""
    @State private var selectedTCG: TCGType = .pokemon
    @State private var cardSet = ""
    @State private var selectedRarity: Rarity = .common
    @State private var cardNumber = ""
    @State private var cardDescription = ""
    @State private var selectedCondition: CardCondition = .nearMint
    @State private var isGraded = false
    @State private var selectedGradeService: GradeService = .psa
    @State private var gradeScore = 10
    
    // UI State
    @State private var showingScanner = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var cardImage: UIImage?
    @State private var isSaving = false
    
    private var accentColor: Color {
        selectedTCG.themeColor
    }
    
    var body: some View {
        ZStack {
            // Background
            accentColor
                .opacity(0.05)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: { dismiss() }) {
                        SwiftUI.Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                    
                    Text("Nuova Carta")
                        .font(.headline)
                        .opacity(0.0) // Hidden for layout balance, title is below
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Title Section
                        VStack(spacing: 4) {
                            Text("Crea Carta")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.primary, .primary.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Aggiungi manualmente i dettagli")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        
                        // Image Picker Section
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                if let cardImage = cardImage {
                                    SwiftUI.Image(uiImage: cardImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 160, height: 220)
                                        .clipped()
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    // Edit Badge
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Spacer()
                                            SwiftUI.Image(systemName: "pencil.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.white)
                                                .shadow(radius: 4)
                                                .padding(8)
                                        }
                                    }
                                    .frame(width: 160, height: 220)
                                } else {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .frame(width: 160, height: 220)
                                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                                        .overlay(
                                            VStack(spacing: 12) {
                                                Circle()
                                                    .fill(accentColor.opacity(0.1))
                                                    .frame(width: 60, height: 60)
                                                    .overlay(
                                                        SwiftUI.Image(systemName: "camera.fill")
                                                            .font(.title2)
                                                            .foregroundColor(accentColor)
                                                    )
                                                
                                                Text("Aggiungi Foto")
                                                    .font(.system(size: 14, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                                .foregroundColor(accentColor.opacity(0.3))
                                        )
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        
                        // TCG Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("GIOCO DI CARTE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(TCGType.allCases, id: \.self) { tcg in
                                        TCGSelectionPill(
                                            tcg: tcg,
                                            isSelected: selectedTCG == tcg,
                                            action: { withAnimation { selectedTCG = tcg } }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Basic Info Section
                        VStack(spacing: 16) {
                            CustomTextField(
                                icon: "character.cursor.ibeam",
                                placeholder: "Nome Carta",
                                text: $cardName,
                                accentColor: accentColor,
                                rightIcon: "camera.viewfinder",
                                rightAction: { showingScanner = true }
                            )
                            
                            HStack(spacing: 12) {
                                CustomTextField(
                                    icon: "number",
                                    placeholder: "Set",
                                    text: $cardSet,
                                    accentColor: accentColor
                                )
                                
                                CustomTextField(
                                    icon: "hashtag",
                                    placeholder: "N°",
                                    text: $cardNumber,
                                    accentColor: accentColor
                                )
                                .frame(width: 100)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Details Section
                        VStack(spacing: 16) {
                            // Rarity
                            CustomPicker(
                                icon: "star.fill",
                                title: "Rarità",
                                selection: $selectedRarity,
                                options: Rarity.allCases,
                                accentColor: accentColor
                            )
                            
                            // Condition
                            CustomPicker(
                                icon: "heart.fill",
                                title: "Condizione",
                                selection: $selectedCondition,
                                options: CardCondition.allCases,
                                accentColor: accentColor
                            )
                            
                            // Grading Toggle
                            Toggle(isOn: $isGraded.animation()) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(isGraded ? accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                                            .frame(width: 32, height: 32)
                                        SwiftUI.Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(isGraded ? accentColor : .secondary)
                                    }
                                    Text("Carta Gradata")
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .padding(16)
                            .background(Color(.systemBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                            
                            if isGraded {
                                HStack(spacing: 12) {
                                    CustomPicker(
                                        icon: "building.columns.fill",
                                        title: "Servizio",
                                        selection: $selectedGradeService,
                                        options: GradeService.allCases,
                                        accentColor: accentColor
                                    )
                                    
                                    VStack(spacing: 0) {
                                        Text("Voto")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Stepper("\(gradeScore)", value: $gradeScore, in: 1...10)
                                            .labelsHidden()
                                    }
                                    .padding(12)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIZIONE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                                .padding(.leading, 4)
                            
                            TextEditor(text: $cardDescription)
                                .frame(height: 100)
                                .padding(12)
                                .background(Color(.systemBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 80) // Space for bottom button
                    }
                    .padding(.bottom, 20)
                }
            }
            
            // Bottom Action Button
            VStack {
                Spacer()
                Button(action: saveCard) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Salva Carta")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .disabled(cardName.isEmpty || isSaving)
                .opacity(cardName.isEmpty ? 0.6 : 1.0)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showingScanner) {
            CardScannerView(isPresented: $showingScanner) { scannedName in
                self.cardName = scannedName
                // Auto-fill logic
                if scannedName.contains("Pikachu") {
                    selectedTCG = .pokemon
                    cardSet = "Base Set"
                    selectedRarity = .rare
                    cardNumber = "25/102"
                }
            }
        }
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    cardImage = image
                }
            }
        }
    }
    
    private func saveCard() {
        isSaving = true
        Task {
            var imageURL: String? = nil
            
            if let cardImage = cardImage,
               let imageData = cardImage.jpegData(compressionQuality: 0.8) {
                imageURL = await cardService.uploadCardImage(imageData)
            }
            
            let card = Card(
                id: nil,
                templateId: 1,
                name: cardName,
                rarity: selectedRarity,
                condition: selectedCondition,
                imageURL: imageURL,
                isFoil: false,
                quantity: 1,
                ownerId: 1,
                createdAt: Date(),
                updatedAt: Date(),
                tcgType: selectedTCG,
                set: cardSet,
                cardNumber: cardNumber,
                expansion: nil,
                marketPrice: nil,
                description: cardDescription.isEmpty ? nil : cardDescription
            )
            
            // Simulate network delay for better UX
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }
}

// MARK: - Custom Components

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let accentColor: Color
    var rightIcon: String? = nil
    var rightAction: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
            }
            
            TextField(placeholder, text: $text)
                .font(.system(size: 16))
            
            if let rightIcon = rightIcon, let action = rightAction {
                Button(action: action) {
                    SwiftUI.Image(systemName: rightIcon)
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct TCGSelectionPill: View {
    let tcg: TCGType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                SwiftUI.Image(systemName: tcg.systemIcon)
                    .font(.system(size: 12))
                Text(tcg.displayName)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? tcg.themeColor.opacity(0.15) : Color(.secondarySystemBackground))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? tcg.themeColor : Color.clear, lineWidth: 1.5)
            )
            .foregroundColor(isSelected ? tcg.themeColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

struct CustomPicker<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let icon: String
    let title: String
    @Binding var selection: T
    let options: [T]
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 36, height: 36)
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker(title, selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(option.rawValue.capitalized).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .accentColor(.primary)
                .offset(x: -8) // Align picker text
            }
            
            Spacer()
            
            SwiftUI.Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
