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
            "Padrão suspeito detectado (high_speed_spike)"
        )
    }

    func testTranslateSubmissionReasonFallbackToOriginal() {
        XCTAssertEqual(translateSubmissionReason("unexpected_reason"), "unexpected_reason")
    }

    func testSubmissionTileFocusPriority() {
        let withTurn = makeRunSubmissionResultFixture(
            loopValidation: makeLoopValidationFixture(primaryTile: "tile-loop"),
            territoryResult: makeTerritoryResultFixture(tileId: "tile-territory"),
            turnResult: makeTurnResultFixture(tileId: "tile-turn")
        )
        XCTAssertEqual(submissionTileFocusId(for: withTurn), "tile-turn")

        let withTerritoryOnly = makeRunSubmissionResultFixture(
            loopValidation: makeLoopValidationFixture(primaryTile: "tile-loop"),
            territoryResult: makeTerritoryResultFixture(tileId: "tile-territory"),
            turnResult: nil
        )
        XCTAssertEqual(submissionTileFocusId(for: withTerritoryOnly), "tile-territory")

        let withLoopOnly = makeRunSubmissionResultFixture(
            loopValidation: makeLoopValidationFixture(primaryTile: "tile-loop"),
            territoryResult: nil,
            turnResult: nil
        )
        XCTAssertEqual(submissionTileFocusId(for: withLoopOnly), "tile-loop")
    }
}
