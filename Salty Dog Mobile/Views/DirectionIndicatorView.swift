import SwiftUI

/// Calculates the shortest angular distance between two angles
/// Returns a value between -180 and 180 degrees
private func shortestAngularDistance(from: Double, to: Double) -> Double {
    var delta = to - from
    // Normalize to -180...180 range
    delta = delta.truncatingRemainder(dividingBy: 360)
    if delta > 180 {
        delta -= 360
    } else if delta < -180 {
        delta += 360
    }
    return delta
}

/// Wind vane style direction indicator that rotates based on heading
/// Features smooth rotation animation and nautical styling
struct DirectionIndicatorView: View {
    let heading: Double
    let size: CGSize
    
    @State private var animatedHeading: Double = 0
    
    var body: some View {
        ZStack {
            // Rotating compass dial (ring + markers)
            ZStack {
                // Compass ring background
                Circle()
                    .stroke(Color.saltyCardBackground, lineWidth: 3)
                
                // Cardinal direction markers
                CardinalMarkersView()
            }
            .rotationEffect(.degrees(-animatedHeading))
            
            // Static wind vane arrow - always points up
            WindVaneArrow()
                .fill(Color.saltyBlue)
                .shadow(color: .saltyBlue.opacity(0.5), radius: 4, x: 0, y: 2)
            
            // Center cap (static)
            Circle()
                .fill(Color.saltyCardBackground)
                .frame(width: size.width * 0.15, height: size.height * 0.15)
            
            Circle()
                .stroke(Color.saltyBlue.opacity(0.5), lineWidth: 1)
                .frame(width: size.width * 0.15, height: size.height * 0.15)
        }
        .frame(width: size.width, height: size.height)
        .onChange(of: heading) { _, newHeading in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                // Calculate shortest angular distance to handle 0/360 boundary
                let delta = shortestAngularDistance(from: animatedHeading, to: newHeading)
                animatedHeading += delta
            }
        }
        .onAppear {
            animatedHeading = heading
        }
    }
}

/// Cardinal direction markers around the compass
struct CardinalMarkersView: View {
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = geometry.size.height / 2 - 10

            ZStack {
                // Major tick marks (N, E, S, W)
                ForEach(0..<4) { index in
                    let angle = Double(index) * 90

                    TickMark(length: 8, width: 2)
                        .fill(Color.saltyBlue)
                        // Offset to edge, then rotate
                        .offset(y: -radius)
                        .rotationEffect(.degrees(angle))
                }
//                
                // Minor tick marks (NE, SE, SW, NW)
                ForEach(0..<4) { index in
                    let angle = Double(index) * 90

                    TickMark(length: 5, width: 2)
                        .fill(Color.saltyTextPrimary)
                        // Offset to edge, then rotate
                        .offset(y: -radius-20)
                        .rotationEffect(.degrees(angle+45))
                }
                
                // N marker (special highlight)
                Text("N")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.saltyOrange)
                    .position(
                        x: center.x,
                        y: center.y - radius - 20
                    )
                // S marker (standard text)
                Text("S")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.saltyTextPrimary)
                    .position(
                        x: center.x,
                        y: center.y + radius + 20
                    )
                // E marker (standard text)
                Text("E")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.saltyTextPrimary)
                    .position(
                        x: center.x + radius + 20,
                        y: center.y
                    )
                // E marker (standard text)
                Text("W")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.saltyTextPrimary)
                    .position(
                        x: center.x - radius - 20,
                        y: center.y
                    )
            }
        }
    }
}

/// Tick mark shape for compass markers
struct TickMark: Shape {
    let length: CGFloat
    let width: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: CGPoint(x: center.x - width/2, y: center.y - length/2))
        path.addLine(to: CGPoint(x: center.x + width/2, y: center.y - length/2))
        path.addLine(to: CGPoint(x: center.x + width/2, y: center.y + length/2))
        path.addLine(to: CGPoint(x: center.x - width/2, y: center.y + length/2))
        path.closeSubpath()
        return path
    }
}

/// Wind vane arrow shape - elegant pointer design
struct WindVaneArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let centerX = width / 2
        let centerY = height / 2
        
        // Arrow pointing up (north when rotation is 0)
        let arrowTip = CGPoint(x: centerX, y: height * 0.1)
        let arrowLeft = CGPoint(x: centerX - width * 0.12, y: centerY)
        let arrowRight = CGPoint(x: centerX + width * 0.12, y: centerY)
        let arrowNotchLeft = CGPoint(x: centerX - width * 0.06, y: centerY - height * 0.05)
        let arrowNotchRight = CGPoint(x: centerX + width * 0.06, y: centerY - height * 0.05)
        
        // Tail
        let tailTop = CGPoint(x: centerX, y: centerY + height * 0.05)
        let tailBottom = CGPoint(x: centerX, y: height * 0.85)
        let tailLeft = CGPoint(x: centerX - width * 0.04, y: height * 0.75)
        let tailRight = CGPoint(x: centerX + width * 0.04, y: height * 0.75)
        
        // Draw arrow head
        path.move(to: arrowTip)
        path.addLine(to: arrowRight)
        path.addLine(to: arrowNotchRight)
        path.addLine(to: tailTop)
        
        // Draw tail
        path.addLine(to: CGPoint(x: centerX + width * 0.03, y: centerY + height * 0.1))
        path.addLine(to: tailRight)
        path.addLine(to: tailBottom)
        path.addLine(to: tailLeft)
        path.addLine(to: CGPoint(x: centerX - width * 0.03, y: centerY + height * 0.1))
        
        // Complete arrow head
        path.addLine(to: tailTop)
        path.addLine(to: arrowNotchLeft)
        path.addLine(to: arrowLeft)
        path.closeSubpath()
        
        return path
    }
}

/// Simplified direction indicator for compact displays
struct CompactDirectionIndicator: View {
    let heading: Double
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.saltyCardBackground)
            
            Image(systemName: "location.north.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.saltyBlue)
                .rotationEffect(.degrees(heading))
        }
    }
}

/// Wind direction arrow indicator using SF Symbol
/// Arrow points in the direction the wind is blowing FROM
struct WindDirectionArrowView: View {
    let windDirection: Double // degrees (0-360, meteorological convention: direction wind blows FROM)
    var size: CGFloat = 24
    var color: Color = .saltyBlue
    var showBackground: Bool = false
    
    @State private var animatedDirection: Double = 0
    
    var body: some View {
        ZStack {
            if showBackground {
                Circle()
                    .fill(Color.saltyCardBackground)
                    .frame(width: size * 1.5, height: size * 1.5)
            }
            
            Image(systemName: "arrow.up")
                .font(.system(size: size, weight: .bold))
                .foregroundColor(color)
                .rotationEffect(.degrees(animatedDirection))
        }
        .onChange(of: windDirection) { _, newDirection in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                // Calculate shortest angular distance to handle 0/360 boundary
                let delta = shortestAngularDistance(from: animatedDirection, to: newDirection)
                animatedDirection += delta
            }
        }
        .onAppear {
            animatedDirection = windDirection
        }
    }
}

/// Wind direction indicator with label
struct WindDirectionIndicatorView: View {
    let windDirection: Double
    let windSpeed: String
    let unit: String
    var size: CGFloat = 32
    
    var body: some View {
        HStack(spacing: 8) {
            WindDirectionArrowView(
                windDirection: windDirection,
                size: size,
                color: .saltyBlue,
                showBackground: true
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(windSpeed) \(unit)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.saltyTextPrimary)
                
                Text(HeadingFormatter.cardinalDirection(for: windDirection))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.saltyTextSecondary)
            }
        }
    }
}

#Preview("Direction Indicator") {
    VStack(spacing: 40) {
        DirectionIndicatorView(
            heading: 45,
            size: CGSize(width: 120, height: 120)
        )
        
        DirectionIndicatorView(
            heading: 225,
            size: CGSize(width: 80, height: 80)
        )
    }
    .padding()
    .background(Color.black)
}

#Preview("Wind Direction Arrow") {
    VStack(spacing: 30) {
        // Simple arrow
        WindDirectionArrowView(windDirection: 45, size: 32)
        
        // Arrow with background
        WindDirectionArrowView(windDirection: 180, size: 24, showBackground: true)
        
        // Full indicator with speed
        WindDirectionIndicatorView(
            windDirection: 225,
            windSpeed: "12",
            unit: "KTS"
        )
        
        // Different directions
        HStack(spacing: 20) {
            ForEach([0, 90, 180, 270], id: \.self) { direction in
                VStack {
                    WindDirectionArrowView(windDirection: Double(direction), size: 20)
                    Text("\(direction)°")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
    .padding()
    .background(Color.black)
}
