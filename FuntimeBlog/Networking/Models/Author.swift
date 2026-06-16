import Foundation

struct Author: Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    let bio: String?
    let avatarURL: URL?
}
