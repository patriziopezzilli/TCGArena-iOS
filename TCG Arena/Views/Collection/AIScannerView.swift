import SwiftUI
import UIKit

struct AIScannerView: View {
    @Binding var isPresented: Bool
    @StateObject private var searchService = VisualSearchService.shared
    @EnvironmentObject var cardService: CardService
    
    @State private var image: UIImage?
    @State private var showingImagePicker = true
    @State private var isLoading = false
    @State private var searchResults: [SearchResult] = []
    @State private var errorMessage: String?
    @State private var matchedCards: [CardTemplate] = []
    @State private var selectedTemplateId: Int64?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    CyberneticScanningView(image: image)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        SwiftUI.Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .shadow(color: .orange.opacity(0.5), radius: 10)
                        
                        Text("ERRORE SISTEMA")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                            .font(.body)
                        
                        Button(action: {
                            self.errorMessage = nil
                            self.showingImagePicker = true
                        }) {
                            Text("RIAVVIA SCANSIONE")
                                .font(.headline)
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else if !matchedCards.isEmpty {
                    // ... (keep existing results list)
                    List {
                        Section(header: Text("MATCH TROVATI")
                                    .font(.caption)
                                    .foregroundColor(.blue)) {
                            ForEach(matchedCards) { card in
                                CardRow(card: card)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        print("Selected card: \(card.name)")
                                    }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                } else {
                    // Initial State
                    ZStack {
                        Color.black.edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 30) {
                            Spacer()
                            
                            SwiftUI.Image(systemName: "viewfinder")
                                .font(.system(size: 100, weight: .thin))
                                .foregroundColor(.blue)
                                .opacity(0.8)
                            
                            VStack(spacing: 8) {
                                Text("AI VISION SYSTEM")
                                    .font(.system(size: 24, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Text("Inquadra la carta per l'analisi vettoriale")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                HStack {
                                    SwiftUI.Image(systemName: "camera.fill")
                                    Text("ATTIVA SENSORI")
                                }
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: .blue.opacity(0.6), radius: 20, x: 0, y: 0)
                            }
                            .padding(.bottom, 50)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationBarItems(trailing: Button("ESCI") {
                isPresented = false
            }.foregroundColor(.white))
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $image, sourceType: .camera)
                    .ignoresSafeArea()
            }
            // ... (keep onChange)
        }
    }
    // ... (keep performSearch)
}

// MARK: - Futuristic UI Components

struct CyberneticScanningView: View {
    let image: UIImage?
    @State private var isScanning = false
    @State private var textOpacity = 0.5
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Scanned Image Container
                ZStack {
                    if let image = image {
                        SwiftUI.Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                            )
                            .padding(20)
                            .blur(radius: 2) // Slight digital blur
                    }
                    
                    // Scanning Grid Pattern
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .cyan.opacity(0.2), .clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(
                             SwiftUI.Image(systemName: "circle.grid.2x2.fill") // Fake grid texture pattern
                                .resizable(resizingMode: .tile)
                                .opacity(0.1)
                        )
                    
                    // The Laser Beam
                    GeometryReader { geometry in
                        Rectangle()
                            .fill(LinearGradient(colors: [.clear, .green, .clear], startPoint: .top, endPoint: .bottom))
                            .frame(height: 5)
                            .shadow(color: .green, radius: 10, x: 0, y: 0)
                            .offset(y: isScanning ? geometry.size.height : -10)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isScanning
                            )
                    }
                    .padding(20) // Match image padding
                    
                    // HUD Corners
                    HUDCorners()
                        .padding(10)
                }
                .frame(maxHeight: 500)
                
                Spacer().frame(height: 40)
                
                // Loading Text
                VStack(spacing: 5) {
                    Text("ANALISI NEURALE IN CORSO...")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .opacity(textOpacity)
                        .animation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: textOpacity)
                    
                    Text("IDENTIFICAZIONE VETTORI...")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                }
            }
        }
        .onAppear {
            isScanning = true
            textOpacity = 1.0
        }
    }
}

struct HUDCorners: View {
    var body: some View {
        ZStack {
            // Top Left
            VStack {
                HStack {
                    CornerShape()
                        .stroke(Color.cyan, lineWidth: 3)
                        .frame(width: 50, height: 50)
                    Spacer()
                    // Top Right
                    CornerShape()
                        .stroke(Color.cyan, lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(90))
                }
                Spacer()
                // Bottom
                HStack {
                    // Bottom Left
                    CornerShape()
                        .stroke(Color.cyan, lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    Spacer()
                    // Bottom Right
                    CornerShape()
                        .stroke(Color.cyan, lineWidth: 3)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(180))
                }
            }
        }
    }
}

struct CornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}
    
    private func performSearch(image: UIImage) {
        isLoading = true
        errorMessage = nil
        matchedCards = []
        
        Task {
            do {
                let results = try await searchService.searchCard(image: image)
                
                if results.isEmpty {
                    errorMessage = "Nessun risultato trovato. Prova con una luce migliore o uno sfondo neutro."
                } else {
                    // Fetch full card details for each result
                    var cards: [CardTemplate] = []
                    
                    for res in results {
                         // Use continuation to bridge completion block to async/await
                         let card: CardTemplate? = await withCheckedContinuation { continuation in
                             cardService.getCardTemplateById(Int(res.card_id)) { result in
                                 switch result {
                                 case .success(let template):
                                     continuation.resume(returning: template)
                                 case .failure:
                                     continuation.resume(returning: nil)
                                 }
                             }
                         }
                         
                         if let card = card {
                             cards.append(card)
                         }
                    }
                    
                    DispatchQueue.main.async {
                        self.matchedCards = cards
                        if self.matchedCards.isEmpty {
                            self.errorMessage = "Trovati risultati ma impossibile scaricare i dettagli. Riprova."
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Errore: \(error.localizedDescription)"
                }
            }
            DispatchQueue.main.async {
                 self.isLoading = false
            }
        }
    }
}

// Minimal CardRow for display
struct CardRow: View {
    let card: CardTemplate
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: card.imageUrl ?? "")) { image in
                 image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                 Color.gray.opacity(0.3)
            }
            .frame(width: 40, height: 56)
            .cornerRadius(4)
            
            VStack(alignment: .leading) {
                Text(card.name).font(.headline)
                Text(card.cardNumber ?? "").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

// Standard ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
