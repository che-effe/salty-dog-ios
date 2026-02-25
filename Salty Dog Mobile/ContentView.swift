import SwiftUI

struct ContentView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var speedUnit: SpeedUnit
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MainDashboardView(
                locationManager: locationManager,
                speedUnit: $speedUnit
            )
            .tabItem {
                Label("Navigate", systemImage: "location.north.fill")
            }
            .tag(0)
            
            StatsView(
                locationManager: locationManager,
                speedUnit: $speedUnit
            )
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(1)
            
            SettingsView(locationManager: locationManager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(.saltyBlue)
        .onAppear {
            configureTabBarAppearance()
            locationManager.requestAuthorization()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.saltyDarkPanel)
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.saltyBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.saltyBlue)
        ]
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.saltyTextSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.saltyTextSecondary)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView(
        locationManager: LocationManager(),
        speedUnit: .constant(.knots)
    )
}
