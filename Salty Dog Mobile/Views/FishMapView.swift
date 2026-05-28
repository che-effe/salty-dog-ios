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
/// Displays a gradient heatmap overlay indicating fishing potential across water areas
struct HeatmapOverlay: MapContent {
    let hotspots: [CLLocationCoordinate2D: Double] // coordinate: score (0-1)
    let showLabels: Bool = false
    
    // Grid resolution for heatmap interpolation (in degrees)
    private let gridStep: Double = 0.005 // ~500m grid
    
    var body: some MapContent {
        // Generate a gradient grid from hotspots
        let gridPoints = generateHeatmapGrid()
        
        ForEach(Array(gridPoints.enumerated()), id: \.offset) { index, point in
            if point.score > 0.25 { // Only show meaningful scores
                Annotation("", coordinate: point.coordinate) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(gradientColorForScore(point.score))
                        .frame(width: 12, height: 12)
                        .opacity(0.6)
                }
            }
        }
        
        // Show hotspot centers with labels if enabled
        if showLabels {
            ForEach(Array(hotspots.sorted(by: { $0.value > $1.value }).enumerated()), id: \.offset) { index, item in
                let (coord, score) = item
                Annotation("", coordinate: coord) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(gradientColorForScore(score))
                                .frame(width: 20, height: 20)
                            
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 20, height: 20)
                        }
                        
                        Text(String(format: "%.0f%%", score * 100))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(gradientColorForScore(score))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                }
            }
        }
    }
    
    /// Generate grid points with interpolated scores across the area
    private func generateHeatmapGrid() -> [HeatmapGridPoint] {
        guard !hotspots.isEmpty else { return [] }
        
        // Find bounds of hotspots
        let lats = hotspots.keys.map { $0.latitude }
        let lons = hotspots.keys.map { $0.longitude }
        
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else {
            return []
        }
        
        // Expand bounds by 20% for smoother gradient edges
        let latPadding = (maxLat - minLat) * 0.2
        let lonPadding = (maxLon - minLon) * 0.2
        
        var gridPoints: [HeatmapGridPoint] = []
        
        // Generate grid
        var lat = minLat - latPadding
        while lat <= maxLat + latPadding {
            var lon = minLon - lonPadding
            while lon <= maxLon + lonPadding {
                let gridCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                let interpolatedScore = interpolateScore(at: gridCoord)
                gridPoints.append(HeatmapGridPoint(coordinate: gridCoord, score: interpolatedScore))
                lon += gridStep
            }
            lat += gridStep
        }
        
        return gridPoints
    }
    
    /// Interpolate score at a given location based on nearby hotspots
    private func interpolateScore(at coordinate: CLLocationCoordinate2D) -> Double {
        guard !hotspots.isEmpty else { return 0 }
        
        // Calculate weighted average based on distance to hotspots
        var totalWeight: Double = 0
        var weightedScore: Double = 0
        
        for (hotspotCoord, score) in hotspots {
            let distance = coordinate.distance(to: hotspotCoord)
            
            // Use inverse distance weighting with a falloff radius of 0.05 degrees (~5km)
            let falloffRadius: Double = 0.05
            let weight = max(0, 1.0 - (distance / falloffRadius))
            
            if weight > 0 {
                totalWeight += weight
                weightedScore += score * weight
            }
        }
        
        return totalWeight > 0 ? weightedScore / totalWeight : 0
    }
    
    /// Get gradient color for score (red -> orange -> yellow -> green)
    private func gradientColorForScore(_ score: Double) -> Color {
        if score > 0.8 {
            return Color.green
        } else if score > 0.65 {
            return Color(red: 0.5, green: 1.0, blue: 0) // Yellow-green
        } else if score > 0.5 {
            return Color.yellow
        } else if score > 0.35 {
            return Color.orange
        } else if score > 0.25 {
            return Color(red: 1.0, green: 0.5, blue: 0) // Orange-red
        } else {
            return Color.red.opacity(0.7)
        }
    }
}

// MARK: - Heatmap Grid Point
struct HeatmapGridPoint {
    let coordinate: CLLocationCoordinate2D
    let score: Double
}

// MARK: - Coordinate Distance Extension
extension CLLocationCoordinate2D {
    /// Calculate distance in degrees between two coordinates
    func distance(to other: CLLocationCoordinate2D) -> Double {
        let latDiff = (latitude - other.latitude) * (latitude - other.latitude)
        let lonDiff = (longitude - other.longitude) * (longitude - other.longitude)
        return sqrt(latDiff + lonDiff)
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
