import XCTest
import Combine
@testable import LigaRun

@MainActor
final class AuthViewModelTests: XCTestCase {
    func testHandleSocialTokenLinkRequiredShowsChallenge() async {
        let mockSession = MockSession()
        mockSession.shouldThrowLink = true
        let viewModel = AuthViewModel(session: mockSession)

        await viewModel.handleSocialToken(
            provider: .apple,
            idToken: "id",
            authorizationCode: nil,
            nonce: "nonce",
            emailHint: "user@example.com",
            givenName: "First",
            familyName: "Last",
            avatarUrl: nil
        )

        XCTAssertNotNil(viewModel.socialLinkChallenge)
        XCTAssertEqual(viewModel.linkEmail, "")
        XCTAssertEqual(viewModel.socialLinkChallenge?.provider, .apple)
        XCTAssertTrue(mockSession.exchangeCount == 1)
    }

    func testConfirmLinkClearsChallenge() async {
        let mockSession = MockSession()
        let viewModel = AuthViewModel(session: mockSession)
        viewModel.socialLinkChallenge = AuthViewModel.SocialLinkChallenge(
            linkToken: "link",
            provider: .google,
            emailMasked: "user@example.com"
        )
        viewModel.linkEmail = "user@example.com"
        viewModel.linkPassword = "secret"

        await viewModel.confirmLink()

        XCTAssertNil(viewModel.socialLinkChallenge)
        XCTAssertTrue(mockSession.confirmCalled)
    }
}

private final class MockSession: SessionManaging {
    let objectWillChange = ObservableObjectPublisher()
    var shouldThrowLink = false
    var exchangeCount = 0
    var confirmCalled = false

    func login(email: String, password: String) async throws {}

    func register(email: String, username: String, password: String) async throws {}

    func exchangeSocial(
        provider: SocialProvider,
        idToken: String,
        authorizationCode: String?,
        nonce: String?,
        emailHint: String?,
        givenName: String?,
        familyName: String?,
        avatarUrl: String?
    ) async throws {
        exchangeCount += 1
        if shouldThrowLink {
            let response = SocialLinkRequiredResponse(linkToken: "link", provider: provider, emailMasked: emailHint)
            throw SocialLinkRequiredError(response: response)
        }
    }

    func confirmSocialLink(linkToken: String, email: String, password: String) async throws {
        confirmCalled = true
    }
}
