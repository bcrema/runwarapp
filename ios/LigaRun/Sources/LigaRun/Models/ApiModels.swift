import Foundation
import CoreLocation

struct AuthResponse: Codable {
    let user: User
    let token: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case user
        case token = "accessToken"
        case refreshToken
    }
}

struct TokenRefreshResponse: Codable {
    let token: String
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case token = "accessToken"
        case refreshToken
    }
}

struct User: Codable, Identifiable {
    let id: String
    let email: String
    var username: String
    var avatarUrl: String?
    var isPublic: Bool
    var bandeiraId: String?
    var bandeiraName: String?
    var role: String
    var totalRuns: Int
    var totalDistance: Double
    var totalTilesConquered: Int
}

struct UpdateProfileRequest: Codable {
    var username: String?
    var avatarUrl: String?
    var isPublic: Bool?
}

enum OwnerType: String, Codable {
    case solo = "SOLO"
    case bandeira = "BANDEIRA"
}

struct Tile: Codable, Identifiable {
    let id: String
    let lat: Double
    let lng: Double
    let boundary: [[Double]]
    let ownerType: OwnerType?
    let ownerId: String?
    let ownerName: String?
    let ownerColor: String?
    let shield: Int
    let isInCooldown: Bool
    let isInDispute: Bool
    let guardianId: String?
    let guardianName: String?

    var boundaryCoordinates: [CLLocationCoordinate2D] {
        boundary.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
    }
}

struct TileStats: Codable {
    let totalTiles: Int
    let ownedTiles: Int
    let neutralTiles: Int
    let tilesInDispute: Int
    let disputePercentage: Double
}

struct Run: Codable, Identifiable {
    let id: String
    let userId: String
    let distance: Double
    let duration: Double
    let startTime: String
    let endTime: String
    let isLoopValid: Bool
    let loopDistance: Double?
    let territoryAction: String?
    let targetTileId: String?
    let isValidForTerritory: Bool
    let fraudFlags: [String]
    let createdAt: String
}

struct LoopValidation: Codable {
    let isValid: Bool
    let distance: Double
    let duration: Double
    let closingDistance: Double
    let tilesCovered: [String]
    let primaryTile: String?
    let primaryTileCoverage: Double
    let fraudFlags: [String]
    let failureReasons: [String]
}

struct TerritoryResult: Codable {
    let success: Bool
    let actionType: String?
    let reason: String?
    let ownerChanged: Bool
    let shieldChange: Int
    let shieldBefore: Int
    let shieldAfter: Int
    let inDispute: Bool
    let tileId: String?
}

struct RunSubmissionResult: Codable {
    let run: Run
    let loopValidation: LoopValidation
    let territoryResult: TerritoryResult?
    let dailyActionsRemaining: Int
}

extension RunSubmissionResult: Identifiable {
    var id: String { run.id }
}

struct DailyStatus: Codable {
    let userActionsUsed: Int
    let userActionsRemaining: Int
    let bandeiraActionsUsed: Int?
    let bandeiraActionCap: Int?
}

struct Bandeira: Codable, Identifiable {
    let id: String
    let name: String
    let slug: String
    let category: String
    let color: String
    let logoUrl: String?
    let description: String?
    let memberCount: Int
    let totalTiles: Int
    let createdById: String
    let createdByUsername: String
}

struct BandeiraMember: Codable, Identifiable {
    let id: String
    let username: String
    let avatarUrl: String?
    let role: String
    let totalTilesConquered: Int
}

struct CreateBandeiraRequest: Codable {
    let name: String
    let category: String
    let color: String
    let description: String?
}
