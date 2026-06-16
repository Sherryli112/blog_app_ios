import Foundation
import Observation

@Observable
final class CategoryViewModel {
    enum LoadState {
        case idle, loading, loaded, failed(String)
    }

    var regions: [Region] = []
    var loadState: LoadState = .idle

    private let service: ArticleServing

    init(service: ArticleServing = APIArticleService()) {
        self.service = service
    }

    func load() async {
        guard case .idle = loadState else { return }
        loadState = .loading
        do {
            regions = try await service.regions()
            loadState = .loaded
        } catch {
            loadState = .failed(error.localizedDescription)
        }
    }

    func reload() async {
        loadState = .idle
        await load()
    }
}
