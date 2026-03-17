import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    struct SocialLinkChallenge: Identifiable {
        let id = UUID()
        let linkToken: String
        let provider: SocialProvider
        let emailMasked: String?
    }

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var username: String = ""
    @Published var isRegistering: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    @Published var socialLoading: Bool = false
    @Published var socialLinkChallenge: SocialLinkChallenge?
    @Published var linkEmail: String = ""
    @Published var linkPassword: String = ""
    @Published var linkError: String?

    private let session: any SessionManaging

    init(session: any SessionManaging) {
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

    func handleSocialToken(
        provider: SocialProvider,
        idToken: String,
        authorizationCode: String?,
        nonce: String?,
        emailHint: String?,
        givenName: String?,
        familyName: String?,
        avatarUrl: String?
    ) async {
        socialLoading = true
        errorMessage = nil
        linkError = nil
        do {
            try await session.exchangeSocial(
                provider: provider,
                idToken: idToken,
                authorizationCode: authorizationCode,
                nonce: nonce,
                emailHint: emailHint,
                givenName: givenName,
                familyName: familyName,
                avatarUrl: avatarUrl
            )
        } catch let linkError as SocialLinkRequiredError {
            socialLinkChallenge = SocialLinkChallenge(
                linkToken: linkError.linkToken,
                provider: linkError.provider,
                emailMasked: linkError.emailMasked
            )
            linkEmail = ""
            linkPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
        socialLoading = false
    }

    func confirmLink() async {
        guard let challenge = socialLinkChallenge else { return }
        guard !linkEmail.isEmpty, !linkPassword.isEmpty else {
            linkError = "Preencha email e senha para vincular."
            return
        }

        socialLoading = true
        linkError = nil
        do {
            try await session.confirmSocialLink(linkToken: challenge.linkToken, email: linkEmail, password: linkPassword)
            socialLinkChallenge = nil
            linkEmail = ""
            linkPassword = ""
        } catch {
            linkError = error.localizedDescription
        }
        socialLoading = false
    }
}
