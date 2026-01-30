import Foundation
import CoreLocation
import Combine

@MainActor
final class CompanionRunManager: ObservableObject {
    @Published var state: RunState = .idle
    @Published var distanceMeters: Double = 0
    @Published var duration: TimeInterval = 0
    @Published var currentPace: Double = 0 // seconds per km
    @Published var loopProgress: Double = 0 // 0..1 for 1.2km goal
    @Published var locations: [CLLocation] = []
    @Published var currentLocation: CLLocation?

    private let locationManager: LocationManager
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var startTime: Date?

    let loopGoal: Double = 1200

    init(locationManager: LocationManager = LocationManager()) {
        self.locationManager = locationManager

        locationManager.$location
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.handleNewLocation(location)
            }
            .store(in: &cancellables)
    }

    func startIfNeeded() {
        guard state == .idle else { return }
        start()
    }

    func start() {
        state = .running
        distanceMeters = 0
        duration = 0
        currentPace = 0
        loopProgress = 0
        locations = []
        startTime = Date()
        locationManager.requestPermission()
        locationManager.startTracking()

        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.duration += 1
                self?.updatePace()
            }
    }

    func pause() {
        guard state == .running else { return }
        state = .paused
        timer?.cancel()
        locationManager.stopTracking()
    }

    func resume() {
        guard state == .paused else { return }
        state = .running
        locationManager.startTracking()
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.duration += 1
                self?.updatePace()
            }
    }

    func stop() {
        state = .idle
        timer?.cancel()
        locationManager.stopTracking()
        startTime = nil
    }

    private func handleNewLocation(_ location: CLLocation?) {
        guard state == .running, let location = location else { return }

        currentLocation = location
        if let lastLocation = locations.last {
            let delta = location.distance(from: lastLocation)
            distanceMeters += delta
        }

        locations.append(location)
        updateLoopProgress()
    }

    private func updatePace() {
        // Require at least 10 meters to calculate a meaningful pace
        guard distanceMeters >= 10 else {
            currentPace = 0
            return
        }
        currentPace = duration / (distanceMeters / 1000)
    }

    private func updateLoopProgress() {
        loopProgress = min(distanceMeters / loopGoal, 1.0)
    }

    var formattedDistance: String {
        let km = distanceMeters / 1000
        return String(format: "%.2f km", km)
    }

    var formattedPace: String {
        if distanceMeters == 0 { return "-:-- /km" }
        let minutes = Int(currentPace / 60)
        let seconds = Int(currentPace.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d /km", minutes, seconds)
    }

    var routeCoordinates: [CLLocationCoordinate2D] {
        locations.map { $0.coordinate }
    }
}
