//
//  SuggestionModalView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/21/25.
//

import SwiftUI

struct SuggestionModalView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @State private var isSending = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Cosa vorresti vedere su TCG Arena?")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                TextEditor(text: $text)
                    .frame(height: 200)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                
                Spacer()
                
                Button(action: sendSuggestion) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Invia Suggerimento")
                                .bold()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            }
            .padding()
            .navigationTitle("Suggerimenti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") { dismiss() }
                }
            }
        }
    }
    
    private func sendSuggestion() {
        guard !text.isEmpty else { return }
        isSending = true
        
        let endpoint = "/api/suggestions"
        let body: [String: String] = ["text": text]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        
        APIClient.shared.request(endpoint: endpoint, method: .post, body: jsonData) { result in
            DispatchQueue.main.async {
                isSending = false
                switch result {
                case .success:
                    // Success Haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    ToastManager.shared.showSuccess("Grazie per il tuo feedback!")
                    dismiss()
                case .failure(let error):
                    ToastManager.shared.showError("Errore nell'invio: \(error.localizedDescription)")
                }
            }
        }
    }
}
