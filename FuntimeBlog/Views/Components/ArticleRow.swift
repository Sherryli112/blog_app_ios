import SwiftUI

struct ArticleRow: View {
    let article: Article

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            AsyncImage(url: article.imageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                default:
                    AppTheme.Color.cardSurface
                }
            }
            .frame(width: 90, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(article.title)
                    .font(AppTheme.Font.sectionHeader)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                HStack(spacing: AppTheme.Spacing.xs) {
                    Text(article.author)
                        .font(AppTheme.Font.meta)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(Self.dateFormatter.string(from: article.date))
                        .font(AppTheme.Font.meta)
                        .foregroundStyle(.secondary)
                }

                if let tag = article.tags.first {
                    Text(tag)
                        .font(AppTheme.Font.tag)
                        .foregroundStyle(AppTheme.Color.primary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 2)
                        .background(AppTheme.Color.primary.opacity(0.1), in: Capsule())
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    ArticleRow(article: SampleData.articles[0])
        .padding()
}
