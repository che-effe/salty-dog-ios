import Foundation

// MARK: - Speed Unit Enum
enum SpeedUnit: String, CaseIterable, Identifiable {
    case knots = "speed: kts"
    case mph = "speed: mph"
    case kph = "speed: kph"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .knots: return "Knots"
        case .mph: return "MPH"
        case .kph: return "KPH"
        }
    }
    
    var distanceUnit: DistanceUnit {
        switch self {
        case .knots: return .nauticalMiles
        case .mph: return .miles
        case .kph: return .kilometers
        }
    }
    
    var distanceLabel: String {
        distanceUnit.abbreviation
    }
    
    // Convert from meters per second to this unit
    func convert(fromMetersPerSecond mps: Double) -> Double {
        switch self {
        case .knots: return mps * 1.94384
        case .mph: return mps * 2.23694
        case .kph: return mps * 3.6
        }
    }
    
    // Convert distance from meters to appropriate distance unit
    func convertDistance(fromMeters meters: Double) -> Double {
        distanceUnit.convert(fromMeters: meters)
    }
}

// MARK: - Distance Unit Enum
enum DistanceUnit: String, CaseIterable {
    case nauticalMiles = "nm"
    case miles = "mi"
    case kilometers = "km"
    
    var abbreviation: String { rawValue }
    
    var displayName: String {
        switch self {
        case .nauticalMiles: return "Nautical Miles"
        case .miles: return "Miles"
        case .kilometers: return "Kilometers"
        }
    }
    
    func convert(fromMeters meters: Double) -> Double {
        switch self {
        case .nauticalMiles: return meters / 1852
        case .miles: return meters / 1609.344
        case .kilometers: return meters / 1000
        }
    }
}

// MARK: - Heading Formatter
struct HeadingFormatter {
    static func format(_ degrees: Double) -> String {
        let normalized = ((degrees.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        return String(format: "%03.0f°", normalized)
    }
    
    static func cardinalDirection(for degrees: Double) -> String {
        let normalized = ((degrees.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((normalized + 11.25) / 22.5) % 16
        return directions[index]
    }
}

// MARK: - Speed Formatter
struct SpeedFormatter {
    static func format(_ speed: Double, unit: SpeedUnit, decimals: Int = 1) -> String {
        if speed < 0 {
            return "---"
        }
        return String(format: "%.\(decimals)f", speed)
    }
}

// MARK: - Distance Formatter
struct DistanceFormatter {
    static func format(_ distance: Double, decimals: Int = 2) -> String {
        if distance < 0 {
            return "---"
        }
        return String(format: "%.\(decimals)f", distance)
    }
}

// MARK: - Duration Formatter
struct DurationFormatter {
    static func format(_ seconds: TimeInterval) -> String {
        if seconds < 0 {
            return "--:--"
        }
        
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}

// MARK: - Time Formatter
struct TimeFormatter {
    static func currentTime(use24Hour: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm"
        return formatter.string(from: Date())
    }
    
    static func currentTimeWithSeconds(use24Hour: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = use24Hour ? "HH:mm:ss" : "h:mm:ss"
        return formatter.string(from: Date())
    }
}
