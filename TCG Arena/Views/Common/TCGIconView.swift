import SwiftUI

/// A view that displays the icon for a TCG type, using custom icons when available
/// and falling back to SF Symbols otherwise
struct TCGIconView: View {
    let tcgType: TCGType
    var size: CGFloat = 20
    var color: Color? = nil
    
    var body: some View {
        Group {
            if let customIcon = tcgType.customIconName {
                SwiftUI.Image(customIcon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                SwiftUI.Image(systemName: tcgType.systemIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: size, height: size)
        .foregroundColor(color ?? tcgType.themeColor)
    }
}

#Preview {
    VStack(spacing: 20) {
        ForEach(TCGType.allCases, id: \.self) { tcg in
            HStack {
                TCGIconView(tcgType: tcg, size: 24)
                Text(tcg.displayName)
            }
        }
    }
    .padding()
}

