import SwiftUI

// MARK: - Planet Weather Header (Apple Weather iOS 26 Style)

/// Header with planet name, distance, giant temperature, and condition
struct PlanetWeatherHeader: View {
    let planetName: String
    let distance: String
    let temperature: Int
    let condition: String
    let conditionIcon: String
    let highTemp: Int
    let lowTemp: Int
    let solarTime: String
    
    var body: some View {
        VStack(spacing: 4) {
            // Planet Name
            Text(planetName)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(.white)
            
            // Distance with icon
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12))
                Text(distance)
                    .font(.system(size: 15, weight: .regular))
            }
            .foregroundStyle(.white.opacity(0.7))
            .padding(.bottom, 8)
            
            // Giant Temperature
            Text("\(temperature)°")
                .font(.system(size: 96, weight: .thin))
                .foregroundStyle(.white)
                .padding(.vertical, -10)
            
            // Condition with icon
            HStack(spacing: 6) {
                Image(systemName: conditionIcon)
                    .font(.system(size: 16))
                Text(condition)
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.9))
            .padding(.bottom, 4)
            
            // High/Low + Solar Time
            HStack(spacing: 16) {
                Text("H:\(highTemp)° L:\(lowTemp)°")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("•")
                
                HStack(spacing: 4) {
                    Image(systemName: "sun.min")
                        .font(.system(size: 12))
                    Text("\(solarTime)")
                        .font(.system(size: 16, weight: .regular))
                }
            }
            .foregroundStyle(.white.opacity(0.6))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        PlanetWeatherHeader(
            planetName: "Vénus",
            distance: "108.2 M km",
            temperature: 458,
            condition: "Pluie acide",
            conditionIcon: "cloud.rain",
            highTemp: 471,
            lowTemp: 447,
            solarTime: "07:59"
        )
    }
}
