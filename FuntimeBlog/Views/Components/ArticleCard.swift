import SwiftUI

private let articleDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "zh_TW")
    f.dateStyle = .long
    f.timeStyle = .none
    return f
}()

struct ArticleCardView: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: 190)
                .overlay { cover }
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.hero))

            if let tag = article.tags.first {
                Text(tag.uppercased())
                    .font(AppTheme.Font.tag)
                    .foregroundStyle(AppTheme.Color.accent)
            }

            Text(article.title)
                .font(AppTheme.Font.cardTitle)
                .foregroundStyle(AppTheme.Color.textPrimary)
                .lineLimit(2)

            Text("\(article.author) · \(articleDateFormatter.string(from: article.date))")
                .font(AppTheme.Font.meta)
                .foregroundStyle(AppTheme.Color.textSecondary)
        }
        .cardStyle()
    }

    @ViewBuilder
    private var cover: some View {
        AsyncImage(url: article.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .empty:
                ZStack {
                    AppTheme.Gradient.primary
                    ProgressView().tint(.white)
                }
            default:
                ZStack {
                    AppTheme.Gradient.primary
                    Image(systemName: article.coverSystemImageName)
                        .resizable().scaledToFit()
                        .frame(width: 56, height: 56)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }
}

struct ArticleCardLink: View {
    let article: Article

    var body: some View {
        NavigationLink(value: article) {
            ArticleCardView(article: article)
        }
        .buttonStyle(PressableCardStyle())
        .overlay(alignment: .topTrailing) {
            BookmarkButton(article: article, circular: true)
                .padding(AppTheme.Spacing.lg)
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ArticleCardLink(article: SampleData.articles[0])
                .padding(AppTheme.Spacing.lg)
        }
    }
    .environment(BookmarkStore())
}
