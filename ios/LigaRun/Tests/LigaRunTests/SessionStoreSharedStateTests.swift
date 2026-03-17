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

    @MainActor
    func testNavigateToBandeirasSelectsCanonicalTabAndSurface() {
        let store = SessionStore()

        store.navigateToBandeiras(tab: .ranking)

        XCTAssertEqual(store.selectedTab, .bandeiras)
        XCTAssertEqual(store.selectedTabIndex, SessionStore.RootTab.bandeiras.rawValue)
        XCTAssertEqual(store.activeBandeirasHubTab, .ranking)
    }

    @MainActor
    func testNavigateToMapInfersMapFilterFromFocusContextWhenNeeded() {
        let store = SessionStore()

        store.navigateToMap(focusContext: .bandeira(bandeiraId: "band-7"))

        XCTAssertEqual(store.selectedTab, .map)
        XCTAssertEqual(store.activeMapOwnershipFilter, .myBandeira)
        XCTAssertEqual(store.mapFocusContext, .bandeira(bandeiraId: "band-7"))
    }

    @MainActor
    func testNavigateToMapPreservesExplicitFilterOverride() {
        let store = SessionStore()

        store.navigateToMap(filter: .disputed, focusContext: .user(userId: "user-9"))

        XCTAssertEqual(store.selectedTab, .map)
        XCTAssertEqual(store.activeMapOwnershipFilter, .disputed)
        XCTAssertEqual(store.mapFocusContext, .user(userId: "user-9"))
    }

    @MainActor
    func testConsumeMapFocusContextIsOneShot() {
        let store = SessionStore()
        store.mapFocusContext = .user(userId: "user-1")

        XCTAssertEqual(store.consumeMapFocusContext(), .user(userId: "user-1"))
        XCTAssertNil(store.mapFocusContext)
        XCTAssertNil(store.consumeMapFocusContext())
    }

    @MainActor
    func testResetWaveV3SharedStateRestoresCanonicalDefaults() {
        let store = SessionStore()
        store.activeMapOwnershipFilter = .mine
        store.mapFocusContext = .user(userId: "user-2")
        store.activeBandeirasHubTab = .myTeam

        store.resetWaveV3SharedState()

        XCTAssertEqual(store.activeMapOwnershipFilter, .all)
        XCTAssertNil(store.mapFocusContext)
        XCTAssertEqual(store.activeBandeirasHubTab, .explore)
    }
}
