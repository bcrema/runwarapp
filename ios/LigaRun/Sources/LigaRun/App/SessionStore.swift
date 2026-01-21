import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var token: String?
    @Published var currentUser: User?

    lazy var api: APIClient = {
        APIClient(
            baseURL: AppEnvironment.apiBaseURL,
            tokenProvider: { [weak self] in self?.token }
        )
    }()

    init() {
        let storedToken = UserDefaults.standard.string(forKey: AppEnvironment.tokenStorageKey)
        self.token = storedToken
    }

    func bootstrap() async {
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
        token = nil
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: AppEnvironment.tokenStorageKey)
    }

    private func setSession(from auth: AuthResponse) {
        token = auth.token
        currentUser = auth.user
        UserDefaults.standard.set(auth.token, forKey: AppEnvironment.tokenStorageKey)
    }
}
