import Foundation

enum AppEnvironment {
    private static let defaultBaseURLString = "https://runwar-backend-484753220670.us-central1.run.app"

    static let apiBaseURL: URL = {
        let bundleValue = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String

        // Use bundle value when it is a valid, non-placeholder URL; otherwise fall back to default backend.
        if
            let raw = bundleValue,
            let url = URL(string: raw),
            let host = url.host,
            host != "api" && host != "localhost"
        {
            return url
        }

        return URL(string: defaultBaseURLString)!
    }()

    static let mapboxAccessToken: String = {
        Bundle.main.object(forInfoDictionaryKey: "MAPBOX_ACCESS_TOKEN") as? String ?? ""
    }()

    static let keychainService: String = {
        Bundle.main.bundleIdentifier ?? "com.runwar.ligarun"
    }()

    static let accessTokenKey = "runwar_access_token"
    static let refreshTokenKey = "runwar_refresh_token"

    static var googleClientID: String? {
        Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String
    }

    static var googleReversedClientID: String? {
        Bundle.main.object(forInfoDictionaryKey: "GOOGLE_REVERSED_CLIENT_ID") as? String
    }

    static var appleAssociatedDomain: String? {
        Bundle.main.object(forInfoDictionaryKey: "APPLE_ASSOCIATED_DOMAIN") as? String
    }

    static var appleServiceID: String? {
        Bundle.main.object(forInfoDictionaryKey: "APPLE_SERVICE_ID") as? String
    }

    static var appleTeamID: String? {
        Bundle.main.object(forInfoDictionaryKey: "APPLE_TEAM_ID") as? String
    }
}
