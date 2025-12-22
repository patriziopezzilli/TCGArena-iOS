//
//  EditCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/6/25.
//

import SwiftUI

struct EditCardView: View {
    let card: Card
    let deckId: Int64?
    var onCardUpdated: ((Card) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    
    @State private var name: String
    @State private var condition: CardCondition
    @State private var gradingCompany: GradeService?
    @State private var grade: CardGrade?
    @State private var certificateNumber: String
    
    init(card: Card, deckId: Int64? = nil, onCardUpdated: ((Card) -> Void)? = nil) {
        self.card = card
        self.deckId = deckId
        self.onCardUpdated = onCardUpdated
        self._name = State(initialValue: card.name)
        self._condition = State(initialValue: card.condition)
        self._gradingCompany = State(initialValue: card.gradingCompany)
        self._grade = State(initialValue: card.grade)
        self._certificateNumber = State(initialValue: card.certificateNumber ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Details")) {
                    TextField("Card Name", text: $name)
                    
                    Picker("Condition", selection: $condition) {
                        ForEach(CardCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(condition)
                        }
                    }
                }
                
                Section(header: Text("Grading")) {
                    Picker("Grading Company", selection: $gradingCompany) {
                        Text("Nessuna").tag(GradeService?.none)
                        ForEach(GradeService.allCases, id: \.self) { service in
                            Text(service.displayName).tag(service as GradeService?)
                        }
                    }
                    
                    Picker("Grade", selection: $grade) {
                        Text("None").tag(CardGrade?.none)
                        ForEach(CardGrade.allCases, id: \.self) { grade in
                            Text(grade.displayName).tag(grade as CardGrade?)
                        }
                    }
                    
                    TextField("Certificate Number", text: $certificateNumber)
                }
            }
            .navigationTitle("Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annulla") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Salva") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        // Update in service with original card ID and new values
        cardService.updateCard(
            originalCard: card, 
            name: name, 
            condition: condition,
            gradingCompany: gradingCompany,
            grade: grade,
            certificateNumber: certificateNumber.isEmpty ? nil : certificateNumber,
            deckId: deckId
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedCard):
                    // Card updated successfully on backend
                    // Call callback to update parent view
                    onCardUpdated?(updatedCard)
                    dismiss()
                case .failure(let error):
                    // Handle error, perhaps show alert
                    print("Error updating card: \(error.localizedDescription)")
                    dismiss()
                }
            }
        }
    }
}
