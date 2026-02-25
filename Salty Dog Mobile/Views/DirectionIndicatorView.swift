import SwiftUI

/// Wind vane style direction indicator that rotates based on heading
/// Features smooth rotation animation and nautical styling
struct DirectionIndicatorView: View {
    let heading: Double
    let size: CGSize
    
    @State private var animatedHeading: Double = 0
    
    var body: some View {
        ZStack {
            // Compass ring background
            Circle()
                .stroke(Color.saltyCardBackground, lineWidth: 3)
            
            // Cardinal direction markers
            CardinalMarkersView()
            
            // Wind vane arrow
            WindVaneArrow()
                .fill(Color.saltyBlue)
                .rotationEffect(.degrees(animatedHeading))
                .shadow(color: .saltyBlue.opacity(0.5), radius: 4, x: 0, y: 2)
            
            // Center cap
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
                animatedHeading = calculateShortestRotation(from: -animatedHeading, to: -newHeading)
            }
        }
        .onAppear {
            animatedHeading = heading
        }
    }
    
    /// Calculate the shortest rotation path to avoid 359° -> 1° going the long way
    private func calculateShortestRotation(from current: Double, to target: Double) -> Double {
        let normalizedCurrent = current.truncatingRemainder(dividingBy: 360)
        let normalizedTarget = target.truncatingRemainder(dividingBy: 360)
        
        var delta = normalizedTarget - normalizedCurrent
        
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        
        return current + delta
    }
}

/// Cardinal direction markers around the compass
struct CardinalMarkersView: View {
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 8
            
            ZStack {
                // Major tick marks (N, E, S, W)
                ForEach([0, 90, 180, 270], id: \.self) { angle in
                    TickMark(length: 10, width: 2)
                        .fill(Color.saltyBlue)
                        .position(
                            x: center.x + radius * CGFloat(sin(Double(angle) * .pi / 180)),
                            y: center.y - radius * CGFloat(cos(Double(angle) * .pi / 180))
                        )
                        .rotationEffect(.degrees(Double(angle)), anchor: .center)
                }
                
                // Minor tick marks (every 30°)
                ForEach([30, 60, 120, 150, 210, 240, 300, 330], id: \.self) { angle in
                    TickMark(length: 5, width: 1)
                        .fill(Color.saltyTextSecondary.opacity(0.5))
                        .position(
                            x: center.x + radius * CGFloat(sin(Double(angle) * .pi / 180)),
                            y: center.y - radius * CGFloat(cos(Double(angle) * .pi / 180))
                        )
                        .rotationEffect(.degrees(Double(angle)), anchor: .center)
                }
                
                // N marker (special highlight)
                Text("N")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.saltyOrange)
                    .position(
                        x: center.x,
                        y: center.y - radius + 16
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
