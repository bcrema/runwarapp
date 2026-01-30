import Foundation
import OSLog

final class RunUploadService: Sendable {
    private let api: APIClient
    private let store: RunSessionStore
    private let logger = Logger(subsystem: AppEnvironment.keychainService, category: "RunUploadService")

    init(api: APIClient, store: RunSessionStore) {
        self.api = api
        self.store = store
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

        let coordinates = session.points.map { point in
            ["lat": point.latitude, "lng": point.longitude]
        }
        let timestamps = session.points.map { point in
            Int(point.timestamp.timeIntervalSince1970)
        }

        do {
            let result = try await api.submitRunCoordinates(coordinates: coordinates, timestamps: timestamps)
            updatedSession.status = .uploaded
            updatedSession.lastError = nil
            _ = try await store.update(updatedSession)
            return result
        } catch {
            updatedSession.status = .failed
            updatedSession.lastError = error.localizedDescription
            _ = try? await store.update(updatedSession)
            throw error
        }
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
