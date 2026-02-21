import CoreLocation
import Foundation
import XCTest
@testable import LigaRun

final class RunUploadServiceTests: XCTestCase {
    @MainActor
    func testUploadPendingSessionsUploadsPendingAndSkipsUploaded() async throws {
        let store = RunSessionStore(fileURL: makeTempFileURL())
        let pending = makeSessionFixture(id: UUID(), status: .pending)
        let alreadyUploaded = makeSessionFixture(id: UUID(), status: .uploaded)
        _ = try await store.append(pending)
        _ = try await store.append(alreadyUploaded)

        let api = RunSubmissionAPISpy(result: .success(makeRunSubmissionResultFixture(runId: "run-sync-ok")))
        let service = RunUploadService(api: api, store: store)

        let results = await service.uploadPendingSessions()
        let sessions = await store.loadSessions()
        let uploadedPending = sessions.first { $0.id == pending.id }
        let untouchedUploaded = sessions.first { $0.id == alreadyUploaded.id }

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.run.id, "run-sync-ok")
        XCTAssertEqual(api.submitCoordinatesCalls, 1)
        XCTAssertEqual(uploadedPending?.status, .uploaded)
        XCTAssertEqual(untouchedUploaded?.status, .uploaded)
    }

    @MainActor
    func testUploadConvertsTrackPointsIntoCoordinatesAndTimestamps() async throws {
        let store = RunSessionStore(fileURL: makeTempFileURL())
        let session = makeSessionFixture(id: UUID(), status: .pending)
        let api = RunSubmissionAPISpy(result: .success(makeRunSubmissionResultFixture(runId: "run-payload")))
        let service = RunUploadService(api: api, store: store)

        _ = try await store.append(session)
        _ = try await service.upload(session)

        let payload = api.lastPayload
        XCTAssertEqual(payload?.coordinates.count, 2)
        XCTAssertEqual(payload?.timestamps.count, 2)
        XCTAssertEqual(payload?.coordinates.first?["lat"], session.points.first?.latitude)
        XCTAssertEqual(payload?.coordinates.first?["lng"], session.points.first?.longitude)
        XCTAssertEqual(payload?.timestamps.first, Int(session.points.first?.timestamp.timeIntervalSince1970 ?? 0))
    }

    @MainActor
    func testUploadMarksFailedAndPreservesSessionForRetryOnNetworkError() async throws {
        let store = RunSessionStore(fileURL: makeTempFileURL())
        let session = makeSessionFixture(id: UUID(), status: .pending)
        _ = try await store.append(session)

        let api = RunSubmissionAPISpy(
            result: .failure(APIError(error: "NETWORK_ERROR", message: "Offline", details: nil))
        )
        let service = RunUploadService(api: api, store: store)

        do {
            _ = try await service.upload(session)
            XCTFail("Expected upload to throw")
        } catch {
            // expected
        }

        let persisted = await store.loadSessions().first { $0.id == session.id }
        XCTAssertEqual(persisted?.status, .failed)
        XCTAssertEqual(persisted?.lastError, "Offline")
        XCTAssertNotNil(persisted?.lastUploadAttempt)
    }

    @MainActor
    func testUploadHealthKitSessionWithoutPointsRecoversPayloadAndUploads() async throws {
        let startedAt = Date().addingTimeInterval(-900)
        let endedAt = startedAt.addingTimeInterval(600)
        let store = RunSessionStore(fileURL: makeTempFileURL())
        let pendingHealthKitSession = RunSessionRecord(
            id: UUID(),
            startedAt: startedAt,
            endedAt: endedAt,
            duration: 600,
            distanceMeters: 0,
            points: [],
            source: .healthKit,
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )
        _ = try await store.append(pendingHealthKitSession)

        let payload = makeSyncedPayload(startedAt: startedAt, endedAt: endedAt)
        let syncSpy = HealthKitRunSyncSpy(result: .success(payload))
        let api = RunSubmissionAPISpy(result: .success(makeRunSubmissionResultFixture(runId: "run-healthkit")))
        let service = RunUploadService(api: api, store: store, healthKitSync: syncSpy)

        let results = await service.uploadPendingSessions()
        let persisted = await store.loadSessions().first { $0.id == pendingHealthKitSession.id }

        XCTAssertEqual(results.first?.run.id, "run-healthkit")
        XCTAssertEqual(syncSpy.syncCalls, 1)
        XCTAssertEqual(api.submitCoordinatesCalls, 1)
        XCTAssertEqual(api.lastPayload?.coordinates.count, payload.coordinates.count)
        XCTAssertEqual(api.lastPayload?.timestamps, payload.timestamps)
        XCTAssertEqual(persisted?.status, .uploaded)
        XCTAssertEqual(persisted?.points.count, payload.coordinates.count)
    }

    @MainActor
    func testUploadKeepsSessionPendingOnURLTimeoutError() async throws {
        let store = RunSessionStore(fileURL: makeTempFileURL())
        let session = makeSessionFixture(id: UUID(), status: .pending)
        _ = try await store.append(session)

        let api = RunSubmissionAPISpy(result: .failure(URLError(.timedOut)))
        let service = RunUploadService(api: api, store: store)

        do {
            _ = try await service.upload(session)
            XCTFail("Expected upload to throw")
        } catch {
            // expected
        }

        let persisted = await store.loadSessions().first { $0.id == session.id }
        XCTAssertEqual(persisted?.status, .pending)
    }

    @MainActor
    func testEnqueueHealthKitSyncTimeoutPersistsPendingSessionForRetry() async throws {
        let startedAt = Date().addingTimeInterval(-600)
        let endedAt = Date()
        let store = RunSessionStore(fileURL: makeTempFileURL())
        let syncSpy = HealthKitRunSyncSpy(result: .failure(HealthKitRunSyncError.routeTimedOut))
        let api = RunSubmissionAPISpy(result: .success(makeRunSubmissionResultFixture(runId: "run-ignored")))
        let service = RunUploadService(api: api, store: store, healthKitSync: syncSpy)

        await service.enqueueHealthKitSync(startDate: startedAt, endDate: endedAt, timeout: 1)

        let sessions = await store.loadSessions()
        XCTAssertEqual(syncSpy.syncCalls, 1)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.source, .healthKit)
        XCTAssertEqual(sessions.first?.status, .pending)
        XCTAssertTrue(sessions.first?.points.isEmpty ?? false)
        XCTAssertEqual(sessions.first?.lastError, HealthKitRunSyncError.routeTimedOut.localizedDescription)
    }

    @MainActor
    func testEnqueueHealthKitSyncWithoutTimeoutUsesConfiguredHealthKitTimeout() async throws {
        let startedAt = Date().addingTimeInterval(-600)
        let endedAt = Date()
        let store = RunSessionStore(fileURL: makeTempFileURL())
        let syncSpy = HealthKitRunSyncSpy(result: .success(makeSyncedPayload(startedAt: startedAt, endedAt: endedAt)))
        let api = RunSubmissionAPISpy(result: .success(makeRunSubmissionResultFixture(runId: "run-healthkit-timeout")))
        let service = RunUploadService(api: api, store: store, healthKitSync: syncSpy, healthKitTimeout: 42)

        await service.enqueueHealthKitSync(startDate: startedAt, endDate: endedAt)

        XCTAssertEqual(syncSpy.lastTimeout, 42)
    }

    private func makeSessionFixture(
        id: UUID,
        status: RunSessionStatus,
        source: RunSessionSource = .localTracking
    ) -> RunSessionRecord {
        let startedAt = Date().addingTimeInterval(-600)
        let endedAt = Date()
        return RunSessionRecord(
            id: id,
            startedAt: startedAt,
            endedAt: endedAt,
            duration: 600,
            distanceMeters: 1500,
            points: [
                makeTrackPointFixture(lat: -25.4295, lng: -49.2717, timestamp: startedAt),
                makeTrackPointFixture(lat: -25.4290, lng: -49.2710, timestamp: startedAt.addingTimeInterval(5))
            ],
            source: source,
            status: status,
            lastUploadAttempt: nil,
            lastError: nil
        )
    }

    private func makeSyncedPayload(startedAt: Date, endedAt: Date) -> SyncedWorkoutPayload {
        let coordinates = [
            CLLocationCoordinate2D(latitude: -25.4295, longitude: -49.2717),
            CLLocationCoordinate2D(latitude: -25.4290, longitude: -49.2710)
        ]
        let timestamps = [
            Int(startedAt.timeIntervalSince1970),
            Int(endedAt.timeIntervalSince1970)
        ]
        return SyncedWorkoutPayload(
            coordinates: coordinates,
            timestamps: timestamps,
            source: SyncedWorkoutSourceMetadata(
                workoutId: UUID().uuidString,
                startedAt: startedAt,
                endedAt: endedAt,
                activityType: "37",
                sourceName: "Health"
            )
        )
    }

    private func makeTempFileURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }

        return directory.appendingPathComponent("run-sessions.json")
    }
}

@MainActor
private final class RunSubmissionAPISpy: RunSubmissionAPIProviding {
    private let result: Result<RunSubmissionResult, Error>
    private(set) var submitCoordinatesCalls = 0
    private(set) var lastPayload: (coordinates: [[String: Double]], timestamps: [Int], mode: String, targetQuadraId: String?)?

    init(result: Result<RunSubmissionResult, Error>) {
        self.result = result
    }

    func submitRunCoordinates(coordinates: [[String: Double]], timestamps: [Int], mode: String, targetQuadraId: String?) async throws -> RunSubmissionResult {
        submitCoordinatesCalls += 1
        lastPayload = (coordinates, timestamps, mode, targetQuadraId)
        return try result.get()
    }
}

@MainActor
private final class HealthKitRunSyncSpy: HealthKitRunSyncProviding {
    private let result: Result<SyncedWorkoutPayload, Error>
    private(set) var syncCalls = 0
    private(set) var lastTimeout: TimeInterval?

    init(result: Result<SyncedWorkoutPayload, Error>) {
        self.result = result
    }

    func syncWorkout(startDate: Date, endDate: Date, timeout: TimeInterval) async throws -> SyncedWorkoutPayload {
        syncCalls += 1
        lastTimeout = timeout
        return try result.get()
    }
}
