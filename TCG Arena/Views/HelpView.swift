//
//  HelpView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/20/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SUPPORTO")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .tracking(2)
                        
                        Text("Come possiamo aiutarti?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // FAQ Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            SwiftUI.Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.blue)
                            Text("Domande Frequenti")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 0) {
                            FAQItem(
                                question: "Come funziona il sistema punti?",
                                answer: "Guadagni punti partecipando a tornei, scansionando carte e interagendo con la community. I punti possono essere riscattati per premi esclusivi."
                            )
                            Divider().padding(.horizontal)
                            FAQItem(
                                question: "Come aggiungo carte alla mia collezione?",
                                answer: "Usa il pulsante + nella sezione Carte per scansionare o cercare manualmente le carte da aggiungere."
                            )
                            Divider().padding(.horizontal)
                            FAQItem(
                                question: "Come partecipo a un torneo?",
                                answer: "Trova un torneo nella sezione Negozi o Eventi, clicca su di esso e premi 'Iscriviti'. Segui le istruzioni del negozio."
                            )
                            Divider().padding(.horizontal)
                            FAQItem(
                                question: "Come cambio il mio TCG preferito?",
                                answer: "Vai in Altro → Impostazioni e seleziona i tuoi TCG preferiti nella sezione dedicata."
                            )
                        }
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 24)
                    }
                    
                    // Contact Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            SwiftUI.Image(systemName: "envelope.fill")
                                .foregroundColor(.green)
                            Text("Contattaci")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            ContactRow(
                                icon: "envelope.fill",
                                title: "Email",
                                subtitle: "support@tcgarena.it",
                                color: .blue
                            ) {
                                if let url = URL(string: "mailto:support@tcgarena.it") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            ContactRow(
                                icon: "globe",
                                title: "Sito Web",
                                subtitle: "www.tcgarena.it",
                                color: .purple
                            ) {
                                if let url = URL(string: "https://www.tcgarena.it") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            
                            ContactRow(
                                icon: "message.fill",
                                title: "Social",
                                subtitle: "@tcgarena_official",
                                color: .pink
                            ) {
                                if let url = URL(string: "https://instagram.com/tcgarena_official") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Chiudi") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Text(question)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    SwiftUI.Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(16)
            }
            
            if isExpanded {
                Text(answer)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                SwiftUI.Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
