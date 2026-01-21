import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var username: String = ""
    @Published var isRegistering: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    func submit() async {
        errorMessage = nil
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Preencha email e senha."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            if isRegistering {
                try await session.register(email: email, username: username, password: password)
            } else {
                try await session.login(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
