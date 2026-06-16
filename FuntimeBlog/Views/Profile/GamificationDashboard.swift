import SwiftUI

struct GamificationDashboard: View {
    @Environment(GameStore.self) private var gameStore

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            XPProgressView()
            CheckInView()
        }
    }
}

#Preview {
    GamificationDashboard()
        .padding()
        .environment(GameStore())
}
