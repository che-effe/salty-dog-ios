import Foundation
import WeatherKit
import CoreLocation
import Combine

// MARK: - Weather Data Model
struct WeatherData: Equatable {
    let temperature: Double // Celsius
    let feelsLike: Double // Celsius
    let windSpeed: Double // meters per second
    let windDirection: Double // degrees (0-360)
    let windGust: Double? // meters per second
    let barometricPressure: Double // millibars (hPa)
    let pressureTrend: PressureTrend
    let humidity: Double // percentage (0-100)
    let condition: String
    let symbolName: String // SF Symbol name
    let uvIndex: Int
    let visibility: Double // meters
    let lastUpdated: Date
    
    enum PressureTrend: String, Equatable {
        case rising = "Rising"
        case falling = "Falling"
        case steady = "Steady"
        case unknown = "Unknown"
    }
    
    static let empty = WeatherData(
        temperature: 0,
        feelsLike: 0,
        windSpeed: 0,
        windDirection: 0,
        windGust: nil,
        barometricPressure: 0,
        pressureTrend: .unknown,
        humidity: 0,
        condition: "--",
        symbolName: "questionmark",
        uvIndex: 0,
        visibility: 0,
        lastUpdated: Date()
    )
}

// MARK: - Marine Data Model (for future API integration)
struct MarineData: Equatable {
    let waterTemperature: Double? // Celsius
    let tideStatus: TideStatus?
    let tideHeight: Double? // meters
    let nextHighTide: Date?
    let nextLowTide: Date?
    let waveHeight: Double? // meters
    let swellDirection: Double? // degrees
    let lastUpdated: Date
    
    enum TideStatus: String, Equatable {
        case rising = "Rising"
        case falling = "Falling"
        case high = "High"
        case low = "Low"
        case unknown = "Unknown"
    }
    
    static let empty = MarineData(
        waterTemperature: nil,
        tideStatus: nil,
        tideHeight: nil,
        nextHighTide: nil,
        nextLowTide: nil,
        waveHeight: nil,
        swellDirection: nil,
        lastUpdated: Date()
    )
}

// MARK: - Weather Error
enum WeatherError: Error, LocalizedError {
    case locationNotAvailable
    case weatherServiceUnavailable
    case fetchFailed(Error)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable:
            return "Location not available"
        case .weatherServiceUnavailable:
            return "Weather service unavailable"
        case .fetchFailed(let error):
            return "Failed to fetch weather: \(error.localizedDescription)"
        case .unauthorized:
            return "Weather service not authorized"
        }
    }
}

// MARK: - Weather Manager
@MainActor
class WeatherManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentWeather: WeatherData = .empty
    @Published var marineData: MarineData = .empty
    @Published var isLoading: Bool = false
    @Published var error: WeatherError?
    @Published var lastFetchLocation: CLLocation?
    
    // MARK: - Private Properties
    private let weatherService = WeatherService.shared
    private var fetchTask: Task<Void, Never>?
    private var autoRefreshTask: Task<Void, Never>?
    
    /// Minimum time between weather fetches (in seconds)
    private let minimumFetchInterval: TimeInterval = 300 // 5 minutes
    
    /// Minimum distance change to trigger a new fetch (in meters)
    private let minimumFetchDistance: CLLocationDistance = 1000 // 1 km
    
    // MARK: - Initialization
    init() {}
    
    deinit {
        fetchTask?.cancel()
        autoRefreshTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Fetch weather data for the given location
    /// - Parameter location: The CLLocation to fetch weather for
    func fetchWeather(for location: CLLocation) async {
        // Check if we should skip this fetch (too recent or too close)
        if shouldSkipFetch(for: location) {
            return
        }
        
        // Cancel any existing fetch
        fetchTask?.cancel()
        
        isLoading = true
        error = nil
        
        do {
            let weather = try await weatherService.weather(for: location)
            
            // Extract current weather data
            let current = weather.currentWeather
            
            // Map pressure trend
            let pressureTrend: WeatherData.PressureTrend
            switch current.pressureTrend {
            case .rising:
                pressureTrend = .rising
            case .falling:
                pressureTrend = .falling
            case .steady:
                pressureTrend = .steady
            @unknown default:
                pressureTrend = .unknown
            }
            
            currentWeather = WeatherData(
                temperature: current.temperature.value,
                feelsLike: current.apparentTemperature.value,
                windSpeed: current.wind.speed.converted(to: .metersPerSecond).value,
                windDirection: current.wind.direction.converted(to: .degrees).value,
                windGust: current.wind.gust?.converted(to: .metersPerSecond).value,
                barometricPressure: current.pressure.converted(to: .millibars).value,
                pressureTrend: pressureTrend,
                humidity: current.humidity * 100,
                condition: current.condition.description,
                symbolName: current.symbolName,
                uvIndex: current.uvIndex.value,
                visibility: current.visibility.converted(to: .meters).value,
                lastUpdated: Date()
            )
            
            lastFetchLocation = location
            isLoading = false
            
        } catch {
            self.error = .fetchFailed(error)
            isLoading = false
        }
    }
    
    /// Fetch weather using a coordinate
    /// - Parameters:
    ///   - latitude: The latitude
    ///   - longitude: The longitude
    func fetchWeather(latitude: Double, longitude: Double) async {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        await fetchWeather(for: location)
    }
    
    /// Start auto-refreshing weather data at specified interval
    /// - Parameters:
    ///   - location: A closure that returns the current location
    ///   - interval: Refresh interval in seconds (default 10 minutes)
    func startAutoRefresh(locationProvider: @escaping () -> CLLocation?, interval: TimeInterval = 600) {
        stopAutoRefresh()
        
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                if let location = locationProvider() {
                    await self?.fetchWeather(for: location)
                }
                try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }
    }
    
    /// Stop auto-refreshing weather data
    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }
    
    /// Force refresh weather data even if within minimum interval
    /// - Parameter location: The location to fetch weather for
    func forceRefresh(for location: CLLocation) async {
        lastFetchLocation = nil // Reset to force fetch
        await fetchWeather(for: location)
    }
    
    /// Fetch marine data (placeholder for future API integration)
    /// - Note: WeatherKit does not provide tide or water temperature data.
    ///         This method is a placeholder for integration with a marine data API
    ///         such as NOAA, Stormglass, or WorldTides.
    func fetchMarineData(for location: CLLocation) async {
        // TODO: Integrate with marine data API
        // Example APIs:
        // - NOAA Tides and Currents: https://tidesandcurrents.noaa.gov/api/
        // - Stormglass: https://stormglass.io/
        // - WorldTides: https://www.worldtides.info/
        
        // For now, return empty data
        marineData = .empty
    }
    
    // MARK: - Private Methods
    
    private func shouldSkipFetch(for location: CLLocation) -> Bool {
        guard let lastLocation = lastFetchLocation else {
            return false
        }
        
        let timeSinceLastFetch = Date().timeIntervalSince(currentWeather.lastUpdated)
        let distanceFromLastFetch = location.distance(from: lastLocation)
        
        // Skip if fetched recently AND haven't moved significantly
        return timeSinceLastFetch < minimumFetchInterval && 
               distanceFromLastFetch < minimumFetchDistance
    }
}

// MARK: - Temperature Unit Conversion Extension
extension WeatherManager {
    
    /// Convert temperature from Celsius to Fahrenheit
    static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return (celsius * 9/5) + 32
    }
    
    /// Convert temperature from Fahrenheit to Celsius
    static func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        return (fahrenheit - 32) * 5/9
    }
}



// MARK: - Pressure Formatting Extension
extension WeatherManager {
    
    /// Convert pressure from millibars to inches of mercury
    static func millibarsToInHg(_ mb: Double) -> Double {
        return mb * 0.02953
    }
    
    /// Get pressure description
    static func pressureDescription(millibars: Double) -> String {
        switch millibars {
        case ..<1009: return "Low"
        case 1009..<1023: return "Normal"
        default: return "High"
        }
    }
}

// MARK: - Temperature Unit Enum
enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius = "°C"
    case fahrenheit = "°F"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }
    
    func convert(fromCelsius celsius: Double) -> Double {
        switch self {
        case .celsius: return celsius
        case .fahrenheit: return WeatherManager.celsiusToFahrenheit(celsius)
        }
    }
    
    func format(_ celsius: Double, decimals: Int = 0) -> String {
        let value = convert(fromCelsius: celsius)
        return String(format: "%.\(decimals)f\(rawValue)", value)
    }
}

// MARK: - Pressure Unit Enum
enum PressureUnit: String, CaseIterable, Identifiable {
    case millibars = "mb"
    case inchesHg = "inHg"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .millibars: return "Millibars"
        case .inchesHg: return "Inches Hg"
        }
    }
    
    func convert(fromMillibars mb: Double) -> Double {
        switch self {
        case .millibars: return mb
        case .inchesHg: return WeatherManager.millibarsToInHg(mb)
        }
    }
    
    func format(_ millibars: Double, decimals: Int = 1) -> String {
        let value = convert(fromMillibars: millibars)
        let decimalPlaces = self == .inchesHg ? 2 : decimals
        return String(format: "%.\(decimalPlaces)f \(rawValue)", value)
    }
}
