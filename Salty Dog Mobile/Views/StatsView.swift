import SwiftUI

/// Session statistics view with detailed breakdown and track map
struct StatsView: View {
    @ObservedObject var locationManager: LocationManager
    @Binding var speedUnit: SpeedUnit
    
    @State private var showResetConfirmation = false
    
    // MARK: - Computed Display Values
    
    private var displayTopSpeed: String {
        let speed = speedUnit.convert(fromMetersPerSecond: locationManager.topSpeed)
        return SpeedFormatter.format(speed, unit: speedUnit)
    }
    
    private var displayAverageSpeed: String {
        let speed = speedUnit.convert(fromMetersPerSecond: locationManager.averageSpeed)
        return SpeedFormatter.format(speed, unit: speedUnit)
    }
    
    private var displayDistance: String {
        let distance = speedUnit.convertDistance(fromMeters: locationManager.totalDistance)
        return DistanceFormatter.format(distance)
    }
    
    private var displayDuration: String {
        DurationFormatter.format(locationManager.sessionDuration)
    }
    
    private var displayCurrentSpeed: String {
        let speed = speedUnit.convert(fromMetersPerSecond: locationManager.currentSpeed)
        return SpeedFormatter.format(speed, unit: speedUnit)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Session overview cards
                    sessionOverviewSection
                    
                    // Track map
                    trackMapSection
                    
                    // Detailed stats breakdown
                    detailedStatsSection
                    
                    // Session controls
                    sessionControlsSection
                }
                .padding(.vertical)
            }
            .background(Color.saltyBackground)
            .navigationTitle("Session Stats")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Reset Session?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        locationManager.resetSession()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will clear all current session data including top speed, distance, and track.")
            }
        }
    }
    
    // MARK: - Section Views
    
    private var sessionOverviewSection: some View {
        VStack(spacing: 16) {
            // Primary stats row
            HStack(spacing: 12) {
                primaryStatCard(
                    title: "TOP SPEED",
                    value: displayTopSpeed,
                    unit: speedUnit.rawValue,
                    icon: "speedometer",
                    accentColor: .saltyOrange
                )
                
                primaryStatCard(
                    title: "DISTANCE",
                    value: displayDistance,
                    unit: speedUnit.distanceLabel,
                    icon: "point.topleft.down.curvedto.point.bottomright.up",
                    accentColor: .saltyBlue
                )
            }
            
            // Secondary stats row
            HStack(spacing: 12) {
                secondaryStatCard(
                    title: "AVG SPEED",
                    value: displayAverageSpeed,
                    unit: speedUnit.rawValue
                )
                
                secondaryStatCard(
                    title: "DURATION",
                    value: displayDuration,
                    unit: ""
                )
                
                secondaryStatCard(
                    title: "POINTS",
                    value: "\(locationManager.trackPoints.count)",
                    unit: ""
                )
            }
        }
        .padding(.horizontal, DesignConstants.screenPadding)
    }
    
    private var trackMapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Track")
                    .font(.headline)
                    .foregroundColor(.saltyTextPrimary)
                
                Spacer()
                
                if !locationManager.trackPoints.isEmpty {
                    Text("\(locationManager.trackPoints.count) points")
                        .font(.caption)
                        .foregroundColor(.saltyTextSecondary)
                }
            }
            .padding(.horizontal, DesignConstants.screenPadding)
            
            TrackMapView(trackPoints: locationManager.trackCoordinates)
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
                .padding(.horizontal, DesignConstants.screenPadding)
        }
    }
    
    private var detailedStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.saltyTextPrimary)
                .padding(.horizontal, DesignConstants.screenPadding)
            
            VStack(spacing: 1) {
                detailRow(label: "Current Speed", value: "\(displayCurrentSpeed) \(speedUnit.rawValue)")
                detailRow(label: "Top Speed", value: "\(displayTopSpeed) \(speedUnit.rawValue)")
                detailRow(label: "Average Speed", value: "\(displayAverageSpeed) \(speedUnit.rawValue)")
                detailRow(label: "Total Distance", value: "\(displayDistance) \(speedUnit.distanceLabel)")
                detailRow(label: "Session Duration", value: displayDuration)
                detailRow(label: "Track Points", value: "\(locationManager.trackPoints.count)")
                detailRow(label: "Tracking Status", value: locationManager.isTracking ? "Active" : "Paused")
            }
            .background(Color.saltyCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
            .padding(.horizontal, DesignConstants.screenPadding)
        }
    }
    
    private var sessionControlsSection: some View {
        VStack(spacing: 12) {
            // Tracking toggle
            Button(action: {
                if locationManager.isTracking {
                    locationManager.stopTracking()
                } else {
                    locationManager.startTracking()
                }
            }) {
                HStack {
                    Image(systemName: locationManager.isTracking ? "pause.fill" : "play.fill")
                    Text(locationManager.isTracking ? "Pause Tracking" : "Resume Tracking")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(locationManager.isTracking ? Color.saltyOrange : Color.saltyGreen)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Reset button
            Button(action: {
                showResetConfirmation = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Session")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.saltyCardBackground)
                .foregroundColor(.saltyTextPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.saltyTextSecondary.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, DesignConstants.screenPadding)
        .padding(.bottom, 20)
    }
    
    // MARK: - Component Views
    
    private func primaryStatCard(
        title: String,
        value: String,
        unit: String,
        icon: String,
        accentColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.saltyTextSecondary)
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.saltyDisplay(36, weight: .bold))
                    .foregroundColor(.saltyTextPrimary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                
                Text(unit)
                    .font(.saltyLabel(14, weight: .medium))
                    .foregroundColor(accentColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .saltyCardStyle()
    }
    
    private func secondaryStatCard(
        title: String,
        value: String,
        unit: String
    ) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.saltyTextSecondary)
            
            Text(value)
                .font(.saltyDisplay(20, weight: .bold))
                .foregroundColor(.saltyTextPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.saltyBlue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.saltyCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.saltyTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.saltyTextPrimary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.saltyDarkPanel)
    }
}

#Preview {
    StatsView(
        locationManager: LocationManager(),
        speedUnit: .constant(.knots)
    )
}
