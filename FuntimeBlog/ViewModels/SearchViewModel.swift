import Foundation
import Observation

@Observable
final class SearchViewModel {
    var keyword: String = ""
    var results: [Article] = []
    var isSearching = false
    var isLoadingMore = false
    var noResults = false
    var searchError: String?

    private var currentPage = 0
    private var totalPages = 1
    var hasMore: Bool { currentPage < totalPages }

    private let service: ArticleServing
    private var searchTask: Task<Void, Never>?

    init(service: ArticleServing = APIArticleService()) {
        self.service = service
    }

    func onKeywordChange() {
        searchTask?.cancel()
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            noResults = false
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    func performSearch() async {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        searchError = nil
        currentPage = 0
        totalPages = 1
        results = []
        noResults = false
        await fetchPage()
        isSearching = false
    }

    func loadMore() async {
        guard hasMore, !isLoadingMore else { return }
        isLoadingMore = true
        await fetchPage()
        isLoadingMore = false
    }

    private func fetchPage() async {
        let query = ArticleQuery(keyword: keyword.trimmingCharacters(in: .whitespaces))
        do {
            let result = try await service.fetchArticles(page: currentPage + 1, query: query)
            results.append(contentsOf: result.articles)
            currentPage = result.page
            totalPages = result.pageCount
            noResults = results.isEmpty
        } catch {
            searchError = error.localizedDescription
        }
    }
}
