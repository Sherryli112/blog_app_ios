import Foundation
import Observation

@Observable
final class CategoryViewModel {
    enum ViewState {
        case loading
        case loaded
        case failed(String)
    }

    private let service: ArticleServing
    private(set) var regions: [Region] = []
    var state: ViewState = .loading

    init(service: ArticleServing = APIArticleService()) {
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            regions = try await service.regions()
            state = regions.isEmpty ? .failed("沒有可瀏覽的分類。") : .loaded
        } catch {
            state = .failed("無法載入分類，請稍後再試。")
        }
    }
}
