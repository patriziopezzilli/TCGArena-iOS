import Foundation
import Combine

@MainActor
class ChatService: ObservableObject {
    @Published var conversations: [ChatConversation] = []
    @Published var currentMessages: [ChatMessage] = []
    @Published var isLoading = false
    
    private let apiClient = APIClient.shared
    
    // Polling support
    private var pollingTimer: Timer?
    
    func startPolling(conversationId: Int64) {
        stopPolling()
         // Poll every 3 seconds
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.loadMessages(conversationId: conversationId, showLoading: false)
            }
        }
    }
    
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    // MARK: - API Methods
    
    func loadConversations() async {
        isLoading = true
        do {
            let fetched: [ChatConversation] = try await apiClient.request("/api/chat", method: "GET")
            self.conversations = fetched
        } catch {
            print("❌ Error loading conversations: \(error)")
        }
        isLoading = false
    }
    
    func startChat(targetUserId: Int64, type: ChatType, context: String? = nil, completion: @escaping (ChatConversation?) -> Void) {
        let req = CreateChatRequest(targetUserId: targetUserId, type: type.rawValue, contextJson: context)
        
        Task {
            do {
                let conv: ChatConversation = try await apiClient.request("/api/chat/start", method: "POST", body: req)
                completion(conv)
            } catch {
                print("❌ Error starting chat: \(error)")
                completion(nil)
            }
        }
    }
    
    func loadMessages(conversationId: Int64, showLoading: Bool = true) async {
        if showLoading && currentMessages.isEmpty { isLoading = true }
        do {
            let msgs: [ChatMessage] = try await apiClient.request("/api/chat/\(conversationId)/messages", method: "GET")
            // Only update if changed to avoid jitter, or just replace
            if msgs != self.currentMessages {
                self.currentMessages = msgs
            }
        } catch {
            print("❌ Error loading messages: \(error)")
        }
        if showLoading { isLoading = false }
    }
    
    func sendMessage(conversationId: Int64, content: String) async {
        let req = ChatSendMessageRequest(content: content)
        do {
            let newMsg: ChatMessage = try await apiClient.request("/api/chat/\(conversationId)/send", method: "POST", body: req)
            self.currentMessages.append(newMsg)
        } catch {
             print("❌ Error sending message: \(error)")
        }
    }
    
    func completeTrade(conversationId: Int64, points: Int) async -> Bool {
        let req = CompleteTradeRequest(points: points)
        do {
            let _: ChatConversation = try await apiClient.request("/api/chat/\(conversationId)/complete", method: "POST", body: req)
            return true
        } catch {
            print("❌ Error completing trade: \(error)")
            return false
        }
    }
}

struct CompleteTradeRequest: Encodable {
    let points: Int
}
