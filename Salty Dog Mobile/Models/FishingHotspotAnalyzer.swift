import Foundation
import CoreLocation
import Combine

// MARK: - Fishing Hotspot Analyzer
/// Analyzes fishing logs and current conditions to identify promising fishing locations
/// Matches historical successful fishing conditions with real-time data to generate a heatmap
@MainActor
class FishingHotspotAnalyzer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var hotspots: [CLLocationCoordinate2D: Double] = [:] // coordinate: score (0-1)
    @Published var isAnalyzing: Bool = false
    @Published var analysis: HotspotAnalysis?
    
    // MARK: - Private Properties
    private let gridResolution: Double = 0.01 // ~1km grid at the equator
    
    // Weights for different condition factors (0-1)
    private let weights = ConditionWeights(
        temperature: 0.25,
        tide: 0.20,
        pressure: 0.20,
        wind: 0.15,
        humidity: 0.10,
        visibility: 0.10
    )
    
    // MARK: - Initialization
    init() {}
    
    // MARK: - Analysis Methods
    
    /// Analyze fishing logs and generate hotspots based on current conditions
    /// - Parameters:
    ///   - logs: Historical fishing logs
    ///   - currentWeather: Current weather data
    ///   - currentMarine: Current marine data
    ///   - center: Center location for analysis
    ///   - radius: Search radius in kilometers
    func analyzeForHotspots(
        logs: [FishingLog],
        currentWeather: WeatherData,
        currentMarine: MarineData,
        center: CLLocationCoordinate2D,
        radius: Double = 50
    ) {
        isAnalyzing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var resultHotspots: [CLLocationCoordinate2D: Double] = [:]
            var insights: [String] = []
            
            // Group logs by location grid
            let groupedLogs = self.groupLogsByLocation(logs, gridResolution: self.gridResolution)
            
            // For each grid cell with historical data
            for (gridCell, cellLogs) in groupedLogs {
                // Calculate average conditions from successful fishing in this cell
                let historicalConditions = self.analyzeHistoricalConditions(cellLogs)
                
                // Score current conditions against historical patterns
                let score = self.scoreCurrentConditions(
                    currentWeather: currentWeather,
                    currentMarine: currentMarine,
                    historicalConditions: historicalConditions
                )
                
                if score > 0.3 { // Only include meaningful scores
                    resultHotspots[gridCell] = score
                }
            }
            
            // Generate insights
            insights = self.generateInsights(
                currentWeather: currentWeather,
                currentMarine: currentMarine,
                hotspots: resultHotspots,
                logs: logs
            )
            
            DispatchQueue.main.async {
                self.hotspots = resultHotspots
                self.analysis = HotspotAnalysis(
                    timestamp: Date(),
                    topLocations: self.topLocations(from: resultHotspots, limit: 5),
                    insights: insights,
                    conditionSummary: self.summarizeConditions(currentWeather, currentMarine)
                )
                self.isAnalyzing = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Group fishing logs into grid cells
    private func groupLogsByLocation(
        _ logs: [FishingLog],
        gridResolution: Double
    ) -> [CLLocationCoordinate2D: [FishingLog]] {
        var grouped: [CLLocationCoordinate2D: [FishingLog]] = [:]
        
        for log in logs {
            let gridCell = CLLocationCoordinate2D(
                latitude: (log.latitude / gridResolution).rounded() * gridResolution,
                longitude: (log.longitude / gridResolution).rounded() * gridResolution
            )
            
            if grouped[gridCell] == nil {
                grouped[gridCell] = []
            }
            grouped[gridCell]?.append(log)
        }
        
        return grouped
    }
    
    /// Analyze historical conditions from logs in a location
    private func analyzeHistoricalConditions(_ logs: [FishingLog]) -> HistoricalConditions {
        let weatherSnapshots = logs.map { $0.weatherSnapshot }
        let marineSnapshots = logs.map { $0.marineSnapshot }
        let successMetrics = logs.map { (fishCount: $0.fishEntries.count, weight: $0.totalWeight) }
        
        return HistoricalConditions(
            avgTemperature: weatherSnapshots.compactMap { $0.temperature }.average,
            tempRange: (
                min: weatherSnapshots.compactMap { $0.temperature }.min() ?? 0,
                max: weatherSnapshots.compactMap { $0.temperature }.max() ?? 0
            ),
            avgPressure: weatherSnapshots.compactMap { $0.barometricPressure }.average,
            pressureRange: (
                min: weatherSnapshots.compactMap { $0.barometricPressure }.min() ?? 0,
                max: weatherSnapshots.compactMap { $0.barometricPressure }.max() ?? 0
            ),
            avgWindSpeed: weatherSnapshots.compactMap { $0.windSpeed }.average,
            preferredWindRange: (min: 0, max: 5),
            avgHumidity: weatherSnapshots.compactMap { $0.humidity }.average,
            avgVisibility: weatherSnapshots.compactMap { $0.visibility }.average,
            commonTideStatus: marineSnapshots.compactMap { $0.tideStatus }.mode() ?? "Unknown",
            avgWaterTemp: marineSnapshots.compactMap { $0.waterTemperature }.average,
            avgSuccessMetric: successMetrics.map { Double($0.fishCount) }.average
        )
    }
    
    /// Score current conditions against historical patterns
    private func scoreCurrentConditions(
        currentWeather: WeatherData,
        currentMarine: MarineData,
        historicalConditions: HistoricalConditions
    ) -> Double {
        var scores: [Double] = []
        
        // Temperature match
        let tempScore = scoreMatch(
            current: currentWeather.temperature,
            target: historicalConditions.avgTemperature,
            range: historicalConditions.tempRange,
            maxDeviation: 5
        )
        scores.append(tempScore * weights.temperature)
        
        // Pressure match
        let pressureScore = scoreMatch(
            current: currentWeather.barometricPressure,
            target: historicalConditions.avgPressure,
            range: historicalConditions.pressureRange,
            maxDeviation: 5
        )
        scores.append(pressureScore * weights.pressure)
        
        // Wind score (prefer lower winds)
        let windScore = scoreWindSpeed(currentWeather.windSpeed)
        scores.append(windScore * weights.wind)
        
        // Humidity score
        let humidityScore = 1.0 - (abs(currentWeather.humidity - 70) / 100)
        scores.append(max(0, humidityScore) * weights.humidity)
        
        // Visibility score
        let visibilityScore = min(1.0, currentWeather.visibility / 5000) // 5km = excellent
        scores.append(visibilityScore * weights.visibility)
        
        // Tide bonus
        var tideScore: Double = 0.1
        if let currentTide = currentMarine.tideStatus?.rawValue,
           currentTide == historicalConditions.commonTideStatus {
            tideScore = 1.0
        }
        scores.append(tideScore * weights.tide)
        
        let totalScore = scores.reduce(0, +)
        return min(1.0, max(0, totalScore))
    }
    
    /// Score how well a current value matches historical data
    private func scoreMatch(
        current: Double,
        target: Double,
        range: (min: Double, max: Double),
        maxDeviation: Double
    ) -> Double {
        let deviation = abs(current - target)
        
        // Perfect score if within range
        if current >= range.min && current <= range.max {
            return 1.0
        }
        
        // Penalize deviation from average
        return max(0, 1.0 - (deviation / maxDeviation))
    }
    
    /// Score wind conditions (lower is better for most fishing)
    private func scoreWindSpeed(_ windSpeed: Double) -> Double {
        // Ideal: 0-3 m/s (0-7 mph)
        if windSpeed <= 3 {
            return 1.0
        }
        // Acceptable: 3-7 m/s
        if windSpeed <= 7 {
            return 0.7
        }
        // Not ideal: 7-10 m/s
        if windSpeed <= 10 {
            return 0.3
        }
        // Poor: >10 m/s
        return 0
    }
    
    /// Get top scoring locations
    private func topLocations(
        from hotspots: [CLLocationCoordinate2D: Double],
        limit: Int
    ) -> [TopLocation] {
        return hotspots
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { TopLocation(coordinate: $0.key, score: $0.value) }
    }
    
    /// Generate actionable insights based on analysis
    private func generateInsights(
        currentWeather: WeatherData,
        currentMarine: MarineData,
        hotspots: [CLLocationCoordinate2D: Double],
        logs: [FishingLog]
    ) -> [String] {
        var insights: [String] = []
        
        // Check for ideal conditions
        if currentWeather.windSpeed < 3 {
            insights.append("🌬️ Wind conditions are ideal - minimal wind today")
        }
        
        if let temp = currentMarine.waterTemperature, temp > 15 && temp < 25 {
            insights.append("🌡️ Water temperature is in the sweet spot")
        }
        
        if currentWeather.barometricPressure > 1015 {
            insights.append("📊 Atmospheric pressure is rising - good fishing window")
        }
        
        if !hotspots.isEmpty {
            let topScore = hotspots.values.max() ?? 0
            if topScore > 0.8 {
                insights.append("📍 Excellent conditions match found at nearby locations")
            } else if topScore > 0.6 {
                insights.append("📍 Good condition matches at several locations")
            }
        }
        
        if currentMarine.tideStatus == .rising {
            insights.append("🌊 Tide is rising - often productive for feeding fish")
        }
        
        let totalLogs = logs.count
        if totalLogs > 0 {
            let avgFish = Double(logs.flatMap { $0.fishEntries }.count) / Double(totalLogs)
            insights.append("📈 Your historical average: \(String(format: "%.1f", avgFish)) fish per trip")
        }
        
        return insights
    }
    
    /// Create a summary of current conditions
    private func summarizeConditions(
        _ weather: WeatherData,
        _ marine: MarineData
    ) -> String {
        var summary = "\(Int(weather.temperature))°C, "
        summary += "\(String(format: "%.1f", weather.windSpeed)) m/s winds, "
        summary += "\(String(format: "%.0f", weather.barometricPressure)) mb"
        
        if let waterTemp = marine.waterTemperature {
            summary += ", \(Int(waterTemp))°C water"
        }
        
        return summary
    }
}

// MARK: - Data Structures

struct ConditionWeights {
    let temperature: Double
    let tide: Double
    let pressure: Double
    let wind: Double
    let humidity: Double
    let visibility: Double
}

struct HistoricalConditions {
    let avgTemperature: Double
    let tempRange: (min: Double, max: Double)
    let avgPressure: Double
    let pressureRange: (min: Double, max: Double)
    let avgWindSpeed: Double
    let preferredWindRange: (min: Double, max: Double)
    let avgHumidity: Double
    let avgVisibility: Double
    let commonTideStatus: String
    let avgWaterTemp: Double?
    let avgSuccessMetric: Double
}

struct HotspotAnalysis {
    let timestamp: Date
    let topLocations: [TopLocation]
    let insights: [String]
    let conditionSummary: String
}

struct TopLocation {
    let coordinate: CLLocationCoordinate2D
    let score: Double
}

// MARK: - Array Extensions

extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}

extension Array where Element == String {
    func mode() -> String? {
        let counts = Dictionary(grouping: self, by: { $0 }).mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}
