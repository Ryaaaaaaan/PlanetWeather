import SwiftUI

// MARK: - Planet Background (Starfield + Gradient)

/// Background view with starfield and planet-adaptive gradient
struct PlanetBackground: View {
    let planet: Planet
    
    private var gradientColors: [Color] {
        switch planet.id {
        case "sun":
            return [.orange.opacity(0.4), .red.opacity(0.2), .black]
        case "mercury":
            return [.gray.opacity(0.3), .black]
        case "venus":
            return [.yellow.opacity(0.25), .orange.opacity(0.15), .black]
        case "earth":
            return [.blue.opacity(0.25), .cyan.opacity(0.1), .black]
        case "mars":
            return [.red.opacity(0.3), .orange.opacity(0.15), .black]
        case "jupiter":
            return [.orange.opacity(0.25), .brown.opacity(0.15), .black]
        case "saturn":
            return [Color(hex: "E4C97A").opacity(0.25), .brown.opacity(0.1), .black]
        case "uranus":
            return [.cyan.opacity(0.3), .teal.opacity(0.15), .black]
        case "neptune":
            return [.blue.opacity(0.35), .indigo.opacity(0.2), .black]
        case "pluto":
            return [.brown.opacity(0.2), .gray.opacity(0.15), .black]
        default:
            return [.gray.opacity(0.2), .black]
        }
    }
    
    var body: some View {
        ZStack {
            // Layer 1: Deep space black
            Color.black
            
            // Layer 2: Starfield texture (if available)
            if let starfieldImage = UIImage(named: "starmap_background") {
                Image(uiImage: starfieldImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .opacity(0.6)
            } else {
                // Fallback: Generated stars
                GeneratedStarfield()
            }
            
            // Layer 3: Planet-colored gradient overlay
            LinearGradient(
                colors: gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Generated Starfield (Fallback)

struct GeneratedStarfield: View {
    private let starCount = 150
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for _ in 0..<starCount {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let radius = CGFloat.random(in: 0.5...2)
                    let opacity = Double.random(in: 0.3...1.0)
                    
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Ellipse().path(in: rect), with: .color(.white.opacity(opacity)))
                }
            }
        }
    }
}

#Preview {
    PlanetBackground(planet: Planet(
        id: "venus",
        name: "Vénus",
        type: .terrestrial,
        gravity: 0.91,
        distanceFromSun: 108.2,
        meanTemperature: 458,
        dayDurationHours: 2802,
        atmosphericPressure: 92,
        atmosphereComposition: "CO2 96.5%",
        orbitalPeriodDays: 225,
        moonCount: 0,
        hasRings: false,
        themeColors: ["E4C97A"],
        symbolName: "sparkles"
    ))
}
