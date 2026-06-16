import SwiftUI

struct CheckInView: View {
    @Environment(GameStore.self) private var gameStore
    @State private var showReward = false
    @State private var earnedXP = 0
    @State private var checkInDone = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("連續簽到 \(gameStore.profile.streakDays) 天")
                    .font(.headline)
            }

            HStack(spacing: 12) {
                ForEach(1...7, id: \.self) { day in
                    Circle()
                        .fill(day <= gameStore.profile.streakDays
                              ? AppTheme.Color.primary
                              : Color.secondary.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay {
                            if day <= gameStore.profile.streakDays {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                }
            }

            Button {
                earnedXP = gameStore.checkIn()
                checkInDone = true
                showReward = true
            } label: {
                Label(
                    gameStore.profile.canCheckInToday
                        ? "今日簽到 (+\(min(gameStore.profile.streakDays + 1, 7) * 10) XP)"
                        : "今日已簽到",
                    systemImage: gameStore.profile.canCheckInToday ? "star.fill" : "checkmark.circle.fill"
                )
            }
            .primaryButtonStyle()
            .disabled(!gameStore.profile.canCheckInToday || checkInDone)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .sensoryFeedback(.success, trigger: checkInDone)
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .alert("簽到成功！", isPresented: $showReward) {
            Button("太棒了") { }
        } message: {
            Text("獲得 \(earnedXP) XP！連續簽到 \(gameStore.profile.streakDays) 天")
        }
    }
}

#Preview {
    CheckInView()
        .padding()
        .environment(GameStore())
}
