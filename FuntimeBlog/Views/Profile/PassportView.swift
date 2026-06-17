import SwiftUI

struct PassportView: View {
    @Environment(GameStore.self) private var gameStore

    private let predefinedCities = [
        "台北", "台中", "台南", "高雄", "宜蘭", "花蓮",
        "東京", "關西", "北海道", "沖繩",
        "首爾", "釜山",
        "曼谷", "清邁", "峇里島", "新加坡",
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.md), count: 4)

    /// 預設城市 + 任何從文章收集到但不在預設清單的城市（例如上海、京都等）
    private func displayCities(stamps: [String]) -> [String] {
        let extra = stamps.filter { !predefinedCities.contains($0) }
        return predefinedCities + extra
    }

    var body: some View {
        let stamps = gameStore.profile.stamps
        let cities = displayCities(stamps: stamps)
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("旅遊護照")
                            .font(.title.bold())
                        Text("已收集 \(stamps.count) / \(cities.count) 個城市印章")
                            .font(AppTheme.Font.meta)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.Color.primary)
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Color.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))

                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
                    ForEach(cities, id: \.self) { city in
                        stampCell(city: city, collected: stamps.contains(city))
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Color.background)
        .navigationTitle("旅遊護照")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stampCell(city: String, collected: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(collected
                          ? AppTheme.Color.primary.opacity(0.15)
                          : Color.secondary.opacity(0.08))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Circle()
                            .stroke(
                                collected ? AppTheme.Color.primary : Color.secondary.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2, dash: collected ? [] : [4, 2])
                            )
                    }

                if collected {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.Color.primary)
                } else {
                    Image(systemName: "questionmark")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }

            Text(city)
                .font(.caption2)
                .foregroundStyle(collected ? .primary : .secondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    NavigationStack {
        PassportView()
    }
    .environment(GameStore())
}
