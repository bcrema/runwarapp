import XCTest
@testable import LigaRun

final class SubmissionResultPresentationTests: XCTestCase {
    func testTranslateSubmissionReasonKnownMapping() {
        XCTAssertEqual(
            translateSubmissionReason("tile_in_cooldown"),
            "Tile em cooldown; ataque bloqueado no momento."
        )
    }

    func testTranslateSubmissionReasonFraudFlag() {
        XCTAssertEqual(
            translateSubmissionReason("fraud_flag:high_speed_spike"),
            "Padrao suspeito detectado (high_speed_spike)"
        )
    }

    func testTranslateSubmissionReasonFallbackToOriginal() {
        XCTAssertEqual(translateSubmissionReason("unexpected_reason"), "unexpected_reason")
    }

    func testSubmissionTileFocusPriority() {
        let withTurn = makeRunSubmissionResultFixture(
            loopValidation: makeLoopValidationFixture(primaryQuadra: "quadra-loop"),
            territoryResult: makeTerritoryResultFixture(quadraId: "quadra-territory"),
            turnResult: makeTurnResultFixture(quadraId: "quadra-turn")
        )
        XCTAssertEqual(submissionTileFocusId(for: withTurn), "quadra-turn")

        let withTerritoryOnly = makeRunSubmissionResultFixture(
            loopValidation: makeLoopValidationFixture(primaryQuadra: "quadra-loop"),
            territoryResult: makeTerritoryResultFixture(quadraId: "quadra-territory"),
            turnResult: nil
        )
        XCTAssertEqual(submissionTileFocusId(for: withTerritoryOnly), "quadra-territory")

        let withLoopOnly = makeRunSubmissionResultFixture(
            loopValidation: makeLoopValidationFixture(primaryQuadra: "quadra-loop"),
            territoryResult: nil,
            turnResult: nil
        )
        XCTAssertEqual(submissionTileFocusId(for: withLoopOnly), "quadra-loop")
    }

    func testTerritoryImpactMappingByActionType() {
        let conquest = makeRunSubmissionResultFixture(
            turnResult: makeTurnResultFixture(actionType: "CONQUEST")
        )
        XCTAssertEqual(submissionTerritoryImpact(for: conquest), .conquest)

        let attack = makeRunSubmissionResultFixture(
            turnResult: makeTurnResultFixture(actionType: "ATTACK")
        )
        XCTAssertEqual(submissionTerritoryImpact(for: attack), .attack)

        let defense = makeRunSubmissionResultFixture(
            turnResult: makeTurnResultFixture(actionType: "DEFENSE")
        )
        XCTAssertEqual(submissionTerritoryImpact(for: defense), .defense)

        let none = makeRunSubmissionResultFixture(territoryResult: nil, turnResult: nil)
        XCTAssertEqual(submissionTerritoryImpact(for: none), .noEffect)
    }

    func testSubmissionReasonsAreMergedTranslatedAndDeduplicated() {
        let result = makeRunSubmissionResultFixture(
            loopValidation: makeLoopValidationFixture(
                failureReasons: ["distance_too_short"],
                fraudFlags: ["high_speed_spike"]
            ),
            territoryResult: makeTerritoryResultFixture(reason: "distance_too_short"),
            turnResult: makeTurnResultFixture(reasons: ["tile_in_cooldown"])
        )

        let reasons = submissionResultReasons(for: result)

        XCTAssertEqual(
            reasons,
            [
                "Tile em cooldown; ataque bloqueado no momento.",
                "Distancia muito curta (minimo 1.2km)",
                "Padrao suspeito detectado (high_speed_spike)"
            ]
        )
    }

    func testRunDurationLabelFormatting() {
        let short = RunSubmissionResult(
            run: makeRunFixture(duration: 605),
            loopValidation: makeLoopValidationFixture(),
            territoryResult: makeTerritoryResultFixture(),
            turnResult: makeTurnResultFixture(),
            dailyActionsRemaining: 1
        )
        XCTAssertEqual(submissionRunDurationLabel(for: short), "10:05")

        let long = RunSubmissionResult(
            run: makeRunFixture(duration: 3725),
            loopValidation: makeLoopValidationFixture(),
            territoryResult: makeTerritoryResultFixture(),
            turnResult: makeTurnResultFixture(),
            dailyActionsRemaining: 1
        )
        XCTAssertEqual(submissionRunDurationLabel(for: long), "1:02:05")
    }

    func testShieldDeltaLabelUsesTurnResultThenTerritoryFallback() {
        let withTurn = makeRunSubmissionResultFixture(
            territoryResult: makeTerritoryResultFixture(shieldBefore: 20, shieldAfter: 35),
            turnResult: makeTurnResultFixture(shieldBefore: 30, shieldAfter: 40)
        )
        XCTAssertEqual(submissionShieldDeltaLabel(for: withTurn), "30 -> 40")

        let territoryOnly = makeRunSubmissionResultFixture(
            territoryResult: makeTerritoryResultFixture(shieldBefore: 20, shieldAfter: 35),
            turnResult: nil
        )
        XCTAssertEqual(submissionShieldDeltaLabel(for: territoryOnly), "20 -> 35")
    }
}
