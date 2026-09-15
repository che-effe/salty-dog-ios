import SwiftUI
import RevenueCat
import StoreKit

// MARK: - ProAngler Subscription Sheet
/// Subscription management sheet for ProAngler features
struct ProAnglerSubscriptionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var isSubscribed: Bool

    init(isSubscribed: Binding<Bool>) {
        self._isSubscribed = isSubscribed
    }

    @State private var offering: Offering?
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?
    @State private var showErrorAlert: Bool = false

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

                            if let offering {
                                ForEach(offering.availablePackages.sorted(by: sortPackages(_:_:)), id: \.identifier) { pkg in
                                    pricingOption(
                                        period: periodLabel(for: pkg),
                                        price: pkg.storeProduct.localizedPriceString,
                                        description: packageDescription(for: pkg, base: priceDescription(for: pkg)),
                                        isRecommended: offering.annual?.identifier == pkg.identifier
                                    )
                                }
                            } else {
                                HStack(spacing: 12) {
                                    ProgressView()
                                    Text("Loading prices…")
                                        .font(.subheadline)
                                        .foregroundColor(.saltyTextSecondary)
                                }
                            }
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
                                .disabled(isPurchasing)
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
                            
                            Button(action: restorePurchases) {
                                Text("Restore Purchases")
                                    .font(.subheadline)
                                    .foregroundColor(.saltyTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
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
            .task { loadOffering() }
            .alert("Purchase Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseError ?? "Unknown error")
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

    private func periodLabel(for package: Package) -> String {
        if let period = package.storeProduct.subscriptionPeriod {
            switch period.unit {
            case .day: return "Daily"
            case .week: return "Weekly"
            case .month: return "Monthly"
            case .year: return "Annual"
            @unknown default: return "Subscription"
            }
        } else {
            return "Lifetime"
        }
    }

    private func priceDescription(for package: Package) -> String {
        if package.storeProduct.subscriptionPeriod != nil {
            return "cancel anytime"
        } else {
            return "one-time purchase"
        }
    }
    
    private func packageDescription(for package: Package, base: String) -> String {
        var desc: String
        if let period = package.storeProduct.subscriptionPeriod {
            switch period.unit {
            case .day: desc = "per day, \(base)"
            case .week: desc = "per week, \(base)"
            case .month: desc = "per month, \(base)"
            case .year: desc = "per year, \(base)"
            @unknown default: desc = base
            }
        } else {
            desc = base
        }
        if package.storeProduct.introductoryDiscount != nil {
            desc += " • Intro offer available"
        }
        return desc
    }

    private func sortPackages(_ a: Package, _ b: Package) -> Bool {
        rank(for: a) < rank(for: b)
    }

    private func rank(for package: Package) -> Int {
        if let unit = package.storeProduct.subscriptionPeriod?.unit {
            switch unit {
            case .year: return 0
            case .month: return 1
            case .week: return 2
            case .day: return 3
            @unknown default: return 10
            }
        }
        // Non-subscription / lifetime at the end
        return 9
    }

    private func subscribeToProAngler() {
        guard let pkg =
            offering?.annual ??
            offering?.monthly ??
            offering?.availablePackages.first
        else {
            purchaseError = "No products available."
            showErrorAlert = true
            return
        }

        isPurchasing = true
        Task {
            do {
                let result = try await Purchases.shared.purchase(package: pkg)
                if result.customerInfo.entitlements.all["SaltyDog Pro"]?.isActive == true {
                    isSubscribed = true
                    dismiss()
                } else {
                    purchaseError = "Purchase succeeded, but entitlement is not active."
                    showErrorAlert = true
                }
            } catch {
                let nsError = error as NSError
                let isCancelled = (nsError.domain == SKErrorDomain && nsError.code == SKError.paymentCancelled.rawValue) || nsError.code == SKError.paymentCancelled.rawValue
                if isCancelled {
                    // User cancelled the purchase
                } else {
                    purchaseError = error.localizedDescription
                    showErrorAlert = true
                }
            }
            isPurchasing = false
        }
    }

    private func restorePurchases() {
        Task {
            do {
                let info = try await Purchases.shared.restorePurchases()
                if info.entitlements.all["SaltyDog Pro"]?.isActive == true {
                    isSubscribed = true
                    dismiss()
                } else {
                    purchaseError = "No active purchases to restore."
                    showErrorAlert = true
                }
            } catch {
                purchaseError = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func loadOffering() {
        Task {
            do {
                let offerings = try await Purchases.shared.offerings()
                offering = offerings.current
            } catch {
                purchaseError = "Failed to load products: \(error.localizedDescription)"
                showErrorAlert = true
            }
        }
    }
}
func checkEntitlement() async {
    do {
        let customerInfo = try await Purchases.shared.customerInfo()
        if customerInfo.entitlements.all["SaltyDog Pro"]?.isActive == true {
            // User has access to entitlement
        }
    } catch {
        print("Error: \(error)")
    }
}
#Preview {
    ProAnglerSubscriptionSheet(isSubscribed: .constant(false))
}

