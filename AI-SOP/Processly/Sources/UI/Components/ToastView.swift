import SwiftUI

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .accessibilityAddTraits(.isStatus)
    }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?
    let duration: TimeInterval

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    ToastView(message: message)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    self.message = nil
                                }
                            }
                        }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: message)
    }
}

extension View {
    func toast(message: Binding<String?>, duration: TimeInterval = 3) -> some View {
        modifier(ToastModifier(message: message, duration: duration))
    }
}

