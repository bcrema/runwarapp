import Foundation
import XCTest
@testable import LigaRun

final class ApiModelsDecodingTests: XCTestCase {
    func testAuthResponseDecodesUserWithQuadraFieldNames() throws {
        let json = """
        {
          "accessToken": "token-123",
          "refreshToken": "refresh-123",
          "user": {
            "id": "u1",
            "email": "runner@ligarun.app",
            "username": "runner",
            "avatarUrl": null,
            "isPublic": true,
            "bandeiraId": null,
            "bandeiraName": null,
            "role": "USER",
            "totalRuns": 7,
            "totalDistance": 15.2,
            "totalDistanceMeters": 15200,
            "totalQuadrasConquered": 4
          }
        }
        """

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.token, "token-123")
        XCTAssertEqual(decoded.refreshToken, "refresh-123")
        XCTAssertEqual(decoded.user.totalTilesConquered, 4)
    }

    func testQuadraStatsDecodesQuadraFieldNames() throws {
        let json = """
        {
          "totalQuadras": 100,
          "ownedQuadras": 25,
          "neutralQuadras": 75,
          "quadrasInDispute": 5,
          "disputePercentage": 20
        }
        """

        let decoded = try JSONDecoder().decode(QuadraStats.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.totalTiles, 100)
        XCTAssertEqual(decoded.ownedTiles, 25)
        XCTAssertEqual(decoded.neutralTiles, 75)
        XCTAssertEqual(decoded.tilesInDispute, 5)
        XCTAssertEqual(decoded.disputePercentage, 20)
    }

    func testBandeiraDecodesQuadraFieldName() throws {
        let json = """
        {
          "id": "b1",
          "name": "Liga Azul",
          "slug": "liga-azul",
          "category": "running",
          "color": "#0088FF",
          "logoUrl": null,
          "description": "Equipe",
          "memberCount": 10,
          "totalQuadras": 25,
          "createdById": "u1",
          "createdByUsername": "captain"
        }
        """

        let decoded = try JSONDecoder().decode(Bandeira.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.totalTiles, 25)
        XCTAssertEqual(decoded.name, "Liga Azul")
    }

    func testBandeiraMemberDecodesQuadraFieldName() throws {
        let json = """
        {
          "id": "u2",
          "username": "sprinter",
          "avatarUrl": null,
          "role": "MEMBER",
          "totalQuadrasConquered": 11
        }
        """

        let decoded = try JSONDecoder().decode(BandeiraMember.self, from: Data(json.utf8))

        XCTAssertEqual(decoded.totalTilesConquered, 11)
        XCTAssertEqual(decoded.username, "sprinter")
    }
}
