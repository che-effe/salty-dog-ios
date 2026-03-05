import Foundation
import CoreLocation
import Combine

// MARK: - Marine Data Service
/// Service for fetching marine data including water temperature and tide information
/// Integrates with NOAA CO-OPS API (free, US data) and supports StormGlass.io integration
@MainActor
class MarineDataService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentMarineData: MarineData = .empty
    @Published var isLoading: Bool = false
    @Published var error: MarineError?
    @Published var lastFetchLocation: CLLocation?
    
    // MARK: - Private Properties
    private let session: URLSession
    private var fetchTask: Task<Void, Never>?
    
    /// Minimum time between fetches (5 minutes)
    private let minimumFetchInterval: TimeInterval = 300
    
    /// Minimum distance change to trigger a new fetch (1 km)
    private let minimumFetchDistance: CLLocationDistance = 1000
    
    // API Configuration
    private let noaaBaseURL = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
    
    /// Optional StormGlass API key (set via environment or config)
    var stormGlassAPIKey: String?
    private let stormGlassBaseURL = "https://api.stormglass.io/v2"
    
    // MARK: - Initialization
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Fetch marine data for a location
    /// Attempts NOAA first, falls back to StormGlass if NOAA fails and API key is available
    func fetchMarineData(for location: CLLocation) async {
        // Check if we should skip this fetch
        if shouldSkipFetch(for: location) {
            return
        }
        
        fetchTask?.cancel()
        isLoading = true
        error = nil
        
        do {
            // Try to get data from available sources
            var waterTemp: Double?
            var tideData: TideInfo?
            
            // Attempt NOAA API for US locations
            async let noaaTide = fetchNOAATideData(for: location)
            async let noaaWaterTemp = fetchNOAAWaterTemperature(for: location)
            
            // Await NOAA results
            tideData = try? await noaaTide
            waterTemp = try? await noaaWaterTemp
            
            // If NOAA failed and StormGlass is available, try that
            if waterTemp == nil && stormGlassAPIKey != nil {
                waterTemp = try? await fetchStormGlassWaterTemp(for: location)
            }
            
            if tideData == nil && stormGlassAPIKey != nil {
                tideData = try? await fetchStormGlassTide(for: location)
            }
            
            // Build marine data from available information
            currentMarineData = MarineData(
                waterTemperature: waterTemp,
                tideStatus: tideData?.status,
                tideHeight: tideData?.height,
                nextHighTide: tideData?.nextHigh,
                nextLowTide: tideData?.nextLow,
                waveHeight: nil, // Could be added with additional API
                swellDirection: nil,
                lastUpdated: Date()
            )
            
            lastFetchLocation = location
            isLoading = false
            
        } catch {
            self.error = .fetchFailed(error)
            isLoading = false
        }
    }
    
    /// Fetch using coordinates
    func fetchMarineData(latitude: Double, longitude: Double) async {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        await fetchMarineData(for: location)
    }
    
    // MARK: - NOAA API Integration
    
    /// Find nearest NOAA station for a location
    private func findNearestNOAAStation(for location: CLLocation) async throws -> NOAAStation {
        // NOAA station list endpoint
        let metadataURL = "https://api.tidesandcurrents.noaa.gov/mdapi/prod/webapi/stations.json?type=waterlevels"
        
        guard let url = URL(string: metadataURL) else {
            throw MarineError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MarineError.invalidResponse
        }
        
        let stationResponse = try JSONDecoder().decode(NOAAStationResponse.self, from: data)
        
        // Find nearest station
        guard let nearestStation = stationResponse.stations.min(by: { station1, station2 in
            let loc1 = CLLocation(latitude: station1.lat, longitude: station1.lng)
            let loc2 = CLLocation(latitude: station2.lat, longitude: station2.lng)
            return location.distance(from: loc1) < location.distance(from: loc2)
        }) else {
            throw MarineError.noStationFound
        }
        
        return nearestStation
    }
    
    /// Fetch tide data from NOAA
    private func fetchNOAATideData(for location: CLLocation) async throws -> TideInfo {
        let station = try await findNearestNOAAStation(for: location)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let today = dateFormatter.string(from: Date())
        let tomorrow = dateFormatter.string(from: Date().addingTimeInterval(86400))
        
        // Fetch tide predictions
        var components = URLComponents(string: noaaBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "station", value: station.id),
            URLQueryItem(name: "begin_date", value: today),
            URLQueryItem(name: "end_date", value: tomorrow),
            URLQueryItem(name: "product", value: "predictions"),
            URLQueryItem(name: "datum", value: "MLLW"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "time_zone", value: "lst_ldt"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "interval", value: "hilo")
        ]
        
        guard let url = components.url else {
            throw MarineError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MarineError.invalidResponse
        }
        
        let tideResponse = try JSONDecoder().decode(NOAATidePredictionResponse.self, from: data)
        
        // Parse tide data
        let now = Date()
        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyy-MM-dd HH:mm"
        
        var nextHigh: Date?
        var nextLow: Date?
        var currentTideHeight: Double?
        var tideStatus: MarineData.TideStatus = .unknown
        
        // Find next high and low tides
        for prediction in tideResponse.predictions {
            guard let predictionDate = dateParser.date(from: prediction.t) else { continue }
            
            if predictionDate > now {
                if prediction.type == "H" && nextHigh == nil {
                    nextHigh = predictionDate
                } else if prediction.type == "L" && nextLow == nil {
                    nextLow = predictionDate
                }
            }
            
            // Get latest tide height and determine status
            if predictionDate <= now {
                currentTideHeight = Double(prediction.v)
                if prediction.type == "H" {
                    tideStatus = .falling
                } else {
                    tideStatus = .rising
                }
            }
            
            if nextHigh != nil && nextLow != nil {
                break
            }
        }
        
        return TideInfo(
            height: currentTideHeight,
            status: tideStatus,
            nextHigh: nextHigh,
            nextLow: nextLow
        )
    }
    
    /// Fetch water temperature from NOAA
    private func fetchNOAAWaterTemperature(for location: CLLocation) async throws -> Double {
        let station = try await findNearestNOAAStation(for: location)
        
        var components = URLComponents(string: noaaBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "station", value: station.id),
            URLQueryItem(name: "date", value: "latest"),
            URLQueryItem(name: "product", value: "water_temperature"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "time_zone", value: "lst_ldt"),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components.url else {
            throw MarineError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MarineError.invalidResponse
        }
        
        let waterTempResponse = try JSONDecoder().decode(NOAAWaterTempResponse.self, from: data)
        
        guard let latestReading = waterTempResponse.data.first,
              let temperature = Double(latestReading.v) else {
            throw MarineError.noDataAvailable
        }
        
        return temperature
    }
    
    // MARK: - StormGlass API Integration (Optional)
    
    /// Fetch water temperature from StormGlass
    private func fetchStormGlassWaterTemp(for location: CLLocation) async throws -> Double {
        guard let apiKey = stormGlassAPIKey else {
            throw MarineError.apiKeyMissing
        }
        
        var components = URLComponents(string: "\(stormGlassBaseURL)/weather/point")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "params", value: "waterTemperature")
        ]
        
        guard let url = components.url else {
            throw MarineError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MarineError.invalidResponse
        }
        
        let stormGlassResponse = try JSONDecoder().decode(StormGlassResponse.self, from: data)
        
        guard let firstHour = stormGlassResponse.hours.first,
              let waterTemp = firstHour.waterTemperature?.noaa ?? firstHour.waterTemperature?.sg else {
            throw MarineError.noDataAvailable
        }
        
        return waterTemp
    }
    
    /// Fetch tide data from StormGlass
    private func fetchStormGlassTide(for location: CLLocation) async throws -> TideInfo {
        guard let apiKey = stormGlassAPIKey else {
            throw MarineError.apiKeyMissing
        }
        
        var components = URLComponents(string: "\(stormGlassBaseURL)/tide/extremes/point")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(location.coordinate.longitude))
        ]
        
        guard let url = components.url else {
            throw MarineError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw MarineError.invalidResponse
        }
        
        let tideResponse = try JSONDecoder().decode(StormGlassTideResponse.self, from: data)
        
        let now = Date()
        var nextHigh: Date?
        var nextLow: Date?
        var tideStatus: MarineData.TideStatus = .unknown
        
        let isoFormatter = ISO8601DateFormatter()
        
        for extreme in tideResponse.data {
            guard let extremeDate = isoFormatter.date(from: extreme.time) else { continue }
            
            if extremeDate > now {
                if extreme.type == "high" && nextHigh == nil {
                    nextHigh = extremeDate
                    if tideStatus == .unknown {
                        tideStatus = .rising
                    }
                } else if extreme.type == "low" && nextLow == nil {
                    nextLow = extremeDate
                    if tideStatus == .unknown {
                        tideStatus = .falling
                    }
                }
            }
            
            if nextHigh != nil && nextLow != nil {
                break
            }
        }
        
        return TideInfo(
            height: nil,
            status: tideStatus,
            nextHigh: nextHigh,
            nextLow: nextLow
        )
    }
    
    // MARK: - Helper Methods
    
    private func shouldSkipFetch(for location: CLLocation) -> Bool {
        guard let lastLocation = lastFetchLocation else { return false }
        
        let timeSinceLastFetch = Date().timeIntervalSince(currentMarineData.lastUpdated)
        let distanceFromLast = location.distance(from: lastLocation)
        
        return timeSinceLastFetch < minimumFetchInterval && distanceFromLast < minimumFetchDistance
    }
}

// MARK: - Tide Info
struct TideInfo {
    let height: Double?
    let status: MarineData.TideStatus
    let nextHigh: Date?
    let nextLow: Date?
}

// MARK: - Marine Error
enum MarineError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noStationFound
    case noDataAvailable
    case apiKeyMissing
    case fetchFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noStationFound:
            return "No nearby station found"
        case .noDataAvailable:
            return "No data available for this location"
        case .apiKeyMissing:
            return "API key not configured"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        }
    }
}

// MARK: - NOAA API Response Models

struct NOAAStationResponse: Codable {
    let stations: [NOAAStation]
}

struct NOAAStation: Codable {
    let id: String
    let name: String
    let lat: Double
    let lng: Double
}

struct NOAATidePredictionResponse: Codable {
    let predictions: [NOAATidePrediction]
}

struct NOAATidePrediction: Codable {
    let t: String // time
    let v: String // value (height)
    let type: String // H or L
}

struct NOAAWaterTempResponse: Codable {
    let data: [NOAAWaterTempData]
}

struct NOAAWaterTempData: Codable {
    let t: String // time
    let v: String // value
}

// MARK: - StormGlass API Response Models

struct StormGlassResponse: Codable {
    let hours: [StormGlassHour]
}

struct StormGlassHour: Codable {
    let time: String
    let waterTemperature: StormGlassSource?
}

struct StormGlassSource: Codable {
    let noaa: Double?
    let sg: Double?
}

struct StormGlassTideResponse: Codable {
    let data: [StormGlassTideExtreme]
}

struct StormGlassTideExtreme: Codable {
    let time: String
    let type: String
    let height: Double
}
