import XCTest
@testable import FuntimeBlog

final class GameStoreTests: XCTestCase {

    // MARK: - checkIn XP calculation

    func testCheckIn_firstDay_gives10XP() {
        let store = GameStore(profile: .init(xp: 0, level: 1, streakDays: 0, lastCheckIn: nil, stamps: []))
        let earned = store.checkIn()
        XCTAssertEqual(earned, 10)
        XCTAssertEqual(store.profile.streakDays, 1)
    }

    func testCheckIn_consecutive_gives60XPOnDay6() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let store = GameStore(profile: .init(xp: 0, level: 1, streakDays: 5, lastCheckIn: yesterday, stamps: []))
        let earned = store.checkIn()
        XCTAssertEqual(earned, 60) // min(6, 7) * 10
        XCTAssertEqual(store.profile.streakDays, 6)
    }

    func testCheckIn_streakBreak_resetsTo10XP() {
        // 中斷前連續 6 天，中斷後應重置為第 1 天 = 10 XP
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let store = GameStore(profile: .init(xp: 0, level: 1, streakDays: 6, lastCheckIn: twoDaysAgo, stamps: []))
        let earned = store.checkIn()
        XCTAssertEqual(earned, 10, "中斷後應得 10 XP，而非舊 streak 計算的 70 XP")
        XCTAssertEqual(store.profile.streakDays, 1)
    }

    func testCheckIn_capsAt70XP_onDay8Plus() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let store = GameStore(profile: .init(xp: 0, level: 1, streakDays: 7, lastCheckIn: yesterday, stamps: []))
        let earned = store.checkIn()
        XCTAssertEqual(earned, 70) // min(8, 7) * 10 = 70，上限 70
    }

    func testCheckIn_sameDay_returns0() {
        let store = GameStore(profile: .init(xp: 0, level: 1, streakDays: 1, lastCheckIn: Date(), stamps: []))
        let earned = store.checkIn()
        XCTAssertEqual(earned, 0)
    }

    func testCheckIn_sameDay_doesNotChangeStreak() {
        let store = GameStore(profile: .init(xp: 0, level: 1, streakDays: 3, lastCheckIn: Date(), stamps: []))
        _ = store.checkIn()
        XCTAssertEqual(store.profile.streakDays, 3)
    }

    // MARK: - collectStamp

    func testCollectStamp_newCity_addsStampAndXP() {
        let store = GameStore(profile: .init(xp: 0, level: 1, streakDays: 0, lastCheckIn: nil, stamps: []))
        store.collectStamp(city: "台北")
        XCTAssertTrue(store.profile.stamps.contains("台北"))
        XCTAssertEqual(store.profile.xp, 50)
    }

    func testCollectStamp_duplicate_noChange() {
        let store = GameStore(profile: .init(xp: 0, level: 1, streakDays: 0, lastCheckIn: nil, stamps: ["台北"]))
        store.collectStamp(city: "台北")
        XCTAssertEqual(store.profile.stamps.count, 1)
        XCTAssertEqual(store.profile.xp, 0)
    }
}
