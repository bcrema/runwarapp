import HealthKit
import XCTest
@testable import LigaRun

final class HealthKitAuthorizationStoreTests: XCTestCase {
    @MainActor
    func testUnavailableHealthKitSetsNotAvailable() async {
        let store = FakeHealthStore(
            requestStatus: .unknown,
            canRead: false
        )
        let defaults = makeUserDefaults()
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { false },
            userDefaults: defaults
        )
        await authorizationStore.refreshStatus()

        XCTAssertEqual(authorizationStore.availability, .notAvailable)
        XCTAssertEqual(authorizationStore.status, .notDetermined)
    }

    @MainActor
    func testAuthorizedHealthKitSetsGrantedStatus() async {
        let store = FakeHealthStore(
            requestStatus: .unnecessary,
            canRead: true
        )
        let defaults = makeUserDefaults()
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { true },
            userDefaults: defaults
        )
        await authorizationStore.refreshStatus()

        XCTAssertEqual(authorizationStore.availability, .available)
        XCTAssertEqual(authorizationStore.status, .authorized)
    }

    @MainActor
    func testRequestAuthorizationTriggersHealthStore() async {
        let expectation = expectation(description: "requestAuthorization")
        let store = FakeHealthStore(
            requestStatus: .shouldRequest,
            canRead: false
        ) {
            expectation.fulfill()
        }
        let defaults = makeUserDefaults()
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { true },
            userDefaults: defaults
        )

        await authorizationStore.refreshStatus()
        authorizationStore.requestAuthorization()

        await fulfillment(of: [expectation], timeout: 1.0)
        await authorizationStore.refreshStatus()
        XCTAssertEqual(store.requestedAuthorizationCalls, 1)
        XCTAssertFalse(store.lastRequestedReadTypes.isEmpty)
        XCTAssertEqual(authorizationStore.status, .denied)
    }

    @MainActor
    func testShouldShowPermissionCardWhenAuthorizedIsFalse() async {
        let store = FakeHealthStore(
            requestStatus: .unnecessary,
            canRead: true
        )
        let defaults = makeUserDefaults()
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { true },
            userDefaults: defaults
        )
        await authorizationStore.refreshStatus()

        XCTAssertFalse(authorizationStore.shouldShowPermissionCard)
    }

    @MainActor
    func testShouldShowPermissionCardWhenNotDeterminedIsTrue() async {
        let store = FakeHealthStore(
            requestStatus: .shouldRequest,
            canRead: false
        )
        let defaults = makeUserDefaults()
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { true },
            userDefaults: defaults
        )
        await authorizationStore.refreshStatus()

        XCTAssertTrue(authorizationStore.shouldShowPermissionCard)
    }

    @MainActor
    func testShouldShowPermissionCardWhenDeniedIsTrue() async {
        let store = FakeHealthStore(
            requestStatus: .unnecessary,
            canRead: false
        )
        let defaults = makeUserDefaults(requested: true)
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { true },
            userDefaults: defaults
        )
        await authorizationStore.refreshStatus()

        XCTAssertTrue(authorizationStore.shouldShowPermissionCard)
    }

    @MainActor
    func testDeniedWhenRequestStatusUnnecessaryAfterRequest() async {
        let store = FakeHealthStore(
            requestStatus: .unnecessary,
            canRead: false
        )
        let defaults = makeUserDefaults(requested: true)
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { true },
            userDefaults: defaults
        )
        await authorizationStore.refreshStatus()

        XCTAssertEqual(authorizationStore.status, .denied)
        XCTAssertTrue(authorizationStore.shouldShowPermissionCard)
    }

    @MainActor
    func testShouldShowPermissionCardWhenHealthDataUnavailableIsTrue() async {
        let store = FakeHealthStore(
            requestStatus: .unknown,
            canRead: false
        )
        let defaults = makeUserDefaults()
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { false },
            userDefaults: defaults
        )
        await authorizationStore.refreshStatus()

        XCTAssertTrue(authorizationStore.shouldShowPermissionCard)
    }
}

private final class FakeHealthStore: HealthStoreProviding, @unchecked Sendable {
    private let requestStatusValue: HKAuthorizationRequestStatus
    private let canRead: Bool
    private let onRequest: (() -> Void)?
    private(set) var requestedAuthorizationCalls = 0
    private(set) var lastRequestedReadTypes: Set<HKObjectType> = []

    init(
        requestStatus: HKAuthorizationRequestStatus,
        canRead: Bool,
        onRequest: (() -> Void)? = nil
    ) {
        requestStatusValue = requestStatus
        self.canRead = canRead
        self.onRequest = onRequest
    }

    func requestStatus(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async -> HKAuthorizationRequestStatus {
        requestStatusValue
    }

    func hasReadAuthorization(for type: HKSampleType) async -> Bool {
        canRead
    }

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws {
        requestedAuthorizationCalls += 1
        lastRequestedReadTypes = typesToRead
        onRequest?()
    }
}

private func makeUserDefaults(requested: Bool = false) -> UserDefaults {
    let suiteName = "HealthKitAuthorizationStoreTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    if requested {
        defaults.set(true, forKey: "healthkit.authorization.requested")
    }
    return defaults
}
