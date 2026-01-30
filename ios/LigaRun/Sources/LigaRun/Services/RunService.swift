import Foundation
import CoreLocation

protocol RunServiceProtocol {
    func submitRunGpx(fileURL: URL) async throws -> RunSubmissionResult
    func submitRunCoordinates(coordinates: [CLLocationCoordinate2D], timestamps: [Int]) async throws -> RunSubmissionResult
    func getMyRuns() async throws -> [Run]
    func getDailyStatus() async throws -> DailyStatus
}

class RunService: RunServiceProtocol {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func submitRunGpx(fileURL: URL) async throws -> RunSubmissionResult {
        return try await apiClient.submitRunGpx(fileURL: fileURL)
    }

    func submitRunCoordinates(coordinates: [CLLocationCoordinate2D], timestamps: [Int]) async throws -> RunSubmissionResult {
        let coordsArray = coordinates.map { ["lat": $0.latitude, "lng": $0.longitude] }
        return try await apiClient.submitRunCoordinates(coordinates: coordsArray, timestamps: timestamps)
    }
    
    func getMyRuns() async throws -> [Run] {
        return try await apiClient.getMyRuns()
    }
    
    func getDailyStatus() async throws -> DailyStatus {
        return try await apiClient.getDailyStatus()
    }
}
