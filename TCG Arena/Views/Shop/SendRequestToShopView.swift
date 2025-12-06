//
//  SendRequestToShopView.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 12/3/25.
//

import SwiftUI

struct SendRequestToShopView: View {
    let shop: Shop
    let onRequestSent: (() -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var requestService: RequestService
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedType: CustomerRequest.RequestType = .general
    @State private var title = ""
    @State private var description = ""
    @State private var isSending = false
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        title.count >= 5
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Shop Info Header
                        shopInfoHeader
                        
                        // Request Type Selector
                        requestTypeSection
                        
                        // Form Fields
                        formFieldsSection
                        
                        // Tips Section
                        tipsSection
                        
                        // Send Button
                        sendButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Send Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        SwiftUI.Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Shop Info Header
    private var shopInfoHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                SwiftUI.Image(systemName: "storefront.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(shop.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if shop.isVerified {
                        SwiftUI.Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }
                
                Text(shop.address)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Request Type Section
    private var requestTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What do you need?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(CustomerRequest.RequestType.allCases, id: \.self) { type in
                    RequestTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Form Fields Section
    private var formFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Title")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text("*")
                        .foregroundColor(.red)
                }
                
                TextField("Brief description of your request...", text: $title)
                    .font(.system(size: 16))
                    .padding(14)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(!title.isEmpty ? Color.indigo.opacity(0.5) : Color.clear, lineWidth: 1.5)
                    )
                
                HStack {
                    Text("\(title.count)/100")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !title.isEmpty && title.count < 5 {
                        Text("Min 5 characters")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Description Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Details (Optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Add more details: card names, conditions, quantities, budget range...")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                    }
                    
                    TextEditor(text: $description)
                        .font(.system(size: 15))
                        .frame(minHeight: 100)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .scrollContentBackground(.hidden)
                }
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                SwiftUI.Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Tips for a great request")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                RequestTipRow(text: "Be specific about card names and sets")
                RequestTipRow(text: "Mention the condition you're looking for")
                RequestTipRow(text: "Include quantity if buying multiple")
                RequestTipRow(text: "Add your budget range for evaluations")
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Send Button
    private var sendButton: some View {
        Button(action: sendRequest) {
            HStack(spacing: 8) {
                if isSending {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    SwiftUI.Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                    Text("Send Request")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isValid ? Color.indigo : Color.gray)
            )
        }
        .disabled(!isValid || isSending)
        .padding(.top, 8)
    }
    
    // MARK: - Send Request
    private func sendRequest() {
        guard isValid, authService.currentUserId != nil else { return }
        
        isSending = true
        
        let request = CreateRequestRequest(
            shopId: String(shop.id),
            type: selectedType,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? "No additional details" : description.trimmingCharacters(in: .whitespacesAndNewlines),
            attachmentUrl: nil
        )
        
        Task {
            do {
                _ = try await requestService.createRequest(request)
                await MainActor.run {
                    isSending = false
                    onRequestSent?()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSending = false
                    ToastManager.shared.showError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Request Type Card
private struct RequestTypeCard: View {
    let type: CustomerRequest.RequestType
    let isSelected: Bool
    let action: () -> Void
    
    private var typeColor: Color {
        switch type.color {
        case "blue": return .indigo
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "cyan": return .cyan
        default: return .gray
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? typeColor : typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    SwiftUI.Image(systemName: type.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : typeColor)
                }
                
                Text(type.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? typeColor : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? typeColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? typeColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Request Tip Row
private struct RequestTipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            SwiftUI.Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
                .padding(.top, 2)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SendRequestToShopView(shop: Shop.preview, onRequestSent: nil)
        .environmentObject(RequestService())
        .environmentObject(AuthService())
        .withToastSupport()
}
