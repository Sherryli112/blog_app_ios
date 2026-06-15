import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @Environment(ReadingHistoryStore.self) private var historyStore

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                historySection
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let articles):
                if articles.isEmpty {
                    ContentUnavailableView.search(text: viewModel.query)
                } else {
                    resultList(articles)
                }
            case .failed(let message):
                ContentUnavailableView {
                    Label("搜尋失敗", systemImage: "exclamationmark.triangle")
                } description: { Text(message) }
            }
        }
        .background(AppTheme.Color.background)
        .navigationTitle("搜尋")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.query, prompt: "搜尋文章標題")
        .onChange(of: viewModel.query) { viewModel.onQueryChanged() }
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }

    @ViewBuilder
    private var historySection: some View {
        let history = historyStore.articles
        if history.isEmpty {
            ContentUnavailableView {
                Label("還沒有閱讀紀錄", systemImage: "clock")
            } description: {
                Text("讀過的文章會顯示在這裡。")
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Text("最近閱讀")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(AppTheme.Color.textPrimary)
                        Spacer()
                        Button("清除") { historyStore.clear() }
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.Color.primary)
                    }

                    LazyVStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(history) { article in
                            NavigationLink(value: article) {
                                HistoryRow(article: article)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
        }
    }

    private func resultList(_ articles: [Article]) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.lg) {
                ForEach(articles) { article in
                    ArticleCardLink(article: article)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
    }
}

private struct HistoryRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Color.clear
                .frame(width: 64, height: 64)
                .overlay {
                    AsyncImage(url: article.imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        default:
                            AppTheme.Gradient.primary
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.Color.textPrimary)
                    .lineLimit(2)
                Text(article.author)
                    .font(.caption)
                    .foregroundStyle(AppTheme.Color.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Color.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environment(BookmarkStore())
    .environment(ReadingHistoryStore())
}
