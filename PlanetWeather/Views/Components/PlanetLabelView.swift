import SwiftUI

// MARK: - Planet Label View (Ultra-Minimalist)

/// Simple text label for planet name - Apple minimalist style
struct PlanetLabelView: View {
    let planetName: String
    let isVisible: Bool
    
    var body: some View {
        Text(planetName.uppercased())
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .tracking(4)
            .foregroundStyle(.white.opacity(0.85))
            .shadow(color: .black.opacity(0.5), radius: 8, y: 2)
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 8)
            .animation(.easeOut(duration: 0.35), value: isVisible)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 30) {
            Circle()
                .fill(Color.yellow)
                .frame(width: 60, height: 60)
                .shadow(color: .yellow.opacity(0.4), radius: 20)
            
            PlanetLabelView(planetName: "Saturne", isVisible: true)
        }
    }
}
