import SwiftUI

struct BandeirasView: View {
    private let session: SessionStore
    @StateObject private var viewModel: BandeirasViewModel

    init(session: SessionStore) {
        self.session = session
        _viewModel = StateObject(wrappedValue: BandeirasViewModel(session: session))
    }

    var body: some View {
        navigationContainer {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        List {
            Section {
                HStack {
                    TextField("Buscar bandeiras", text: $viewModel.searchQuery)
                        .textFieldStyle(.roundedBorder)
                    Button("Buscar") {
                        Task { await viewModel.search() }
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView("Carregando...")
            }

            ForEach(viewModel.bandeiras) { bandeira in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(Color(hex: bandeira.color))
                            .frame(width: 16, height: 16)
                        Text(bandeira.name)
                            .font(.headline)
                        Spacer()
                        Text("\(bandeira.memberCount) membros")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if let description = bandeira.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Tiles: \(bandeira.totalTiles)")
                            .font(.caption)
                        Spacer()
                        if session.currentUser?.bandeiraId == bandeira.id {
                            Button("Sair") {
                                Task { await viewModel.leave() }
                            }
                        } else {
                            Button("Entrar") {
                                Task { await viewModel.join(bandeira: bandeira) }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bandeiras")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .alert("Erro", isPresented: Binding(get: {
            viewModel.errorMessage != nil
        }, set: { newValue in
            if !newValue { viewModel.errorMessage = nil }
        })) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
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
}
