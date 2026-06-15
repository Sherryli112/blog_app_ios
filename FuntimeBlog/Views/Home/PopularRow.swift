import SwiftUI

private let popularRowFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "zh_TW")
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

struct PopularRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Color.clear
                .frame(width: 80, height: 80)
                .overlay { thumbnail }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                if let tag = article.tags.first {
                    Text(tag.uppercased())
                        .font(AppTheme.Font.tag)
                        .foregroundStyle(AppTheme.Color.accent)
                }
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.textPrimary)
                    .lineLimit(2)
                Text(popularRowFormatter.string(from: article.date))
                    .font(.caption)
                    .foregroundStyle(AppTheme.Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var thumbnail: some View {
        AsyncImage(url: article.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            default:
                AppTheme.Gradient.primary
            }
        }
    }
}

#Preview {
    PopularRow(article: SampleData.articles[0])
        .padding()
}
