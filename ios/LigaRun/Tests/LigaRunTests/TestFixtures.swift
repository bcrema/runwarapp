import CoreLocation
import Foundation
@testable import LigaRun

func makeRunFixture(
    id: String = UUID().uuidString,
    distance: Double = 5000,
    duration: Double = 1800,
    isLoopValid: Bool = true,
    territoryAction: String? = nil,
    targetQuadraId: String? = nil
) -> Run {
    let formatter = ISO8601DateFormatter()
    let startDate = Date()
    let endDate = startDate.addingTimeInterval(duration)

    return Run(
        id: id,
        userId: UUID().uuidString,
        distance: distance,
        duration: duration,
        startTime: formatter.string(from: startDate),
        endTime: formatter.string(from: endDate),
        isLoopValid: isLoopValid,
        loopDistance: distance,
        territoryAction: territoryAction,
        targetQuadraId: targetQuadraId,
        isValidForTerritory: isLoopValid,
        fraudFlags: [],
        createdAt: formatter.string(from: endDate)
    )
}

func makeLoopValidationFixture(
    isValid: Bool = true,
    primaryQuadra: String? = "quadra-primary",
    failureReasons: [String] = [],
    fraudFlags: [String] = [],
    quadrasCovered: [String]? = nil
) -> LoopValidation {
    let resolvedQuadrasCovered: [String]
    if let quadrasCovered = quadrasCovered {
        resolvedQuadrasCovered = quadrasCovered
    } else if let primaryQuadra = primaryQuadra {
        resolvedQuadrasCovered = [primaryQuadra]
    } else {
        resolvedQuadrasCovered = ["quadra-primary"]
    }

    return LoopValidation(
        isValid: isValid,
        distance: 5000,
        duration: 1800,
        closingDistance: 10,
        quadrasCovered: resolvedQuadrasCovered,
        primaryQuadra: primaryQuadra,
        primaryQuadraCoverage: 0.7,
        fraudFlags: fraudFlags,
        failureReasons: failureReasons
    )
}

func makeTerritoryResultFixture(
    actionType: String? = "CONQUEST",
    reason: String? = nil,
    shieldBefore: Int = 65,
    shieldAfter: Int = 85,
    quadraId: String? = "quadra-territory"
) -> TerritoryResult {
    TerritoryResult(
        success: true,
        actionType: actionType,
        reason: reason,
        ownerChanged: true,
        shieldChange: shieldAfter - shieldBefore,
        shieldBefore: shieldBefore,
        shieldAfter: shieldAfter,
        inDispute: false,
        quadraId: quadraId
    )
}

func makeTurnResultFixture(
    actionType: String? = "CONQUEST",
    quadraId: String? = "quadra-turn",
    shieldBefore: Int? = 65,
    shieldAfter: Int? = 85,
    reasons: [String] = []
) -> TurnResult {
    TurnResult(
        actionType: actionType,
        quadraId: quadraId,
        h3Index: nil,
        previousOwner: nil,
        newOwner: nil,
        shieldBefore: shieldBefore,
        shieldAfter: shieldAfter,
        cooldownUntil: nil,
        disputeState: nil,
        capsRemaining: TurnCapsRemaining(userActionsRemaining: 1, bandeiraActionsRemaining: nil),
        reasons: reasons
    )
}

func makeRunSubmissionResultFixture(
    runId: String = UUID().uuidString,
    loopValidation: LoopValidation = makeLoopValidationFixture(),
    territoryResult: TerritoryResult? = makeTerritoryResultFixture(),
    turnResult: TurnResult? = makeTurnResultFixture()
) -> RunSubmissionResult {
    RunSubmissionResult(
        run: makeRunFixture(id: runId),
        loopValidation: loopValidation,
        territoryResult: territoryResult,
        turnResult: turnResult,
        dailyActionsRemaining: 1
    )
}

func makeQuadraFixture(
    id: String = "tile-1",
    lat: Double = -25.429,
    lng: Double = -49.271,
    ownerType: OwnerType? = .solo,
    ownerName: String? = "Runner",
    ownerColor: String? = "#00AACC",
    shield: Int = 70,
    isInDispute: Bool = false
) -> Quadra {
    Quadra(
        id: id,
        lat: lat,
        lng: lng,
        boundary: [[lat, lng], [lat + 0.001, lng], [lat + 0.001, lng + 0.001], [lat, lng + 0.001]],
        ownerType: ownerType,
        ownerId: "owner-1",
        ownerName: ownerName,
        ownerColor: ownerColor,
        shield: shield,
        isInCooldown: false,
        isInDispute: isInDispute,
        guardianId: nil,
        guardianName: nil,
        championUserId: nil,
        championBandeiraId: nil,
        championName: nil
    )
}

func makeBandeiraFixture(id: String = "b1", name: String = "Liga Azul") -> Bandeira {
    Bandeira(
        id: id,
        name: name,
        slug: "liga-azul",
        category: "running",
        color: "#0088FF",
        logoUrl: nil,
        description: "Equipe de corrida",
        memberCount: 10,
        totalTiles: 25,
        createdById: "u1",
        createdByUsername: "captain"
    )
}

func makeTrackPointFixture(
    lat: Double,
    lng: Double,
    timestamp: Date
) -> RunTrackPoint {
    RunTrackPoint(location: CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
        altitude: 900,
        horizontalAccuracy: 5,
        verticalAccuracy: 5,
        timestamp: timestamp
    ))
}
