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
struct HeatmapOverlay: View {
    let hotspots: [CLLocationCoordinate2D: Double] // coordinate: score

    var body: some View {
        ZStack {
            ForEach(hotspots.sorted(by: { $0.value > $1.value }), id: \.key) { coord, score in
                Circle()
                    .fill(Color.red.opacity(min(0.7, max(0.1, score/20))))
                    .frame(width: 40, height: 40)
                    .position(/* convert coord to CGPoint on map */)
            }
        }
    }
}
/// Interactive map view displaying the GPS track with start/current position markers
struct FishMapView: View {
    var showFullScreenButton: Bool = true
    
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
            FullScreenFishMapView()
        }
    }
    
    private var mapView: some View {
        Map(position: $cameraPosition) {
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
                Map(position: $cameraPosition)
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
