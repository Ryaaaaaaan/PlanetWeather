import SwiftUI

// MARK: - Hourly Forecast Card (Apple Weather iOS 26 Style)

/// Horizontal scrolling hourly forecast with Liquid Glass background
struct PlanetHourlyForecastCard: View {
    let forecasts: [PlanetHourlyForecast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            Label("PRÉVISIONS HORAIRES", systemImage: "clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
            
            Divider()
                .background(.white.opacity(0.2))
            
            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(forecasts) { forecast in
                        VStack(spacing: 12) {
                            // Hour
                            Text(forecast.hour)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            // Icon
                            Image(systemName: forecast.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(iconColor(for: forecast.icon))
                                .frame(height: 30)
                            
                            // Temperature
                            Text("\(forecast.temperature)°")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(16)
        // Liquid Glass effect
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private func iconColor(for icon: String) -> Color {
        switch icon {
        case "sun.max.fill", "sun.max":
            return .yellow
        case "cloud.sun", "cloud.sun.fill":
            return .white
        case "cloud", "cloud.fill":
            return .gray
        case "cloud.rain", "cloud.rain.fill":
            return .cyan
        case "snowflake":
            return .cyan
        case "wind":
            return .white.opacity(0.8)
        case "hurricane", "tornado":
            return .orange
        case "moon", "moon.fill", "moon.stars", "moon.stars.fill":
            return .white.opacity(0.9)
        case "thermometer.sun.fill":
            return .orange
        default:
            return .white
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        PlanetHourlyForecastCard(forecasts: [
            PlanetHourlyForecast(hour: "Minuit", icon: "cloud.rain", temperature: 459),
            PlanetHourlyForecast(hour: "1h", icon: "cloud.rain", temperature: 458),
            PlanetHourlyForecast(hour: "2h", icon: "cloud.rain", temperature: 460),
            PlanetHourlyForecast(hour: "3h", icon: "cloud.rain", temperature: 457),
            PlanetHourlyForecast(hour: "4h", icon: "cloud.rain", temperature: 459),
            PlanetHourlyForecast(hour: "5h", icon: "cloud.rain", temperature: 458)
        ])
        .padding()
    }
}
