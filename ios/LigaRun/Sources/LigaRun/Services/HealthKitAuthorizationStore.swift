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
    func requestStatus(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async -> HKAuthorizationRequestStatus
    func hasReadAuthorization(for type: HKSampleType) async -> Bool
    func requestAuthorization(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async throws
}

extension HKHealthStore: HealthStoreProviding {
    func requestStatus(
        toShare typesToShare: Set<HKSampleType>,
        read typesToRead: Set<HKObjectType>
    ) async -> HKAuthorizationRequestStatus {
        await withCheckedContinuation { continuation in
            getRequestStatusForAuthorization(toShare: typesToShare, read: typesToRead) { status, error in
                if error != nil {
                    continuation.resume(returning: .unknown)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }

    func hasReadAuthorization(for type: HKSampleType) async -> Bool {
        await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) { _, samples, error in
                if let error = error as? HKError, error.code == .errorAuthorizationDenied {
                    continuation.resume(returning: false)
                } else if error != nil {
                    continuation.resume(returning: false)
                } else {
                    continuation.resume(returning: (samples?.isEmpty == false))
                }
            }
            execute(query)
        }
    }
}

@MainActor
final class HealthKitAuthorizationStore: ObservableObject {
    @Published private(set) var availability: HealthKitAvailability = .checking
    @Published private(set) var status: HealthKitAuthorizationState = .notDetermined

    var shouldShowPermissionCard: Bool {
        switch availability {
        case .available:
            return status != .authorized
        case .checking, .notAvailable:
            return true
        }
    }

    private let healthStore: HealthStoreProviding
    private let isHealthDataAvailable: () -> Bool
    private let userDefaults: UserDefaults
    private let readTypes: Set<HKObjectType>
    private let workoutType: HKSampleType
    private let requestedFlagKey = "healthkit.authorization.requested"

    init(
        healthStore: HealthStoreProviding = HKHealthStore(),
        isHealthDataAvailable: @escaping () -> Bool = { HKHealthStore.isHealthDataAvailable() },
        userDefaults: UserDefaults = .standard
    ) {
        self.healthStore = healthStore
        self.isHealthDataAvailable = isHealthDataAvailable
        self.userDefaults = userDefaults
        let workoutType = HKObjectType.workoutType()
        let workoutRouteType = HKSeriesType.workoutRoute()
        let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)
        var readTypes: Set<HKObjectType> = [workoutType, workoutRouteType]
        if let distanceType {
            readTypes.insert(distanceType)
        }
        self.readTypes = readTypes
        self.workoutType = workoutType
        Task { @MainActor in
            await refreshStatus()
        }
    }

    func refreshStatus() async {
        guard isHealthDataAvailable() else {
            availability = .notAvailable
            status = .notDetermined
            return
        }

        availability = .available
        let requestStatus = await healthStore.requestStatus(toShare: [], read: readTypes)
        status = await mapAuthorization(requestStatus: requestStatus)
    }

    func requestAuthorization() {
        guard availability == .available else { return }
        userDefaults.set(true, forKey: requestedFlagKey)
        Task { @MainActor in
            do {
                try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            } catch {
                // Ignore authorization errors; status refresh handles current state.
            }
            await refreshStatus()
        }
    }

    private func mapAuthorization(
        requestStatus: HKAuthorizationRequestStatus
    ) async -> HealthKitAuthorizationState {
        let canRead = await hasReadAuthorizationForReadTypes()

        if canRead {
            return .authorized
        }

        switch requestStatus {
        case .unknown:
            return .restricted
        case .unnecessary:
            return userDefaults.bool(forKey: requestedFlagKey) ? .denied : .notDetermined
        case .shouldRequest:
            if !userDefaults.bool(forKey: requestedFlagKey) {
                return .notDetermined
            }
            return .denied
        @unknown default:
            return .restricted
        }
    }

    private func hasReadAuthorizationForReadTypes() async -> Bool {
        await healthStore.hasReadAuthorization(for: workoutType)
    }
}
