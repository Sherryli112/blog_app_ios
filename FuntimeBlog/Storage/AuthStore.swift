import Foundation
import Observation

@Observable
final class AuthStore {
    private static let userKey = "logged_in_user"

    private(set) var user: User?
    var isLoggedIn: Bool { user != nil }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.userKey),
           let saved = try? JSONDecoder().decode(User.self, from: data) {
            user = saved
        }
    }

    func save(user: User) {
        self.user = user
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.userKey)
        }
    }

    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: Self.userKey)
    }
}
