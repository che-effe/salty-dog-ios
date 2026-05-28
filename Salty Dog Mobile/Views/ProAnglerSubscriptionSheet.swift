import SwiftUI

// MARK: - ProAngler Subscription Sheet
/// Subscription management sheet for ProAngler features
struct ProAnglerSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isSubscribed: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.saltyBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.saltyBlue)
                            
                            Text("ProAngler Premium")
                                .font(.title.bold())
                                .foregroundColor(.saltyTextPrimary)
                            
                            Text("Advanced fishing intelligence at your fingertips")
                                .font(.subheadline)
                                .foregroundColor(.saltyTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        
                        // Features List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("What's Included")
                                .font(.headline)
                                .foregroundColor(.saltyTextPrimary)
                            
                            featureItem(
                                icon: "map.fill",
                                title: "Gradient Heatmap",
                                description: "Visual heat gradient showing optimal fishing conditions across water areas"
                            )
                            
                            featureItem(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Condition Matching",
                                description: "AI analyzes your historical catch data against current conditions"
                            )
                            
                            featureItem(
                                icon: "sparkles",
                                title: "Smart Insights",
                                description: "Personalized recommendations based on your fishing patterns"
                            )
                            
                            featureItem(
                                icon: "location.fill",
                                title: "Top Locations",
                                description: "Ranked fishing spots with detailed condition breakdowns"
                            )
                            
                            featureItem(
                                icon: "bell.fill",
                                title: "Condition Alerts",
                                description: "Get notified when conditions match your best catch data"
                            )
                            
                            featureItem(
                                icon: "cloud.fill",
                                title: "Cloud Sync",
                                description: "Access your fishing data across all your devices"
                            )
                        }
                        .saltyCardStyle()
                        
                        // Pricing Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pricing")
                                .font(.headline)
                                .foregroundColor(.saltyTextPrimary)
                            
                            pricingOption(
                                period: "Monthly",
                                price: "$4.99",
                                description: "per month, cancel anytime"
                            )
                            
                            pricingOption(
                                period: "Annual",
                                price: "$39.99",
                                description: "per year (save 33%)",
                                isRecommended: true
                            )
                        }
                        .saltyCardStyle()
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: subscribeToProAngler) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                    Text("Start Free Trial (7 days)")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [.saltyBlue, .saltyBlue.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
                            }
                            
                            Button(action: { dismiss() }) {
                                Text("Maybe Later")
                                    .font(.headline)
                                    .foregroundColor(.saltyBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.saltyBlue.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
                            }
                        }
                        
                        // Legal Text
                        VStack(alignment: .center, spacing: 8) {
                            Text("Terms & Conditions")
                                .font(.caption)
                                .foregroundColor(.saltyBlue)
                                .underline()
                            
                            Text("Free trial requires valid payment method. Subscription renews automatically unless cancelled. You can cancel anytime in Settings.")
                                .font(.caption2)
                                .foregroundColor(.saltyTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(DesignConstants.screenPadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.saltyBlue)
                }
            }
        }
    }
    
    private func featureItem(
        icon: String,
        title: String,
        description: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.saltyBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.saltyTextPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.saltyTextSecondary)
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.saltyDarkPanel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func pricingOption(
        period: String,
        price: String,
        description: String,
        isRecommended: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(period)
                        .font(.subheadline.bold())
                        .foregroundColor(.saltyTextPrimary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.saltyTextSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.title3.bold())
                        .foregroundColor(.saltyBlue)
                }
            }
            
            if isRecommended {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Most Popular")
                        .font(.caption)
                }
                .foregroundColor(.green)
            }
        }
        .padding(12)
        .background(isRecommended ? Color.saltyBlue.opacity(0.08) : Color.saltyDarkPanel)
        .border(isRecommended ? Color.saltyBlue.opacity(0.5) : Color.clear, width: 1)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func subscribeToProAngler() {
        // TODO: Integrate with StoreKit 2 for actual purchases
        // For now, activate the subscription
        isSubscribed = true
        dismiss()
    }
}

#Preview {
    ProAnglerSubscriptionSheet(isSubscribed: .constant(false))
}
