//
//  EditCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/6/25.
//

import SwiftUI

struct EditCardView: View {
    let card: Card
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    
    @State private var name: String
    @State private var condition: Card.CardCondition
    
    init(card: Card) {
        self.card = card
        self._name = State(initialValue: card.name)
        self._condition = State(initialValue: card.condition)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Details")) {
                    TextField("Card Name", text: $name)
                    
                    Picker("Condition", selection: $condition) {
                        ForEach(Card.CardCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        // Update in service with original card ID and new values
        cardService.updateCard(originalCard: card, name: name, condition: condition) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                // Handle error, perhaps show alert
                dismiss()
            }
        }
    }
}

extension Card.CardCondition {
    var displayName: String {
        switch self {
        case .mint: return "Mint"
        case .nearMint: return "Near Mint"
        case .lightlyPlayed: return "Lightly Played"
        case .moderatelyPlayed: return "Moderately Played"
        case .heavilyPlayed: return "Heavily Played"
        case .damaged: return "Damaged"
        }
    }
}
