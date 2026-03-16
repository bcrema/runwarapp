import XCTest
@testable import LigaRun

final class SessionStoreSharedStateTests: XCTestCase {
    @MainActor
    func testWaveV3SharedStateStartsWithCanonicalDefaults() {
        let store = SessionStore()

        XCTAssertEqual(store.activeMapOwnershipFilter, .all)
        XCTAssertNil(store.mapFocusContext)
        XCTAssertEqual(store.activeBandeirasHubTab, .explore)
    }

    @MainActor
    func testWaveV3SharedStatePersistsAssignedContext() {
        let store = SessionStore()

        store.activeMapOwnershipFilter = .myBandeira
        store.mapFocusContext = .bandeira(bandeiraId: "band-1")
        store.activeBandeirasHubTab = .myTeam

        XCTAssertEqual(store.activeMapOwnershipFilter, .myBandeira)
        XCTAssertEqual(store.mapFocusContext, .bandeira(bandeiraId: "band-1"))
        XCTAssertEqual(store.activeBandeirasHubTab, .myTeam)
    }
}
