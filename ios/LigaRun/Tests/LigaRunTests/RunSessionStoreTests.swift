import XCTest
import CoreLocation
@testable import LigaRun

final class RunSessionStoreTests: XCTestCase {
    func testAppendAndLoadPersistsSession() async throws {
        let fileURL = makeTempFileURL()
        let store = RunSessionStore(fileURL: fileURL)
        let session = RunSessionRecord(
            id: UUID(),
            startedAt: Date(),
            endedAt: Date(),
            duration: 120,
            distanceMeters: 1000,
            points: [RunTrackPoint(location: CLLocation(latitude: 1, longitude: 2))],
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )

        _ = try await store.append(session)
        let loaded = await store.loadSessions()

        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first, session)
    }

    func testUpdateReplacesExistingSession() async throws {
        let fileURL = makeTempFileURL()
        let store = RunSessionStore(fileURL: fileURL)
        let sessionId = UUID()
        let initial = RunSessionRecord(
            id: sessionId,
            startedAt: Date(),
            endedAt: Date(),
            duration: 100,
            distanceMeters: 500,
            points: [],
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )

        _ = try await store.append(initial)

        var updated = initial
        updated.status = .uploaded
        _ = try await store.update(updated)

        let loaded = await store.loadSessions()
        XCTAssertEqual(loaded.first?.status, .uploaded)
    }

    func testRemoveDeletesSession() async throws {
        let fileURL = makeTempFileURL()
        let store = RunSessionStore(fileURL: fileURL)
        let sessionId = UUID()
        let session = RunSessionRecord(
            id: sessionId,
            startedAt: Date(),
            endedAt: Date(),
            duration: 60,
            distanceMeters: 300,
            points: [],
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )

        _ = try await store.append(session)
        _ = try await store.remove(id: sessionId)

        let loaded = await store.loadSessions()
        XCTAssertTrue(loaded.isEmpty)
    }

    private func makeTempFileURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return directory.appendingPathComponent("run-sessions.json")
    }
}
