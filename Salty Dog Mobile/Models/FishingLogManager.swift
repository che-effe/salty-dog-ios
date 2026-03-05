import Foundation
import CoreLocation
import Combine
import SwiftUI

// MARK: - Fishing Log Manager
/// Manages persistence and CRUD operations for fishing logs
@MainActor
class FishingLogManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var logs: [FishingLog] = []
    @Published var isLoading: Bool = false
    @Published var error: FishingLogError?
    
    // MARK: - Private Properties
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    /// Storage file URL
    private var storageURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent("fishing_logs.json")
    }
    
    // MARK: - Initialization
    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        loadLogs()
    }
    
    // MARK: - CRUD Operations
    
    /// Add a new fishing log
    func addLog(_ log: FishingLog) {
        logs.insert(log, at: 0) // Add to beginning (newest first)
        saveLogs()
    }
    
    /// Create a new log with current location and environmental data
    func createLog(
        latitude: Double,
        longitude: Double,
        spotName: String? = nil,
        fishEntries: [FishEntry] = [],
        weatherData: WeatherData,
        marineData: MarineData,
        notes: String? = nil
    ) -> FishingLog {
        let log = FishingLog(
            latitude: latitude,
            longitude: longitude,
            spotName: spotName,
            fishEntries: fishEntries,
            weatherSnapshot: WeatherSnapshot(from: weatherData),
            marineSnapshot: MarineSnapshot(from: marineData),
            notes: notes
        )
        addLog(log)
        return log
    }
    
    /// Update an existing log
    func updateLog(_ log: FishingLog) {
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            logs[index] = log
            saveLogs()
        }
    }
    
    /// Delete a log
    func deleteLog(_ log: FishingLog) {
        logs.removeAll { $0.id == log.id }
        saveLogs()
    }
    
    /// Delete logs at offsets (for SwiftUI List)
    func deleteLogs(at offsets: IndexSet) {
        logs.remove(atOffsets: offsets)
        saveLogs()
    }
    
    /// Toggle favorite status
    func toggleFavorite(_ log: FishingLog) {
        if let index = logs.firstIndex(where: { $0.id == log.id }) {
            var updatedLog = logs[index]
            updatedLog.isFavorite.toggle()
            logs[index] = updatedLog
            saveLogs()
        }
    }
    
    /// Add a fish entry to an existing log
    func addFishEntry(to logId: UUID, entry: FishEntry) {
        if let index = logs.firstIndex(where: { $0.id == logId }) {
            var updatedLog = logs[index]
            updatedLog.fishEntries.append(entry)
            logs[index] = updatedLog
            saveLogs()
        }
    }
    
    /// Remove a fish entry from a log
    func removeFishEntry(from logId: UUID, entryId: UUID) {
        if let index = logs.firstIndex(where: { $0.id == logId }) {
            var updatedLog = logs[index]
            updatedLog.fishEntries.removeAll { $0.id == entryId }
            logs[index] = updatedLog
            saveLogs()
        }
    }
    
    // MARK: - Query Operations
    
    /// Get logs filtered by date range
    func logs(from startDate: Date, to endDate: Date) -> [FishingLog] {
        logs.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    /// Get logs for a specific fish type
    func logs(forFishType fishType: String) -> [FishingLog] {
        logs.filter { log in
            log.fishEntries.contains { $0.fishType.lowercased() == fishType.lowercased() }
        }
    }
    
    /// Get favorite logs
    var favoriteLogs: [FishingLog] {
        logs.filter(\.isFavorite)
    }
    
    /// Get logs near a location (within radius in meters)
    func logs(near coordinate: CLLocationCoordinate2D, radius: Double = 1000) -> [FishingLog] {
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return logs.filter { log in
            let logLocation = CLLocation(latitude: log.latitude, longitude: log.longitude)
            return logLocation.distance(from: targetLocation) <= radius
        }
    }
    
    /// Get statistics for all logs
    var statistics: FishingStatistics {
        FishingStatistics(logs: logs)
    }
    
    // MARK: - Persistence
    
    /// Load logs from disk
    func loadLogs() {
        isLoading = true
        error = nil
        
        guard fileManager.fileExists(atPath: storageURL.path) else {
            logs = []
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: storageURL)
            logs = try decoder.decode([FishingLog].self, from: data)
            isLoading = false
        } catch {
            self.error = .loadFailed(error)
            logs = []
            isLoading = false
        }
    }
    
    /// Save logs to disk
    func saveLogs() {
        do {
            let data = try encoder.encode(logs)
            try data.write(to: storageURL, options: .atomic)
            error = nil
        } catch {
            self.error = .saveFailed(error)
        }
    }
    
    /// Export logs as JSON
    func exportAsJSON() throws -> Data {
        return try encoder.encode(logs)
    }
    
    /// Import logs from JSON data
    func importFromJSON(_ data: Data) throws {
        let importedLogs = try decoder.decode([FishingLog].self, from: data)
        // Merge with existing logs, avoiding duplicates
        for log in importedLogs {
            if !logs.contains(where: { $0.id == log.id }) {
                logs.append(log)
            }
        }
        // Sort by timestamp, newest first
        logs.sort { $0.timestamp > $1.timestamp }
        saveLogs()
    }
    
    /// Clear all logs
    func clearAllLogs() {
        logs = []
        saveLogs()
    }
}

// MARK: - Fishing Log Error
enum FishingLogError: Error, LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case exportFailed(Error)
    case importFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "Failed to load fishing logs: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save fishing logs: \(error.localizedDescription)"
        case .exportFailed(let error):
            return "Failed to export fishing logs: \(error.localizedDescription)"
        case .importFailed(let error):
            return "Failed to import fishing logs: \(error.localizedDescription)"
        }
    }
}

// MARK: - Fishing Statistics
struct FishingStatistics {
    let totalLogs: Int
    let totalFish: Int
    let totalWeight: Double // kilograms
    let uniqueFishTypes: Set<String>
    let mostCaughtFish: String?
    let biggestFishWeight: Double?
    let longestFish: Double?
    let averageFishPerTrip: Double
    
    init(logs: [FishingLog]) {
        self.totalLogs = logs.count
        
        let allFish = logs.flatMap(\.fishEntries)
        self.totalFish = allFish.count
        self.totalWeight = allFish.compactMap(\.weight).reduce(0, +)
        self.uniqueFishTypes = Set(allFish.map(\.fishType))
        
        // Most caught fish type
        let fishTypeCounts = Dictionary(grouping: allFish, by: \.fishType)
            .mapValues(\.count)
        self.mostCaughtFish = fishTypeCounts.max(by: { $0.value < $1.value })?.key
        
        // Biggest fish by weight
        self.biggestFishWeight = allFish.compactMap(\.weight).max()
        
        // Longest fish
        self.longestFish = allFish.compactMap(\.length).max()
        
        // Average fish per trip
        self.averageFishPerTrip = totalLogs > 0 ? Double(totalFish) / Double(totalLogs) : 0
    }
}
