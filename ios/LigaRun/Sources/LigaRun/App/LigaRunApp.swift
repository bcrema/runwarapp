import SwiftUI

@main
struct LigaRunApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .task {
                    await session.bootstrap()
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        if session.token == nil {
            AuthView(session: session)
        } else {
            MainTabView()
        }
    }
}
