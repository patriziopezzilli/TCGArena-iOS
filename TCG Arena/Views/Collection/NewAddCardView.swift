//
//  NewAddCardView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI
import Vision
import VisionKit
import PhotosUI

struct NewAddCardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cardService: CardService
    @EnvironmentObject var deckService: DeckService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 80, height: 80)
                        
                        SwiftUI.Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Add New Card")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Choose how you'd like to add your card to the collection")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Options
                VStack(spacing: 20) {
                    // OCR Option
                    NavigationLink(destination: CardScanView()
                        .environmentObject(cardService)
                        .environmentObject(deckService)) {
                        AddCardOptionView(
                            icon: "camera.viewfinder",
                            title: "Scan Card",
                            subtitle: "Use camera to automatically detect card details",
                            color: Color.blue,
                            isRecommended: true
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Manual Option
                    NavigationLink(destination: ManualAddCardView()
                        .environmentObject(cardService)
                        .environmentObject(deckService)) {
                        AddCardOptionView(
                            icon: "keyboard",
                            title: "Add Manually", 
                            subtitle: "Enter card information by hand",
                            color: Color.purple,
                            isRecommended: false
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Quick Tips
                VStack(spacing: 12) {
                    HStack {
                        SwiftUI.Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text("Pro Tips")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TipRowView(
                            icon: "camera",
                            text: "For best results, scan cards in good lighting"
                        )
                        
                        TipRowView(
                            icon: "hand.raised.fill",
                            text: "Make sure the card is flat and fully visible"
                        )
                        
                        TipRowView(
                            icon: "checkmark.circle",
                            text: "Review scanned info before saving"
                        )
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}

// MARK: - Add Card Option View
struct AddCardOptionView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isRecommended: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 60, height: 60)
                
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if isRecommended {
                        Text("RECOMMENDED")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.green)
                            )
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            
            // Arrow
            SwiftUI.Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(color)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color, lineWidth: isRecommended ? 2 : 1)
                .opacity(isRecommended ? 0.6 : 0.3)
        )
    }
}

// MARK: - Tip Row View
struct TipRowView: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(nil)
            
            Spacer()
        }
    }
}

#Preview {
    NewAddCardView()
        .environmentObject(CardService())
}