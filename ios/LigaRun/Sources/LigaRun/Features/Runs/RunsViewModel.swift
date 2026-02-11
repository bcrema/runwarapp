import Foundation

@MainActor
final class RunsViewModel: ObservableObject {
    @Published var runs: [Run] = []
    @Published var dailyStatus: DailyStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var submissionResult: RunSubmissionResult?

    private let runService: RunServiceProtocol
    private let uploadService: RunUploadServiceProtocol

    init(
        session: SessionStore,
        runService: RunServiceProtocol? = nil,
        runSessionStore: RunSessionStore = RunSessionStore(),
        uploadService: RunUploadServiceProtocol? = nil
    ) {
        self.runService = runService ?? RunService(apiClient: session.api)
        self.uploadService = uploadService ?? RunUploadService(api: session.api, store: runSessionStore)
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        async let runsTask = runService.getMyRuns()
        async let dailyStatusTask = runService.getDailyStatus()
        var runsError: Error?

        do {
            runs = try await runsTask
        } catch {
            runsError = error
        }

        do {
            dailyStatus = try await dailyStatusTask
        } catch {
            dailyStatus = nil
        }

        let uploadResults = await uploadService.uploadPendingSessions()
        if uploadResults.count == 1 {
            submissionResult = uploadResults[0]
        } else {
            submissionResult = nil
        }

        if let runsError {
            if let apiError = runsError as? APIError {
                errorMessage = "API Error: \(apiError.message)"
            } else {
                errorMessage = "System Error: \(runsError.localizedDescription)"
            }
        }
    }

    func submitGPX(at url: URL) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await runService.submitRunGpx(fileURL: url)
            submissionResult = result
            runs.insert(result.run, at: 0)
            dailyStatus = try? await runService.getDailyStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
