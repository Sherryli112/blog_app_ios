import SwiftUI

struct XPProgressView: View {
    @Environment(GameStore.self) private var gameStore

    var body: some View {
        let profile = gameStore.profile

        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lv.\(profile.level) \(GameProfile.levelTitle(for: profile.level))")
                        .font(.title3.bold())
                    Text("\(profile.xpInCurrentLevel) / \(profile.xpForThisLevel) XP")
                        .font(AppTheme.Font.meta)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(AppTheme.Color.primary.opacity(0.2), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: profile.levelProgress)
                        .stroke(AppTheme.Color.primary,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(profile.levelProgress * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.Color.primary)
                }
                .frame(width: 52, height: 52)
                .animation(.spring, value: profile.levelProgress)
            }

            ProgressView(value: profile.levelProgress)
                .tint(AppTheme.Color.primary)
                .scaleEffect(x: 1, y: 1.5)

            if profile.level < 6 {
                Text("再 \(profile.xpForThisLevel - profile.xpInCurrentLevel) XP 升至 Lv.\(profile.level + 1) \(GameProfile.levelTitle(for: profile.level + 1))")
                    .font(AppTheme.Font.meta)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
    }
}

#Preview {
    XPProgressView()
        .padding()
        .environment(GameStore())
}
