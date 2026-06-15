import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.Color.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .shadow(color: AppTheme.Color.primary.opacity(0.08), radius: 12, y: 6)
    }
}

struct GlassCircle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .padding(8)
            .background(.ultraThinMaterial, in: Circle())
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
    func glassCircle() -> some View { modifier(GlassCircle()) }
}

struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}
