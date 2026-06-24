import Foundation
import Observation

@Observable
final class AuthStore {
    private static let userKey = "logged_in_user"

    private(set) var user: User?
    var isLoggedIn: Bool { user != nil }

    init() {
        if let json = KeychainHelper.load(for: Self.userKey),
           let data = json.data(using: .utf8),
           let saved = try? JSONDecoder().decode(User.self, from: data) {
            user = saved
        }
    }

    func save(user: User) {
        self.user = user
        if let data = try? JSONEncoder().encode(user),
           let json = String(data: data, encoding: .utf8) {
            KeychainHelper.save(json, for: Self.userKey)
        }
    }

    func logout() {
        user = nil
        KeychainHelper.delete(for: Self.userKey)
    }
}
