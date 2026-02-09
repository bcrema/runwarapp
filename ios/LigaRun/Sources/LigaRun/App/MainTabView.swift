import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        TabView(selection: $session.selectedTabIndex) {
            MapScreen(session: session)
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }
                .tag(0)

            RunsView(session: session)
                .tabItem {
                    Label("Corridas", systemImage: "figure.run")
                }
                .tag(1)

            BandeirasView(session: session)
                .tabItem {
                    Label("Bandeiras", systemImage: "flag")
                }
                .tag(2)

            ProfileView(session: session)
                .tabItem {
                    Label("Perfil", systemImage: "person.circle")
                }
                .tag(3)
        }
        .task {
            if session.currentUser == nil {
                try? await session.refreshUser()
            }
        }
    }
}
