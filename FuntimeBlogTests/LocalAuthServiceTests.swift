import XCTest
@testable import FuntimeBlog

final class LocalAuthServiceTests: XCTestCase {
    let service = LocalAuthService()

    // 多帳號儲存的 key，以及舊版單一帳號 key（遷移來源），測試前後都清乾淨避免互相污染。
    private let storeKey = "local_auth_users"
    private let legacyKey = "local_auth_user"

    override func setUp() {
        super.setUp()
        KeychainHelper.delete(for: storeKey)
        KeychainHelper.delete(for: legacyKey)
    }

    override func tearDown() {
        KeychainHelper.delete(for: storeKey)
        KeychainHelper.delete(for: legacyKey)
        super.tearDown()
    }

    // MARK: - register

    func testRegister_firstUser_succeeds() throws {
        let user = try service.register(username: "alice", email: "alice@test.com", password: "pass123")
        XCTAssertEqual(user.email, "alice@test.com")
        XCTAssertEqual(user.username, "alice")
    }

    func testRegister_duplicateEmail_throws() throws {
        _ = try service.register(username: "alice", email: "alice@test.com", password: "pass1")
        XCTAssertThrowsError(
            try service.register(username: "alice2", email: "alice@test.com", password: "pass2")
        )
    }

    func testRegister_duplicateUsername_throws() throws {
        _ = try service.register(username: "alice", email: "alice@test.com", password: "pass1")
        XCTAssertThrowsError(
            try service.register(username: "alice", email: "other@test.com", password: "pass2")
        )
    }

    func testRegister_secondUserWithDifferentCredentials_succeeds() throws {
        // 多帳號設計：不同 email + 不同暱稱應可成功註冊第二個帳號。
        _ = try service.register(username: "alice", email: "alice@test.com", password: "pass1")
        let bob = try service.register(username: "bob", email: "bob@test.com", password: "pass2")
        XCTAssertEqual(bob.email, "bob@test.com")
        XCTAssertNotEqual(bob.id, 1, "第二個帳號應有不同的 id")
    }

    func testRegister_existingAccountNotOverwritten_byNewAccount() throws {
        // 原 #3 的核心保證：註冊新帳號不會覆蓋既有帳號，兩者都能正常登入。
        _ = try service.register(username: "alice", email: "alice@test.com", password: "pass1")
        _ = try service.register(username: "bob", email: "bob@test.com", password: "pass2")

        let alice = try service.login(identifier: "alice@test.com", password: "pass1")
        let bob = try service.login(identifier: "bob@test.com", password: "pass2")
        XCTAssertEqual(alice.email, "alice@test.com")
        XCTAssertEqual(bob.email, "bob@test.com")
    }

    // MARK: - login

    func testLogin_correctPassword_succeeds() throws {
        _ = try service.register(username: "alice", email: "alice@test.com", password: "mypassword")
        let user = try service.login(identifier: "alice@test.com", password: "mypassword")
        XCTAssertEqual(user.email, "alice@test.com")
    }

    func testLogin_byUsername_succeeds() throws {
        _ = try service.register(username: "alice", email: "alice@test.com", password: "mypassword")
        let user = try service.login(identifier: "alice", password: "mypassword")
        XCTAssertEqual(user.username, "alice")
    }

    func testLogin_wrongPassword_throws() throws {
        _ = try service.register(username: "alice", email: "alice@test.com", password: "correct")
        XCTAssertThrowsError(try service.login(identifier: "alice@test.com", password: "wrong"))
    }

    func testLogin_noAccount_throws() {
        XCTAssertThrowsError(try service.login(identifier: "nobody@test.com", password: "anything"))
    }

    // MARK: - password security

    func testPasswordNotStoredInPlainText() throws {
        _ = try service.register(username: "alice", email: "alice@test.com", password: "supersecret")
        let raw = KeychainHelper.load(for: storeKey) ?? ""
        XCTAssertFalse(raw.contains("supersecret"), "密碼不應以明文出現在 Keychain 儲存內容中")
    }
}
