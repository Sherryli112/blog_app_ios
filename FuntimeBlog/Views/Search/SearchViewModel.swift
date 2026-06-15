import Foundation
import Observation

@Observable
final class SearchViewModel {
    enum ViewState {
        case idle
        case loading
        case loaded([Article])
        case failed(String)
    }

    private let service: ArticleServing
    var query: String = ""
    var state: ViewState = .idle

    private var searchTask: Task<Void, Never>?

    init(service: ArticleServing = APIArticleService()) {
        self.service = service
    }

    func onQueryChanged() {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await search(text: trimmed)
        }
    }

    private func search(text: String) async {
        state = .loading
        do {
            let page = try await service.fetchArticles(
                page: 1,
                query: ArticleQuery(text: text)
            )
            state = .loaded(page.articles)
        } catch {
            state = .failed("搜尋失敗，請稍後再試。")
        }
    }
}
