import SwiftUI

// MARK: - Color Extensions
extension Color {
    // Primary palette
    static let saltyBlue = Color(hex: "47A8FF")
    static let saltyBackground = Color.black
    static let saltyDarkPanel = Color(hex: "0a1628")
    static let saltyCardBackground = Color(hex: "152238")
    
    // Text colors
    static let saltyTextPrimary = Color.white
    static let saltyTextSecondary = Color(hex: "666666")
    
    // Semantic colors
    static let saltyGreen = Color(hex: "4CAF50")
    static let saltyOrange = Color(hex: "FF5722")
    
    // Convenience initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design Constants
struct DesignConstants {
    // Spacing
    static let screenPadding: CGFloat = 20
    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 24
    static let componentSpacing: CGFloat = 16
    
    // Wave animation
    static let waveHeight: CGFloat = 80
    static let waveAnimationDuration: Double = 2.0
    
    // Direction indicator
    static let directionIndicatorSize: CGSize = CGSize(width: 120, height: 120)
    
    // Typography
    struct Typography {
        static let clockSize: CGFloat = 120
        static let speedValueSize: CGFloat = 96
        static let speedUnitSize: CGFloat = 24
        static let headingValueSize: CGFloat = 36
        static let headingLabelSize: CGFloat = 18
        static let statLabelSize: CGFloat = 14
        static let statValueSize: CGFloat = 32
        
        // Landscape adjustments
        static let landscapeSpeedSize: CGFloat = 72
        static let landscapeStatSize: CGFloat = 28
    }
    
    // Animation
    struct Animation {
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.3)
        static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.8)
        static let wavePhase: SwiftUI.Animation = .linear(duration: 2.0).repeatForever(autoreverses: false)
    }
}

// MARK: - View Modifiers
struct SaltyCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(DesignConstants.cardPadding)
            .background(Color.saltyCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cardCornerRadius))
    }
}

extension View {
    func saltyCardStyle() -> some View {
        modifier(SaltyCardStyle())
    }
}

// MARK: - Font Extensions
extension Font {
    static func saltyDisplay(_ size: CGFloat, weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight)
    }
    
    static func saltyLabel(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
