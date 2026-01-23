import Foundation

@MainActor
final class RunsViewModel: ObservableObject {
    @Published var runs: [Run] = []
    @Published var dailyStatus: DailyStatus?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var submissionResult: RunSubmissionResult?

    private let session: SessionStore

    init(session: SessionStore) {
        self.session = session
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let runsTask = session.api.getMyRuns(limit: 20)
            async let statusTask = session.api.getDailyStatus()
            runs = try await runsTask
            dailyStatus = try await statusTask
        } catch let apiError as APIError {
            errorMessage = "API Error: \(apiError.message)"
        } catch {
            errorMessage = "System Error: \(error.localizedDescription)"
        }
    }

    func submitGPX(at url: URL) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            submissionResult = try await session.api.submitRunGpx(fileURL: url)
            runs.insert(submissionResult!.run, at: 0)
            dailyStatus = try? await session.api.getDailyStatus()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
