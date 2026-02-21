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

struct Quadra: Codable, Identifiable {
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
    let championUserId: String?
    let championBandeiraId: String?
    let championName: String?

    var boundaryCoordinates: [CLLocationCoordinate2D] {
        boundary.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
    }
}

typealias Tile = Quadra

struct QuadraStats: Codable {
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
    let targetQuadraId: String?
    let isValidForTerritory: Bool
    let fraudFlags: [String]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, userId, distance, duration, startTime, endTime, isLoopValid, loopDistance
        case territoryAction, targetQuadraId, isValidForTerritory, fraudFlags, createdAt, targetTileId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        distance = try container.decode(Double.self, forKey: .distance)
        duration = try container.decode(Double.self, forKey: .duration)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        isLoopValid = try container.decode(Bool.self, forKey: .isLoopValid)
        loopDistance = try container.decodeIfPresent(Double.self, forKey: .loopDistance)
        territoryAction = try container.decodeIfPresent(String.self, forKey: .territoryAction)
        targetQuadraId = try container.decodeIfPresent(String.self, forKey: .targetQuadraId)
            ?? container.decodeIfPresent(String.self, forKey: .targetTileId)
        isValidForTerritory = try container.decode(Bool.self, forKey: .isValidForTerritory)
        fraudFlags = try container.decode([String].self, forKey: .fraudFlags)
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
}

struct LoopValidation: Codable {
    let isValid: Bool
    let distance: Double
    let duration: Double
    let closingDistance: Double
    let quadrasCovered: [String]
    let primaryQuadra: String?
    let primaryQuadraCoverage: Double
    let fraudFlags: [String]
    let failureReasons: [String]

    enum CodingKeys: String, CodingKey {
        case isValid, distance, duration, closingDistance, quadrasCovered, primaryQuadra, primaryQuadraCoverage, fraudFlags, failureReasons
        case tilesCovered, primaryTile, primaryTileCoverage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isValid = try container.decode(Bool.self, forKey: .isValid)
        distance = try container.decode(Double.self, forKey: .distance)
        duration = try container.decode(Double.self, forKey: .duration)
        closingDistance = try container.decode(Double.self, forKey: .closingDistance)
        quadrasCovered = try container.decodeIfPresent([String].self, forKey: .quadrasCovered)
            ?? container.decode([String].self, forKey: .tilesCovered)
        primaryQuadra = try container.decodeIfPresent(String.self, forKey: .primaryQuadra)
            ?? container.decodeIfPresent(String.self, forKey: .primaryTile)
        primaryQuadraCoverage = try container.decodeIfPresent(Double.self, forKey: .primaryQuadraCoverage)
            ?? container.decode(Double.self, forKey: .primaryTileCoverage)
        fraudFlags = try container.decode([String].self, forKey: .fraudFlags)
        failureReasons = try container.decode([String].self, forKey: .failureReasons)
    }
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
    let quadraId: String?

    enum CodingKeys: String, CodingKey {
        case success, actionType, reason, ownerChanged, shieldChange, shieldBefore, shieldAfter, inDispute, quadraId, tileId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        success = try container.decode(Bool.self, forKey: .success)
        actionType = try container.decodeIfPresent(String.self, forKey: .actionType)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        ownerChanged = try container.decode(Bool.self, forKey: .ownerChanged)
        shieldChange = try container.decode(Int.self, forKey: .shieldChange)
        shieldBefore = try container.decode(Int.self, forKey: .shieldBefore)
        shieldAfter = try container.decode(Int.self, forKey: .shieldAfter)
        inDispute = try container.decode(Bool.self, forKey: .inDispute)
        quadraId = try container.decodeIfPresent(String.self, forKey: .quadraId)
            ?? container.decodeIfPresent(String.self, forKey: .tileId)
    }
}

struct TurnResult: Codable {
    let actionType: String?
    let quadraId: String?
    let h3Index: String?
    let previousOwner: TurnOwnerSnapshot?
    let newOwner: TurnOwnerSnapshot?
    let shieldBefore: Int?
    let shieldAfter: Int?
    let cooldownUntil: String?
    let disputeState: String?
    let capsRemaining: TurnCapsRemaining
    let reasons: [String]

    enum CodingKeys: String, CodingKey {
        case actionType, quadraId, h3Index, previousOwner, newOwner, shieldBefore, shieldAfter, cooldownUntil, disputeState, capsRemaining, reasons, tileId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actionType = try container.decodeIfPresent(String.self, forKey: .actionType)
        quadraId = try container.decodeIfPresent(String.self, forKey: .quadraId)
            ?? container.decodeIfPresent(String.self, forKey: .tileId)
        h3Index = try container.decodeIfPresent(String.self, forKey: .h3Index)
        previousOwner = try container.decodeIfPresent(TurnOwnerSnapshot.self, forKey: .previousOwner)
        newOwner = try container.decodeIfPresent(TurnOwnerSnapshot.self, forKey: .newOwner)
        shieldBefore = try container.decodeIfPresent(Int.self, forKey: .shieldBefore)
        shieldAfter = try container.decodeIfPresent(Int.self, forKey: .shieldAfter)
        cooldownUntil = try container.decodeIfPresent(String.self, forKey: .cooldownUntil)
        disputeState = try container.decodeIfPresent(String.self, forKey: .disputeState)
        capsRemaining = try container.decode(TurnCapsRemaining.self, forKey: .capsRemaining)
        reasons = try container.decode([String].self, forKey: .reasons)
    }
}

struct TurnOwnerSnapshot: Codable {
    let id: String?
    let type: OwnerType?
}

struct TurnCapsRemaining: Codable {
    let userActionsRemaining: Int
    let bandeiraActionsRemaining: Int?
}

struct RunSubmissionResult: Codable {
    let run: Run
    let loopValidation: LoopValidation
    let territoryResult: TerritoryResult?
    let turnResult: TurnResult?
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

extension Run {
    init(
        id: String,
        userId: String,
        distance: Double,
        duration: Double,
        startTime: String,
        endTime: String,
        isLoopValid: Bool,
        loopDistance: Double?,
        territoryAction: String?,
        targetQuadraId: String?,
        isValidForTerritory: Bool,
        fraudFlags: [String],
        createdAt: String
    ) {
        self.id = id
        self.userId = userId
        self.distance = distance
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.isLoopValid = isLoopValid
        self.loopDistance = loopDistance
        self.territoryAction = territoryAction
        self.targetQuadraId = targetQuadraId
        self.isValidForTerritory = isValidForTerritory
        self.fraudFlags = fraudFlags
        self.createdAt = createdAt
    }
}

extension LoopValidation {
    init(
        isValid: Bool,
        distance: Double,
        duration: Double,
        closingDistance: Double,
        quadrasCovered: [String],
        primaryQuadra: String?,
        primaryQuadraCoverage: Double,
        fraudFlags: [String],
        failureReasons: [String]
    ) {
        self.isValid = isValid
        self.distance = distance
        self.duration = duration
        self.closingDistance = closingDistance
        self.quadrasCovered = quadrasCovered
        self.primaryQuadra = primaryQuadra
        self.primaryQuadraCoverage = primaryQuadraCoverage
        self.fraudFlags = fraudFlags
        self.failureReasons = failureReasons
    }
}

extension TerritoryResult {
    init(
        success: Bool,
        actionType: String?,
        reason: String?,
        ownerChanged: Bool,
        shieldChange: Int,
        shieldBefore: Int,
        shieldAfter: Int,
        inDispute: Bool,
        quadraId: String?
    ) {
        self.success = success
        self.actionType = actionType
        self.reason = reason
        self.ownerChanged = ownerChanged
        self.shieldChange = shieldChange
        self.shieldBefore = shieldBefore
        self.shieldAfter = shieldAfter
        self.inDispute = inDispute
        self.quadraId = quadraId
    }
}

extension TurnResult {
    init(
        actionType: String?,
        quadraId: String?,
        h3Index: String?,
        previousOwner: TurnOwnerSnapshot?,
        newOwner: TurnOwnerSnapshot?,
        shieldBefore: Int?,
        shieldAfter: Int?,
        cooldownUntil: String?,
        disputeState: String?,
        capsRemaining: TurnCapsRemaining,
        reasons: [String]
    ) {
        self.actionType = actionType
        self.quadraId = quadraId
        self.h3Index = h3Index
        self.previousOwner = previousOwner
        self.newOwner = newOwner
        self.shieldBefore = shieldBefore
        self.shieldAfter = shieldAfter
        self.cooldownUntil = cooldownUntil
        self.disputeState = disputeState
        self.capsRemaining = capsRemaining
        self.reasons = reasons
    }
}
