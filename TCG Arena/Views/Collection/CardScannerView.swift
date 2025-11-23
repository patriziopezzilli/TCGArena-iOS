//
//  CardScannerView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import AVFoundation
import Vision
import VisionKit

struct CardScannerView: View {
    @State private var showingCamera = false
    @State private var showingDocumentScanner = false
    @State private var scannedImages: [UIImage] = []
    @State private var recognizedText: String = ""
    @State private var isProcessing = false
    @Binding var isPresented: Bool
    let onCardRecognized: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    SwiftUI.Image(systemName: "camera.viewfinder")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Scan Your Cards")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Use your camera to quickly add cards to your collection")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Scanning Options
                VStack(spacing: 16) {
                    TCGButton("Camera Scanner") {
                        // Mock scanner - simulate card recognition
                        simulateCardScan()
                    }
                    
                    TCGButton("Mock Sample Cards", style: .secondary) {
                        showMockCards()
                    }
                    
                    if #available(iOS 16.0, *), DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                        TCGButton("Document Scanner (Real)", style: .plain) {
                            showingDocumentScanner = true
                        }
                    }
                }
                
                // Processing Indicator
                if isProcessing {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Processing card...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Recognized Text Display
                if !recognizedText.isEmpty {
                    ScrollView {
                        Text(recognizedText)
                            .font(.caption)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 100)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Card Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
        .sheet(isPresented: $showingCamera) {
            CameraView { image in
                scannedImages.append(image)
                processImage(image)
            }
        }
        .sheet(isPresented: $showingDocumentScanner) {
            if #available(iOS 16.0, *) {
                DocumentScannerView { images in
                    scannedImages.append(contentsOf: images)
                    for image in images {
                        processImage(image)
                    }
                }
            } else {
                // Fallback per iOS 15
                Text("Document Scanner requires iOS 16.0+")
                    .padding()
            }
        }
    }
    
    private func processImage(_ image: UIImage) {
        isProcessing = true
        
        guard let cgImage = image.cgImage else {
            isProcessing = false
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    isProcessing = false
                }
                return
            }
            
            let recognizedStrings = observations.compactMap { observation in
                return observation.topCandidates(1).first?.string
            }
            
            DispatchQueue.main.async {
                recognizedText = recognizedStrings.joined(separator: "\n")
                parseCardInfo(from: recognizedText)
                isProcessing = false
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            DispatchQueue.main.async {
                isProcessing = false
            }
        }
    }
    
    private func parseCardInfo(from text: String) {
        // Basic parsing logic - can be enhanced with ML models
        let lines = text.components(separatedBy: .newlines)
        var cardName = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLine.isEmpty && trimmedLine.count > 3 {
                if cardName.isEmpty {
                    cardName = trimmedLine
                } else {
                    break
                }
            }
        }
        
        if !cardName.isEmpty {
            onCardRecognized(cardName)
        }
    }
    
    // MARK: - Mock Functions
    private func simulateCardScan() {
        isProcessing = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            let mockCards = ["Pikachu", "Charizard", "Blastoise", "Venusaur", "Mew", "Lugia"]
            let randomCard = mockCards.randomElement() ?? "Unknown Card"
            
            isProcessing = false
            recognizedText = "Scanned: \(randomCard)"
            onCardRecognized(randomCard)
            
            // Auto dismiss after showing result
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isPresented = false
            }
        }
    }
    
    private func showMockCards() {
        let mockCards = [
            "Pikachu ex - Base Set",
            "Charizard VMAX - Champion's Path",
            "Monkey D. Luffy - Romance Dawn",
            "Blue-Eyes White Dragon - LOB",
            "Black Lotus - Alpha",
            "Lightning Bolt - Limited Edition"
        ]
        
        // Show selection sheet
        let alert = UIAlertController(title: "Select a Card", message: "Choose from sample cards:", preferredStyle: .actionSheet)
        
        for card in mockCards {
            alert.addAction(UIAlertAction(title: card, style: .default) { _ in
                onCardRecognized(card)
                isPresented = false
            })
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
}

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraDevice = .rear
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        
        init(onImageCaptured: @escaping (UIImage) -> Void) {
            self.onImageCaptured = onImageCaptured
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Document Scanner View
@available(iOS 16.0, *)
struct DocumentScannerView: UIViewControllerRepresentable {
    let onImagesScanned: ([UIImage]) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onImagesScanned: onImagesScanned)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onImagesScanned: ([UIImage]) -> Void
        
        init(onImagesScanned: @escaping ([UIImage]) -> Void) {
            self.onImagesScanned = onImagesScanned
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Handle scanned items
        }
    }
}

#Preview {
    CardScannerView(isPresented: .constant(true)) { cardName in
        print("Recognized card: \(cardName)")
    }
}