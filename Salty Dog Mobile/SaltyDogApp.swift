import SwiftUI

@main
struct SaltyDogApp: App {
    @StateObject private var locationManager = LocationManager()
    @AppStorage("speedUnit") private var speedUnitRaw: String = SpeedUnit.knots.rawValue
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = true
    
    var speedUnit: Binding<SpeedUnit> {
        Binding(
            get: { SpeedUnit(rawValue: speedUnitRaw) ?? .knots },
            set: { speedUnitRaw = $0.rawValue }
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(locationManager: locationManager, speedUnit: speedUnit)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Keep screen on while navigating
                    UIApplication.shared.isIdleTimerDisabled = keepScreenOn
                }
                .onChange(of: keepScreenOn) { _, newValue in
                    UIApplication.shared.isIdleTimerDisabled = newValue
                }
        }
    }
}
