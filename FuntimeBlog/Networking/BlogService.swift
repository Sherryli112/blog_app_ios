import Foundation

// MARK: - Shared DTOs

private struct ListResponseDTO<T: Decodable>: Decodable {
    let data: [T]
    let meta: MetaDTO
}

private struct MetaDTO: Decodable {
    let pagination: PaginationDTO
}

private struct PaginationDTO: Decodable {
    let page: Int
    let pageCount: Int
    let total: Int
}

private struct NamedDTO: Decodable {
    let name: String?
    let displayName: String?
}

private struct CoverDTO: Decodable {
    let url: String?
}

private struct AuthorDTO: Decodable {
    let name: String?
    let slug: String?
}

// MARK: - Article List DTO

private struct ArticleSummaryDTO: Decodable {
    let id: Int
    let title: String
    let excerpt: String?
    let slug: String
    let publishedAt: String?
    let cover: CoverDTO?
    let author: AuthorDTO?
    let theme: NamedDTO?
    let city: NamedDTO?

    func toArticle() -> Article {
        Article(
            id: String(id),
            title: title,
            author: author?.name ?? "FunTime",
            authorSlug: author?.slug ?? "",
            date: FunTimeAPI.date(publishedAt),
            tags: [theme?.displayName].compactMap { $0 },
            coverSystemImageName: "photo",
            imageURL: FunTimeAPI.imageURL(cover?.url),
            slug: slug,
            excerpt: excerpt ?? ""
        )
    }
}

// MARK: - Article Detail DTO

private struct ArticleDetailDTO: Decodable {
    let id: Int
    let title: String
    let excerpt: String?
    let slug: String
    let content: String?
    let publishedAt: String?
    let cover: CoverDTO?
    let author: AuthorDTO?
    let theme: NamedDTO?
    let category: NamedDTO?

    func toArticle() -> Article {
        let tags = [category?.displayName, theme?.displayName].compactMap { $0 }
        return Article(
            id: String(id),
            title: title,
            author: author?.name ?? "FunTime",
            authorSlug: author?.slug ?? "",
            date: FunTimeAPI.date(publishedAt),
            tags: tags,
            coverSystemImageName: "photo",
            imageURL: FunTimeAPI.imageURL(cover?.url),
            slug: slug,
            excerpt: excerpt ?? "",
            contentHTML: content
        )
    }
}

// MARK: - Region DTO

private struct RegionDTO: Decodable {
    let id: Int
    let displayName: String?
    let themes: [ThemeDTO]?

    struct ThemeDTO: Decodable {
        let displayName: String?
    }

    func toRegion() -> Region {
        Region(
            id: id,
            name: displayName ?? "",
            cities: (themes ?? []).compactMap { $0.displayName }
        )
    }
}

// MARK: - APIArticleService

struct APIArticleService: ArticleServing {
    private let pageSize = 20

    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "sort", value: "publishedAt:desc"),
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize)),
            URLQueryItem(name: "withExtraData", value: "true")
        ]
        if let category = query.category, !category.isEmpty {
            items.append(URLQueryItem(name: "filters[ft_category][display_name][$eq]", value: category))
        }
        if let city = query.city, !city.isEmpty {
            items.append(URLQueryItem(name: "filters[ft_theme][display_name][$eq]", value: city))
        }
        if let tag = query.tag, !tag.isEmpty {
            items.append(URLQueryItem(name: "filters[tags][name][$eq]", value: tag))
        }
        if let text = query.text, !text.isEmpty {
            items.append(URLQueryItem(name: "filters[title][$containsi]", value: text))
        }
        let response: ListResponseDTO<ArticleSummaryDTO> = try await FunTimeAPI.get("articles", query: items)
        return ArticlePage(
            articles: response.data.map { $0.toArticle() },
            page: response.meta.pagination.page,
            pageCount: response.meta.pagination.pageCount
        )
    }

    func articleDetail(slug: String) async throws -> Article {
        let dto: ArticleDetailDTO = try await FunTimeAPI.get("articles/slug/\(slug)")
        return dto.toArticle()
    }

    func regions() async throws -> [Region] {
        let dtos: [RegionDTO] = try await FunTimeAPI.get("ft-regions")
        return dtos.map { $0.toRegion() }.filter { !$0.cities.isEmpty }
    }

    func authorArticles(authorSlug: String, page: Int) async throws -> ArticlePage {
        let items: [URLQueryItem] = [
            URLQueryItem(name: "filters[author][slug][$eq]", value: authorSlug),
            URLQueryItem(name: "sort", value: "publishedAt:desc"),
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize)),
            URLQueryItem(name: "withExtraData", value: "true")
        ]
        let response: ListResponseDTO<ArticleSummaryDTO> = try await FunTimeAPI.get("articles", query: items)
        return ArticlePage(
            articles: response.data.map { $0.toArticle() },
            page: response.meta.pagination.page,
            pageCount: response.meta.pagination.pageCount
        )
    }
}
