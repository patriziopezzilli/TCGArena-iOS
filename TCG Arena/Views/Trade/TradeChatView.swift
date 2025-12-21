//
//  TradeChatView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI

struct TradeChatView: View {
    let match: TradeMatch
    @Environment(\.presentationMode) var presentationMode
    @State private var messageText = ""
    @State private var messages: [TradeMessage] = []
    @State private var showCloseDealAlert = false
    @State private var timer: Timer?
    @State private var currentStatus: String?
    
    var isChatActive: Bool {
        let status = currentStatus ?? match.status
        return status != "COMPLETED" && status != "CANCELLED"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    SwiftUI.Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                    SwiftUI.Image(systemName: match.userAvatar)
                        .foregroundColor(.white)
                        .font(.system(size: 14))
                }
                .padding(.leading, 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.userName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    // Removed "Online" badge
                }
                
                Spacer()
                
                if isChatActive {
                    Button(action: { showCloseDealAlert = true }) {
                        Text("Concludi")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            
            // Trade Context Header
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Text("In trattativa per:")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    ForEach(match.matchedCards) { card in
                        HStack(spacing: 6) {
                            SwiftUI.Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(card.cardName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(red: 0.08, green: 0.08, blue: 0.1))
            
            // Chat Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            TradeMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if !isChatActive {
                            Text("SCAMBIO COMPLETATO")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                                .padding(.top, 20)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    if let lastId = messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input Area
            if isChatActive {
                HStack(spacing: 12) {
                    TextField("Scrivi un messaggio...", text: $messageText)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .foregroundColor(.white)
                    
                    Button(action: sendMessage) {
                        Circle()
                            .fill(messageText.isEmpty ? Color.gray : Color.green)
                            .frame(width: 44, height: 44)
                            .overlay(
                                SwiftUI.Image(systemName: "arrow.up")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                            )
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
                .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            } else {
                HStack {
                    Text("Questa conversazione è terminata.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.1, green: 0.1, blue: 0.12))
            }
        }
        .background(Color(red: 0.05, green: 0.05, blue: 0.07).ignoresSafeArea())
        .navigationBarHidden(true)
        .alert(isPresented: $showCloseDealAlert) {
            Alert(
                title: Text("Concludi Scambio"),
                message: Text("Confermi di aver completato lo scambio con \(match.userName)? Le carte verranno rimosse dalle vostre liste."),
                primaryButton: .default(Text("Conferma Scambio"), action: closeDeal),
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            currentStatus = match.status
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }
    
    func startPolling() {
        fetchMessages()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            fetchMessages()
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchMessages() {
        Task {
            do {
                let response = try await TradeService.shared.fetchMessages(matchId: match.id)
                DispatchQueue.main.async {
                    self.messages = response.messages
                    self.currentStatus = response.matchStatus
                }
            } catch {
                print("Error fetching messages: \(error)")
            }
        }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        let textToSend = messageText
        messageText = "" // Clear immediately for UI responsiveness
        
        Task {
            do {
                try await TradeService.shared.sendMessage(matchId: match.id, content: textToSend)
                fetchMessages() // Refresh immediately
            } catch {
                print("Error sending message: \(error)")
                // Optionally restore text if failed
            }
        }
    }
    
    func closeDeal() {
        Task {
            do {
                try await TradeService.shared.completeTrade(matchId: match.id)
                DispatchQueue.main.async {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                print("Error closing deal: \(error)")
            }
        }
    }
}

struct TradeMessageBubble: View {
    let message: TradeMessage
    
    var body: some View {
        HStack {
            if message.isCurrentUser { Spacer() }
            
            VStack(alignment: message.isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(message.isCurrentUser ? .black : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isCurrentUser ? Color.green : Color(white: 0.2))
                    .cornerRadius(16)
                
                Text(formatTime(message.sentAt))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
            }
            
            if !message.isCurrentUser { Spacer() }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
