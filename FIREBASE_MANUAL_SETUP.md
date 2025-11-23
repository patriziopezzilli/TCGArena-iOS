# 🚀 Guida Step-by-Step: Aggiungere Firebase SDK manualmente in Xcode

## ⚠️ Problema Rilevato
Il progetto ha alcuni problemi di configurazione che richiedono correzione manuale in Xcode.

## 📋 Procedura Manuale (Raccomandata)

### 1️⃣ Apri il Progetto in Xcode
```bash
# Apri TCG Arena in Xcode
open "/Users/PATRIZIO.PEZZILLI/Documents/Personale/TCG Arena - iOS App/TCG Arena.xcodeproj"
```

### 2️⃣ Correggi il Deployment Target
1. **Seleziona il progetto** "TCG Arena" nel navigator
2. **Vai su "TCG Arena" target** (non il progetto)
3. **Tab "General"** > **Deployment Info**
4. **Cambia "iOS Deployment Target"** da qualunque valore sia impostato a: **15.0**

### 3️⃣ Aggiungi Firebase Package Dependencies
1. **File** > **Add Package Dependencies...**
2. **URL del repository**: `https://github.com/firebase/firebase-ios-sdk`
3. **Dependency Rule**: "Up to Next Major Version" con **10.19.0**
4. **Clicca "Add Package"**
5. **Seleziona questi 4 moduli:**
   - ✅ **FirebaseAnalytics** 
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore**
   - ✅ **FirebaseStorage**
6. **Clicca "Add Package"**

### 4️⃣ Verifica GoogleService-Info.plist
1. **Controlla che sia visibile** nel Project Navigator sotto "TCG Arena"
2. **Se non c'è:** trascina il file dalla cartella TCG Arena nel progetto
3. **Assicurati sia nel target**: seleziona il file e verifica che "TCG Arena" sia spuntato in Target Membership

### 5️⃣ Test dell'App
1. **Seleziona simulatore iOS 15.0+** dal menu destination
2. **Build e Run**: **⌘+R**
3. **Verifica che l'app si avvii** senza errori

## 🔧 Troubleshooting

### Se vedi errori di iOS 26.1:
1. **Project Settings** > **TCG Arena project** > **Build Settings**
2. **Cerca "iOS Deployment Target"**
3. **Cambia TUTTI i valori** a **15.0**

### Se Firebase non si compila:
1. **Product** > **Clean Build Folder** (⌘+Shift+K)
2. **Xcode** > **Settings** > **Components** > controlla che iOS SDK sia aggiornato
3. **Riavvia Xcode**
4. **Ri-aggiungi Firebase packages** se necessario

### Se GoogleService-Info.plist non è riconosciuto:
1. **Seleziona il file** nel Project Navigator
2. **File Inspector** (pannello di destra)
3. **Target Membership** > spunta **"TCG Arena"**

## 📱 Moduli Firebase Inclusi

Una volta aggiunto correttamente, avrai:

- **🔐 FirebaseAuth** - Autenticazione email/password
- **📊 FirebaseFirestore** - Database NoSQL real-time  
- **📁 FirebaseStorage** - Storage per immagini carte
- **📈 FirebaseAnalytics** - Analytics e metriche app

## ✅ Verifica Finale

Dopo aver completato i passi:
1. **Il progetto compila** senza errori
2. **L'app si avvia** nel simulatore
3. **Vedi le 5 tab** (Collection, Tournaments, Decks, Community, Profile)
4. **Nessun crash** all'avvio

## 🎯 Prossimi Passi

Una volta che Firebase è configurato:
1. **Configura Firebase Console** (Authentication, Firestore, Storage)
2. **Testa le funzionalità** base dell'app
3. **Inizia lo sviluppo** delle features specifiche

---

**💡 Tip**: Se continui ad avere problemi, crea un nuovo progetto Xcode e trasferisci i file sorgente - a volte è più veloce che debuggare problemi di configurazione complessi!