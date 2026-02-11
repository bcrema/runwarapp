import CoreLocation
import Foundation
import OSLog

@MainActor
protocol RunUploadServiceProtocol {
    func uploadPendingSessions() async -> [RunSubmissionResult]
    func enqueueHealthKitSync(startDate: Date, endDate: Date, timeout: TimeInterval) async
}

extension RunUploadServiceProtocol {
    func enqueueHealthKitSync(startDate: Date, endDate: Date, timeout: TimeInterval) async {}
}

@MainActor
final class RunUploadService: RunUploadServiceProtocol {
    private let api: RunSubmissionAPIProviding
    private let store: RunSessionStore
    private let healthKitSync: HealthKitRunSyncProviding?
    private let healthKitTimeout: TimeInterval
    private let logger = Logger(subsystem: AppEnvironment.keychainService, category: "RunUploadService")

    init(
        api: RunSubmissionAPIProviding,
        store: RunSessionStore,
        healthKitSync: HealthKitRunSyncProviding? = nil,
        healthKitTimeout: TimeInterval = 15
    ) {
        self.api = api
        self.store = store
        self.healthKitSync = healthKitSync
        self.healthKitTimeout = healthKitTimeout
    }

    func uploadPendingSessions() async -> [RunSubmissionResult] {
        let sessions = await store.loadSessions()
        var results: [RunSubmissionResult] = []

        for session in sessions where session.status != .uploaded {
            do {
                let result = try await upload(session)
                results.append(result)
            } catch {
                logger.error("Failed to upload session \(session.id.uuidString): \(error.localizedDescription)")
            }
        }

        return results
    }

    func enqueueHealthKitSync(startDate: Date, endDate: Date, timeout: TimeInterval = 15) async {
        guard let healthKitSync else { return }

        do {
            let payload = try await healthKitSync.syncWorkout(
                startDate: startDate,
                endDate: endDate,
                timeout: timeout
            )
            let session = makeHealthKitSession(from: payload)
            _ = try await store.append(session)
            _ = try await upload(session)
        } catch {
            logger.error("HealthKit sync failed: \(error.localizedDescription)")
            guard shouldPersistPendingHealthKitSession(for: error) else { return }
            await persistHealthKitPendingSession(startDate: startDate, endDate: endDate, error: error)
        }
    }

    func upload(_ session: RunSessionRecord) async throws -> RunSubmissionResult {
        var updatedSession = session
        updatedSession.status = .uploading
        updatedSession.lastUploadAttempt = Date()
        do {
            _ = try await store.update(updatedSession)
        } catch {
            logger.error("Failed to mark session as uploading: \(error.localizedDescription)")
            throw error
        }

        do {
            let payload = try await payloadForUpload(session: session)
            if session.points.isEmpty && !payload.recoveredTrackPoints.isEmpty {
                updatedSession.points = payload.recoveredTrackPoints
                _ = try await store.update(updatedSession)
            }

            let result = try await api.submitRunCoordinates(
                coordinates: payload.coordinates,
                timestamps: payload.timestamps
            )
            updatedSession.status = .uploaded
            updatedSession.lastError = nil
            _ = try await store.update(updatedSession)
            return result
        } catch {
            updatedSession.status = shouldKeepSessionPendingAfterFailure(error) ? .pending : .failed
            updatedSession.lastError = error.localizedDescription
            _ = try? await store.update(updatedSession)
            throw error
        }
    }

    private func payloadForUpload(session: RunSessionRecord) async throws -> UploadPayload {
        if session.source == .healthKit {
            let syncedPayload = try await resolveHealthKitPayload(for: session)
            return UploadPayload(
                coordinates: syncedPayload.coordinates.map { ["lat": $0.latitude, "lng": $0.longitude] },
                timestamps: syncedPayload.timestamps,
                recoveredTrackPoints: trackPoints(
                    coordinates: syncedPayload.coordinates,
                    timestamps: syncedPayload.timestamps
                )
            )
        }

        return UploadPayload(
            coordinates: session.points.map { ["lat": $0.latitude, "lng": $0.longitude] },
            timestamps: session.points.map { Int($0.timestamp.timeIntervalSince1970) },
            recoveredTrackPoints: []
        )
    }

    private func resolveHealthKitPayload(for session: RunSessionRecord) async throws -> SyncedWorkoutPayload {
        if !session.points.isEmpty {
            return SyncedWorkoutPayload(
                coordinates: session.points.map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                },
                timestamps: session.points.map { Int($0.timestamp.timeIntervalSince1970) },
                source: SyncedWorkoutSourceMetadata(
                    workoutId: session.id.uuidString,
                    startedAt: session.startedAt,
                    endedAt: session.endedAt,
                    activityType: "unknown",
                    sourceName: nil
                )
            )
        }

        guard let healthKitSync else {
            throw HealthKitRunSyncError.routeNotFound
        }

        return try await healthKitSync.syncWorkout(
            startDate: session.startedAt,
            endDate: session.endedAt,
            timeout: healthKitTimeout
        )
    }

    private func makeHealthKitSession(from payload: SyncedWorkoutPayload) -> RunSessionRecord {
        let recoveredTrackPoints = trackPoints(coordinates: payload.coordinates, timestamps: payload.timestamps)
        return RunSessionRecord(
            id: UUID(),
            startedAt: payload.source.startedAt,
            endedAt: payload.source.endedAt,
            duration: payload.source.endedAt.timeIntervalSince(payload.source.startedAt),
            distanceMeters: totalDistance(for: recoveredTrackPoints),
            points: recoveredTrackPoints,
            source: .healthKit,
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )
    }

    private func trackPoints(
        coordinates: [CLLocationCoordinate2D],
        timestamps: [Int]
    ) -> [RunTrackPoint] {
        guard coordinates.count == timestamps.count else { return [] }
        return zip(coordinates, timestamps).map { coordinate, timestamp in
            let location = CLLocation(
                coordinate: coordinate,
                altitude: 0,
                horizontalAccuracy: 0,
                verticalAccuracy: -1,
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp))
            )
            return RunTrackPoint(location: location)
        }
    }

    private func totalDistance(for points: [RunTrackPoint]) -> Double {
        guard points.count > 1 else { return 0 }
        var total: Double = 0
        for index in 1..<points.count {
            let previous = CLLocation(latitude: points[index - 1].latitude, longitude: points[index - 1].longitude)
            let current = CLLocation(latitude: points[index].latitude, longitude: points[index].longitude)
            total += current.distance(from: previous)
        }
        return total
    }

    private func shouldKeepSessionPendingAfterFailure(_ error: Error) -> Bool {
        guard let syncError = error as? HealthKitRunSyncError else { return false }
        switch syncError {
        case .routeTimedOut, .routeNotFound, .routeEmpty:
            return true
        case .healthDataUnavailable, .workoutNotFound:
            return false
        }
    }

    private func shouldPersistPendingHealthKitSession(for error: Error) -> Bool {
        guard let syncError = error as? HealthKitRunSyncError else { return false }
        switch syncError {
        case .routeTimedOut, .routeNotFound, .routeEmpty:
            return true
        case .healthDataUnavailable, .workoutNotFound:
            return false
        }
    }

    private func persistHealthKitPendingSession(startDate: Date, endDate: Date, error: Error) async {
        var existing = await store.loadSessions().first {
            $0.source == .healthKit &&
            abs($0.startedAt.timeIntervalSince1970 - startDate.timeIntervalSince1970) < 1 &&
            abs($0.endedAt.timeIntervalSince1970 - endDate.timeIntervalSince1970) < 1 &&
            $0.status != .uploaded
        }

        if existing == nil {
            let pendingSession = RunSessionRecord(
                id: UUID(),
                startedAt: startDate,
                endedAt: endDate,
                duration: max(endDate.timeIntervalSince(startDate), 0),
                distanceMeters: 0,
                points: [],
                source: .healthKit,
                status: .pending,
                lastUploadAttempt: Date(),
                lastError: error.localizedDescription
            )
            _ = try? await store.append(pendingSession)
            return
        }

        if var existing {
            existing.status = .pending
            existing.lastUploadAttempt = Date()
            existing.lastError = error.localizedDescription
            _ = try? await store.update(existing)
        }
    }

    private struct UploadPayload {
        let coordinates: [[String: Double]]
        let timestamps: [Int]
        let recoveredTrackPoints: [RunTrackPoint]
    }

    func buildGpxString(for session: RunSessionRecord) -> String {
        let header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
        "<gpx version=\"1.1\" creator=\"LigaRun\" xmlns=\"http://www.topografix.com/GPX/1/1\">\n" +
        "<trk><name>Run</name><trkseg>\n"
        let footer = "</trkseg></trk>\n</gpx>"

        let formatter = ISO8601DateFormatter()
        let entries = session.points.map { point in
            let timeString = formatter.string(from: point.timestamp)
            var segment = "<trkpt lat=\"\(point.latitude)\" lon=\"\(point.longitude)\">"
            if let altitude = point.altitude {
                segment += "<ele>\(altitude)</ele>"
            }
            segment += "<time>\(timeString)</time></trkpt>"
            return segment
        }

        return header + entries.joined(separator: "\n") + "\n" + footer
    }
}
