import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        TabView {
            MapScreen(session: session)
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }

            RunsView(session: session)
                .tabItem {
                    Label("Corridas", systemImage: "figure.run")
                }

            BandeirasView(session: session)
                .tabItem {
                    Label("Bandeiras", systemImage: "flag")
                }

            ProfileView()
                .tabItem {
                    Label("Perfil", systemImage: "person.circle")
                }
        }
        .task {
            if session.currentUser == nil {
                try? await session.refreshUser()
            }
        }
    }
}
