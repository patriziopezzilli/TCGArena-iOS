//
//  SharedComponents.swift
//  TCG Arena
//
//  Created by TCG Arena Team on 11/10/25.
//

import SwiftUI

// MARK: - Section Header
struct SectionHeaderView: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Modern Text Field
struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                SwiftUI.Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                TextField("Enter \(title.lowercased())", text: $text)
                    .font(.system(size: 16, weight: .medium))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}

// MARK: - Modern Picker Field
struct ModernPickerField<T: Hashable & CaseIterable>: View {
    let title: String
    @Binding var selection: T
    let options: T.AllCases
    let icon: String
    let displayName: (T) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Menu {
                ForEach(Array(options), id: \.self) { option in
                    Button(action: { selection = option }) {
                        Text(displayName(option))
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    SwiftUI.Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    
                    Text(displayName(selection))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    SwiftUI.Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
    }
}

// MARK: - Modern Toggle Field
struct ModernToggleField: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        SectionHeaderView(title: "Test Section", subtitle: "Test subtitle")
        
        ModernTextField(title: "Name", text: .constant("Test"), icon: "textformat")
        
        ModernPickerField(
            title: "Type",
            selection: .constant(TCGType.pokemon),
            options: TCGType.allCases,
            icon: "gamecontroller"
        ) { type in
            type.displayName
        }
        
        ModernToggleField(
            title: "Public",
            subtitle: "Make this item public",
            isOn: .constant(true),
            icon: "globe"
        )
    }
    .padding()
}