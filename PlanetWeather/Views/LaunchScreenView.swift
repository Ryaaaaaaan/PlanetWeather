import SwiftUI

// MARK: - Launch Screen View

/// Premium animated launch screen with fluid background
/// Creates an immersive first impression while the app loads
struct LaunchScreenView: View {
    
    // MARK: - State
    
    @State private var isAnimating = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    
    /// Callback when launch animation completes
    var onComplete: (() -> Void)?
    
    // MARK: - Theme Colors (Neutral cosmic theme)
    
    private let themeColors: [Color] = [
        Color(hex: "#0D1B2A"),  // Deep space blue
        Color(hex: "#1B263B"),  // Dark navy
        Color(hex: "#415A77"),  // Muted steel blue
        Color(hex: "#778DA9")   // Light cosmic gray
    ]
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Animated fluid background
            fluidBackground
                .opacity(backgroundOpacity)
            
            // Content
            VStack(spacing: 20) {
                Spacer()
                
                // Logo/Icon
                logoView
                
                // Title
                titleView
                
                Spacer()
                
                // Loading indicator
                loadingIndicator
                    .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Fluid Background
    
    private var fluidBackground: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(hex: "#0D1B2A"),
                        Color(hex: "#1B263B")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Animated orbs
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeColors[2].opacity(0.4),
                                themeColors[2].opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.5
                        )
                    )
                    .frame(width: geometry.size.width * 0.8)
                    .offset(
                        x: isAnimating ? 50 : -50,
                        y: isAnimating ? -100 : -50
                    )
                    .blur(radius: 60)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                themeColors[3].opacity(0.3),
                                themeColors[3].opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: geometry.size.width * 0.4
                        )
                    )
                    .frame(width: geometry.size.width * 0.6)
                    .offset(
                        x: isAnimating ? -30 : 30,
                        y: isAnimating ? 150 : 100
                    )
                    .blur(radius: 40)
                
                // Subtle stars/particles
                starsOverlay(in: geometry.size)
            }
        }
    }
    
    // MARK: - Stars Overlay
    
    private func starsOverlay(in size: CGSize) -> some View {
        Canvas { context, canvasSize in
            // Generate deterministic star positions
            let starCount = 50
            for i in 0..<starCount {
                let seed = Double(i * 127 + 31)
                let x = (sin(seed) * 0.5 + 0.5) * canvasSize.width
                let y = (cos(seed * 1.3) * 0.5 + 0.5) * canvasSize.height
                let radius = (sin(seed * 0.7) * 0.5 + 0.5) * 1.5 + 0.5
                let opacity = (cos(seed * 0.9) * 0.5 + 0.5) * 0.6 + 0.2
                
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
        .opacity(isAnimating ? 0.8 : 0.3)
    }
    
    // MARK: - Logo View
    
    private var logoView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#4169E1").opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(isAnimating ? 1.2 : 0.9)
            
            // Planet sphere
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#4169E1"),
                            Color(hex: "#1E3A8A"),
                            Color(hex: "#0D1B2A")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    // Glass highlight
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .center
                            )
                        )
                        .padding(8)
                )
                .overlay(
                    // Subtle ring
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.5),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 100, height: 25)
                        .rotationEffect(.degrees(-15))
                        .offset(y: 5)
                )
                .shadow(color: Color(hex: "#4169E1").opacity(0.5), radius: 20, x: 0, y: 10)
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }
    
    // MARK: - Title View
    
    private var titleView: some View {
        VStack(spacing: 8) {
            Text("Cosmic")
                .font(.system(size: 42, weight: .light, design: .rounded))
                .tracking(4)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 20)
            
            Text("Weather")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .tracking(8)
                .foregroundStyle(.white.opacity(0.6))
                .opacity(showSubtitle ? 1 : 0)
                .offset(y: showSubtitle ? 0 : 10)
        }
    }
    
    // MARK: - Loading Indicator
    
    private var loadingIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.white.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .opacity(showSubtitle ? 1 : 0)
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Background fade in
        withAnimation(.easeOut(duration: 0.5)) {
            backgroundOpacity = 1
        }
        
        // Logo entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Title fade in
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            showTitle = true
        }
        
        // Subtitle fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showSubtitle = true
        }
        
        // Background animation loop
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true).delay(0.3)) {
            isAnimating = true
        }
        
        // Complete after animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            onComplete?()
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchScreenView()
}
