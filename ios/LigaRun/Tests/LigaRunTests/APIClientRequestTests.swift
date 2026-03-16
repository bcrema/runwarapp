import Foundation
import XCTest
@testable import LigaRun

final class APIClientRequestTests: XCTestCase {
    override func setUp() {
        super.setUp()
        URLProtocolStub.reset()
    }

    override func tearDown() {
        URLProtocolStub.reset()
        super.tearDown()
    }

    @MainActor
    func testGetQuadrasByUserRequestsExpectedEndpoint() async throws {
        let client = makeClient()
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/quadras/user/user-123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")

            return HTTPStubResponse(
                statusCode: 200,
                body: Data("[]".utf8)
            )
        }

        let quadras = try await client.getQuadrasByUser(userId: "user-123")

        XCTAssertTrue(quadras.isEmpty)
    }

    @MainActor
    func testGetQuadrasByBandeiraRequestsExpectedEndpoint() async throws {
        let client = makeClient()
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.path, "/api/quadras/bandeira/band-456")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")

            return HTTPStubResponse(
                statusCode: 200,
                body: Data("[]".utf8)
            )
        }

        let quadras = try await client.getQuadrasByBandeira(bandeiraId: "band-456")

        XCTAssertTrue(quadras.isEmpty)
    }

    @MainActor
    func testUpdateMemberRoleSendsExpectedPayload() async throws {
        let client = makeClient()
        let expectedRequest = UpdateBandeiraMemberRoleRequest(userId: "user-789", role: "ADMIN")

        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.url?.path, "/api/bandeiras/band-456/members/role")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try XCTUnwrap(request.httpBodyData)
            let decodedBody = try JSONDecoder().decode(UpdateBandeiraMemberRoleRequest.self, from: body)
            XCTAssertEqual(decodedBody, expectedRequest)

            return HTTPStubResponse(
                statusCode: 200,
                body: Data(#"{"success":true}"#.utf8)
            )
        }

        let success = try await client.updateMemberRole(
            bandeiraId: "band-456",
            request: expectedRequest
        )

        XCTAssertTrue(success)
    }

    @MainActor
    private func makeClient() -> APIClient {
        APIClient(
            baseURL: URL(string: "https://example.com")!,
            tokenProvider: { "token-123" },
            session: makeSession()
        )
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    @MainActor
    func testExchangeSocialSendsExpectedPayload() async throws {
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/auth/social/exchange")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

            let body = try XCTUnwrap(request.httpBodyData)
            let decoded = try JSONDecoder().decode(SocialPayload.self, from: body)
            XCTAssertEqual(decoded.provider, .google)
            XCTAssertEqual(decoded.idToken, "token-xyz")
            XCTAssertEqual(decoded.authorizationCode, "code-123")

            let response = """
            {
                "user": {
                    "id": "user-id",
                    "email": "user@example.com",
                    "username": "user",
                    "avatarUrl": null,
                    "isPublic": true,
                    "bandeiraId": null,
                    "bandeiraName": null,
                    "role": "MEMBER",
                    "totalRuns": 0,
                    "totalDistance": 0,
                    "totalTilesConquered": 0
                },
                "accessToken": "t1",
                "refreshToken": "r1"
            }
            """.data(using: .utf8)!

            return HTTPStubResponse(statusCode: 200, body: response)
        }

        let client = makeClient()
        let response = try await client.exchangeSocial(
            provider: .google,
            idToken: "token-xyz",
            authorizationCode: "code-123",
            nonce: nil,
            emailHint: "hint@example.com",
            givenName: nil,
            familyName: nil,
            avatarUrl: nil
        )

        XCTAssertEqual(response.token, "t1")
        XCTAssertEqual(response.refreshToken, "r1")
    }

    @MainActor
    func testExchangeSocialThrowsLinkRequired() async throws {
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.url?.path, "/api/auth/social/exchange")
            let response = #"{"error":"LINK_REQUIRED","message":"Linking needed","linkToken":"token","provider":"apple","emailMasked":"u***"}"#.data(using: .utf8)!
            return HTTPStubResponse(statusCode: 409, body: response)
        }

        let client = makeClient()
        do {
            _ = try await client.exchangeSocial(
                provider: .apple,
                idToken: "token",
                authorizationCode: nil,
                nonce: nil,
                emailHint: nil,
                givenName: nil,
                familyName: nil,
                avatarUrl: nil
            )
            XCTFail("Expected SocialLinkRequiredError")
        } catch {
            XCTAssertTrue(error is SocialLinkRequiredError)
        }
    }

    @MainActor
    func testConfirmSocialLinkPostsExpectedPayload() async throws {
        URLProtocolStub.handler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.url?.path, "/api/auth/social/link/confirm")

            let body = try XCTUnwrap(request.httpBodyData)
            let decoded = try JSONDecoder().decode(LinkPayload.self, from: body)
            XCTAssertEqual(decoded.linkToken, "link-1")
            XCTAssertEqual(decoded.email, "user@example.com")

            let response = """
            {
                "user": {
                    "id": "user-id",
                    "email": "user@example.com",
                    "username": "user",
                    "avatarUrl": null,
                    "isPublic": true,
                    "bandeiraId": null,
                    "bandeiraName": null,
                    "role": "MEMBER",
                    "totalRuns": 0,
                    "totalDistance": 0,
                    "totalTilesConquered": 0
                },
                "accessToken": "access",
                "refreshToken": "refresh"
            }
            """.data(using: .utf8)!

            return HTTPStubResponse(statusCode: 200, body: response)
        }

        let client = makeClient()
        let auth = try await client.confirmSocialLink(linkToken: "link-1", email: "user@example.com", password: "secret")
        XCTAssertEqual(auth.token, "access")
        XCTAssertEqual(auth.refreshToken, "refresh")
    }
}

private struct HTTPStubResponse {
    let statusCode: Int
    let body: Data
}

private struct SocialPayload: Decodable {
    let provider: SocialProvider
    let idToken: String
    let authorizationCode: String?
}

private struct LinkPayload: Decodable {
    let linkToken: String
    let email: String
    let password: String
}

private final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    static var handler: ((URLRequest) throws -> HTTPStubResponse)?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            guard let handler = Self.handler else {
                throw URLError(.badServerResponse)
            }

            let response = try handler(request)
            let httpResponse = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: response.statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!

            client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: response.body)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    static func reset() {
        handler = nil
    }
}

private extension URLRequest {
    var httpBodyData: Data? {
        if let httpBody {
            return httpBody
        }

        guard let stream = httpBodyStream else {
            return nil
        }

        stream.open()
        defer { stream.close() }

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        var data = Data()
        while stream.hasBytesAvailable {
            let bytesRead = stream.read(buffer, maxLength: bufferSize)
            guard bytesRead > 0 else { break }
            data.append(buffer, count: bytesRead)
        }

        return data.isEmpty ? nil : data
    }
}
