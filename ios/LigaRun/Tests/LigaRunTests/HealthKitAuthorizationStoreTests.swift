import HealthKit
import XCTest
@testable import LigaRun

final class HealthKitAuthorizationStoreTests: XCTestCase {
    @MainActor
    func testUnavailableHealthKitSetsNotAvailable() {
        let store = FakeHealthStore(authorizationStatus: .notDetermined)
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { false }
        )

        XCTAssertEqual(authorizationStore.availability, .notAvailable)
        XCTAssertEqual(authorizationStore.status, .notDetermined)
    }

    @MainActor
    func testAuthorizedHealthKitSetsGrantedStatus() {
        let store = FakeHealthStore(authorizationStatus: .sharingAuthorized)
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { true }
        )

        XCTAssertEqual(authorizationStore.availability, .available)
        XCTAssertEqual(authorizationStore.status, .authorized)
    }

    @MainActor
    func testRequestAuthorizationTriggersHealthStore() {
        let store = FakeHealthStore(authorizationStatus: .notDetermined)
        let authorizationStore = HealthKitAuthorizationStore(
            healthStore: store,
            isHealthDataAvailable: { true }
        )

        authorizationStore.requestAuthorization()

        XCTAssertEqual(store.requestedAuthorizationCalls, 1)
        XCTAssertFalse(store.lastRequestedReadTypes.isEmpty)
    }
}

private final class FakeHealthStore: HealthStoreProviding {
    private let authorization: HKAuthorizationStatus
    private(set) var requestedAuthorizationCalls = 0
    private(set) var lastRequestedReadTypes: Set<HKObjectType> = []

    init(authorizationStatus: HKAuthorizationStatus) {
        authorization = authorizationStatus
    }

    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        authorization
    }

    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>?,
        read typesToRead: Set<HKObjectType>,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        requestedAuthorizationCalls += 1
        lastRequestedReadTypes = typesToRead
        completion(true, nil)
    }
}
