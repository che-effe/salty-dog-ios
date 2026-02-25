import SwiftUI
import Combine

/// The primary navigation display showing real-time speed, heading, and navigation data
struct MainDashboardView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var speedUnit: SpeedUnit
    
    @State private var currentTime = Date()
    @AppStorage("use24Hour") private var use24Hour: Bool = false
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Computed Display Values
    
    private var displaySpeed: String {
        let speed = speedUnit.convert(fromMetersPerSecond: locationManager.currentSpeed)
        return SpeedFormatter.format(speed, unit: speedUnit)
    }
    
    private var displayTopSpeed: String {
        let speed = speedUnit.convert(fromMetersPerSecond: locationManager.topSpeed)
        return SpeedFormatter.format(speed, unit: speedUnit)
    }
    
    private var displayDistance: String {
        let distance = speedUnit.convertDistance(fromMeters: locationManager.totalDistance)
        return DistanceFormatter.format(distance)
    }
    
    private var displayHeading: String {
        HeadingFormatter.format(locationManager.currentHeading)
    }
    
    private var displayTime: String {
        TimeFormatter.currentTime(use24Hour: use24Hour)
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.saltyBackground.ignoresSafeArea()
                
                if verticalSizeClass == .compact {
                    landscapeLayout(geometry: geometry)
                } else {
                    portraitLayout(geometry: geometry)
                }
            }
        }
        .onReceive(timer) { currentTime = $0 }
    }
    
    // MARK: - Portrait Layout
    
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            // Clock display
            clockDisplay
                .padding(.top, 8)
            
            // Speed and Direction row
            HStack(spacing: 12) {
                speedCard
                    .frame(maxWidth: .infinity)
                
                directionIndicator
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, DesignConstants.screenPadding)
            
            // Heading bar
            headingBar
                .padding(.horizontal, DesignConstants.screenPadding)
            
            // Stats summary row
            statsSummary
                .padding(.horizontal, DesignConstants.screenPadding)
            
            Spacer()
            
            // Wave animation at bottom
            WaveAnimationView(isActive: locationManager.isTracking)
                .frame(height: DesignConstants.waveHeight)
                .ignoresSafeArea(edges: .bottom)
        }
    }
    
    // MARK: - Landscape Layout
    
    @ViewBuilder
    private func landscapeLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 24) {
            // Left side: Speed display
            VStack {
                Spacer()
                landscapeSpeedDisplay
                Spacer()
                
                // Compact wave
                CompactWaveView()
                    .frame(height: 30)
            }
            .frame(width: geometry.size.width * 0.4)
            
            // Right side: Stats and heading
            VStack(spacing: 16) {
                Spacer()
                
                // Stats stack
                landscapeStatRow(label: "TOP SPEED", value: displayTopSpeed, unit: speedUnit.rawValue)
                landscapeStatRow(label: "DISTANCE", value: displayDistance, unit: speedUnit.distanceLabel)
                landscapeStatRow(label: "HEADING", value: displayHeading, unit: "")
                landscapeStatRow(label: "DURATION", value: DurationFormatter.format(locationManager.sessionDuration), unit: "")
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            // Far right: Direction indicator
            directionIndicator
                .padding(.trailing, 16)
        }
        .padding(.horizontal, DesignConstants.screenPadding)
    }
    
    // MARK: - Component Views
    
    private var clockDisplay: some View {
        Text(displayTime)
            .font(.saltyDisplay(DesignConstants.Typography.clockSize, weight: .heavy))
            .foregroundColor(.saltyTextPrimary)
            .monospacedDigit()
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.2), value: displayTime)
    }
    
    private var speedCard: some View {
        VStack(spacing: 4) {
            Text(displaySpeed)
                .font(.saltyDisplay(DesignConstants.Typography.speedValueSize, weight: .black))
                .foregroundColor(.saltyTextPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.15), value: displaySpeed)
            
            Text(speedUnit.rawValue)
                .font(.saltyLabel(DesignConstants.Typography.speedUnitSize, weight: .semibold))
                .foregroundColor(.saltyBlue)
                .textCase(.uppercase)
        }
        .saltyCardStyle()
    }
    
    private var landscapeSpeedDisplay: some View {
        VStack(spacing: 8) {
            Text(displaySpeed)
                .font(.saltyDisplay(DesignConstants.Typography.landscapeSpeedSize, weight: .black))
                .foregroundColor(.saltyTextPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            
            Text(speedUnit.rawValue)
                .font(.saltyLabel(DesignConstants.Typography.speedUnitSize, weight: .semibold))
                .foregroundColor(.saltyBlue)
                .textCase(.uppercase)
        }
        .saltyCardStyle()
    }
    
    private var directionIndicator: some View {
        DirectionIndicatorView(
            heading: locationManager.currentHeading,
            size: DesignConstants.directionIndicatorSize
        )
    }
    
    private var headingBar: some View {
        HStack {
            Text("HEADING")
                .font(.saltyLabel(DesignConstants.Typography.headingLabelSize, weight: .semibold))
                .foregroundColor(.saltyBlue)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(HeadingFormatter.cardinalDirection(for: locationManager.currentHeading))
                    .font(.saltyLabel(DesignConstants.Typography.headingLabelSize, weight: .bold))
                    .foregroundColor(.saltyOrange)
                
                Text(displayHeading)
                    .font(.saltyDisplay(DesignConstants.Typography.headingValueSize, weight: .bold))
                    .foregroundColor(.saltyTextPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .padding(.vertical, 12)
        .saltyCardStyle()
    }
    
    private var statsSummary: some View {
        HStack(spacing: 16) {
            statCard(
                title: "TOP SPEED",
                value: displayTopSpeed,
                unit: speedUnit.rawValue
            )
            
            statCard(
                title: "DISTANCE",
                value: displayDistance,
                unit: speedUnit.distanceLabel
            )
            
            statCard(
                title: "DURATION",
                value: DurationFormatter.format(locationManager.sessionDuration),
                unit: ""
            )
        }
    }
    
    private func statCard(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.saltyLabel(DesignConstants.Typography.statLabelSize, weight: .semibold))
                .foregroundColor(.saltyBlue)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.saltyDisplay(DesignConstants.Typography.statValueSize, weight: .bold))
                    .foregroundColor(.saltyTextPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.saltyLabel(12, weight: .medium))
                        .foregroundColor(.saltyTextSecondary)
                }
            }
            .minimumScaleFactor(0.7)
            .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .saltyCardStyle()
    }
    
    private func landscapeStatRow(label: String, value: String, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.saltyLabel(14, weight: .semibold))
                .foregroundColor(.saltyBlue)
            
            Spacer()
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.saltyDisplay(DesignConstants.Typography.landscapeStatSize, weight: .bold))
                    .foregroundColor(.saltyTextPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.saltyLabel(12, weight: .medium))
                        .foregroundColor(.saltyTextSecondary)
                        .frame(width: 30, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.saltyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Authorization Overlay

extension MainDashboardView {
    @ViewBuilder
    private var authorizationOverlay: some View {
        if locationManager.authorizationStatus == .denied {
            VStack(spacing: 16) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.saltyOrange)
                
                Text("Location Access Required")
                    .font(.headline)
                    .foregroundColor(.saltyTextPrimary)
                
                Text("SaltyDog needs location access to display your speed and track your route.")
                    .font(.subheadline)
                    .foregroundColor(.saltyTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.saltyBlue)
            }
            .padding(32)
            .background(Color.saltyDarkPanel)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding()
        }
    }
}

#Preview("Portrait") {
    MainDashboardView(
        locationManager: LocationManager(),
        speedUnit: .constant(.knots)
    )
}

#Preview("Landscape") {
    MainDashboardView(
        locationManager: LocationManager(),
        speedUnit: .constant(.knots)
    )
    .previewInterfaceOrientation(.landscapeLeft)
}
