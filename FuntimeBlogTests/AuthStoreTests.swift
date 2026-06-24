import XCTest
@testable import FuntimeBlog

final class AuthStoreTests: XCTestCase {
    private let key = "logged_in_user"
    private let testUser = User(id: 1, username: "alice", email: "alice@test.com",
                                confirmed: true, blocked: false)

    override func setUp() {
        super.setUp()
        KeychainHelper.delete(for: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        super.tearDown()
        KeychainHelper.delete(for: key)
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - save

    func testSave_persistsUser_restoredByNewInstance() {
        let store = AuthStore()
        store.save(user: testUser)

        let restored = AuthStore()
        XCTAssertEqual(restored.user?.email, "alice@test.com")
        XCTAssertEqual(restored.user?.username, "alice")
    }

    func testSave_doesNotWriteToUserDefaults() {
        let store = AuthStore()
        store.save(user: testUser)

        let raw = UserDefaults.standard.data(forKey: key)
        XCTAssertNil(raw, "User 資料不應儲存在 UserDefaults（PII 安全風險）")
    }

    // MARK: - logout

    func testLogout_clearsUser_inMemory() {
        let store = AuthStore()
        store.save(user: testUser)
        store.logout()

        XCTAssertNil(store.user)
        XCTAssertFalse(store.isLoggedIn)
    }

    func testLogout_preventsRestore_onNewInstance() {
        let store = AuthStore()
        store.save(user: testUser)
        store.logout()

        let restored = AuthStore()
        XCTAssertNil(restored.user, "logout 後新建的 AuthStore 不應還原使用者")
    }
}
