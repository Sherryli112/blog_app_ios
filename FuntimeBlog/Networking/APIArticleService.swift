import Foundation

// MARK: - DTOs

private struct ListResponseDTO: Decodable {
    let data: [ArticleSummaryDTO]
    let meta: MetaDTO
}

private struct MetaDTO: Decodable {
    let pagination: PaginationDTO
}

private struct PaginationDTO: Decodable {
    let page: Int
    let pageCount: Int
}

private struct NamedDTO: Decodable {
    let displayName: String?
}

private struct CoverDTO: Decodable {
    let url: String?
}

private struct AuthorDTO: Decodable {
    let name: String?
    let slug: String?
}

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
            authorSlug: author?.slug,
            date: FunTimeAPI.date(publishedAt),
            tags: [theme?.displayName, city?.displayName].compactMap { $0 },
            imageURL: FunTimeAPI.imageURL(cover?.url),
            slug: slug,
            excerpt: excerpt ?? "",
            contentHTML: nil
        )
    }
}

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
    let city: NamedDTO?

    func toArticle() -> Article {
        Article(
            id: String(id),
            title: title,
            author: author?.name ?? "FunTime",
            authorSlug: author?.slug,
            date: FunTimeAPI.date(publishedAt),
            tags: [theme?.displayName, city?.displayName].compactMap { $0 },
            imageURL: FunTimeAPI.imageURL(cover?.url),
            slug: slug,
            excerpt: excerpt ?? "",
            contentHTML: content
        )
    }
}

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

// MARK: - Service

struct APIArticleService: ArticleServing {
    private let pageSize = 20

    func fetchArticles(page: Int, query: ArticleQuery) async throws -> ArticlePage {
        var items = [
            URLQueryItem(name: "pagination[page]", value: String(page)),
            URLQueryItem(name: "pagination[pageSize]", value: String(pageSize)),
            URLQueryItem(name: "withExtraData", value: "true"),
            URLQueryItem(name: "sort", value: query.sort ?? "custom_published_at:desc"),
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
        if let authorSlug = query.authorSlug, !authorSlug.isEmpty {
            items.append(URLQueryItem(name: "filters[author][slug][$eq]", value: authorSlug))
        }
        if let keyword = query.keyword, !keyword.isEmpty {
            items.append(URLQueryItem(name: "filters[title][$containsi]", value: keyword))
        }
        let response: ListResponseDTO = try await FunTimeAPI.get("articles", query: items)
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
}
