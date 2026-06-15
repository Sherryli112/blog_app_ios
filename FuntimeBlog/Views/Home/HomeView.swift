import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        GeometryReader { proxy in
            Group {
                switch viewModel.state {
                case .loading:
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    content(topInset: proxy.safeAreaInsets.top)
                case .failed(let message):
                    ContentUnavailableView {
                        Label("載入失敗", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("重試") { Task { await viewModel.load() } }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.Color.background)
            .ignoresSafeArea(edges: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
        .task {
            if case .loading = viewModel.state { await viewModel.load() }
        }
    }

    private func content(topInset: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.xl) {
                heroCarousel(topInset: topInset)

                if !viewModel.popularArticles.isEmpty {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("熱門文章")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(AppTheme.Color.textPrimary)

                        ForEach(viewModel.popularArticles) { article in
                            NavigationLink(value: article) {
                                PopularRow(article: article)
                            }
                            .buttonStyle(PressableCardStyle())
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
        }
        .refreshable { await viewModel.load() }
    }

    @ViewBuilder
    private func heroCarousel(topInset: CGFloat) -> some View {
        let heroes = viewModel.heroArticles
        if !heroes.isEmpty {
            TabView {
                ForEach(heroes) { article in
                    NavigationLink(value: article) {
                        HeroCard(article: article, topInset: topInset)
                    }
                    .buttonStyle(PressableCardStyle())
                }
            }
            .frame(height: 300 + topInset)
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(BookmarkStore())
    .environment(ReadingHistoryStore())
}
