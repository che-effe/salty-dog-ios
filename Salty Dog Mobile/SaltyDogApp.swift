import SwiftUI
import RevenueCat

@main
struct SaltyDogApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherManager = WeatherManager()
    @AppStorage("speedUnit") private var speedUnitRaw: String = SpeedUnit.knots.rawValue
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = true
    @AppStorage("hasProAnglerSubscription") private var hasProAngler: Bool = false
    @State private var showingProSheet: Bool = false

    var speedUnit: Binding<SpeedUnit> {
        Binding(
            get: { SpeedUnit(rawValue: speedUnitRaw) ?? .knots },
            set: { speedUnitRaw = $0.rawValue }
        )
    }
    init() {
           Purchases.configure(withAPIKey: "test_FLSrPGhHGBBQWRuWGXxSyCJwzwW")
    }
    
    func checkEntitlement() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            if customerInfo.entitlements.all["SaltyDog Pro"]?.isActive == true {
                hasProAngler = true;
                showingProSheet = true
            }
        } catch {
            print("Error: \(error)")
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView(
                locationManager: locationManager,
                weatherManager: weatherManager,
                speedUnit: speedUnit
            )
            .preferredColorScheme(.dark)
            .onAppear {
                // Keep screen on while navigating
                UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            }
            .onChange(of: keepScreenOn) { _, newValue in
                UIApplication.shared.isIdleTimerDisabled = newValue
            }
            .task { await checkEntitlement() }
            .sheet(isPresented: $showingProSheet) {
                ProAnglerSubscriptionSheet(isSubscribed: $hasProAngler)
            }
        }
    }
}
