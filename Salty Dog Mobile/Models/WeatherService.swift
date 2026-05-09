import Foundation
import WeatherKit
import CoreLocation

/// Wrapper around WeatherKit to handle weather data fetching
class WeatherService {
    static let shared = WeatherService()
    
    private let weatherService = WeatherKit.WeatherService()
    
    /// Fetch weather data for a given location
    /// - Parameter location: The CLLocation to fetch weather for
    /// - Returns: Weather object containing current and forecast data
    func weather(for location: CLLocation) async throws -> Weather {
        do {
            let weather = try await weatherService.weather(for: location)
            return weather
        } catch {
            throw WeatherError.fetchFailed(error)
        }
    }
}
