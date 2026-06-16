import Foundation
import Observation

@Observable
final class AuthStore {
    private static let tokenKey = "jwt_token"

    private(set) var user: User?
    private(set) var token: String?
    var isLoggedIn: Bool { token != nil }

    init() {
        token = KeychainHelper.load(for: Self.tokenKey)
    }

    func save(token: String, user: User) {
        self.token = token
        self.user = user
        KeychainHelper.save(token, for: Self.tokenKey)
    }

    func logout() {
        token = nil
        user = nil
        KeychainHelper.delete(for: Self.tokenKey)
    }
}
