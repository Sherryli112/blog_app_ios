import SwiftUI

struct ArticleCard: View {
    let article: Article

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: article.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    LinearGradient(
                        colors: [AppTheme.Color.primary.opacity(0.3), AppTheme.Color.primaryLight.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()
            .overlay(alignment: .topTrailing) {
                FavoriteButton(article: article, circular: true)
                    .padding(AppTheme.Spacing.sm)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                if !article.tags.isEmpty {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        ForEach(article.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(AppTheme.Font.tag)
                                .foregroundStyle(AppTheme.Color.primary)
                                .padding(.horizontal, AppTheme.Spacing.sm)
                                .padding(.vertical, 2)
                                .background(AppTheme.Color.primary.opacity(0.1), in: Capsule())
                        }
                    }
                }

                Text(article.title)
                    .font(AppTheme.Font.cardTitle)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(article.author)
                    Text("·")
                    Text(Self.dateFormatter.string(from: article.date))
                }
                .font(AppTheme.Font.meta)
                .foregroundStyle(.secondary)
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
    }
}

#Preview {
    ArticleCard(article: SampleData.articles[0])
        .padding()
        .environment(FavoritesStore())
}
