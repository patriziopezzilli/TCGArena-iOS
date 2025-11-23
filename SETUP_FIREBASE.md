# 🔥 Setup Firebase per TCG Arena - Guida Passo-Passo

## ✅ Passo 1: File GoogleService-Info.plist - COMPLETATO
Il file `GoogleService-Info.plist` è già stato aggiunto correttamente al progetto nella cartella `TCG Arena/`.

## 📦 Passo 2: Aggiungere Firebase SDK via Xcode

### 1. Apri Xcode
```bash
# Apri il progetto
open "TCG Arena.xcodeproj"
```

### 2. Aggiungi Package Dependencies
1. In Xcode, vai su **File** > **Add Package Dependencies...**
2. Incolla questo URL: `https://github.com/firebase/firebase-ios-sdk`
3. Clicca **Add Package**
4. Nella schermata che appare, seleziona questi 4 pacchetti:
   - ✅ **FirebaseAuth** (per autenticazione)
   - ✅ **FirebaseFirestore** (per database)  
   - ✅ **FirebaseStorage** (per file/immagini)
   - ✅ **FirebaseAnalytics** (per statistiche)
5. Clicca **Add Package**

### 3. Verifica Setup
Dopo l'installazione, dovresti vedere nella sezione **Package Dependencies** di Xcode:
```
├── firebase-ios-sdk
│   ├── FirebaseAuth
│   ├── FirebaseFirestore
│   ├── FirebaseStorage  
│   └── FirebaseAnalytics
```

## 🔧 Passo 3: Configurazione Firebase Console

### Servizi da Abilitare
1. **Authentication**
   - Vai su https://console.firebase.google.com/
   - Seleziona il progetto "TCG Arena"
   - Authentication > Sign-in method
   - Abilita: **Email/Password**

2. **Firestore Database**
   - Database > Firestore Database
   - **Create database**
   - Modalità: **Start in test mode** (per ora)
   - Posizione: **europe-west** (consigliato per Europa)

3. **Storage**
   - Storage > Get started
   - **Start in test mode** (per ora)
   - Posizione: **europe-west**

## 🚀 Prossimi Passi per Te:

⚠️ **IMPORTANTE**: Ho rilevato alcuni problemi di configurazione. Segui la **guida manuale** in `FIREBASE_MANUAL_SETUP.md` per il setup corretto.

### Quick Setup:
1. **Apri Xcode**: 
   ```bash
   open "TCG Arena.xcodeproj"
   ```

2. **Correggi Deployment Target** a iOS 15.0 (Progetto > Target > General)

3. **Aggiungi Firebase SDK manualmente**:
   - File > Add Package Dependencies
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Seleziona: FirebaseAuth, FirebaseFirestore, FirebaseStorage, FirebaseAnalytics

4. **Verifica GoogleService-Info.plist** sia nel target

5. **Test**: Build e Run (⌘+R)

## 📱 Test Funzionalità Avanzate

### Per testare tutte le funzionalità:
1. **Fotocamera** (scansione carte): Usa device fisico
2. **GPS** (mappa tornei): Usa device fisico o simulatore con posizione
3. **Performance**: Test su device reale consigliato

## ⚠️ Troubleshooting

### Errore "FirebaseApp.configure() failed"
- Verifica che `GoogleService-Info.plist` sia nel target "TCG Arena"
- Bundle ID deve essere: `com.tcgarena.ios`

### Errori di compilazione Firebase
- Clean Build Folder: **⌘+Shift+K**
- Restart Xcode
- Re-add Firebase packages se necessario

### Problemi Permission Camera/Location
- I permessi sono già configurati in `Info.plist`
- Su device reale, accetta i permessi quando richiesti

## 🎯 Prossimi Passi

Una volta completato il setup:
1. **Test basic functionality** - Tab navigation funziona
2. **Implementa autenticazione** - Sign up/Login
3. **Aggiungi prime carte** - Test card management  
4. **Prova la mappa** - Test location features

## 📞 Supporto

Se hai problemi:
1. Controlla la console Xcode per errori specifici
2. Verifica configurazione Firebase Console
3. Assicurati che tutti i package Firebase siano installati

**Happy Coding! 🚀**