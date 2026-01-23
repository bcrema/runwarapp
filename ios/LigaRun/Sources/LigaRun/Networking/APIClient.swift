import Foundation

struct APIError: LocalizedError, Codable {
    let error: String?
    let message: String
    let details: [String: String]?

    var errorDescription: String? { message }
}

private struct EmptyBody: Encodable {}

private struct RunCoordinatesRequest: Encodable {
    let coordinates: [[String: Double]]
    let timestamps: [Int]
}

private struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

private struct LogoutRequest: Encodable {
    let refreshToken: String?
}

@MainActor
final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let tokenProvider: () -> String?
    private let refreshHandler: (() async throws -> String?)?

    init(
        baseURL: URL,
        tokenProvider: @escaping () -> String?,
        refreshHandler: (() async throws -> String?)? = nil
    ) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.refreshHandler = refreshHandler
        self.session = URLSession(configuration: .default)

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Public endpoints

    func login(email: String, password: String) async throws -> AuthResponse {
        try await request("/api/auth/login", method: "POST", body: ["email": email, "password": password])
    }

    func register(email: String, username: String, password: String) async throws -> AuthResponse {
        try await request("/api/auth/register", method: "POST", body: ["email": email, "username": username, "password": password])
    }

    func refreshToken(_ refreshToken: String) async throws -> TokenRefreshResponse {
        try await request(
            "/api/auth/refresh",
            method: "POST",
            body: RefreshTokenRequest(refreshToken: refreshToken),
            allowRefresh: false
        )
    }

    func logout(refreshToken: String?) async throws {
        _ = try await request(
            "/api/auth/logout",
            method: "POST",
            body: LogoutRequest(refreshToken: refreshToken),
            allowRefresh: false
        ) as EmptyResponse
    }

    func getMe() async throws -> User {
        try await request("/api/users/me")
    }

    func updateProfile(request: UpdateProfileRequest) async throws -> User {
        try await self.request("/api/users/me", method: "PUT", body: request)
    }

    func getTiles(bounds: (minLat: Double, minLng: Double, maxLat: Double, maxLng: Double)) async throws -> [Tile] {
        let query = [
            URLQueryItem(name: "minLat", value: "\(bounds.minLat)"),
            URLQueryItem(name: "minLng", value: "\(bounds.minLng)"),
            URLQueryItem(name: "maxLat", value: "\(bounds.maxLat)"),
            URLQueryItem(name: "maxLng", value: "\(bounds.maxLng)")
        ]
        return try await request("/api/tiles", query: query)
    }

    func getTile(id: String) async throws -> Tile {
        try await request("/api/tiles/\(id)")
    }

    func getTileStats() async throws -> TileStats {
        try await request("/api/tiles/stats")
    }

    func getDisputedTiles() async throws -> [Tile] {
        try await request("/api/tiles/disputed")
    }

    func submitRunGpx(fileURL: URL) async throws -> RunSubmissionResult {
        let data = try Data(contentsOf: fileURL)
        return try await multipartRequest(
            "/api/runs",
            fileData: data,
            fileName: fileURL.lastPathComponent,
            mimeType: "application/gpx+xml"
        )
    }

    func submitRunCoordinates(coordinates: [[String: Double]], timestamps: [Int]) async throws -> RunSubmissionResult {
        let payload = RunCoordinatesRequest(coordinates: coordinates, timestamps: timestamps)
        return try await self.request("/api/runs/coordinates", method: "POST", body: payload)
    }

    func getMyRuns(limit: Int = 20) async throws -> [Run] {
        try await request("/api/runs", query: [URLQueryItem(name: "limit", value: "\(limit)")])
    }

    func getDailyStatus() async throws -> DailyStatus {
        try await request("/api/runs/daily-status")
    }

    func getBandeiras() async throws -> [Bandeira] {
        try await request("/api/bandeiras")
    }

    func getBandeira(id: String) async throws -> Bandeira {
        try await request("/api/bandeiras/\(id)")
    }

    func getBandeiraMembers(id: String) async throws -> [BandeiraMember] {
        try await request("/api/bandeiras/\(id)/members")
    }

    func createBandeira(request: CreateBandeiraRequest) async throws -> Bandeira {
        try await self.request("/api/bandeiras", method: "POST", body: request)
    }

    func joinBandeira(id: String) async throws -> Bandeira {
        try await request("/api/bandeiras/\(id)/join", method: "POST")
    }

    func leaveBandeira() async throws {
        _ = try await request("/api/bandeiras/leave", method: "POST") as EmptyResponse
    }

    func getBandeiraRankings() async throws -> [Bandeira] {
        try await request("/api/bandeiras/rankings")
    }

    func searchBandeiras(query: String) async throws -> [Bandeira] {
        try await request("/api/bandeiras/search", query: [URLQueryItem(name: "q", value: query)])
    }

    // MARK: - Core request helpers

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem]? = nil,
        allowRefresh: Bool = true
    ) async throws -> T {
        try await request(
            path,
            method: method,
            query: query,
            body: Optional<EmptyBody>.none as EmptyBody?,
            allowRefresh: allowRefresh
        )
    }

    private func request<T: Decodable, Body: Encodable>(
        _ path: String,
        method: String = "GET",
        query: [URLQueryItem]? = nil,
        body: Body? = nil,
        allowRefresh: Bool = true
    ) async throws -> T {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if let query = query, !query.isEmpty {
            components.queryItems = query
        }

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await performRequest(
            url: url,
            method: method,
            body: body
        )

        if response.statusCode == 401, allowRefresh, let refreshHandler {
            if (try? await refreshHandler()) != nil {
                let (retryData, retryResponse) = try await performRequest(
                    url: url,
                    method: method,
                    body: body
                )
                return try decode(T.self, data: retryData, response: retryResponse)
            }
        }

        return try decode(T.self, data: data, response: response)
    }

    private func multipartRequest<T: Decodable>(
        _ path: String,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"
        let request = multipartURLRequest(
            path: path,
            boundary: boundary,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType
        )

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401, let refreshHandler {
            if (try? await refreshHandler()) != nil {
                let retryRequest = multipartURLRequest(
                    path: path,
                    boundary: boundary,
                    fileData: fileData,
                    fileName: fileName,
                    mimeType: mimeType
                )
                let (retryData, retryResponse) = try await session.data(for: retryRequest)
                return try decode(T.self, data: retryData, response: retryResponse)
            }
        }

        return try decode(T.self, data: data, response: response)
    }

    private func multipartURLRequest(
        path: String,
        boundary: String,
        fileData: Data,
        fileName: String,
        mimeType: String
    ) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        return request
    }

    private func performRequest<Body: Encodable>(
        url: URL,
        method: String,
        body: Body?
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30

        if let body = body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        return (data, httpResponse)
    }

    private func decode<T: Decodable>(_ type: T.Type, data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200..<300).contains(httpResponse.statusCode) {
            if data.isEmpty, let empty = EmptyResponse() as? T {
                return empty
            }
            return try decoder.decode(T.self, from: data)
        }

        if let apiError = try? decoder.decode(APIError.self, from: data) {
            throw apiError
        }

        throw URLError(.badServerResponse)
    }
}

/// Empty marker to allow decoding 204 responses.
struct EmptyResponse: Codable {}
