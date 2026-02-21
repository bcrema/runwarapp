import XCTest
@testable import LigaRun

final class QuadraEligibilityPolicyTests: XCTestCase {
    private let policy = QuadraEligibilityPolicy()

    func testEvaluateEligibleCompetitiveWhenUserIsSoloOwner() {
        let user = makeUserFixture(id: "runner-1", bandeiraId: nil)
        let quadra = makeTileFixture(ownerType: .solo, ownerId: "runner-1")

        let result = policy.evaluate(currentUser: user, quadra: quadra)

        XCTAssertEqual(result.status, .eligibleCompetitive)
        XCTAssertNil(result.reasonSummary)
    }

    func testEvaluateEligibleCompetitiveWhenUserBandeiraOwnsQuadra() {
        let user = makeUserFixture(id: "runner-1", bandeiraId: "band-1")
        let quadra = makeTileFixture(ownerType: .bandeira, ownerId: "band-1")

        let result = policy.evaluate(currentUser: user, quadra: quadra)

        XCTAssertEqual(result.status, .eligibleCompetitive)
    }

    func testEvaluateEligibleCompetitiveWhenUserIsChampion() {
        let user = makeUserFixture(id: "runner-1", bandeiraId: nil)
        let quadra = makeTileFixture(ownerType: .solo, ownerId: "owner-2", championUserId: "runner-1")

        let result = policy.evaluate(currentUser: user, quadra: quadra)

        XCTAssertEqual(result.status, .eligibleCompetitive)
    }

    func testEvaluateEligibleCompetitiveWhenUserBandeiraIsChampion() {
        let user = makeUserFixture(id: "runner-1", bandeiraId: "band-1")
        let quadra = makeTileFixture(ownerType: .solo, ownerId: "owner-2", championBandeiraId: "band-1")

        let result = policy.evaluate(currentUser: user, quadra: quadra)

        XCTAssertEqual(result.status, .eligibleCompetitive)
    }

    func testEvaluateTrainingOnlyWhenQuadraMetadataIsMissing() {
        let user = makeUserFixture(id: "runner-1", bandeiraId: "band-1")
        let quadra = makeTileFixture(ownerType: nil, ownerId: nil, championUserId: nil, championBandeiraId: nil)

        let result = policy.evaluate(currentUser: user, quadra: quadra)

        XCTAssertEqual(result.status, .trainingOnly(reason: .missingQuadraOwnershipData))
        XCTAssertEqual(result.reasonSummary, QuadraEligibilityReason.missingQuadraOwnershipData.rawValue)
    }

    func testEvaluateTrainingOnlyWhenUserContextIsMissing() {
        let resultWithoutUser = policy.evaluate(
            currentUser: nil,
            quadra: makeTileFixture(ownerType: .solo, ownerId: "owner-2")
        )

        XCTAssertEqual(resultWithoutUser.status, .trainingOnly(reason: .missingUserContext))

        let userWithoutBandeira = makeUserFixture(id: "runner-1", bandeiraId: nil)
        let bandeiraOwnedQuadra = makeTileFixture(ownerType: .bandeira, ownerId: "band-1")

        let resultWithoutBandeiraContext = policy.evaluate(currentUser: userWithoutBandeira, quadra: bandeiraOwnedQuadra)

        XCTAssertEqual(resultWithoutBandeiraContext.status, .trainingOnly(reason: .missingUserContext))

        let quadraWithOnlyBandeiraChampion = makeTileFixture(
            ownerType: nil,
            ownerId: nil,
            championUserId: nil,
            championBandeiraId: "band-1"
        )

        let resultWithOnlyBandeiraChampion = policy.evaluate(
            currentUser: userWithoutBandeira,
            quadra: quadraWithOnlyBandeiraChampion
        )

        XCTAssertEqual(resultWithOnlyBandeiraChampion.status, .trainingOnly(reason: .missingUserContext))
    }

    func testEvaluateTrainingOnlyWhenUserIsNotOwnerNorChampion() {
        let user = makeUserFixture(id: "runner-1", bandeiraId: "band-1")
        let quadra = makeTileFixture(ownerType: .solo, ownerId: "owner-2", championUserId: "runner-2", championBandeiraId: "band-2")

        let result = policy.evaluate(currentUser: user, quadra: quadra)

        XCTAssertEqual(result.status, .trainingOnly(reason: .userNotOwnerNorChampion))
        XCTAssertFalse(policy.canCompete(currentUser: user, quadra: quadra))
    }

    func testCanCompeteTrueWhenEligible() {
        let user = makeUserFixture(id: "runner-1", bandeiraId: nil)
        let quadra = makeTileFixture(ownerType: .solo, ownerId: "runner-1")

        XCTAssertTrue(policy.canCompete(currentUser: user, quadra: quadra))
    }
}

private func makeUserFixture(
    id: String,
    bandeiraId: String?
) -> User {
    User(
        id: id,
        email: "\(id)@ligarun.app",
        username: id,
        avatarUrl: nil,
        isPublic: true,
        bandeiraId: bandeiraId,
        bandeiraName: bandeiraId.map { _ in "Liga" },
        role: "runner",
        totalRuns: 0,
        totalDistance: 0,
        totalTilesConquered: 0
    )
}
