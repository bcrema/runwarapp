import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var token: String?
    @Published private(set) var refreshToken: String?
    @Published var currentUser: User?

    private let keychain = KeychainStore(service: AppEnvironment.keychainService)

    lazy var api: APIClient = {
        APIClient(
            baseURL: AppEnvironment.apiBaseURL,
            tokenProvider: { [weak self] in self?.token },
            refreshHandler: { [weak self] in
                try await self?.refreshSession()
            }
        )
    }()

    init() {
        self.token = try? keychain.read(account: AppEnvironment.accessTokenKey)
        self.refreshToken = try? keychain.read(account: AppEnvironment.refreshTokenKey)
    }

    func bootstrap() async {
        if token == nil, refreshToken != nil {
            _ = try? await refreshSession()
        }

        guard token != nil else { return }
        try? await refreshUser()
    }

    func login(email: String, password: String) async throws {
        let auth = try await api.login(email: email, password: password)
        setSession(from: auth)
    }

    func register(email: String, username: String, password: String) async throws {
        let auth = try await api.register(email: email, username: username, password: password)
        setSession(from: auth)
    }

    func refreshUser() async throws {
        currentUser = try await api.getMe()
    }

    func updateProfile(request: UpdateProfileRequest) async throws {
        currentUser = try await api.updateProfile(request: request)
    }

    func logout() {
        let refreshToken = refreshToken
        Task {
            try? await api.logout(refreshToken: refreshToken)
        }
        token = nil
        refreshToken = nil
        currentUser = nil
        try? keychain.delete(account: AppEnvironment.accessTokenKey)
        try? keychain.delete(account: AppEnvironment.refreshTokenKey)
    }

    private func setSession(from auth: AuthResponse) {
        token = auth.token
        currentUser = auth.user
        try? keychain.save(auth.token, account: AppEnvironment.accessTokenKey)
        if let refreshToken = auth.refreshToken {
            self.refreshToken = refreshToken
            try? keychain.save(refreshToken, account: AppEnvironment.refreshTokenKey)
        } else {
            self.refreshToken = nil
            try? keychain.delete(account: AppEnvironment.refreshTokenKey)
        }
    }

    private func refreshSession() async throws -> String? {
        guard let refreshToken else {
            throw SessionError.missingRefreshToken
        }

        let response = try await api.refreshToken(refreshToken)
        token = response.token
        try? keychain.save(response.token, account: AppEnvironment.accessTokenKey)

        if let newRefreshToken = response.refreshToken {
            refreshToken = newRefreshToken
            try? keychain.save(newRefreshToken, account: AppEnvironment.refreshTokenKey)
        }

        return token
    }
}

enum SessionError: LocalizedError {
    case missingRefreshToken

    var errorDescription: String? {
        switch self {
        case .missingRefreshToken:
            return "Refresh token indisponível."
        }
    }
}
