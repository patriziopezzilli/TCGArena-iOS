# TCG Arena - iOS App

> **Una piattaforma mobile completa per appassionati di Trading Card Games**

TCG Arena è un'app iOS nativa sviluppata in SwiftUI che offre agli appassionati di carte collezionabili (Pokemon, Magic: The Gathering, Yu-Gi-Oh!, One Piece TCG) una piattaforma completa per gestire le proprie collezioni, trovare tornei locali e connettersi con la community.

## 🚀 Funzionalità Principali

### 📱 Gestione Collezione Digitale
- **Scansione automatica delle carte** usando Vision Framework
- **Organizzazione avanzata** con filtri personalizzabili
- **Supporto per carte gradate** (PSA, PCA, CGC, BGS)
- **Monitoraggio prezzi** in tempo reale
- **Foto e metadati dettagliati** per ogni carta

### 🗺️ Mappa Tornei Interattiva
- **Geolocalizzazione** di negozi e tornei
- **Registrazione online** agli eventi
- **Notifiche push** per promemoria
- **Dettagli completi** degli eventi
- **Sistema di valutazione** negozi e tornei

### 🏗️ Deck Builder
- **Costruzione mazzi** per tutti i TCG supportati
- **Validazione formato** automatica
- **Condivisione** con la community
- **Statistiche e analisi** del mazzo

### 👥 Community Features
- **Chat e forum** per discussioni
- **Classifiche e sfide** online
- **Eventi della community**
- **Sistema di valutazioni** e recensioni

### 💎 Modello Freemium
- **Funzioni base gratuite** per tutti
- **Premium features** per utenti avanzati
- **Scansioni illimitate** per utenti premium
- **Strumenti di analisi avanzati**

## 🏗️ Architettura Tecnica

### Tecnologie Utilizzate
- **SwiftUI** - Framework UI nativo Apple
- **Firebase** - Backend completo (Auth, Firestore, Storage, Analytics)
- **MapKit** - Integrazione mappe native iOS
- **Vision Framework** - Riconoscimento ottico delle carte
- **Core Location** - Servizi di geolocalizzazione
- **VisionKit** - Scanner documenti avanzato

### Pattern Architetturale
- **MVVM (Model-View-ViewModel)** per separazione delle responsabilità
- **Combine** per reactive programming
- **Async/Await** per operazioni asincrone
- **Dependency Injection** per testabilità

### Struttura del Progetto
```
TCG Arena/
├── Models/              # Modelli dati (Card, User, Tournament, Deck)
├── Views/               # Interfacce utente SwiftUI
│   ├── Collection/      # Gestione collezione e scansione
│   ├── Map/            # Mappa tornei e dettagli
│   └── Components/     # Componenti UI riutilizzabili
├── Services/           # Servizi Firebase e API
├── ViewModels/         # Business logic e state management
└── Assets.xcassets/    # Risorse grafiche e colori
```

## 🚦 Prerequisiti e Setup

### Requisiti di Sistema
- **Xcode 15.0+**
- **iOS 15.0+** (alcune funzionalità avanzate richiedono iOS 16.0+)
- **Swift 5.9+**
- **Account sviluppatore Apple** (per testing su device)

### Setup Firebase

1. **Crea progetto Firebase:**
   ```bash
   # Visita https://console.firebase.google.com/
   # Crea nuovo progetto "TCG Arena"
   # Abilita Google Analytics
   ```

2. **Aggiungi app iOS:**
   ```
   Bundle ID: com.tcgarena.ios
   Nome app: TCG Arena iOS
   ```

3. **Scarica GoogleService-Info.plist:**
   - Scarica il file di configurazione
   - Aggiungi al progetto Xcode nella cartella "TCG Arena"

4. **Configura servizi Firebase:**
   ```bash
   # Authentication -> Sign-in method -> Email/Password
   # Firestore Database -> Crea database (modalità test)
   # Storage -> Inizializza (modalità test)
   ```

### Installazione Dipendenze

Firebase SDK viene installato tramite Swift Package Manager:

1. **In Xcode:** File > Add Package Dependencies
2. **URL:** `https://github.com/firebase/firebase-ios-sdk`
3. **Seleziona pacchetti:**
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage
   - FirebaseAnalytics

### Configurazione Permessi

L'app richiede i seguenti permessi (già configurati in `Info.plist`):

```xml
<!-- Accesso fotocamera per scansione carte -->
<key>NSCameraUsageDescription</key>
<string>TCG Arena needs camera access to scan trading cards</string>

<!-- Posizione per trovare tornei nelle vicinanze -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>TCG Arena uses location to find nearby stores and tournaments</string>
```

## 🛠️ Sviluppo

### Avvio del Progetto
1. **Clona il repository**
2. **Apri `TCG Arena.xcodeproj` in Xcode**
3. **Aggiungi `GoogleService-Info.plist`**
4. **Seleziona team di sviluppo**
5. **Build e Run** (⌘+R)

### Testing
```bash
# Unit tests
⌘+U

# UI tests
⌘+U (seleziona UI Test target)

# Testing su device fisico consigliato per:
# - Funzionalità fotocamera
# - GPS e mappe
# - Performance reali
```

### Struttura Database Firestore

```javascript
// Collezioni principali
users/                  # Profili utenti
  {userId}/
    email: string
    username: string
    displayName: string
    isPremium: boolean
    
cards/                  # Carte degli utenti
  {cardId}/
    name: string
    tcgType: string
    rarity: string
    ownerID: string
    imageURL: string?
    
tournaments/            # Eventi e tornei
  {tournamentId}/
    title: string
    tcgType: string
    location: object
    startDate: timestamp
    registrations/       # Sotto-collezione
      {userId}: object
      
decks/                  # Mazzi degli utenti
  {deckId}/
    name: string
    tcgType: string
    cards: array
    ownerID: string
```

## 📱 Funzionalità Dettagliate

### Scansione Carte
- **Vision Framework** per OCR automatico
- **Parsing intelligente** del testo riconosciuto
- **Supporto fotocamera e scanner documenti**
- **Correzione manuale** dei dati riconosciuti

### Mappa Tornei
- **Ricerca geografica** con Core Location
- **Annotazioni personalizzate** per tipo torneo
- **Bottom sheet** con lista tornei
- **Integrazione con calendario** iOS

### Sistema Premium
- **Freemium model** con funzionalità base gratuite
- **In-App Purchases** per upgrade premium
- **Scansioni illimitate** per utenti premium
- **Analytics avanzati** e insights

## 🎨 Design System

### Colori Principali
- **Primary Blue:** Sistema iOS standard
- **Secondary Colors:** Basati su rarità delle carte
- **System Colors:** Compatibilità Dark/Light mode

### Tipografia
- **SF Pro Rounded** per titoli
- **SF Pro** per corpo del testo
- **Dimensioni dinamiche** per accessibilità

### Componenti UI
- **TCGButton:** Bottone personalizzato con stati
- **CardRowView:** Lista carte con metadati
- **TournamentCardView:** Card tornei con azioni
- **Design minimale** seguendo linee guida Apple

## 🔒 Sicurezza e Privacy

### Autenticazione
- **Firebase Auth** con email/password
- **Validazione server-side** delle operazioni
- **Token di sessione** sicuri

### Dati Utente
- **GDPR compliance** per utenti EU
- **Crittografia in transito** (HTTPS/TLS)
- **Storage sicuro** su Firebase

### Privacy
- **Accesso posizione** solo quando necessario
- **Foto carte** crittografate nel cloud
- **Dati anonimi** per analytics

## 🚀 Roadmap Futura

### Versione 1.1
- [ ] **Chat in tempo reale** con Firebase
- [ ] **Push notifications** avanzate
- [ ] **Condivisione social** delle collezioni

### Versione 1.2  
- [ ] **API esterne** per prezzi in tempo reale
- [ ] **Machine Learning** per riconoscimento carte
- [ ] **Modalità offline** limitata

### Versione 2.0
- [ ] **Apple Watch companion app**
- [ ] **iPad optimization** con multi-window
- [ ] **Marketplace integrato** per scambio carte

## 📄 Licenza

Questo progetto è proprietario. Tutti i diritti riservati.

## 👥 Team

- **Lead Developer:** TCG Arena Team
- **UI/UX Design:** Apple Design Guidelines
- **Backend:** Firebase Platform

## 📞 Supporto

Per assistenza tecnica o domande:
- **Email:** support@tcgarena.app
- **GitHub Issues:** Per bug e feature request
- **Discord Community:** Link nella app

---

**TCG Arena** - *L'app definitiva per collezionisti di carte*