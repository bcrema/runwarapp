import Foundation
import HealthKit

enum HealthKitAvailability: Equatable {
    case checking
    case available
    case notAvailable
}

enum HealthKitAuthorizationState: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

protocol HealthStoreProviding: Sendable {
    func authorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws
}

extension HKHealthStore: HealthStoreProviding {}

@MainActor
final class HealthKitAuthorizationStore: ObservableObject {
    @Published private(set) var availability: HealthKitAvailability = .checking
    @Published private(set) var status: HealthKitAuthorizationState = .notDetermined

    private let healthStore: HealthStoreProviding
    private let isHealthDataAvailable: () -> Bool
    private let readTypes: Set<HKObjectType>
    private let statusType: HKObjectType

    init(
        healthStore: HealthStoreProviding = HKHealthStore(),
        isHealthDataAvailable: @escaping () -> Bool = { HKHealthStore.isHealthDataAvailable() }
    ) {
        self.healthStore = healthStore
        self.isHealthDataAvailable = isHealthDataAvailable
        let workoutType = HKObjectType.workoutType()
        let workoutRouteType = HKSeriesType.workoutRoute()
        let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        var readTypes: Set<HKObjectType> = [workoutType, workoutRouteType]
        if let distanceType {
            readTypes.insert(distanceType)
        }
        self.readTypes = readTypes
        self.statusType = workoutType
        refreshStatus()
    }

    func refreshStatus() {
        guard isHealthDataAvailable() else {
            availability = .notAvailable
            status = .notDetermined
            return
        }

        availability = .available
        status = mapAuthorization(healthStore.authorizationStatus(for: statusType))
    }

    func requestAuthorization() {
        guard availability == .available else { return }
        Task { @MainActor in
            do {
                try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            } catch {
                // Ignore authorization errors; status refresh handles current state.
            }
            refreshStatus()
        }
    }

    private func mapAuthorization(_ authorization: HKAuthorizationStatus) -> HealthKitAuthorizationState {
        switch authorization {
        case .notDetermined:
            return .notDetermined
        case .sharingAuthorized:
            return .authorized
        case .sharingDenied:
            return .denied
        @unknown default:
            return .restricted
        }
    }
}
