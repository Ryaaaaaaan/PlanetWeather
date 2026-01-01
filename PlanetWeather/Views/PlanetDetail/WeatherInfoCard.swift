import SwiftUI

// MARK: - Weather Info Card (Apple Weather iOS 26 Style)

/// Generic info card with icon, value, unit, and optional detail
struct WeatherInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    var detail: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with SF Symbol
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)
            
            Spacer()
            
            // Main value
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 34, weight: .regular, design: .rounded))
                    .foregroundStyle(.white)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            
            // Optional detail
            if let detail = detail {
                Text(detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        // Liquid Glass effect
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            WeatherInfoCard(
                icon: "wind",
                title: "VENT",
                value: "405",
                unit: "km/h",
                detail: "Direction: Est"
            )
            
            WeatherInfoCard(
                icon: "aqi.medium",
                title: "ATMOSPHÈRE",
                value: "92.000",
                unit: "Bar",
                detail: "CO2 96.5%, N2 3.5%"
            )
            
            WeatherInfoCard(
                icon: "arrow.down.to.line",
                title: "GRAVITÉ",
                value: "0.91",
                unit: "g"
            )
            
            WeatherInfoCard(
                icon: "moon.stars",
                title: "LUNES",
                value: "0",
                unit: ""
            )
        }
        .padding()
    }
}
