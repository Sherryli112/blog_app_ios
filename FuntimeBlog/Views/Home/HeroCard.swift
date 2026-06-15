import SwiftUI

struct HeroCard: View {
    let article: Article
    var topInset: CGFloat = 0

    private let baseHeight: CGFloat = 300

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: baseHeight + topInset)
            .overlay { cover }
            .clipped()
            .overlay {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.15), .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .overlay(alignment: .bottomLeading) { caption }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if let tag = article.tags.first {
                Text(tag.uppercased())
                    .font(AppTheme.Font.tag)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            Text(article.title)
                .font(.system(.title, design: .rounded).bold())
                .foregroundStyle(.white)
                .lineLimit(3)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
            Text(article.date.formatted(.dateTime.month().day()))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 1)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var cover: some View {
        AsyncImage(url: article.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .empty:
                ZStack { AppTheme.Gradient.primary; ProgressView().tint(.white) }
            default:
                ZStack {
                    AppTheme.Gradient.primary
                    Image(systemName: article.coverSystemImageName)
                        .font(.system(size: 64))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }
}

#Preview {
    HeroCard(article: SampleData.articles[0])
        .frame(height: 300)
}
