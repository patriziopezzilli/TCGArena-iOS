//
//  ToastManager.swift
//  TCG Arena
//
//  Centralized toast notification management
//

import Foundation
import SwiftUI

@MainActor
class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: Toast?

    private init() {}

    // MARK: - Toast Types

    enum ToastType {
        case success
        case error
        case warning
        case info

        var color: Color {
            switch self {
            case .success:
                return .green
            case .error:
                return .red
            case .warning:
                return .orange
            case .info:
                return .blue
            }
        }

        var icon: String {
            switch self {
            case .success:
                return "checkmark.circle.fill"
            case .error:
                return "exclamationmark.triangle.fill"
            case .warning:
                return "exclamationmark.triangle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }

    struct Toast: Identifiable {
        let id = UUID()
        let message: String
        let type: ToastType
        let duration: TimeInterval
    }

    // MARK: - Public Methods

    func showToast(
        _ message: String,
        type: ToastType = .info,
        duration: TimeInterval = 3.0
    ) {
        let toast = Toast(message: message, type: type, duration: duration)
        currentToast = toast

        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                withAnimation(.easeInOut) {
                    if currentToast?.id == toast.id {
                        currentToast = nil
                    }
                }
            }
        }
    }

    func showSuccess(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message, type: .success, duration: duration)
    }

    func showError(_ message: String, duration: TimeInterval = 4.0) {
        showToast(message, type: .error, duration: duration)
    }

    func showWarning(_ message: String, duration: TimeInterval = 3.5) {
        showToast(message, type: .warning, duration: duration)
    }

    func showInfo(_ message: String, duration: TimeInterval = 3.0) {
        showToast(message, type: .info, duration: duration)
    }

    func dismiss() {
        print("Dismiss called, currentToast before: \(currentToast != nil)")
        withAnimation(.easeInOut) {
            currentToast = nil
            print("Dismiss called, currentToast after: \(currentToast != nil)")
        }
    }
}

// MARK: - View Extension for Toast Support
extension View {
    func withToastSupport() -> some View {
        self.modifier(ToastModifier())
    }
}

struct ToastModifier: ViewModifier {
    @ObservedObject private var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if let toast = toastManager.currentToast {
                ToastNotificationView(toast: toast)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: toastManager.currentToast?.id)
    }
}

struct ToastNotificationView: View {
    let toast: ToastManager.Toast

    var body: some View {
        HStack(spacing: 12) {
            SwiftUI.Image(systemName: toast.type.icon)
                .foregroundColor(SwiftUI.Color.white)
                .font(.system(size: 18, weight: .semibold))

            SwiftUI.Text(toast.message)
                .foregroundColor(SwiftUI.Color.white)
                .font(.system(size: 14, weight: .semibold))
                .multilineTextAlignment(.leading)

            Spacer()

            SwiftUI.Button(action: {
                print("X button tapped")
                ToastManager.shared.dismiss()
            }) {
                SwiftUI.Image(systemName: "xmark")
                    .foregroundColor(SwiftUI.Color.white)
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .background(SwiftUI.Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(toast.type.color.opacity(0.95))
        )
        .shadow(color: SwiftUI.Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
}
