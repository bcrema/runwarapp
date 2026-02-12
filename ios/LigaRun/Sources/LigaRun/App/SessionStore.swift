import Foundation
import OSLog

@MainActor
final class SessionStore: ObservableObject {
    @Published var token: String?
    @Published private(set) var refreshToken: String?
    @Published var currentUser: User?
    @Published var selectedTabIndex: Int = 0
    @Published var mapFocusTileId: String?
    @Published var pendingSubmissionResult: RunSubmissionResult?

    private let keychain = KeychainStore(service: AppEnvironment.keychainService)
    private let logger = Logger(subsystem: AppEnvironment.keychainService, category: "SessionStore")

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
        self.token = readToken(account: AppEnvironment.accessTokenKey)
        self.refreshToken = readToken(account: AppEnvironment.refreshTokenKey)
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
        let refreshToken = self.refreshToken
        Task { [refreshToken] in
            try? await api.logout(refreshToken: refreshToken)
        }
        token = nil
        self.refreshToken = nil
        currentUser = nil
        deleteToken(account: AppEnvironment.accessTokenKey)
        deleteToken(account: AppEnvironment.refreshTokenKey)
    }

    private func setSession(from auth: AuthResponse) {
        token = auth.token
        currentUser = auth.user
        saveToken(auth.token, account: AppEnvironment.accessTokenKey)
        if let refreshToken = auth.refreshToken {
            self.refreshToken = refreshToken
            saveToken(refreshToken, account: AppEnvironment.refreshTokenKey)
        } else {
            self.refreshToken = nil
            deleteToken(account: AppEnvironment.refreshTokenKey)
        }
    }

    private func refreshSession() async throws -> String? {
        guard let refreshToken else {
            throw SessionError.missingRefreshToken
        }

        let response = try await api.refreshToken(refreshToken)
        token = response.token
        saveToken(response.token, account: AppEnvironment.accessTokenKey)

        if let newRefreshToken = response.refreshToken {
            self.refreshToken = newRefreshToken
            saveToken(newRefreshToken, account: AppEnvironment.refreshTokenKey)
        }

        return token
    }

    private func readToken(account: String) -> String? {
        do {
            return try keychain.read(account: account)
        } catch {
            logger.error("Failed to read keychain item for account '\(account)': \(error.localizedDescription)")
            return nil
        }
    }

    private func saveToken(_ token: String, account: String) {
        do {
            try keychain.save(token, account: account)
        } catch {
            logger.error("Failed to save keychain item for account '\(account)': \(error.localizedDescription)")
        }
    }

    private func deleteToken(account: String) {
        do {
            try keychain.delete(account: account)
        } catch {
            logger.error("Failed to delete keychain item for account '\(account)': \(error.localizedDescription)")
        }
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
