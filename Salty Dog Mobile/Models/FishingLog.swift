import Foundation
import CoreLocation

// MARK: - Fish Entry
/// Represents a single fish catch within a fishing log
struct FishEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var fishType: String
    var weight: Double? // kilograms
    var length: Double? // centimeters
    var notes: String?
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        fishType: String,
        weight: Double? = nil,
        length: Double? = nil,
        notes: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.fishType = fishType
        self.weight = weight
        self.length = length
        self.notes = notes
        self.timestamp = timestamp
    }
    
    // MARK: - Weight Conversion Helpers
    
    /// Weight in pounds
    var weightInPounds: Double? {
        guard let weight = weight else { return nil }
        return weight * 2.20462
    }
    
    /// Set weight from pounds
    mutating func setWeightFromPounds(_ pounds: Double) {
        self.weight = pounds / 2.20462
    }
    
    // MARK: - Length Conversion Helpers
    
    /// Length in inches
    var lengthInInches: Double? {
        guard let length = length else { return nil }
        return length / 2.54
    }
    
    /// Set length from inches
    mutating func setLengthFromInches(_ inches: Double) {
        self.length = inches * 2.54
    }
}

// MARK: - Weather Snapshot
/// Captures weather conditions at the moment of logging
struct WeatherSnapshot: Codable, Equatable {
    let temperature: Double // Celsius
    let feelsLike: Double // Celsius
    let windSpeed: Double // meters per second
    let windDirection: Double // degrees
    let windGust: Double? // meters per second
    let barometricPressure: Double // millibars
    let pressureTrend: String
    let humidity: Double // percentage
    let condition: String
    let uvIndex: Int
    let visibility: Double // meters
    
    init(from weatherData: WeatherData) {
        self.temperature = weatherData.temperature
        self.feelsLike = weatherData.feelsLike
        self.windSpeed = weatherData.windSpeed
        self.windDirection = weatherData.windDirection
        self.windGust = weatherData.windGust
        self.barometricPressure = weatherData.barometricPressure
        self.pressureTrend = weatherData.pressureTrend.rawValue
        self.humidity = weatherData.humidity
        self.condition = weatherData.condition
        self.uvIndex = weatherData.uvIndex
        self.visibility = weatherData.visibility
    }
    
    // Empty initializer for when weather is unavailable
    init() {
        self.temperature = 0
        self.feelsLike = 0
        self.windSpeed = 0
        self.windDirection = 0
        self.windGust = nil
        self.barometricPressure = 0
        self.pressureTrend = "Unknown"
        self.humidity = 0
        self.condition = "Unknown"
        self.uvIndex = 0
        self.visibility = 0
    }
}

// MARK: - Marine Snapshot
/// Captures marine conditions at the moment of logging
struct MarineSnapshot: Codable, Equatable {
    let waterTemperature: Double? // Celsius
    let tideStatus: String?
    let tideHeight: Double? // meters
    let nextHighTide: Date?
    let nextLowTide: Date?
    let waveHeight: Double? // meters
    let swellDirection: Double? // degrees
    
    init(from marineData: MarineData) {
        self.waterTemperature = marineData.waterTemperature
        self.tideStatus = marineData.tideStatus?.rawValue
        self.tideHeight = marineData.tideHeight
        self.nextHighTide = marineData.nextHighTide
        self.nextLowTide = marineData.nextLowTide
        self.waveHeight = marineData.waveHeight
        self.swellDirection = marineData.swellDirection
    }
    
    // Empty initializer for when marine data is unavailable
    init() {
        self.waterTemperature = nil
        self.tideStatus = nil
        self.tideHeight = nil
        self.nextHighTide = nil
        self.nextLowTide = nil
        self.waveHeight = nil
        self.swellDirection = nil
    }
    
    // MARK: - Water Temperature Conversion
    
    /// Water temperature in Fahrenheit
    var waterTemperatureInFahrenheit: Double? {
        guard let temp = waterTemperature else { return nil }
        return temp * 9/5 + 32
    }
}

// MARK: - Fishing Log
/// Represents a complete fishing log entry with location, catches, and environmental data
struct FishingLog: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    
    // Location
    let latitude: Double
    let longitude: Double
    var spotName: String?
    
    // Catches
    var fishEntries: [FishEntry]
    
    // Environmental data
    let weatherSnapshot: WeatherSnapshot
    let marineSnapshot: MarineSnapshot
    
    // User notes
    var notes: String?
    
    // Metadata
    var isFavorite: Bool
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        spotName: String? = nil,
        fishEntries: [FishEntry] = [],
        weatherSnapshot: WeatherSnapshot,
        marineSnapshot: MarineSnapshot,
        notes: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.spotName = spotName
        self.fishEntries = fishEntries
        self.weatherSnapshot = weatherSnapshot
        self.marineSnapshot = marineSnapshot
        self.notes = notes
        self.isFavorite = isFavorite
    }
    
    // MARK: - Computed Properties
    
    /// CLLocationCoordinate2D from stored lat/lon
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Total fish count
    var totalFishCount: Int {
        fishEntries.count
    }
    
    /// Total weight of all fish in kilograms
    var totalWeight: Double {
        fishEntries.compactMap(\.weight).reduce(0, +)
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Short date for list display
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: timestamp)
    }
    
    /// Time only
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

// MARK: - Common Fish Types
/// Predefined fish types for quick selection
enum CommonFishType: String, CaseIterable, Identifiable {
    // Saltwater
    case bass = "Striped Bass"
    case bluefish = "Bluefish"
    case flounder = "Flounder"
    case mackerel = "Mackerel"
    case tuna = "Tuna"
    case mahi = "Mahi-Mahi"
    case snapper = "Snapper"
    case grouper = "Grouper"
    case redfish = "Redfish"
    case tarpon = "Tarpon"
    case kingfish = "Kingfish"
    case wahoo = "Wahoo"
    case cobia = "Cobia"
    case permit = "Permit"
    case bonefish = "Bonefish"
    case sailfish = "Sailfish"
    case marlin = "Marlin"
    case shark = "Shark"
    case halibut = "Halibut"
    case seabass = "Sea Bass"
    
    // General
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .shark: return "🦈"
        case .tuna, .mahi, .wahoo, .sailfish, .marlin: return "🐟"
        default: return "🎣"
        }
    }
}

// MARK: - Weight Unit
enum WeightUnit: String, CaseIterable, Identifiable {
    case pounds = "lbs"
    case kilograms = "kg"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    func convert(fromKilograms kg: Double) -> Double {
        switch self {
        case .pounds: return kg * 2.20462
        case .kilograms: return kg
        }
    }
    
    func convertToKilograms(_ value: Double) -> Double {
        switch self {
        case .pounds: return value / 2.20462
        case .kilograms: return value
        }
    }
}

// MARK: - Length Unit
enum LengthUnit: String, CaseIterable, Identifiable {
    case inches = "in"
    case centimeters = "cm"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    func convert(fromCentimeters cm: Double) -> Double {
        switch self {
        case .inches: return cm / 2.54
        case .centimeters: return cm
        }
    }
    
    func convertToCentimeters(_ value: Double) -> Double {
        switch self {
        case .inches: return value * 2.54
        case .centimeters: return value
        }
    }
}
