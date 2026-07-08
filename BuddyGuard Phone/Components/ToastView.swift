import SwiftUI

struct ToastView: View {
    let icon: String
    let message: String
    var tint: Color = .green

    @State private var expanded = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .symbolEffect(.pulse, isActive: expanded)

            if expanded {
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.darkActive)
                    .lineLimit(2)
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
            }
        }
        .padding(.horizontal, expanded ? 22 : 16)
        .padding(.vertical, expanded ? 16 : 12)
        .frame(minWidth: expanded ? 280 : 52)
        .background {
            Capsule()
                .fill(.lightD)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
        }
        .clipShape(Capsule())
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                expanded = true
            }
        }
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let icon: String
    let message: String
    var tint: Color = .green
    var duration: TimeInterval = 2.5

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented {
                ToastView(icon: icon, message: message, tint: tint)
                    .padding(.top, 8)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.4, anchor: .top).combined(with: .opacity),
                            removal: .scale(scale: 0.6, anchor: .top).combined(with: .opacity)
                        )
                    )
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.easeOut(duration: 0.3)) { isPresented = false }
                        }
                    }
                    .zIndex(999)
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.2), value: isPresented)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, icon: String, message: String, tint: Color = .green, duration: TimeInterval = 2.5) -> some View {
        modifier(ToastModifier(isPresented: isPresented, icon: icon, message: message, tint: tint, duration: duration))
    }
}

#Preview("Light") {
    ToastView(icon: "checkmark.circle.fill", message: "Emergency contacts have been notified", tint: .green)
}

#Preview("Dark") {
    ToastView(icon: "checkmark.circle.fill", message: "Emergency contacts have been notified", tint: .green)
        .preferredColorScheme(.dark)
}
