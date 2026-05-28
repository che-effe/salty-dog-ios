import SwiftUI
import MapKit

// MARK: - Hotspot Analysis Sheet
/// Detailed view showing fishing hotspot analysis and insights
struct HotspotAnalysisSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let analysis: HotspotAnalysis
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.saltyBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Condition Summary
                        conditionsSummaryCard
                        
                        // Top Locations
                        if !analysis.topLocations.isEmpty {
                            topLocationsCard
                        }
                        
                        // Insights
                        insightsCard
                    }
                    .padding(DesignConstants.screenPadding)
                }
            }
            .navigationTitle("Fishing Conditions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.saltyBlue)
                }
            }
        }
    }
    
    private var conditionsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Conditions")
                .font(.headline)
                .foregroundColor(.saltyTextPrimary)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    ConditionRow(
                        label: "Summary",
                        value: analysis.conditionSummary
                    )
                }
                Spacer()
            }
            
            Text("Updated: \(analysis.timestamp.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.saltyTextSecondary)
        }
        .saltyCardStyle()
    }
    
    private var topLocationsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Fishing Locations")
                .font(.headline)
                .foregroundColor(.saltyTextPrimary)
            
            VStack(spacing: 10) {
                ForEach(Array(analysis.topLocations.enumerated()), id: \.offset) { index, location in
                    locationRow(location, rank: index + 1)
                }
            }
        }
        .saltyCardStyle()
    }
    
    private func locationRow(_ location: TopLocation, rank: Int) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .center, spacing: 4) {
                Text("\(rank)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(rankColor(rank))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "%.4f°, %.4f°", location.coordinate.latitude, location.coordinate.longitude))
                    .font(.caption)
                    .foregroundColor(.saltyTextSecondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(scoreColor(location.score))
                    
                    Text(String(format: "%.0f%% match", location.score * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(scoreColor(location.score))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                    
                    Circle()
                        .trim(from: 0, to: location.score)
                        .stroke(scoreColor(location.score), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text(String(format: "%.0f%%", location.score * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.saltyTextPrimary)
                }
                .frame(width: 50, height: 50)
            }
        }
        .padding(10)
        .background(Color.saltyTextPrimary.opacity(0.02))
        .cornerRadius(8)
    }
    
    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights & Recommendations")
                .font(.headline)
                .foregroundColor(.saltyTextPrimary)
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(analysis.insights, id: \.self) { insight in
                    insightItem(insight)
                }
            }
        }
        .saltyCardStyle()
    }
    
    private func insightItem(_ insight: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundColor(.saltyBlue)
                .frame(width: 20)
            
            Text(insight)
                .font(.caption)
                .foregroundColor(.saltyTextSecondary)
                .lineLimit(nil)
            
            Spacer()
        }
        .padding(10)
        .background(Color.saltyBlue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func scoreColor(_ score: Double) -> Color {
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
    
    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1:
            return Color.yellow
        case 2:
            return Color.gray
        case 3:
            return Color(red: 0.8, green: 0.4, blue: 0)
        default:
            return Color.saltyBlue
        }
    }
}

// MARK: - Condition Row Helper
private struct ConditionRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.saltyTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.saltyTextPrimary)
        }
    }
}

#Preview {
    HotspotAnalysisSheet(
        analysis: HotspotAnalysis(
            timestamp: Date(),
            topLocations: [
                TopLocation(coordinate: CLLocationCoordinate2D(latitude: 42.0, longitude: -71.0), score: 0.92),
                TopLocation(coordinate: CLLocationCoordinate2D(latitude: 42.1, longitude: -71.1), score: 0.78),
                TopLocation(coordinate: CLLocationCoordinate2D(latitude: 42.2, longitude: -71.2), score: 0.65)
            ],
            insights: [
                "🌬️ Wind conditions are ideal - minimal wind today",
                "🌡️ Water temperature is in the sweet spot",
                "📊 Atmospheric pressure is rising - good fishing window",
                "🌊 Tide is rising - often productive for feeding fish",
                "📈 Your historical average: 3.2 fish per trip"
            ],
            conditionSummary: "15°C, 2.5 m/s winds, 1015 mb, 12°C water"
        )
    )
}
