# Trade Radar Feature - Technical Documentation

## 1. Overview
The **Trade Radar** is a geolocation-based feature that allows TCG Arena users to find trade partners nearby. It matches users based on their "Have" (Offro) and "Want" (Cerco) lists within a specific radius (default 50km).

## 2. Architecture

### Backend (Spring Boot)
- **Controller**: `TradeController` exposes endpoints for list management and matching.
- **Service**: `TradeService` handles the business logic.
  - **Matching Logic**: Uses the Haversine formula to calculate distances between users.
  - **Filtering**: Matches are found by cross-referencing `TradeListEntry` records (User A "Have" vs User B "Want").
- **Entities**:
  - `TradeListEntry`: Represents a card in a user's list.
  - `TradeMatch`: Represents a calculated match (transient or persisted).

### iOS (SwiftUI)
- **Views**:
  - `TradeRadarView`: Main dashboard with Radar, Lists, and Chat tabs.
  - `RadarScannerView`: Visual representation of the scanning process.
  - `TradeChatView`: Chat interface for negotiating trades.
- **Service**: `TradeService.swift` (Singleton) manages API calls and state.
- **Models**: `TradeMatch`, `TradeListEntry`, `TradeListType`.

## 3. Data Flow

1.  **List Management**:
    - User adds a card to "Want" or "Have" list via `CardDetailView`.
    - API Call: `POST /api/trade/list/add`.
    - Backend saves `TradeListEntry`.

2.  **Finding Matches**:
    - User opens `TradeRadarView`.
    - App requests location permission (mocked/simulated in simulator).
    - API Call: `GET /api/trade/matches?radius=50`.
    - Backend calculates distances and finds compatible lists.
    - Returns a list of `TradeMatchDTO`.

3.  **Chat & Negotiation**:
    - User selects a match.
    - App opens `TradeChatView`.
    - *Current Status*: Chat is local/transient. Backend persistence for chat messages is planned for Phase 2.

## 4. How to Test

### Prerequisites
- Run the Backend Server (`TCGArena-BE`).
- Run the iOS Simulator (`TCGArena-iOS`).
- Ensure you have at least 2 users in the database with different locations (lat/lon).

### Step-by-Step Testing

1.  **Setup User A (You)**:
    - Login to the app.
    - Go to "Collection" or "Discover".
    - Open a card detail.
    - Click **"CERCO"** (Blue button).
    - Verify toast message "Aggiunto alla lista CERCO".

2.  **Setup User B (The Match)**:
    - *Via Database/Postman*: Add a "Have" entry for the SAME card for another user who is within 50km.
    - Example SQL:
      ```sql
      INSERT INTO trade_list_entries (user_id, card_template_id, type) VALUES (2, 101, 'HAVE');
      ```

3.  **Run Radar**:
    - Open **Trade Radar** from the Home Screen.
    - Tap the "OFFLINE" status indicator to toggle it **ONLINE**.
    - The radar will scan and should display User B as a match.

4.  **Check Lists**:
    - Switch to "CERCO" tab in Radar View.
    - Verify the card you added is listed.
    - Click the Trash icon to remove it (API Call: `removeCardFromList`).

5.  **Chat**:
    - Click on the match card in the Radar view.
    - Click "Avvia Chat".
    - Send a message (Simulated).
    - Click "Concludi" to simulate closing the deal.

## 5. Future Improvements
- **Chat Persistence**: Implement WebSocket or Polling for real-time chat stored in DB.
- **Push Notifications**: Notify users when a new match enters their radius.
- **Trade History**: Keep a log of completed trades.
