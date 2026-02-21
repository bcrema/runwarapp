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

    static func == (lhs: RunTrackPoint, rhs: RunTrackPoint) -> Bool {
        guard lhs.latitude == rhs.latitude,
              lhs.longitude == rhs.longitude,
              lhs.altitude == rhs.altitude,
              lhs.horizontalAccuracy == rhs.horizontalAccuracy
        else { return false }
        return abs(lhs.timestamp.timeIntervalSince1970 - rhs.timestamp.timeIntervalSince1970) <= 0.01
    }
}

enum RunSessionStatus: String, Codable {
    case pending
    case uploading
    case uploaded
    case failed
}

enum RunSessionSource: String, Codable {
    case localTracking
    case healthKit
}

enum RunCompetitionMode: String, Codable {
    case competitive = "COMPETITIVE"
    case training = "TRAINING"
}

struct RunSessionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let duration: TimeInterval
    let distanceMeters: Double
    var points: [RunTrackPoint]
    var source: RunSessionSource = .localTracking
    var competitionMode: RunCompetitionMode = .training
    var targetQuadraId: String?
    var eligibilityReason: String?
    var status: RunSessionStatus
    var lastUploadAttempt: Date?
    var lastError: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case startedAt
        case endedAt
        case duration
        case distanceMeters
        case points
        case source
        case competitionMode
        case targetQuadraId
        case eligibilityReason
        case status
        case lastUploadAttempt
        case lastError
    }

    init(
        id: UUID,
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        distanceMeters: Double,
        points: [RunTrackPoint],
        source: RunSessionSource = .localTracking,
        competitionMode: RunCompetitionMode = .training,
        targetQuadraId: String? = nil,
        eligibilityReason: String? = nil,
        status: RunSessionStatus,
        lastUploadAttempt: Date?,
        lastError: String?
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.distanceMeters = distanceMeters
        self.points = points
        self.source = source
        self.competitionMode = competitionMode
        self.targetQuadraId = targetQuadraId
        self.eligibilityReason = eligibilityReason
        self.status = status
        self.lastUploadAttempt = lastUploadAttempt
        self.lastError = lastError
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decode(Date.self, forKey: .endedAt)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
        points = try container.decode([RunTrackPoint].self, forKey: .points)
        source = try container.decodeIfPresent(RunSessionSource.self, forKey: .source) ?? .localTracking
        if let modeString = try container.decodeIfPresent(String.self, forKey: .competitionMode) {
            competitionMode = RunCompetitionMode(rawValue: modeString) ?? .training
        } else {
            competitionMode = .training
        }
        targetQuadraId = try container.decodeIfPresent(String.self, forKey: .targetQuadraId)
        eligibilityReason = try container.decodeIfPresent(String.self, forKey: .eligibilityReason)
        status = try container.decode(RunSessionStatus.self, forKey: .status)
        lastUploadAttempt = try container.decodeIfPresent(Date.self, forKey: .lastUploadAttempt)
        lastError = try container.decodeIfPresent(String.self, forKey: .lastError)
    }

    static func == (lhs: RunSessionRecord, rhs: RunSessionRecord) -> Bool {
        guard lhs.id == rhs.id,
              datesEqual(lhs.startedAt, rhs.startedAt),
              datesEqual(lhs.endedAt, rhs.endedAt),
              lhs.duration == rhs.duration,
              lhs.distanceMeters == rhs.distanceMeters,
              lhs.points == rhs.points,
              lhs.source == rhs.source,
              lhs.competitionMode == rhs.competitionMode,
              lhs.targetQuadraId == rhs.targetQuadraId,
              lhs.eligibilityReason == rhs.eligibilityReason,
              lhs.status == rhs.status,
              datesEqual(lhs.lastUploadAttempt, rhs.lastUploadAttempt),
              lhs.lastError == rhs.lastError
        else { return false }
        return true
    }

    private static func datesEqual(_ lhs: Date, _ rhs: Date) -> Bool {
        abs(lhs.timeIntervalSince1970 - rhs.timeIntervalSince1970) <= 0.001
    }

    private static func datesEqual(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return datesEqual(lhs, rhs)
        default:
            return false
        }
    }
}

actor RunSessionStore {
    private let fileURL: URL
    private let logger = Logger(subsystem: AppEnvironment.keychainService, category: "RunSessionStore")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: date))
        }
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let internetDateTimeFormatter = ISO8601DateFormatter()
            internetDateTimeFormatter.formatOptions = [.withInternetDateTime]
            if let date = fractionalFormatter.date(from: string)
                ?? internetDateTimeFormatter.date(from: string) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date string: \(string)"
            )
        }
        self.fileURL = fileURL ?? RunSessionStore.defaultFileURL()
    }

    func loadSessions() -> [RunSessionRecord] {
        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([RunSessionRecord].self, from: data)
        } catch {
            if let nsError = error as NSError?,
               nsError.domain == NSCocoaErrorDomain,
               nsError.code == NSFileReadNoSuchFileError {
                // File doesn't exist, which is fine
            } else {
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
