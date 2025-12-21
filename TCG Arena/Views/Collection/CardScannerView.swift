//
//  CardScannerView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI
import VisionKit
import AVFoundation

struct CardScannerView: View {
    @Binding var isPresented: Bool
    // Optional callback for legacy usage
    var onCardRecognized: ((String) -> Void)?
    
    @State private var showingScanResult = false
    @State private var scannedQuery: String = ""
    @State private var isScanning = true
    
    // For Mock/Simulator
    @State private var showMockOptions = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable(
                        shouldStartScanning: $isScanning,
                        onTextRecognized: handleRecognizedItems
                    )
                    .ignoresSafeArea()
                } else {
                    // Fallback / Simulator View
                    VStack(spacing: 20) {
                        SwiftUI.Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        Text("Camera not available")
                            .font(.title2)
                        Text("Running on Simulator or device without camera support.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Simulate 'Charizard 4/102'") {
                            handleMatch(tokens: ["Charizard", "4/102"])
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        Button("Simulate 'Pikachu'") {
                            handleMatch(tokens: ["Pikachu"])
                        }
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Overlay UI
                VStack {
                    Text("Frame card name & number")
                        .font(.headline)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding(.top, 40)
                    
                    Spacer()
                    
                    // Cancel Button
                    Button(action: { isPresented = false }) {
                        SwiftUI.Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingScanResult, onDismiss: {
                // Resume scanning when result sheet is dismissed
                isScanning = true
            }) {
                ScanResultView(scannedTokens: scannedTokens)
            }
        }
    }
    
    @State private var scannedTokens: [String] = []
    
    // ...
    
    private func handleRecognizedItems(_ texts: [String]) {
        // Pass everything to backend smart scan
        if !texts.isEmpty {
            handleMatch(tokens: texts)
        }
    }
    
    private func handleMatch(tokens: [String]) {
        // Debounce: matches strictly
        guard !showingScanResult else { return }
        
        // Pause scanning
        isScanning = false
        
        // Match found
        scannedTokens = tokens
        
        // Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        showingScanResult = true
    }
}

// MARK: - VisionKit Representable
struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var shouldStartScanning: Bool
    var onTextRecognized: ([String]) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scannerViewController = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate, // CHANGED: Accurate for small text
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scannerViewController.delegate = context.coordinator
        return scannerViewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if shouldStartScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: DataScannerRepresentable
        
        init(_ parent: DataScannerRepresentable) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(allItems)
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
             processItems(allItems)
        }
        
        private func processItems(_ items: [RecognizedItem]) {
            var extractedTexts: [String] = []
            for item in items {
                switch item {
                case .text(let text):
                    // Filter noise: keep if long enough OR contains digits (like "58" or "4/102")
                    let content = text.transcript
                    if content.count > 3 || content.rangeOfCharacter(from: .decimalDigits) != nil {
                        extractedTexts.append(content)
                    }
                default:
                    break
                }
            }
            // Pass all texts as context
            if !extractedTexts.isEmpty {
                print("DEBUG: Raw Extracted Text (Filtered): \(extractedTexts)")
                parent.onTextRecognized(extractedTexts)
            }
        }
    }
}
