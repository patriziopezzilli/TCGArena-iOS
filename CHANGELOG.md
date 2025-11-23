# Changelog

Tutti i cambiamenti significativi al progetto TCG Arena iOS App saranno documentati in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e questo progetto aderisce a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-23

### Aggiunto
- **Gestione Collezione Digitale**: Scansione automatica delle carte usando Vision Framework
- **Mappa Tornei Interattiva**: Geolocalizzazione di negozi e tornei con registrazione online
- **Deck Builder**: Costruzione e validazione mazzi per tutti i TCG supportati
- **Community Features**: Chat, forum, classifiche e sfide online
- **Sistema Premium**: Modello freemium con funzioni avanzate per utenti premium
- **Integrazione Firebase**: Autenticazione, database, storage e analytics
- **MapKit Integration**: Mappe native iOS per localizzazione eventi
- **Vision Framework**: Riconoscimento ottico delle carte
- **Core Location**: Servizi di geolocalizzazione
- **VisionKit**: Scanner documenti avanzato

### Funzionalità Principali
- **Scansione Carte**: Supporto per Pokemon, Magic: The Gathering, Yu-Gi-Oh!, One Piece TCG
- **Organizzazione Avanzata**: Filtri personalizzabili e supporto carte gradate (PSA, PCA, CGC, BGS)
- **Monitoraggio Prezzi**: Prezzi in tempo reale per tutte le carte
- **Tornei**: Registrazione online, notifiche push, sistema valutazioni
- **Community**: Chat, forum, eventi community, classifiche
- **Deck Building**: Validazione formato automatica, condivisione, statistiche

### Sicurezza
- **Gestione SSL Personalizzata**: Supporto per ambienti aziendali con proxy
- **Autenticazione JWT**: Sicurezza token-based per API
- **Connessione Backend**: Integrazione con API Spring Boot su Render

### Infrastruttura
- **GitHub Repository**: Version control e collaborazione
- **CI/CD Ready**: Preparato per integrazioni continue
- **Documentazione Completa**: README, CONTRIBUTING, LICENSE

### Note
- Versione iniziale completa con tutte le funzionalità core
- Backend deployato su Render con database PostgreSQL
- App configurata per produzione con gestione SSL proxy

## [0.1.0] - 2024-11-01

### Aggiunto
- Progetto iniziale TCG Arena iOS App
- Setup base SwiftUI
- Struttura progetto e architettura
- Connessione backend iniziale