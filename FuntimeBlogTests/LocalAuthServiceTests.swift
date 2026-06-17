import XCTest
@testable import FuntimeBlog

final class LocalAuthServiceTests: XCTestCase {
    let service = LocalAuthService()

    override func setUp() {
        super.setUp()
        KeychainHelper.delete(for: "local_auth_user")
    }

    override func tearDown() {
        super.tearDown()
        KeychainHelper.delete(for: "local_auth_user")
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

    func testRegister_secondUserWithDifferentCredentials_throws() throws {
        // 修正前：第二個使用者會覆蓋第一個
        // 修正後：應拋出錯誤，保護第一個帳號
        _ = try service.register(username: "alice", email: "alice@test.com", password: "pass1")
        XCTAssertThrowsError(
            try service.register(username: "bob", email: "bob@test.com", password: "pass2"),
            "裝置已有帳號時，新的不同帳號不應被允許註冊"
        )
    }

    func testRegister_firstUserStillAccessible_afterBlockedSecondRegistration() throws {
        _ = try service.register(username: "alice", email: "alice@test.com", password: "pass1")
        _ = try? service.register(username: "bob", email: "bob@test.com", password: "pass2") // 預期失敗

        // alice 的帳號應依然有效
        let user = try service.login(identifier: "alice@test.com", password: "pass1")
        XCTAssertEqual(user.email, "alice@test.com")
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
        let raw = KeychainHelper.load(for: "local_auth_user") ?? ""
        XCTAssertFalse(raw.contains("supersecret"), "密碼不應以明文出現在 Keychain 儲存內容中")
    }
}
