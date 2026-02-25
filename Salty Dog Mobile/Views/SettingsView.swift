import SwiftUI
import UniformTypeIdentifiers

/// User preferences and app settings
struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    
    @AppStorage("speedUnit") private var speedUnit: String = SpeedUnit.knots.rawValue
    @AppStorage("use24Hour") private var use24Hour: Bool = false
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = true
    @AppStorage("backgroundTracking") private var backgroundTracking: Bool = false
    
    @State private var showExportSheet = false
    @State private var exportType: ExportType = .gpx
    @State private var exportContent: String = ""
    @State private var showAbout = false
    
    enum ExportType: String, CaseIterable {
        case gpx = "GPX"
        case csv = "CSV"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                unitsSection
                displaySection
                trackingSection
                exportSection
                aboutSection
            }
            .navigationTitle("Settings")
            .scrollContentBackground(.hidden)
            .background(Color.saltyBackground)
            .sheet(isPresented: $showExportSheet) {
                ExportShareSheet(content: exportContent, fileType: exportType)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
    
    // MARK: - Sections
    
    private var unitsSection: some View {
        Section {
            Picker("Speed Unit", selection: $speedUnit) {
                ForEach(SpeedUnit.allCases) { unit in
                    Text(unit.displayName).tag(unit.rawValue)
                }
            }
            .pickerStyle(.menu)
            
            Toggle("24-Hour Time", isOn: $use24Hour)
        } header: {
            Text("Units")
        } footer: {
            Text("Choose your preferred speed and time format.")
        }
        .listRowBackground(Color.saltyCardBackground)
    }
    
    private var displaySection: some View {
        Section {
            Toggle("Keep Screen On", isOn: $keepScreenOn)
        } header: {
            Text("Display")
        } footer: {
            Text("Prevents the screen from dimming while navigating. Uses more battery.")
        }
        .listRowBackground(Color.saltyCardBackground)
        .onChange(of: keepScreenOn) { _, newValue in
            UIApplication.shared.isIdleTimerDisabled = newValue
        }
    }
    
    private var trackingSection: some View {
        Section {
            Toggle("Background Tracking", isOn: $backgroundTracking)
            
            HStack {
                Text("Location Status")
                Spacer()
                Text(locationStatusText)
                    .foregroundColor(locationStatusColor)
            }
            
            if locationManager.authorizationStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .foregroundColor(.saltyBlue)
            }
        } header: {
            Text("Tracking")
        } footer: {
            if backgroundTracking {
                Text("App will continue tracking when in background. This uses more battery but ensures your entire route is recorded.")
            } else {
                Text("Enable background tracking to continue recording when the app is not visible.")
            }
        }
        .listRowBackground(Color.saltyCardBackground)
        .onChange(of: backgroundTracking) { _, enabled in
            if enabled {
                locationManager.enableBackgroundTracking()
            } else {
                locationManager.disableBackgroundTracking()
            }
        }
    }
    
    private var exportSection: some View {
        Section {
            Button(action: { exportSession(as: .gpx) }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.saltyBlue)
                    Text("Export as GPX")
                    Spacer()
                    Text("\(locationManager.trackPoints.count) points")
                        .font(.caption)
                        .foregroundColor(.saltyTextSecondary)
                }
            }
            .disabled(locationManager.trackPoints.isEmpty)
            
            Button(action: { exportSession(as: .csv) }) {
                HStack {
                    Image(systemName: "tablecells")
                        .foregroundColor(.saltyBlue)
                    Text("Export as CSV")
                    Spacer()
                }
            }
            .disabled(locationManager.trackPoints.isEmpty)
        } header: {
            Text("Export Session")
        } footer: {
            Text("Export your current session to share or import into other apps.")
        }
        .listRowBackground(Color.saltyCardBackground)
    }
    
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                    .foregroundColor(.saltyTextSecondary)
            }
            
            HStack {
                Text("Build")
                Spacer()
                Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                    .foregroundColor(.saltyTextSecondary)
            }
            
            Button(action: { showAbout = true }) {
                HStack {
                    Text("About SaltyDog")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.saltyTextSecondary)
                }
            }
            
            // Links - using Button instead of Link to handle potential missing URLs gracefully
            Button(action: openPrivacyPolicy) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.saltyTextSecondary)
                }
            }
            
            Button(action: openSupport) {
                HStack {
                    Text("Support")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.saltyTextSecondary)
                }
            }
        } header: {
            Text("About")
        }
        .listRowBackground(Color.saltyCardBackground)
    }
    
    // MARK: - Helper Properties & Methods
    
    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "When In Use"
        case .authorizedAlways: return "Always"
        }
    }
    
    private var locationStatusColor: Color {
        switch locationManager.authorizationStatus {
        case .notDetermined: return .saltyTextSecondary
        case .denied: return .saltyOrange
        case .authorized, .authorizedAlways: return .saltyGreen
        }
    }
    
    private func exportSession(as type: ExportType) {
        exportType = type
        switch type {
        case .gpx:
            exportContent = locationManager.exportAsGPX()
        case .csv:
            exportContent = locationManager.exportAsCSV()
        }
        showExportSheet = true
    }
    
    private func openPrivacyPolicy() {
        // Replace with your actual privacy policy URL
        if let url = URL(string: "https://example.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSupport() {
        // Replace with your actual support URL
        if let url = URL(string: "https://example.com/support") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Export Share Sheet

struct ExportShareSheet: View {
    let content: String
    let fileType: SettingsView.ExportType
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: fileType == .gpx ? "map" : "tablecells")
                    .font(.system(size: 48))
                    .foregroundColor(.saltyBlue)
                
                Text("Export \(fileType.rawValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(content.count) characters")
                    .font(.caption)
                    .foregroundColor(.saltyTextSecondary)
                
                ShareLink(
                    item: content,
                    subject: Text("SaltyDog Session"),
                    message: Text("My sailing session data")
                ) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.saltyBlue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Button("Copy to Clipboard") {
                    UIPasteboard.general.string = content
                    dismiss()
                }
                .foregroundColor(.saltyBlue)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon placeholder
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [.saltyBlue, .saltyDarkPanel],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "sailboat.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .shadow(color: .saltyBlue.opacity(0.3), radius: 10, y: 5)
                    
                    VStack(spacing: 8) {
                        Text("SaltyDog")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Your Nautical Speed Companion")
                            .font(.subheadline)
                            .foregroundColor(.saltyTextSecondary)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "speedometer", title: "Real-time Speed", description: "GPS-based speed over ground")
                        featureRow(icon: "location.north.fill", title: "Heading", description: "Accurate compass heading")
                        featureRow(icon: "map", title: "Track Recording", description: "Record your journey")
                        featureRow(icon: "square.and.arrow.up", title: "Export", description: "Share as GPX or CSV")
                    }
                    .padding()
                    .background(Color.saltyCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    Text("Designed for sailors, boaters, and paddlers who need real-time navigation data at a glance.")
                        .font(.footnote)
                        .foregroundColor(.saltyTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                }
                .padding(.top, 32)
            }
            .background(Color.saltyBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.saltyBlue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.saltyTextSecondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SettingsView(locationManager: LocationManager())
}
