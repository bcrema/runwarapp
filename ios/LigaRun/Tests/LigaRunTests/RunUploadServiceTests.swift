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

    private func makeSessionFixture(id: UUID, status: RunSessionStatus) -> RunSessionRecord {
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
            status: status,
            lastUploadAttempt: nil,
            lastError: nil
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
    private(set) var lastPayload: (coordinates: [[String: Double]], timestamps: [Int])?

    init(result: Result<RunSubmissionResult, Error>) {
        self.result = result
    }

    func submitRunCoordinates(coordinates: [[String: Double]], timestamps: [Int]) async throws -> RunSubmissionResult {
        submitCoordinatesCalls += 1
        lastPayload = (coordinates, timestamps)
        return try result.get()
    }
}
