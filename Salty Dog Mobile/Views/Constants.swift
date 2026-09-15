import Foundation

/// Centralized configuration constants
/// NOTE: For production, prefer loading this from an xcconfig or Info.plist rather than source.
struct Constants {
    /// RevenueCat Public SDK Key
    /// Replace with your actual Public SDK key from the RevenueCat dashboard.
    static let revenueCatAPIKey: String = Bundle.main.infoDictionary?["REVENUE_CAT_API_KEY"] as? String ?? ""
}
