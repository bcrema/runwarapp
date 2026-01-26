import Foundation
import CoreLocation
import Combine

enum RunState {
    case idle
    case running
    case paused
}

@MainActor
class RunManager: ObservableObject {
    @Published var state: RunState = .idle
    @Published var distanceBytes: Double = 0 // In meters
    @Published var duration: TimeInterval = 0
    @Published var currentPace: Double = 0 // Seconds per km
    @Published var loopProgress: Double = 0 // 0.0 to 1.0 based on 1.2km goal
    @Published var locations: [CLLocation] = []
    @Published var submissionResult: RunSubmissionResult?

    private let locationManager: LocationManager
    private let sessionStore: RunSessionStore
    private let uploadService: RunUploadService
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var startTime: Date?

    let loopGoal: Double = 1200 // 1.2km

    init(
        locationManager: LocationManager,
        sessionStore: RunSessionStore = RunSessionStore(),
        uploadService: RunUploadService
    ) {
        self.locationManager = locationManager
        self.sessionStore = sessionStore
        self.uploadService = uploadService

        locationManager.$location
            .sink { [weak self] location in
                self?.handleNewLocation(location)
            }
            .store(in: &cancellables)
    }

    func startRun() {
        state = .running
        distanceBytes = 0
        duration = 0
        locations = []
        startTime = Date()
        locationManager.startTracking()

        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.duration += 1
                self?.updatePace()
            }
    }

    func pauseRun() {
        state = .paused
        timer?.cancel()
        locationManager.stopTracking()
    }

    func resumeRun() {
        state = .running
        locationManager.startTracking()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.duration += 1
                self?.updatePace()
            }
    }

    func stopRun() {
        state = .idle
        timer?.cancel()
        locationManager.stopTracking()
        guard let startTime else { return }

        let endTime = Date()
        let points = locations.map { RunTrackPoint(location: $0) }
        let session = RunSessionRecord(
            id: UUID(),
            startedAt: startTime,
            endedAt: endTime,
            duration: duration,
            distanceMeters: distanceBytes,
            points: points,
            status: .pending,
            lastUploadAttempt: nil,
            lastError: nil
        )

        Task {
            _ = try? await sessionStore.append(session)
            do {
                let result = try await uploadService.upload(session)
                await MainActor.run {
                    self.submissionResult = result
                }
            } catch {
                // Keep session persisted for retry
            }
        }
    }

    private func handleNewLocation(_ location: CLLocation?) {
        guard state == .running, let location = location else { return }

        if let lastLocation = locations.last {
            let delta = location.distance(from: lastLocation)
            distanceBytes += delta
        }

        locations.append(location)
        updateLoopProgress()
    }

    private func updatePace() {
        if distanceBytes > 0 {
            currentPace = duration / (distanceBytes / 1000)
        }
    }

    private func updateLoopProgress() {
        loopProgress = min(distanceBytes / loopGoal, 1.0)
    }

    var formattedDistance: String {
        let km = distanceBytes / 1000
        return String(format: "%.2f km", km)
    }

    var formattedPace: String {
        if distanceBytes == 0 { return "-:--" }
        let minutes = Int(currentPace / 60)
        let seconds = Int(currentPace.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d /km", minutes, seconds)
    }
}
