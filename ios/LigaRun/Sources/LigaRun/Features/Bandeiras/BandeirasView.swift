import SwiftUI

struct BandeirasView: View {
    @StateObject private var viewModel: BandeirasViewModel
    @State private var isCreateSheetPresented = false

    init(session: SessionStore) {
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
                        .onSubmit { Task { await viewModel.search() } }
                    Button("Buscar") {
                        Task { await viewModel.search() }
                    }
                    .disabled(viewModel.isLoading || viewModel.isMutating)
                }
            }

            if let noticeMessage = viewModel.noticeMessage {
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(noticeMessage)
                            .font(.subheadline)
                        Spacer(minLength: 0)
                        Button {
                            viewModel.noticeMessage = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Fechar mensagem")
                    }
                    .padding(.vertical, 4)
                }
            }

            if viewModel.isLoading && viewModel.bandeiras.isEmpty {
                ProgressView("Carregando...")
            }

            if viewModel.shouldShowEmptyState {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.emptyStateTitle)
                            .font(.headline)
                        Text(viewModel.emptyStateMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if viewModel.hasActiveSearch {
                            Button("Limpar busca") {
                                Task { await viewModel.clearSearch() }
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button("Recarregar lista") {
                                Task { await viewModel.load() }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 8)
                }
            } else {
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
                        if let description = bandeira.description, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Tiles: \(bandeira.totalTiles)")
                                .font(.caption)
                            Spacer()
                            if viewModel.actionBandeiraId == bandeira.id {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            if viewModel.currentBandeiraId == bandeira.id {
                                Button("Sair") {
                                    Task { await viewModel.leave() }
                                }
                                .disabled(viewModel.isMutating || viewModel.isLoading)
                            } else {
                                Button("Entrar") {
                                    Task { await viewModel.join(bandeira: bandeira) }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(viewModel.isMutating || viewModel.isLoading)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Bandeiras")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Criar") {
                    isCreateSheetPresented = true
                }
                .disabled(viewModel.isLoading || viewModel.isMutating)
            }
        }
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .sheet(isPresented: $isCreateSheetPresented) {
            createBandeiraSheet
        }
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

    private var createBandeiraSheet: some View {
        navigationContainer {
            Form {
                Section("Nova bandeira") {
                    TextField("Nome", text: $viewModel.createName)
                    TextField("Categoria", text: $viewModel.createCategory)
                    TextField("Cor (#RRGGBB)", text: $viewModel.createColor)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                    TextField("Descricao", text: $viewModel.createDescription, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Button {
                        Task {
                            await viewModel.createBandeira()
                            if viewModel.errorMessage == nil {
                                isCreateSheetPresented = false
                            }
                        }
                    } label: {
                        if viewModel.isCreating {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Criar bandeira")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(viewModel.isCreating)
                }
            }
            .navigationTitle("Criar bandeira")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        isCreateSheetPresented = false
                    }
                }
            }
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
