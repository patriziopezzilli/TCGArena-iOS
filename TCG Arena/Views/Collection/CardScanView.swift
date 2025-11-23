//
//  CardScanView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI
import Vision
import VisionKit
import AVFoundation

struct CardScanView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    @StateObject private var scannerDelegate = CardScannerDelegate()
    @State private var showingManualEntry = false
    @State private var scannedCard: ScannedCardData?
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            // Camera View
            DocumentCameraView(delegate: scannerDelegate)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)
                            
                            SwiftUI.Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showingManualEntry = true }) {
                        ZStack {
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                                .frame(height: 44)
                            
                            HStack(spacing: 8) {
                                SwiftUI.Image(systemName: "keyboard")
                                    .font(.system(size: 14, weight: .semibold))
                                
                                Text("Manual")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Instructions
                VStack(spacing: 16) {
                    if isProcessing {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("Processing card...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.7))
                        )
                    } else {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                SwiftUI.Image(systemName: "camera.viewfinder")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Position card in frame")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Make sure the card is flat and well-lit")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.6))
                        )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingManualEntry) {
            ManualAddCardView()
                .environmentObject(cardService)
                .environmentObject(deckService)
        }
        .sheet(item: $scannedCard) { cardData in
            CardScanResultView(scannedCard: cardData)
                .environmentObject(cardService)
                .environmentObject(deckService)
        }
        .onReceive(scannerDelegate.scannedCardPublisher) { cardData in
            scannedCard = cardData
        }
        .onReceive(scannerDelegate.processingStatePublisher) { processing in
            isProcessing = processing
        }
    }
}

// MARK: - Document Camera View Wrapper
struct DocumentCameraView: UIViewControllerRepresentable {
    let delegate: CardScannerDelegate
    
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = delegate
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
}

// MARK: - Scanner Delegate
class CardScannerDelegate: NSObject, ObservableObject, VNDocumentCameraViewControllerDelegate {
    @Published var isProcessing = false
    
    private let scannedCardSubject = PassthroughSubject<ScannedCardData, Never>()
    private let processingStateSubject = PassthroughSubject<Bool, Never>()
    
    var scannedCardPublisher: AnyPublisher<ScannedCardData, Never> {
        scannedCardSubject.eraseToAnyPublisher()
    }
    
    var processingStatePublisher: AnyPublisher<Bool, Never> {
        processingStateSubject.eraseToAnyPublisher()
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        processingStateSubject.send(true)
        
        guard scan.pageCount > 0 else {
            processingStateSubject.send(false)
            return
        }
        
        let image = scan.imageOfPage(at: 0)
        processCardImage(image)
        
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        processingStateSubject.send(false)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        processingStateSubject.send(false)
        controller.dismiss(animated: true)
    }
    
    private func processCardImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            processingStateSubject.send(false)
            return
        }
        
        let request = VNRecognizeTextRequest { [weak self] request, error in
            DispatchQueue.main.async {
                self?.handleTextRecognition(request: request, error: error, image: image)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    self.processingStateSubject.send(false)
                }
            }
        }
    }
    
    private func handleTextRecognition(request: VNRequest, error: Error?, image: UIImage) {
        guard let observations = request.results as? [VNRecognizedTextObservation] else {
            processingStateSubject.send(false)
            return
        }
        
        let recognizedText = observations.compactMap { observation in
            observation.topCandidates(1).first?.string
        }
        
        let cardData = parseCardInformation(from: recognizedText, image: image)
        scannedCardSubject.send(cardData)
        processingStateSubject.send(false)
    }
    
    private func parseCardInformation(from texts: [String], image: UIImage) -> ScannedCardData {
        var cardName = ""
        var cardSet = ""
        var cardNumber = ""
        var rarity = Rarity.common
        var tcgType = TCGType.pokemon
        
        // Simple parsing logic - this can be enhanced with better algorithms
        for text in texts {
            let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Detect TCG type
            if cleanText.lowercased().contains("pokemon") || cleanText.lowercased().contains("pikachu") {
                tcgType = .pokemon
            } else if cleanText.lowercased().contains("one piece") || cleanText.lowercased().contains("luffy") {
                tcgType = .onePiece
            } else if cleanText.lowercased().contains("magic") || cleanText.lowercased().contains("mtg") {
                tcgType = .magic
            } else if cleanText.lowercased().contains("yu-gi-oh") || cleanText.lowercased().contains("yugioh") {
                tcgType = .yugioh
            }
            
            // Detect card number (format like "25/102" or "ST01-001")
            if cleanText.contains("/") || cleanText.contains("-") {
                cardNumber = cleanText
            }
            
            // Detect rarity
            if cleanText.lowercased().contains("rare") {
                rarity = .rare
            } else if cleanText.lowercased().contains("ultra") {
                rarity = .ultraRare
            } else if cleanText.lowercased().contains("secret") {
                rarity = .secretRare
            }
            
            // Assume first long text is card name
            if cardName.isEmpty && cleanText.count > 3 && !cleanText.contains("/") && !cleanText.contains("-") {
                cardName = cleanText
            }
        }
        
        // Fallback values
        if cardName.isEmpty {
            cardName = "Scanned Card"
        }
        
        return ScannedCardData(
            name: cardName,
            tcgType: tcgType,
            set: cardSet.isEmpty ? "Unknown Set" : cardSet,
            cardNumber: cardNumber.isEmpty ? "???" : cardNumber,
            rarity: rarity,
            image: image,
            recognizedTexts: texts
        )
    }
}

// MARK: - Scanned Card Data
struct ScannedCardData: Identifiable {
    let id = UUID()
    let name: String
    let tcgType: TCGType
    let set: String
    let cardNumber: String
    let rarity: Rarity
    let image: UIImage
    let recognizedTexts: [String]
}

import Combine

#Preview {
    CardScanView()
        .environmentObject(CardService())
        .environmentObject(DeckService())
}