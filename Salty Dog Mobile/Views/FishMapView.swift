import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: Hashable {
    // Equatable conformance is required for Hashable
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

// MARK: - Heatmap Overlay
/// Displays fishing hotspots as visual overlays on the map
struct HeatmapOverlay: MapContent {
    let hotspots: [CLLocationCoordinate2D: Double] // coordinate: score (0-1)
    let showLabels: Bool = false
    
    var body: some MapContent {
        ForEach(Array(hotspots.sorted(by: { $0.value > $1.value }).enumerated()), id: \.offset) { index, item in
            let (coord, score) = item
            Annotation("", coordinate: coord) {
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(colorForScore(score))
                            .frame(width: sizeForScore(score), height: sizeForScore(score))
                        
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: sizeForScore(score), height: sizeForScore(score))
                    }
                    
                    if showLabels {
                        Text(String(format: "%.0f%%", score * 100))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(colorForScore(score))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            }
        }
    }
    
    private func colorForScore(_ score: Double) -> Color {
        // Red (low score) to Yellow to Green (high score)
        if score > 0.75 {
            return Color.green
        } else if score > 0.6 {
            return Color.yellow
        } else if score > 0.45 {
            return Color.orange
        } else {
            return Color.red.opacity(0.8)
        }
    }
    
    private func sizeForScore(_ score: Double) -> Double {
        // Size ranges from 25 to 55 based on score
        return 25 + (score * 30)
    }
}
/// Interactive map view displaying the GPS track with start/current position markers
struct FishMapView: View {
    var showFullScreenButton: Bool = true
    var hotspots: [CLLocationCoordinate2D: Double] = [:]
    var userLocation: CLLocationCoordinate2D?
    var showHotspots: Bool = true
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showFullScreen = false
    
    var body: some View {
        ZStack {
            mapView
            
            if showFullScreenButton {
                fullScreenButton
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenFishMapView(hotspots: hotspots, userLocation: userLocation)
        }
    }
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Show heatmap hotspots
            if showHotspots && !hotspots.isEmpty {
                HeatmapOverlay(hotspots: hotspots)
            }
            
            // Show user location marker
            if let userLoc = userLocation {
                Annotation("", coordinate: userLoc) {
                    currentPositionMarker
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }
    
    private var currentPositionMarker: some View {
        ZStack {
            // Pulsing ring
            Circle()
                .stroke(Color.saltyOrange.opacity(0.4), lineWidth: 2)
                .frame(width: 28, height: 28)
            
            // Main marker
            Circle()
                .fill(Color.saltyOrange)
                .frame(width: 18, height: 18)
            
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 18, height: 18)
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 6, height: 6)
        }
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
    }
    
    private var fullScreenButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { showFullScreen = true }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.saltyTextPrimary)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(8)
            }
            Spacer()
        }
    }
}

/// Full screen map view with additional controls
struct FullScreenFishMapView: View {
    
    var hotspots: [CLLocationCoordinate2D: Double] = [:]
    var userLocation: CLLocationCoordinate2D?
    
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStyle: MapStyleOption = .standard
    @State private var showHotspots: Bool = true
    
    enum MapStyleOption: String, CaseIterable {
        case standard = "Standard"
        case satellite = "Satellite"
        case hybrid = "Hybrid"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    // Show heatmap hotspots
                    if showHotspots && !hotspots.isEmpty {
                        HeatmapOverlay(hotspots: hotspots)
                    }
                    
                    // Show user location marker
                    if let userLoc = userLocation {
                        Annotation("Current Location", coordinate: userLoc) {
                            currentPositionMarker
                        }
                    }
                }
                .mapStyle(currentMapStyle)
                .mapControls {
                    MapCompass()
                    MapScaleView()
                    MapUserLocationButton()
                }
                
                // Map controls
                VStack {
                    HStack {
                        if !hotspots.isEmpty {
                            Button(action: { showHotspots.toggle() }) {
                                HStack(spacing: 6) {
                                    Image(systemName: showHotspots ? "eye.fill" : "eye.slash.fill")
                                    Text("Hotspots")
                                        .font(.caption)
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(showHotspots ? Color.saltyBlue : Color.gray)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                    
                    Spacer()
                    
                    // Map style picker
                    mapStylePicker
                        .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.saltyBlue)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Fish Map")
                        .font(.headline)
                }
            }

        }
    }
    
    private var startMarker: some View {
        ZStack {
            Circle()
                .fill(Color.saltyGreen)
                .frame(width: 20, height: 20)
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 20, height: 20)
        }
    }
    
    private var currentPositionMarker: some View {
        ZStack {
            Circle()
                .fill(Color.saltyOrange)
                .frame(width: 22, height: 22)
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 22, height: 22)
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
        }
    }
    
    private var currentMapStyle: MapStyle {
        switch mapStyle {
        case .standard:
            return .standard(elevation: .realistic)
        case .satellite:
            return .imagery(elevation: .realistic)
        case .hybrid:
            return .hybrid(elevation: .realistic)
        }
    }
    
    private var mapStylePicker: some View {
        Picker("Map Style", selection: $mapStyle) {
            ForEach(MapStyleOption.allCases, id: \.self) { style in
                Text(style.rawValue).tag(style)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

#Preview("Fish Map") {
    return FishMapView()
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
}
