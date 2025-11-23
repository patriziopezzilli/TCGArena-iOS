//
//  DeckBuilderView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/5/25.
//

import SwiftUI

struct DeckBuilderView: View {
    @StateObject private var deckService = DeckService()
    @State private var showingNewDeck = false
    @State private var selectedTCGType: TCGType? = nil
    
    var filteredUserDecks: [Deck] {
        if let tcgType = selectedTCGType {
            return deckService.userDecks.filter { $0.tcgType == tcgType }
        }
        return deckService.userDecks
    }
    
    var filteredProDecks: [ProDeck] {
        if let tcgType = selectedTCGType {
            return deckService.proDecks.filter { $0.tcgType == tcgType }
        }
        return deckService.proDecks
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Clean Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Decks")
                            .font(.system(size: UIConstants.headerFontSize, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(filteredUserDecks.count) decks")
                            .font(.system(size: UIConstants.subheaderFontSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingNewDeck = true
                    }) {
                        SwiftUI.Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.7, blue: 0.0))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                    
                // Clean TCG Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach([nil] + TCGType.allCases, id: \.self) { tcgType in
                            Button(action: {
                                selectedTCGType = tcgType
                            }) {
                                Text(tcgType?.displayName ?? "All")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(textColorFor(tcgType))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(backgroundColorFor(tcgType))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                    
                VStack(spacing: 20) {
                    // Professional Decks Info Box
                    ProDeckInfoBox()
                        .padding(.horizontal, 20)
                    
                    if filteredUserDecks.isEmpty {
                        VStack(spacing: 24) {
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.8, green: 0.0, blue: 1.0).opacity(0.1))
                                    .frame(width: 120, height: 120)
                                
                                SwiftUI.Image(systemName: "rectangle.stack")
                                    .font(.system(size: 50, weight: .medium))
                                    .foregroundColor(Color(red: 0.8, green: 0.0, blue: 1.0))
                            }
                            
                            VStack(spacing: 12) {
                                Text("No Decks Yet")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Create your first deck to start\nbuilding competitive strategies!")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                        .padding(.vertical, 40)
                    } else {
                        // User Deck List
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(filteredUserDecks) { deck in
                                    NavigationLink(destination: UserDeckListView(deck: deck)) {
                                        UserDeckRowView(deck: deck)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .sheet(isPresented: $showingNewDeck) {
                NewDeckView()
                    .environmentObject(deckService)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func backgroundColorFor(_ tcgType: TCGType?) -> Color {
        if selectedTCGType == tcgType {
            if let type = tcgType {
                return type.themeColor
            } else {
                return Color.black
            }
        } else {
            return Color(.systemGray6)
        }
    }
    
    private func textColorFor(_ tcgType: TCGType?) -> Color {
        return selectedTCGType == tcgType ? .white : .primary
    }
}

struct ProDeckInfoBox: View {
    @State private var showingProDecks = false
    
    var body: some View {
        Button(action: {
            showingProDecks = true
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    SwiftUI.Image(systemName: "star.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Professional Decks")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Vuoi vedere i deck dei professionisti? Clicca qui")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                SwiftUI.Image(systemName: "arrow.right.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: Color.black.opacity(UIConstants.shadowOpacity),
                        radius: UIConstants.shadowRadius,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: UIConstants.cornerRadius)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
        }
        .sheet(isPresented: $showingProDecks) {
            ProDecksListView()
        }
    }
}

#Preview {
    DeckBuilderView()
}