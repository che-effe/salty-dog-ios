import SwiftUI

/// Animated ocean wave view that creates a delightful nautical ambiance
struct WaveAnimationView: View {
    let isActive: Bool
    
    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    @State private var phase3: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient (ocean depth effect)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.saltyDarkPanel.opacity(0.3),
                        Color.saltyBlue.opacity(0.2)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Back wave (slowest, deepest blue)
                WaveShape(
                    amplitude: 15,
                    frequency: 1.2,
                    phase: phase3
                )
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.saltyBlue.opacity(0.3),
                            Color.saltyBlue.opacity(0.15)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: -10)
                // Back wave (slowest, deepest blue)
                WaveShape(
                    amplitude: 8,
                    frequency: 1.05,
                    phase: phase3
                )
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.saltyBlue.opacity(0.3),
                            Color.saltyBlue.opacity(0.15)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: -5)
                // Middle wave
                WaveShape(
                    amplitude: 10,
                    frequency: 1.0,
                    phase: phase2
                )
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.saltyBlue.opacity(0.5),
                            Color.saltyBlue.opacity(0.25)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: 10)
                
                // Front wave (fastest, brightest)
                WaveShape(
                    amplitude: 8,
                    frequency: 0.5,
                    phase: phase1
                )
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.saltyBlue.opacity(0.7),
                            Color.saltyBlue.opacity(0.4)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                ).offset(y: 20)
                
                // Foam highlights on front wave
                WaveShape(
                    amplitude: 10,
                    frequency: 0.2,
                    phase: phase1
                )
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.saltyBlue.opacity(0.9),
                            Color.saltyBlue.opacity(1)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .offset(y: 40)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isActive) { _, active in
            if active {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        // Front wave - fastest
        withAnimation(
            .linear(duration: 2.0)
            .repeatForever(autoreverses: false)
        ) {
            phase1 = .pi * 2
        }
        
        // Middle wave - medium speed
        withAnimation(
            .linear(duration: 2.8)
            .repeatForever(autoreverses: false)
        ) {
            phase2 = .pi * 2
        }
        
        // Back wave - slowest
        withAnimation(
            .linear(duration: 3.5)
            .repeatForever(autoreverses: false)
        ) {
            phase3 = .pi * 2
        }
    }
}

/// Custom wave shape using sine wave mathematics
struct WaveShape: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midHeight = height * 0.4
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: midHeight))
        
        // Draw wave using sine function
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX * frequency * .pi * 2) + phase)
            let y = midHeight + (amplitude * sine)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        
        return path
    }
}

/// A smaller, more subtle wave for compact spaces
struct CompactWaveView: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        WaveShape(amplitude: 4, frequency: 1.5, phase: phase)
            .fill(Color.saltyBlue.opacity(0.4))
            .onAppear {
                withAnimation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = .pi * 2
                }
            }
    }
}

#Preview("Wave Animation") {
    VStack {
        Spacer()
        WaveAnimationView(isActive: true)
            .frame(height: 80)
    }
    .background(Color.black)
}
