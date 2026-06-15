import SwiftUI
import Observation

@Observable
private final class AuthorViewModel {
    enum ViewState {
        case loading
        case loaded([Article])
        case failed(String)
    }

    private let service: ArticleServing
    let authorSlug: String
    let authorName: String
    var state: ViewState = .loading

    init(authorSlug: String,
         authorName: String,
         service: ArticleServing = APIArticleService()) {
        self.authorSlug = authorSlug
        self.authorName = authorName
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            let page = try await service.authorArticles(authorSlug: authorSlug, page: 1)
            state = .loaded(page.articles)
        } catch {
            state = .failed("無法載入作者文章。")
        }
    }
}

struct AuthorView: View {
    let authorSlug: String
    let authorName: String
    @State private var viewModel: AuthorViewModel

    init(authorSlug: String, authorName: String) {
        self.authorSlug = authorSlug
        self.authorName = authorName
        _viewModel = State(initialValue: AuthorViewModel(authorSlug: authorSlug,
                                                         authorName: authorName))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                authorHeader
                Divider()
                articlesSection
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Color.background)
        .navigationTitle(authorName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .task { await viewModel.load() }
    }

    private var authorHeader: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppTheme.Gradient.primary)
                    .frame(width: 80, height: 80)
                Text(String(authorName.prefix(1)))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(authorName)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(AppTheme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.Spacing.lg)
    }

    @ViewBuilder
    private var articlesSection: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .loaded(let articles):
            if articles.isEmpty {
                Text("這位作者還沒有文章。")
                    .foregroundStyle(AppTheme.Color.textSecondary)
            } else {
                LazyVStack(spacing: AppTheme.Spacing.lg) {
                    ForEach(articles) { article in
                        ArticleCardLink(article: article)
                    }
                }
            }
        case .failed(let message):
            Text(message)
                .foregroundStyle(AppTheme.Color.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        AuthorView(authorSlug: "wang-xiaoming", authorName: "王小明")
    }
    .environment(BookmarkStore())
    .environment(ReadingHistoryStore())
}
