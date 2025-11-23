# TCG Arena - Guida per Sviluppatori

## Panoramica del Progetto

TCG Arena è un'applicazione iOS nativa sviluppata in SwiftUI per la gestione di collezioni di Trading Card Games. L'app integra Firebase per il backend e offre funzionalità avanzate come scansione automatica delle carte, mappa interattiva dei tornei e community features.

## Setup di Sviluppo

### 1. Prerequisiti
- Xcode 15.0 o superiore
- iOS 15.0+ target (alcune funzionalità avanzate richiedono iOS 16.0+)
- Account Firebase gratuito
- Account sviluppatore Apple (opzionale per testing su simulatore)

### 2. Configurazione Firebase

#### Creazione Progetto Firebase
1. Visita [Firebase Console](https://console.firebase.google.com/)
2. Clicca "Aggiungi progetto"
3. Nome progetto: "TCG Arena"
4. Abilita Google Analytics (consigliato)

#### Configurazione App iOS
1. Nel progetto Firebase, clicca "Aggiungi app" > iOS
2. Bundle ID: `com.tcgarena.ios`
3. Nome app: "TCG Arena iOS"
4. Scarica `GoogleService-Info.plist`
5. Aggiungi il file alla root del progetto Xcode

#### Servizi da Abilitare
```bash
# Authentication
console.firebase.google.com > Authentication > Sign-in method
Abilita: Email/Password

# Firestore Database  
console.firebase.google.com > Firestore Database
Crea database in modalità test

# Storage
console.firebase.google.com > Storage
Inizializza in modalità test
```

### 3. Installazione Dipendenze

Le dipendenze Firebase vengono gestite tramite Swift Package Manager:

```swift
// In Xcode:
File > Add Package Dependencies
URL: https://github.com/firebase/firebase-ios-sdk

// Seleziona i seguenti pacchetti:
- FirebaseAuth
- FirebaseFirestore  
- FirebaseStorage
- FirebaseAnalytics
```

## Architettura del Codice

### Pattern MVVM
Il progetto segue il pattern Model-View-ViewModel con SwiftUI:

```
Models/          - Strutture dati (Card, User, Tournament, Deck)
Views/           - Interfacce SwiftUI
ViewModels/      - Business logic e state management  
Services/        - Integrazioni Firebase e API esterne
```

### Struttura Firebase

#### Collezioni Firestore
```javascript
// users - Profili utenti
users/{userId} {
    email: string,
    username: string, 
    displayName: string,
    isPremium: boolean,
    dateJoined: timestamp
}

// cards - Carte degli utenti
cards/{cardId} {
    name: string,
    tcgType: "Pokemon" | "Magic" | "YuGiOh" | "OnePiece",
    set: string,
    rarity: string,
    condition: string,
    ownerID: string,
    imageURL?: string,
    marketPrice?: number
}

// tournaments - Eventi e tornei
tournaments/{tournamentId} {
    title: string,
    description: string,
    tcgType: string,
    startDate: timestamp,
    location: {
        name: string,
        address: string, 
        latitude: number,
        longitude: number
    },
    maxParticipants: number,
    currentParticipants: number
}
```

### Servizi Core

#### AuthService
Gestisce autenticazione Firebase:
```swift
@MainActor
class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    func signUp(email: String, password: String) async
    func signIn(email: String, password: String) async  
    func signOut()
}
```

#### CardService
Operazioni su carte e collezioni:
```swift
class CardService: ObservableObject {
    @Published var userCards: [Card] = []
    
    func addCard(_ card: Card) async
    func loadUserCards(userID: String) async
    func uploadCardImage(_ imageData: Data) async -> String?
}
```

#### TournamentService  
Gestione tornei e mappa:
```swift
class TournamentService: ObservableObject {
    @Published var tournaments: [Tournament] = []
    @Published var nearbyTournaments: [Tournament] = []
    
    func loadNearbyTournaments(userLocation: CLLocation) async
    func registerForTournament(tournamentID: String, userID: String) async
}
```

## Funzionalità Principali

### 1. Scansione Carte
Utilizza Vision Framework per OCR automatico:

```swift
// CardScannerView.swift
import Vision
import VisionKit

// Elaborazione immagine con Vision
private func processImage(_ image: UIImage) {
    let request = VNRecognizeTextRequest { request, error in
        // Estrazione testo dalle carte scansionate
        let recognizedText = observations.compactMap { 
            $0.topCandidates(1).first?.string 
        }
    }
}
```

### 2. Mappa Tornei Interattiva
Integrazione MapKit con Core Location:

```swift
// TournamentMapView.swift
import MapKit
import CoreLocation

struct TournamentMapView: View {
    @State private var region = MKCoordinateRegion(...)
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: tournaments) { tournament in
            MapAnnotation(coordinate: tournament.location.coordinate) {
                TournamentMapPin(tournament: tournament)
            }
        }
    }
}
```

### 3. Componenti UI Riutilizzabili

#### TCGButton
Bottone personalizzato con stili Apple:
```swift
struct TCGButton: View {
    enum ButtonStyle {
        case primary, secondary, destructive, plain
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .background(style.backgroundColor)
                .cornerRadius(12)
        }
    }
}
```

#### CardRowView
Visualizzazione carte in lista:
```swift
struct CardRowView: View {
    let card: Card
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: card.imageURL))
            VStack(alignment: .leading) {
                Text(card.name)
                Text(card.rarity.rawValue)
            }
        }
    }
}
```

## Testing e Debug

### Testing su Simulatore
```bash
# Apri Xcode
# Seleziona simulatore iOS 15.0+  
# Build e Run: ⌘+R

# Per funzionalità complete testa su device:
# - Fotocamera (scansione carte)
# - GPS (mappa tornei) 
# - Document Scanner (richiede iOS 16.0+)
# - Performance reali
```

### Unit Testing
```swift
// Esempio test per CardService
@testable import TCG_Arena

class CardServiceTests: XCTestCase {
    func testAddCard() async {
        let service = CardService()
        let card = Card(name: "Test Card", ...)
        await service.addCard(card)
        
        XCTAssertEqual(service.userCards.count, 1)
    }
}
```

### Debug Firebase
```swift
// Abilita debug Firebase in AppDelegate
FirebaseApp.configure()
Firestore.firestore().settings.isPersistenceEnabled = true

// Logs dettagliati
os_log("Firebase operation completed", log: .default, type: .info)
```

## Deploy e Distribuzione

### App Store Connect
1. **Archivio app:** Product > Archive in Xcode
2. **Upload:** Window > Organizer > Distribute App
3. **Configurazione:** App Store Connect per metadata
4. **Review:** Submissione per review Apple

### TestFlight (Beta Testing)  
1. **Upload build** via Xcode o Transporter
2. **Aggiungi tester** in App Store Connect
3. **Distribuzione automatica** agli internal tester

### Configurazione Release
```swift
// Build Settings per Release
SWIFT_COMPILATION_MODE = wholemodule
SWIFT_OPTIMIZATION_LEVEL = -O
DEBUG_INFORMATION_FORMAT = dwarf-with-dsym
```

## Performance e Ottimizzazioni

### Immagini e Media
```swift
// Compression ottimale per upload Firebase
let imageData = image.jpegData(compressionQuality: 0.8)

// Cache per AsyncImage
AsyncImage(url: cardImageURL)
    .cache(.memory) // Cache automatica SwiftUI
```

### Database Queries
```swift  
// Query ottimizzate Firestore
db.collection("cards")
  .whereField("ownerID", isEqualTo: userID)
  .order(by: "dateAdded", descending: true)
  .limit(to: 50) // Paginazione
```

### Memory Management
```swift
// Weak references per evitare retain cycles
@StateObject private var cardService = CardService()

// Cleanup automatico con @Published
class CardService: ObservableObject {
    @Published var cards: [Card] = []
}
```

## Troubleshooting Comuni

### Firebase Setup Issues
```bash
# GoogleService-Info.plist mancante
Error: "FirebaseApp.configure() failed"
Soluzione: Aggiungi GoogleService-Info.plist al progetto

# Bundle ID non corrispondente  
Error: "Firebase configuration failed"
Soluzione: Verifica Bundle ID in Xcode corrisponda a Firebase
```

### Camera/Location Permissions
```xml
<!-- Info.plist deve contenere: -->
<key>NSCameraUsageDescription</key>
<string>TCG Arena needs camera access to scan trading cards</string>

<key>NSLocationWhenInUseUsageDescription</key>  
<string>TCG Arena uses location to find nearby stores and tournaments</string>
```

### Build Errors Comuni
```swift
// Missing import
import FirebaseFirestore // Per @DocumentID
import MapKit // Per coordinate
import Vision // Per text recognition

// Async context required
Task {
    await cardService.loadCards()
}
```

## Contribuire al Progetto

### Git Workflow
```bash
# Branch per nuove features
git checkout -b feature/card-scanner-improvements
git commit -m "feat: improve OCR accuracy for Pokemon cards"
git push origin feature/card-scanner-improvements

# Pull request con template
- Descrizione modifiche
- Screenshots (per UI changes)  
- Testing effettuato
```

### Coding Standards
- **SwiftLint** per style consistency
- **Commenti** per logica complessa
- **MARK:** per organizzazione codice
- **@available** per nuove funzionalità iOS

---

**Happy Coding! 🚀**

Per domande tecniche: developers@tcgarena.app