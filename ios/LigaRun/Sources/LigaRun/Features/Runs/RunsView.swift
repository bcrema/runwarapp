import SwiftUI
import UniformTypeIdentifiers

struct RunsView: View {
    @StateObject private var viewModel: RunsViewModel
    @State private var showingImporter = false

    init(session: SessionStore) {
        _viewModel = StateObject(wrappedValue: RunsViewModel(session: session))
    }

    var body: some View {
        navigationContainer {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        List {
            if let status = viewModel.dailyStatus {
                Section("Ações diárias") {
                    HStack {
                        Text("Usuário")
                        Spacer()
                        Text("\(status.userActionsRemaining) restantes")
                            .bold()
                    }
                    if let bandeiraCap = status.bandeiraActionCap, let bandeiraUsed = status.bandeiraActionsUsed {
                        HStack {
                            Text("Bandeira")
                            Spacer()
                            Text("\(bandeiraCap - bandeiraUsed) restantes")
                                .bold()
                        }
                    }
                }
            }

            Section("Minhas corridas") {
                if viewModel.runs.isEmpty {
                    Text("Nenhuma corrida enviada ainda.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.runs) { run in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(run.distance, specifier: "%.2f") km")
                                    .font(.headline)
                                Spacer()
                                Text(run.isLoopValid ? "Válido" : "Inválido")
                                    .font(.caption)
                                    .foregroundColor(run.isLoopValid ? .green : .red)
                            }
                            if let action = run.territoryAction {
                                Text("Ação: \(action)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text("Início: \(run.startTime)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Corridas")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingImporter = true
                } label: {
                    Label("Enviar GPX", systemImage: "square.and.arrow.up")
                }
            }
        }
        .refreshable {
            await viewModel.load()
        }
        .task {
            await viewModel.load()
        }
        .alert("Erro", isPresented: Binding(get: {
            viewModel.errorMessage != nil
        }, set: { newValue in
            if !newValue { viewModel.errorMessage = nil }
        })) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(item: Binding(
            get: { viewModel.submissionResult },
            set: { _ in viewModel.submissionResult = nil })
        ) { result in
            if #available(iOS 16, *) {
                SubmissionResultView(result: result)
                    .presentationDetents([.medium])
            } else {
                SubmissionResultView(result: result)
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [UTType(filenameExtension: "gpx") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task { await viewModel.submitGPX(at: url) }
                }
            case .failure(let error):
                viewModel.errorMessage = error.localizedDescription
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

struct SubmissionResultView: View {
    let result: RunSubmissionResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Resultado da corrida")
                .font(.headline)

            Text(result.loopValidation.isValid ? "Loop válido" : "Loop inválido")
                .foregroundColor(result.loopValidation.isValid ? .green : .red)

            if let territory = result.territoryResult {
                Text("Território: \(territory.actionType ?? "-")")
                Text("Escudo: \(territory.shieldBefore) → \(territory.shieldAfter)")
            }

            if !result.loopValidation.failureReasons.isEmpty {
                Text("Motivos:")
                    .font(.subheadline.bold())
                ForEach(result.loopValidation.failureReasons, id: \.self) { reason in
                    Text("• \(reason)")
                        .font(.caption)
                }
            }

            Spacer()
        }
        .padding()
    }
}
