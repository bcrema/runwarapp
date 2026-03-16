import Foundation

@MainActor
protocol SessionManaging: ObservableObject {
    func login(email: String, password: String) async throws
    func register(email: String, username: String, password: String) async throws
    func exchangeSocial(
        provider: SocialProvider,
        idToken: String,
        authorizationCode: String?,
        nonce: String?,
        emailHint: String?,
        givenName: String?,
        familyName: String?,
        avatarUrl: String?
    ) async throws
    func confirmSocialLink(linkToken: String, email: String, password: String) async throws
}
