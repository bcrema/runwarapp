import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        TabView(selection: selectedTabBinding) {
            MapScreen(session: session)
                .tabItem {
                    Label("Mapa", systemImage: "map")
                }
                .tag(SessionStore.RootTab.map)

            RunsView(session: session)
                .tabItem {
                    Label("Corridas", systemImage: "figure.run")
                }
                .tag(SessionStore.RootTab.runs)

            BandeirasView(session: session)
                .tabItem {
                    Label("Bandeiras", systemImage: "flag")
                }
                .tag(SessionStore.RootTab.bandeiras)

            ProfileView(session: session)
                .tabItem {
                    Label("Perfil", systemImage: "person.circle")
                }
                .tag(SessionStore.RootTab.profile)
        }
        .task {
            if session.currentUser == nil {
                try? await session.refreshUser()
            }
        }
    }

    private var selectedTabBinding: Binding<SessionStore.RootTab> {
        Binding(
            get: { session.selectedTab },
            set: { session.selectedTab = $0 }
        )
    }
}
