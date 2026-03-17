import SwiftUI

struct BandeirasView: View {
    @ObservedObject private var session: SessionStore
    @StateObject private var viewModel: BandeirasViewModel
    @State private var isCreateSheetPresented = false

    init(session: SessionStore) {
        self.session = session
        _viewModel = StateObject(wrappedValue: BandeirasViewModel(session: session))
    }

    var body: some View {
        navigationContainer {
            List {
                hubPickerSection
                hubContent
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Bandeiras")
            .toolbar {
                if session.activeBandeirasHubTab == .explore {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Criar") {
                            isCreateSheetPresented = true
                        }
                        .disabled(viewModel.isExploreLoading || viewModel.isMutating)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh(tab: session.activeBandeirasHubTab)
        }
        .task {
            await viewModel.activate(tab: session.activeBandeirasHubTab)
        }
        .onChange(of: session.activeBandeirasHubTab) { newValue in
            Task {
                await viewModel.activate(tab: newValue)
            }
        }
        .onChange(of: viewModel.pendingMapIntent) { newValue in
            guard let intent = newValue else { return }
            session.activeMapOwnershipFilter = intent.filter
            session.mapFocusContext = intent.focusContext
            session.selectedTabIndex = 0
            viewModel.consumePendingMapIntent()
        }
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

    private var hubPickerSection: some View {
        Section {
            Picker("Superficie", selection: $session.activeBandeirasHubTab) {
                Text("Explorar").tag(BandeirasHubTab.explore)
                Text("Ranking").tag(BandeirasHubTab.ranking)
                Text("Minha equipe").tag(BandeirasHubTab.myTeam)
            }
            .pickerStyle(.segmented)
        } footer: {
            Text(hubFooterMessage)
        }
    }

    @ViewBuilder
    private var hubContent: some View {
        switch session.activeBandeirasHubTab {
        case .explore:
            exploreContent
        case .ranking:
            rankingContent
        case .myTeam:
            myTeamPlaceholderContent
        }
    }

    private var exploreContent: some View {
        Group {
            Section("Explorar bandeiras") {
                HStack {
                    TextField("Buscar bandeiras", text: $viewModel.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { Task { await viewModel.search() } }

                    Button("Buscar") {
                        Task { await viewModel.search() }
                    }
                    .disabled(viewModel.isExploreLoading || viewModel.isMutating)
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

            if let errorMessage = viewModel.exploreErrorMessage {
                surfaceMessageSection(
                    title: "Nao foi possivel carregar o explorar",
                    message: errorMessage,
                    symbol: "exclamationmark.triangle.fill",
                    tint: .orange,
                    actionTitle: viewModel.hasActiveSearch ? "Tentar busca novamente" : "Recarregar lista"
                ) {
                    if viewModel.hasActiveSearch {
                        await viewModel.search()
                    } else {
                        await viewModel.load()
                    }
                }
            }

            if viewModel.isExploreLoading && viewModel.bandeiras.isEmpty {
                Section {
                    ProgressView("Carregando bandeiras...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                }
            }

            if viewModel.shouldShowExploreEmptyState {
                surfaceMessageSection(
                    title: viewModel.exploreEmptyStateTitle,
                    message: viewModel.exploreEmptyStateMessage,
                    symbol: "flag.slash.fill",
                    tint: .secondary,
                    actionTitle: viewModel.hasActiveSearch ? "Limpar busca" : "Recarregar lista"
                ) {
                    if viewModel.hasActiveSearch {
                        await viewModel.clearSearch()
                    } else {
                        await viewModel.load()
                    }
                }
            } else if !viewModel.bandeiras.isEmpty {
                Section("Comunidade") {
                    ForEach(viewModel.bandeiras) { bandeira in
                        bandeiraExploreRow(for: bandeira)
                    }
                }
            }
        }
    }

    private var rankingContent: some View {
        Group {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ranking territorial")
                        .font(.headline)
                    Text("Acompanhe quem mais expandiu territorio e abra o mapa ja focado na bandeira selecionada.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            if let errorMessage = viewModel.rankingErrorMessage {
                surfaceMessageSection(
                    title: "Nao foi possivel carregar o ranking",
                    message: errorMessage,
                    symbol: "chart.bar.xaxis",
                    tint: .orange,
                    actionTitle: "Tentar novamente"
                ) {
                    await viewModel.loadRanking()
                }
            }

            if viewModel.isRankingLoading && viewModel.rankingBandeiras.isEmpty {
                Section {
                    ProgressView("Carregando ranking...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                }
            }

            if viewModel.shouldShowRankingEmptyState {
                surfaceMessageSection(
                    title: viewModel.rankingEmptyStateTitle,
                    message: viewModel.rankingEmptyStateMessage,
                    symbol: "list.number",
                    tint: .secondary,
                    actionTitle: "Atualizar ranking"
                ) {
                    await viewModel.loadRanking()
                }
            } else if !viewModel.rankingBandeiras.isEmpty {
                Section("Top bandeiras") {
                    ForEach(Array(viewModel.rankingBandeiras.enumerated()), id: \.element.id) { index, bandeira in
                        rankingRow(for: bandeira, position: index + 1)
                    }
                }
            }
        }
    }

    private var myTeamPlaceholderContent: some View {
        Section("Minha equipe") {
            VStack(alignment: .leading, spacing: 12) {
                Label("Superficie reservada para o passo 05", systemImage: "person.3.fill")
                    .font(.headline)

                Text(myTeamPlaceholderMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(viewModel.currentBandeiraId == nil ? "Ir para Explorar" : "Ver ranking atual") {
                    session.activeBandeirasHubTab = viewModel.currentBandeiraId == nil ? .explore : .ranking
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 8)
        }
    }

    private func bandeiraExploreRow(for bandeira: Bandeira) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Circle()
                    .fill(Color(hex: bandeira.color))
                    .frame(width: 16, height: 16)
                    .padding(.top, 3)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(bandeira.name)
                            .font(.headline)
                        if bandeira.id == viewModel.currentBandeiraId {
                            tag("Sua bandeira", tint: .green)
                        }
                    }

                    if let description = bandeira.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 12) {
                        Label("\(bandeira.memberCount) membros", systemImage: "person.2.fill")
                        Label("\(bandeira.totalTiles) tiles", systemImage: "map.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack {
                Spacer()
                if viewModel.actionBandeiraId == bandeira.id {
                    ProgressView()
                        .controlSize(.small)
                }
                if viewModel.currentBandeiraId == bandeira.id {
                    Button("Sair") {
                        Task { await viewModel.leave() }
                    }
                    .disabled(viewModel.isMutating || viewModel.isExploreLoading)
                } else {
                    Button("Entrar") {
                        Task { await viewModel.join(bandeira: bandeira) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isMutating || viewModel.isExploreLoading)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func rankingRow(for bandeira: Bandeira, position: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: bandeira.color))
                    Text("\(position)")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(bandeira.name)
                            .font(.headline)
                        if bandeira.id == viewModel.currentBandeiraId {
                            tag("Sua bandeira", tint: .green)
                        }
                    }

                    HStack(spacing: 12) {
                        Label("\(bandeira.memberCount)", systemImage: "person.2.fill")
                        Label("\(bandeira.totalTiles)", systemImage: "map.fill")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Text(position == 1 ? "Lideranca atual do territorio." : "Posicao \(position) no hub territorial.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Button("Ver territorio") {
                viewModel.requestMapFocus(for: bandeira)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 6)
    }

    private func surfaceMessageSection(
        title: String,
        message: String,
        symbol: String,
        tint: Color,
        actionTitle: String,
        action: @escaping @MainActor () async -> Void
    ) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: symbol)
                    .font(.headline)
                    .foregroundColor(tint)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button(actionTitle) {
                    Task {
                        await action()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.vertical, 8)
        }
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
            .foregroundColor(tint)
    }

    private var hubFooterMessage: String {
        switch session.activeBandeirasHubTab {
        case .explore:
            return "Crie, encontre ou entre em uma bandeira sem perder o fluxo atual."
        case .ranking:
            return "Use o ranking para abrir o mapa com o foco territorial correto."
        case .myTeam:
            return "Gancho reservado para membros e roles na proxima etapa."
        }
    }

    private var myTeamPlaceholderMessage: String {
        if viewModel.currentBandeiraId == nil {
            return "Entre em uma bandeira em Explorar para habilitar o roster e os controles de equipe no passo 05."
        }
        return "Sua equipe sera carregada aqui no passo 05, incluindo membros e roles, sem alterar o hub atual."
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
