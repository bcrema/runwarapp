import Foundation
import CoreLocation
import OSLog

struct RunTrackPoint: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    let horizontalAccuracy: Double?
    let timestamp: Date

    init(location: CLLocation) {
        latitude = location.coordinate.latitude
        longitude = location.coordinate.longitude
        altitude = location.verticalAccuracy >= 0 ? location.altitude : nil
        horizontalAccuracy = location.horizontalAccuracy >= 0 ? location.horizontalAccuracy : nil
        timestamp = location.timestamp
    }
}

enum RunSessionStatus: String, Codable {
    case pending
    case uploading
    case uploaded
    case failed
}

struct RunSessionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let duration: TimeInterval
    let distanceMeters: Double
    let points: [RunTrackPoint]
    var status: RunSessionStatus
    var lastUploadAttempt: Date?
    var lastError: String?
}

actor RunSessionStore {
    private let fileURL: URL
    private let logger = Logger(subsystem: AppEnvironment.keychainService, category: "RunSessionStore")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.fileURL = fileURL ?? RunSessionStore.defaultFileURL()
    }

    func loadSessions() -> [RunSessionRecord] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([RunSessionRecord].self, from: data)
        } catch {
            if (error as NSError).code != NSFileReadNoSuchFileError {
                logger.error("Failed to load run sessions: \(error.localizedDescription)")
            }
            return []
        }
    }

    func saveSessions(_ sessions: [RunSessionRecord]) throws {
        let data = try encoder.encode(sessions)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
    }

    func append(_ session: RunSessionRecord) throws -> [RunSessionRecord] {
        var sessions = loadSessions()
        sessions.append(session)
        try saveSessions(sessions)
        return sessions
    }

    func update(_ session: RunSessionRecord) throws -> [RunSessionRecord] {
        var sessions = loadSessions()
        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
            sessions.append(session)
            try saveSessions(sessions)
            return sessions
        }
        sessions[index] = session
        try saveSessions(sessions)
        return sessions
    }

    func remove(id: UUID) throws -> [RunSessionRecord] {
        var sessions = loadSessions()
        sessions.removeAll { $0.id == id }
        try saveSessions(sessions)
        return sessions
    }

    private static func defaultFileURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("run-sessions.json")
    }
}
