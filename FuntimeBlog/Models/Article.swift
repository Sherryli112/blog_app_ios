import Foundation

struct Article: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let author: String
    let authorSlug: String
    let date: Date
    let tags: [String]
    let coverSystemImageName: String
    let imageURL: URL?
    let slug: String
    let excerpt: String
    let contentHTML: String?

    init(
        id: String,
        title: String,
        author: String,
        authorSlug: String = "",
        date: Date,
        tags: [String],
        coverSystemImageName: String = "photo",
        imageURL: URL? = nil,
        slug: String = "",
        excerpt: String,
        contentHTML: String? = nil
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.authorSlug = authorSlug
        self.date = date
        self.tags = tags
        self.coverSystemImageName = coverSystemImageName
        self.imageURL = imageURL
        self.slug = slug
        self.excerpt = excerpt
        self.contentHTML = contentHTML
    }
}
