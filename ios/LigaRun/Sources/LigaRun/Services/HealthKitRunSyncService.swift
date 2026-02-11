import CoreLocation
import Foundation
import HealthKit

struct SyncedWorkoutSourceMetadata: Codable, Equatable {
    let workoutId: String
    let startedAt: Date
    let endedAt: Date
    let activityType: String
    let sourceName: String?
}

struct SyncedWorkoutPayload {
    let coordinates: [CLLocationCoordinate2D]
    let timestamps: [Int]
    let source: SyncedWorkoutSourceMetadata
}

enum HealthKitRunSyncError: LocalizedError {
    case healthDataUnavailable
    case workoutNotFound
    case routeNotFound
    case routeTimedOut
    case routeEmpty

    var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "Dados do HealthKit indisponiveis neste dispositivo."
        case .workoutNotFound:
            return "Nenhum treino encontrado no intervalo informado."
        case .routeNotFound:
            return "Rota do treino ainda indisponivel no HealthKit."
        case .routeTimedOut:
            return "Tempo limite ao sincronizar rota do HealthKit."
        case .routeEmpty:
            return "Treino sincronizado sem coordenadas de rota."
        }
    }
}

@MainActor
protocol HealthKitRunSyncProviding: AnyObject {
    func syncWorkout(startDate: Date, endDate: Date, timeout: TimeInterval) async throws -> SyncedWorkoutPayload
}

@MainActor
final class HealthKitRunSyncService: HealthKitRunSyncProviding {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    func syncWorkout(startDate: Date, endDate: Date, timeout: TimeInterval) async throws -> SyncedWorkoutPayload {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitRunSyncError.healthDataUnavailable
        }

        guard let workout = try await fetchLatestWorkout(startDate: startDate, endDate: endDate) else {
            throw HealthKitRunSyncError.workoutNotFound
        }

        let metadata = SyncedWorkoutSourceMetadata(
            workoutId: workout.uuid.uuidString,
            startedAt: workout.startDate,
            endedAt: workout.endDate,
            activityType: String(workout.workoutActivityType.rawValue),
            sourceName: workout.sourceRevision.source.name
        )

        let locations = try await fetchRouteLocations(for: workout, timeout: timeout)
        guard !locations.isEmpty else {
            throw HealthKitRunSyncError.routeEmpty
        }

        let coordinates = locations.map(\.coordinate)
        let timestamps = locations.map { Int($0.timestamp.timeIntervalSince1970) }
        return SyncedWorkoutPayload(coordinates: coordinates, timestamps: timestamps, source: metadata)
    }

    private func fetchLatestWorkout(startDate: Date, endDate: Date) async throws -> HKWorkout? {
        let sampleType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: [.strictStartDate]
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples?.first as? HKWorkout)
            }
            healthStore.execute(query)
        }
    }

    private func fetchRouteLocations(for workout: HKWorkout, timeout: TimeInterval) async throws -> [CLLocation] {
        let route = try await fetchRoute(for: workout)
        let timeoutSeconds = max(timeout, 1)

        return try await withCheckedThrowingContinuation { continuation in
            var collected: [CLLocation] = []
            var isFinished = false
            var queryRef: HKWorkoutRouteQuery?

            let timeoutWork = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    guard !isFinished else { return }
                    isFinished = true
                    if let queryRef {
                        self?.healthStore.stop(queryRef)
                    }
                    continuation.resume(throwing: HealthKitRunSyncError.routeTimedOut)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timeoutSeconds, execute: timeoutWork)

            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                Task { @MainActor in
                    guard !isFinished else { return }

                    if let error {
                        isFinished = true
                        timeoutWork.cancel()
                        continuation.resume(throwing: error)
                        return
                    }

                    if let locations {
                        collected.append(contentsOf: locations)
                    }

                    if done {
                        isFinished = true
                        timeoutWork.cancel()
                        continuation.resume(returning: collected)
                    }
                }
            }
            queryRef = query
            healthStore.execute(query)
        }
    }

    private func fetchRoute(for workout: HKWorkout) async throws -> HKWorkoutRoute {
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let route = samples?.first as? HKWorkoutRoute else {
                    continuation.resume(throwing: HealthKitRunSyncError.routeNotFound)
                    return
                }

                continuation.resume(returning: route)
            }
            healthStore.execute(query)
        }
    }
}
