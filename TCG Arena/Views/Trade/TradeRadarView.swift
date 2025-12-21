//
//  TradeRadarView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI
import MapKit

struct TradeRadarView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var tradeService = TradeService.shared
    @State private var isScanning = false
    @State private var selectedTab = 0 // 0: Radar, 1: Cerco, 2: Offro, 3: Chat
    @State private var showMatchDetail = false
    @State private var selectedMatch: TradeMatch?
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            // Dark Theme Background
            Color(red: 0.05, green: 0.05, blue: 0.07)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        SwiftUI.Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.trailing, 8)
                    
                    Text("TRADE RADAR")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .tracking(2)
                    Spacer()
                    
                    // Status Indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isScanning ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(isScanning ? "ONLINE" : "OFFLINE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isScanning ? .green : .gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                    .onTapGesture {
                        withAnimation { isScanning.toggle() }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 20)
                
                // Custom Segmented Control
                HStack(spacing: 0) {
                    RadarTabButton(title: "RADAR", isSelected: selectedTab == 0) { selectedTab = 0 }
                    RadarTabButton(title: "CERCO", isSelected: selectedTab == 1) { selectedTab = 1 }
                    RadarTabButton(title: "OFFRO", isSelected: selectedTab == 2) { selectedTab = 2 }
                    RadarTabButton(title: "CHAT", isSelected: selectedTab == 3) { selectedTab = 3 }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                
                if selectedTab == 0 {
                    RadarScannerView(isScanning: $isScanning, matches: tradeService.matches) { match in
                        selectedMatch = match
                        showMatchDetail = true
                    }
                } else if selectedTab == 1 {
                    TradeListView(type: .want)
                } else if selectedTab == 2 {
                    TradeListView(type: .have)
                } else {
                    TradeChatListView()
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $selectedMatch) { match in
            TradeMatchDetailView(match: match)
        }
        .onAppear {
            if isScanning {
                tradeService.fetchMatches()
                startScanning()
            }
        }
        .onDisappear {
            stopScanning()
        }
        .onChange(of: isScanning) { newValue in
            if newValue {
                tradeService.fetchMatches()
                startScanning()
            } else {
                stopScanning()
                tradeService.matches = []
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func startScanning() {
        stopScanning()
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            tradeService.fetchMatches()
        }
    }
    
    func stopScanning() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Subviews

struct RadarScannerView: View {
    @Binding var isScanning: Bool
    var matches: [TradeMatch]
    var onSelect: (TradeMatch) -> Void
    
    // Animation states
    @State private var rotation: Double = 0
    @State private var rippleScale: CGFloat = 0
    @State private var rippleOpacity: Double = 1
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 * 0.85
            
            ZStack {
                if isScanning {
                    // 1. Grid Background
                    RadarGrid(radius: radius)
                    
                    // 2. Rotating Sweep
                    ZStack {
                        AngularGradient(
                            gradient: Gradient(colors: [.green.opacity(0), .green.opacity(0.1), .green.opacity(0.5)]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        )
                    }
                    .frame(width: radius * 2, height: radius * 2)
                    .clipShape(Circle())
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            rotation = 360
                        }
                    }
                    
                    // 3. Ripples from center
                    Circle()
                        .stroke(Color.green.opacity(0.5), lineWidth: 2)
                        .frame(width: radius * 2 * rippleScale)
                        .opacity(rippleOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) {
                                rippleScale = 1
                                rippleOpacity = 0
                            }
                        }
                    
                    // 4. Matches as Blips
                    ForEach(matches) { match in
                        // Calculate position based on distance
                        // Max distance 10km for visualization
                        let maxDist: Double = 10000
                        let distRatio = min(match.distance / maxDist, 1.0)
                        // Ensure it's not too close to center (min 20%)
                        let adjustedRatio = 0.2 + (distRatio * 0.8)
                        let blipRadius = CGFloat(adjustedRatio) * radius
                        
                        // Random angle based on ID hash
                        let angle = Double(abs(match.id.hashValue) % 360)
                        
                        RadarBlip(match: match)
                            .position(
                                x: center.x + blipRadius * cos(angle * .pi / 180),
                                y: center.y + blipRadius * sin(angle * .pi / 180)
                            )
                            .onTapGesture {
                                onSelect(match)
                            }
                    }
                    
                    // Center User Dot
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .shadow(color: .green, radius: 10, x: 0, y: 0)
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 12, height: 12)
                    }
                    .position(center)
                    
                } else {
                    // Offline State
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 150, height: 150)
                            
                            SwiftUI.Image(systemName: "wifi.slash")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        }
                        
                        Text("RADAR OFFLINE")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)
                            .tracking(2)
                        
                        Button(action: {
                            withAnimation { isScanning = true }
                        }) {
                            Text("ATTIVA SISTEMA")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.green)
                                .cornerRadius(8)
                                .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 0)
                        }
                    }
                    .position(center)
                }
                
                // Matches Layer (Bottom aligned)
                if isScanning && !matches.isEmpty {
                    VStack {
                        Spacer()
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(matches) { match in
                                    MatchCard(match: match)
                                        .onTapGesture {
                                            onSelect(match)
                                        }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct RadarGrid: View {
    let radius: CGFloat
    
    var body: some View {
        ZStack {
            // Concentric circles
            ForEach(1...4, id: \.self) { i in
                Circle()
                    .stroke(Color.green.opacity(Double(i) * 0.1), lineWidth: 1)
                    .frame(width: radius * 2 * CGFloat(i) / 4)
            }
            
            // Crosshairs
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [.clear, .green.opacity(0.3), .clear]), startPoint: .top, endPoint: .bottom))
                .frame(width: 1, height: radius * 2)
            
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [.clear, .green.opacity(0.3), .clear]), startPoint: .leading, endPoint: .trailing))
                .frame(width: radius * 2, height: 1)
        }
    }
}

struct RadarBlip: View {
    let match: TradeMatch
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0
    
    var blipColor: Color {
        if match.matchType == .history { return .gray }
        return match.matchType == .theyHaveWhatIWant ? .green : .blue
    }
    
    var body: some View {
        ZStack {
            // Icon
            Circle()
                .fill(blipColor)
                .frame(width: 12, height: 12)
                .shadow(color: blipColor, radius: 5)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            // Pulse
            Circle()
                .stroke(blipColor, lineWidth: 1)
                .frame(width: 30, height: 30)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                        scale = 1.5
                        opacity = 0
                    }
                }
            
            // Label (Distance)
            Text(match.distance < 1000 ? "\(Int(match.distance))m" : String(format: "%.1fkm", match.distance/1000))
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(2)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .offset(y: 20)
        }
    }
}

struct MatchCard: View {
    let match: TradeMatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                    SwiftUI.Image(systemName: match.userAvatar)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.userName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    if match.distance >= 1000 {
                        Text(String(format: "%.1fkm di distanza", match.distance / 1000))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    } else {
                        Text("\(Int(match.distance))m di distanza")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            if match.matchType == .history {
                Text("CHAT STORICA")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
            } else {
                Text(match.matchType == .theyHaveWhatIWant ? "HA QUELLO CHE CERCHI:" : "CERCA QUELLO CHE HAI:")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(match.matchType == .theyHaveWhatIWant ? .green : .blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if match.matchedCards.isEmpty {
                    Text("Nessuna carta in comune")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(.vertical, 8)
                } else {
                    ForEach(match.matchedCards.prefix(2)) { card in
                        HStack {
                            SwiftUI.Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(card.cardName)
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    if match.matchedCards.count > 2 {
                        Text("+\(match.matchedCards.count - 2) altre")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .frame(width: 260, height: 190)
        .background(Color(white: 0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(match.matchType == .history ? Color.gray.opacity(0.5) : (match.matchType == .theyHaveWhatIWant ? Color.green.opacity(0.5) : Color.blue.opacity(0.5)), lineWidth: 1)
        )
    }
}

struct TradeListView: View {
    let type: TradeListType
    @StateObject private var tradeService = TradeService.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            let list = type == .want ? tradeService.wantList : tradeService.haveList
            
            if list.isEmpty {
                RadarEmptyStateView(
                    icon: type == .want ? "magnifyingglass" : "tray",
                    text: type == .want ? "Non cerchi nessuna carta al momento." : "Non offri nessuna carta al momento.",
                    actionTitle: "AGGIUNGI CARTE",
                    action: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(list) { entry in
                            HStack(spacing: 12) {
                                if let imageUrl = entry.imageUrl, let url = URL(string: imageUrl) {
                                    CachedAsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        case .failure(_):
                                            Color.gray.opacity(0.3)
                                        case .empty:
                                            ProgressView()
                                        @unknown default:
                                            Color.gray.opacity(0.3)
                                        }
                                    }
                                    .frame(width: 60, height: 84)
                                    .cornerRadius(6)
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 84)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.cardName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack(spacing: 6) {
                                        if let tcgType = entry.tcgType {
                                            Text(tcgType)
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .cornerRadius(4)
                                        }
                                        
                                        if let rarity = entry.rarity {
                                            Text(rarity)
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.purple.opacity(0.2))
                                                .foregroundColor(.purple)
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    tradeService.removeCardFromList(cardId: entry.cardTemplateId, type: type)
                                }) {
                                    SwiftUI.Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red.opacity(0.8))
                                        .padding(8)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                            .padding(12)
                            .background(Color(white: 0.12))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            tradeService.fetchList(type: type)
        }
    }
}

struct TradeChatListView: View {
    @StateObject private var tradeService = TradeService.shared
    
    var body: some View {
        VStack {
            if tradeService.matches.isEmpty {
                RadarEmptyStateView(icon: "bubble.left.and.bubble.right", text: "Nessuna chat attiva.")
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(tradeService.matches) { chat in
                            NavigationLink(destination: TradeChatView(match: chat)) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                        SwiftUI.Image(systemName: chat.userAvatar)
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chat.userName)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("Ultimo messaggio: Ciao! Disponibile?")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("10:30")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        
                                        if chat.status == "COMPLETED" {
                                            Text("CONCLUSO")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.gray)
                                                .cornerRadius(4)
                                        } else if chat.status == "CANCELLED" {
                                            Text("ANNULLATO")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.red.opacity(0.5))
                                                .cornerRadius(4)
                                        } else {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 10, height: 10)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(white: 0.1))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Refresh matches to populate chat list (temporary solution)
            tradeService.fetchMatches()
        }
    }
}

struct RadarEmptyStateView: View {
    let icon: String
    let text: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct RadarTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Rectangle()
                    .fill(isSelected ? Color.green : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct TradeMatchDetailView: View {
    let match: TradeMatch
    @Environment(\.presentationMode) var presentationMode
    @State private var isChatActive = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea()
                
                // Hidden Navigation Link for Chat
                NavigationLink(destination: TradeChatView(match: match), isActive: $isChatActive) {
                    EmptyView()
                }
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Spacer()
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            SwiftUI.Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    
                    // User Profile
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.green, lineWidth: 2)
                                .frame(width: 100, height: 100)
                            SwiftUI.Image(systemName: match.userAvatar)
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(match.userName)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            Text("Allenatore Certificato")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Cards
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SCAMBIO PROPOSTO")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                        
                        ForEach(match.matchedCards) { entry in
                            HStack(spacing: 12) {
                                if let imageUrl = entry.imageUrl, let url = URL(string: imageUrl) {
                                    CachedAsyncImage(url: url) { phase in
                                        switch phase {
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        case .failure(_):
                                            Color.gray.opacity(0.3)
                                        case .empty:
                                            ProgressView()
                                        @unknown default:
                                            Color.gray.opacity(0.3)
                                        }
                                    }
                                    .frame(width: 60, height: 84)
                                    .cornerRadius(6)
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 60, height: 84)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(entry.cardName)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack(spacing: 6) {
                                        if let tcgType = entry.tcgType {
                                            Text(tcgType)
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.blue.opacity(0.2))
                                                .foregroundColor(.blue)
                                                .cornerRadius(4)
                                        }
                                        
                                        if let rarity = entry.rarity {
                                            Text(rarity)
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 3)
                                                .background(Color.purple.opacity(0.2))
                                                .foregroundColor(.purple)
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                SwiftUI.Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.green)
                            }
                            .padding(12)
                            .background(Color(white: 0.12))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Action Button
                    Button(action: {
                        Task {
                            do {
                                try await TradeService.shared.startChat(matchId: match.id)
                                DispatchQueue.main.async {
                                    isChatActive = true
                                }
                            } catch {
                                print("Error starting chat: \(error)")
                                DispatchQueue.main.async {
                                    isChatActive = true
                                }
                            }
                        }
                    }) {
                        HStack {
                            SwiftUI.Image(systemName: "bubble.left.fill")
                            Text("Avvia Chat")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(16)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
}


