import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: SessionStore
    @State private var username: String = ""
    @State private var isPublic: Bool = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        navigationContainer {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        Form {
            if let user = session.currentUser {
                Section("Conta") {
                    Text(user.email)
                    TextField("Nome de usuário", text: $username)
                    Toggle("Perfil público", isOn: $isPublic)
                }
            } else {
                ProgressView("Carregando perfil...")
            }

            Section {
                Button("Salvar alterações") {
                    Task { await save() }
                }
                .disabled(isSaving)

                Button("Sair", role: .destructive) {
                    session.logout()
                }
            }
        }
        .navigationTitle("Perfil")
        .task {
            if let user = session.currentUser {
                username = user.username
                isPublic = user.isPublic
            } else {
                try? await session.refreshUser()
                if let user = session.currentUser {
                    username = user.username
                    isPublic = user.isPublic
                }
            }
        }
        .alert("Erro", isPresented: Binding(get: {
            errorMessage != nil
        }, set: { newValue in
            if !newValue { errorMessage = nil }
        })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func navigationContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if #available(iOS 16, *) {
            NavigationStack { content() }
        } else {
            NavigationView { content() }
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    @MainActor
    private func save() async {
        guard !username.isEmpty else {
            errorMessage = "Nome de usuário não pode ser vazio."
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await session.updateProfile(request: UpdateProfileRequest(username: username, avatarUrl: nil, isPublic: isPublic))
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
