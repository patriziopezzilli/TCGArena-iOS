//
//  QRScannerView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/1/25.
//

import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @Environment(\.dismiss) var dismiss
    let onCodeScanned: (String) -> Void
    
    @State private var showManualEntry = false
    @State private var manualCode = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera View
                QRCodeScannerViewController(onCodeScanned: { code in
                    onCodeScanned(code)
                    dismiss()
                })
                .edgesIgnoringSafeArea(.all)
                
                // Overlay
                VStack {
                    Spacer()
                    
                    // Scanning Frame
                    Rectangle()
                        .stroke(AdaptiveColors.brandPrimary, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            VStack {
                                ForEach(0..<4) { _ in
                                    Rectangle()
                                        .fill(AdaptiveColors.brandPrimary)
                                        .frame(width: 20, height: 3)
                                        .padding(.vertical, 2)
                                }
                            }
                            .offset(y: -100)
                        )
                    
                    Text("Align QR code within frame")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Manual Entry Button
                    Button(action: { showManualEntry = true }) {
                        HStack {
                            Image(systemName: "keyboard")
                            Text("Enter Code Manually")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AdaptiveColors.brandPrimary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualCodeEntryView { code in
                    onCodeScanned(code)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - QR Code Scanner View Controller
struct QRCodeScannerViewController: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }
    
    class Coordinator: NSObject, QRScannerViewControllerDelegate {
        let onCodeScanned: (String) -> Void
        
        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }
        
        func didScanCode(_ code: String) {
            onCodeScanned(code)
        }
    }
}

// MARK: - QR Scanner View Controller Delegate
protocol QRScannerViewControllerDelegate: AnyObject {
    func didScanCode(_ code: String)
}

// MARK: - QR Scanner View Controller Implementation
class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    weak var delegate: QRScannerViewControllerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showError("Camera not available")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showError("Camera input error")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            showError("Could not add video input")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            showError("Could not add metadata output")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didScanCode(stringValue)
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Errore", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Manual Code Entry View
struct ManualCodeEntryView: View {
    @Environment(\.dismiss) var dismiss
    let onCodeEntered: (String) -> Void
    
    @State private var code = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter the reservation code manually")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                TextField("Reservation Code", text: $code)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AdaptiveColors.backgroundSecondary)
                    )
                    .autocapitalization(.allCharacters)
                    .autocorrectionDisabled()
                
                Button(action: {
                    onCodeEntered(code)
                }) {
                    Text("Validate Code")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(code.isEmpty ? Color.secondary : AdaptiveColors.brandPrimary)
                        )
                }
                .disabled(code.isEmpty)
                
                Spacer()
            }
            .padding(20)
            .background(AdaptiveColors.backgroundPrimary)
            .navigationTitle("Manual Entry")
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
}

#Preview {
    QRScannerView { code in
        print("Scanned: \(code)")
    }
}
