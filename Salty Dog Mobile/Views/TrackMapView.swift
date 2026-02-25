import SwiftUI
import MapKit

/// Interactive map view displaying the GPS track with start/current position markers
struct TrackMapView: View {
    let trackPoints: [CLLocationCoordinate2D]
    var showFullScreenButton: Bool = true
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showFullScreen = false
    
    var body: some View {
        ZStack {
            mapView
            
            if showFullScreenButton {
                fullScreenButton
            }
            
            if trackPoints.isEmpty {
                emptyStateView
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenMapView(trackPoints: trackPoints)
        }
    }
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
            // Track polyline
            if trackPoints.count >= 2 {
                MapPolyline(coordinates: trackPoints)
                    .stroke(Color.saltyBlue, lineWidth: 4)
            }
            
            // Start marker
            if let first = trackPoints.first {
                Annotation("Start", coordinate: first) {
                    startMarker
                }
            }
            
            // Current position marker
            if let last = trackPoints.last, trackPoints.count > 1 {
                Annotation("Current", coordinate: last) {
                    currentPositionMarker
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            fitToTrack()
        }
        .onChange(of: trackPoints.count) { _, _ in
            // Optionally update camera when track updates
            // For now, let user control the map
        }
    }
    
    private var startMarker: some View {
        ZStack {
            Circle()
                .fill(Color.saltyGreen)
                .frame(width: 16, height: 16)
            
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: 16, height: 16)
        }
        .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
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
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 36))
                .foregroundColor(.saltyTextSecondary)
            
            Text("No Track Data")
                .font(.headline)
                .foregroundColor(.saltyTextSecondary)
            
            Text("Start moving to see your track")
                .font(.caption)
                .foregroundColor(.saltyTextSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.saltyDarkPanel.opacity(0.8))
    }
    
    private func fitToTrack() {
        guard !trackPoints.isEmpty else { return }
        
        // Calculate bounding region
        let lats = trackPoints.map { $0.latitude }
        let lons = trackPoints.map { $0.longitude }
        
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else { return }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.01, (maxLat - minLat) * 1.3),
            longitudeDelta: max(0.01, (maxLon - minLon) * 1.3)
        )
        
        cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
    }
}

/// Full screen map view with additional controls
struct FullScreenMapView: View {
    let trackPoints: [CLLocationCoordinate2D]
    
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStyle: MapStyleOption = .standard
    
    enum MapStyleOption: String, CaseIterable {
        case standard = "Standard"
        case satellite = "Satellite"
        case hybrid = "Hybrid"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $cameraPosition) {
                    if trackPoints.count >= 2 {
                        MapPolyline(coordinates: trackPoints)
                            .stroke(Color.saltyBlue, lineWidth: 4)
                    }
                    
                    if let first = trackPoints.first {
                        Annotation("Start", coordinate: first) {
                            startMarker
                        }
                    }
                    
                    if let last = trackPoints.last, trackPoints.count > 1 {
                        Annotation("Current", coordinate: last) {
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
                
                // Map style picker
                VStack {
                    Spacer()
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
                    Text("Track Map")
                        .font(.headline)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: fitToTrack) {
                        Image(systemName: "scope")
                    }
                    .foregroundColor(.saltyBlue)
                }
            }
            .onAppear {
                fitToTrack()
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
    
    private func fitToTrack() {
        guard !trackPoints.isEmpty else { return }
        
        let lats = trackPoints.map { $0.latitude }
        let lons = trackPoints.map { $0.longitude }
        
        guard let minLat = lats.min(),
              let maxLat = lats.max(),
              let minLon = lons.min(),
              let maxLon = lons.max() else { return }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.005, (maxLat - minLat) * 1.4),
            longitudeDelta: max(0.005, (maxLon - minLon) * 1.4)
        )
        
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}

#Preview("Track Map") {
    // Sample track points for preview
    let samplePoints: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4180),
        CLLocationCoordinate2D(latitude: 37.7760, longitude: -122.4170),
        CLLocationCoordinate2D(latitude: 37.7770, longitude: -122.4165),
        CLLocationCoordinate2D(latitude: 37.7785, longitude: -122.4160)
    ]
    
    return TrackMapView(trackPoints: samplePoints)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
}
