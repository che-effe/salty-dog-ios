import Foundation
import CoreLocation
import Combine

// MARK: - Track Point
struct TrackPoint: Identifiable, Codable, Equatable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let speed: Double // meters per second
    let heading: Double // degrees
    let timestamp: Date
    let altitude: Double
    let horizontalAccuracy: Double
    
    init(location: CLLocation) {
        self.id = UUID()
        self.coordinate = location.coordinate
        self.speed = max(0, location.speed)
        self.heading = location.course >= 0 ? location.course : 0
        self.timestamp = location.timestamp
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
    }
    
    // Codable conformance for CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case id, latitude, longitude, speed, heading, timestamp, altitude, horizontalAccuracy
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        speed = try container.decode(Double.self, forKey: .speed)
        heading = try container.decode(Double.self, forKey: .heading)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        altitude = try container.decode(Double.self, forKey: .altitude)
        horizontalAccuracy = try container.decode(Double.self, forKey: .horizontalAccuracy)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(speed, forKey: .speed)
        try container.encode(heading, forKey: .heading)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
    }
    
    // Manual Equatable conformance since CLLocationCoordinate2D doesn't conform to Equatable
    static func == (lhs: TrackPoint, rhs: TrackPoint) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.speed == rhs.speed &&
        lhs.heading == rhs.heading &&
        lhs.timestamp == rhs.timestamp &&
        lhs.altitude == rhs.altitude &&
        lhs.horizontalAccuracy == rhs.horizontalAccuracy
    }
}

// MARK: - Location Authorization Status
enum LocationAuthStatus {
    case notDetermined
    case denied
    case authorized
    case authorizedAlways
}

// MARK: - Location Manager
@MainActor
class LocationManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentSpeed: Double = 0 // meters per second
    @Published var currentHeading: Double = 0 // degrees
    @Published var topSpeed: Double = 0 // meters per second
    @Published var totalDistance: Double = 0 // meters
    @Published var trackPoints: [TrackPoint] = []
    @Published var authorizationStatus: LocationAuthStatus = .notDetermined
    @Published var isTracking: Bool = false
    @Published var sessionDuration: TimeInterval = 0
    @Published var averageSpeed: Double = 0 // meters per second
    @Published var currentCoordinate: CLLocationCoordinate2D?
    @Published var locationError: String?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var previousLocation: CLLocation?
    private var sessionStartTime: Date?
    private var speedSamples: [Double] = []
    private var sessionTimer: Timer?
    private var backgroundTrackingEnabled: Bool = false
    
    // Minimum accuracy threshold (meters)
    private let minimumAccuracy: CLLocationAccuracy = 20
    // Minimum speed threshold to filter out noise (m/s)
    private let minimumSpeedThreshold: Double = 0.3
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5 // Update every 5 meters moved
        locationManager.activityType = .otherNavigation
        locationManager.headingFilter = 1 // Update for every 1 degree change
        updateAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            // Already authorized for when in use - can request always if needed
            startTracking()
        case .authorizedAlways:
            startTracking()
        default:
            break
        }
    }
    
    func startTracking() {
        guard !isTracking else { return }
        
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        
        isTracking = true
        sessionStartTime = Date()
        startSessionTimer()
        locationError = nil
    }
    
    func stopTracking() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        
        isTracking = false
        stopSessionTimer()
    }
    
    func resetSession() {
        stopTracking()
        
        currentSpeed = 0
        currentHeading = 0
        topSpeed = 0
        totalDistance = 0
        trackPoints = []
        sessionDuration = 0
        averageSpeed = 0
        previousLocation = nil
        speedSamples = []
        sessionStartTime = nil
        
        startTracking()
    }
    
    func enableBackgroundTracking() {
        backgroundTrackingEnabled = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func disableBackgroundTracking() {
        backgroundTrackingEnabled = false
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    // MARK: - Export Functions
    
    func exportAsGPX() -> String {
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="SaltyDog iOS">
            <trk>
                <name>SaltyDog Session - \(ISO8601DateFormatter().string(from: Date()))</name>
                <trkseg>
        """
        
        for point in trackPoints {
            gpx += """
            
                        <trkpt lat="\(point.coordinate.latitude)" lon="\(point.coordinate.longitude)">
                            <ele>\(point.altitude)</ele>
                            <time>\(ISO8601DateFormatter().string(from: point.timestamp))</time>
                            <speed>\(point.speed)</speed>
                            <course>\(point.heading)</course>
                        </trkpt>
            """
        }
        
        gpx += """
        
                </trkseg>
            </trk>
        </gpx>
        """
        
        return gpx
    }
    
    func exportAsCSV() -> String {
        var csv = "Timestamp,Latitude,Longitude,Speed (m/s),Heading,Altitude,Accuracy\n"
        
        for point in trackPoints {
            csv += "\(ISO8601DateFormatter().string(from: point.timestamp)),"
            csv += "\(point.coordinate.latitude),\(point.coordinate.longitude),"
            csv += "\(point.speed),\(point.heading),"
            csv += "\(point.altitude),\(point.horizontalAccuracy)\n"
        }
        
        return csv
    }
    
    // MARK: - Private Methods
    
    private func updateAuthorizationStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .restricted, .denied:
            authorizationStatus = .denied
        case .authorizedWhenInUse:
            authorizationStatus = .authorized
        case .authorizedAlways:
            authorizationStatus = .authorizedAlways
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }
    
    private func processLocation(_ location: CLLocation) {
        // Filter out inaccurate readings
        guard location.horizontalAccuracy <= minimumAccuracy,
              location.horizontalAccuracy >= 0 else {
            return
        }
        
        // Update current coordinate
        currentCoordinate = location.coordinate
        
        // Update speed (filter out negative values)
        let speed = max(0, location.speed)
        if speed >= minimumSpeedThreshold {
            currentSpeed = speed
            speedSamples.append(speed)
            
            // Update top speed
            if speed > topSpeed {
                topSpeed = speed
            }
        } else {
            currentSpeed = 0
        }
        
        // Update average speed
        if !speedSamples.isEmpty {
            averageSpeed = speedSamples.reduce(0, +) / Double(speedSamples.count)
        }
        
        // Update heading from course (more accurate than magnetometer for movement)
        if location.course >= 0 {
            currentHeading = location.course
        }
        
        // Calculate distance traveled
        if let previous = previousLocation {
            let distance = location.distance(from: previous)
            // Only count if moving at reasonable speed (reduces GPS jitter)
            if speed >= minimumSpeedThreshold {
                totalDistance += distance
            }
        }
        
        // Store track point
        let trackPoint = TrackPoint(location: location)
        trackPoints.append(trackPoint)
        
        // Update previous location
        previousLocation = location
    }
    
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSessionDuration()
            }
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    private func updateSessionDuration() {
        guard let start = sessionStartTime else { return }
        sessionDuration = Date().timeIntervalSince(start)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            processLocation(location)
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            // Use magnetic heading as fallback when not moving
            if currentSpeed < minimumSpeedThreshold && newHeading.headingAccuracy >= 0 {
                currentHeading = newHeading.magneticHeading
            }
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            updateAuthorizationStatus()
            
            if authorizationStatus == .authorized || authorizationStatus == .authorizedAlways {
                startTracking()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = "Location access denied. Please enable in Settings."
                    authorizationStatus = .denied
                case .network:
                    locationError = "Network error. GPS should still work."
                default:
                    locationError = "Location error: \(clError.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Coordinate Array for MapKit
extension LocationManager {
    var trackCoordinates: [CLLocationCoordinate2D] {
        trackPoints.map { $0.coordinate }
    }
}
