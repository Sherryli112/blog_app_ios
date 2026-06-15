import SwiftUI

enum AppTheme {
    enum Color {
        static let primary       = SwiftUI.Color(hex: 0xF58900)
        static let primaryDark   = SwiftUI.Color(hex: 0xD97606)
        static let primaryLight  = SwiftUI.Color(hex: 0xFFB04D)
        static let accent        = SwiftUI.Color(hex: 0x009E8E)
        static let accentLight   = SwiftUI.Color(hex: 0x2BC4B4)

        static let background    = SwiftUI.Color(light: SwiftUI.Color(hex: 0xF2F2F7),
                                                 dark: SwiftUI.Color(hex: 0x121212))
        static let cardSurface   = SwiftUI.Color(light: .white,
                                                 dark: SwiftUI.Color(hex: 0x1C1C1E))
        static let textPrimary   = SwiftUI.Color.primary
        static let textSecondary = SwiftUI.Color.secondary
    }

    enum Gradient {
        static let primary = LinearGradient(
            colors: [Color.primary, Color.primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    enum Font {
        static let cardTitle     = SwiftUI.Font.title3.bold()
        static let sectionHeader = SwiftUI.Font.headline
        static let body          = SwiftUI.Font.body
        static let meta          = SwiftUI.Font.subheadline
        static let button        = SwiftUI.Font.headline
        static let tag           = SwiftUI.Font.caption.weight(.heavy)
    }

    enum Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 14
        static let card: CGFloat  = 22
        static let hero: CGFloat  = 18
    }
}
