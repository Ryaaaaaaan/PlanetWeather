import SwiftUI

// MARK: - Planet Type Enum

/// Classifies celestial bodies by their physical composition
enum PlanetType: String, Codable, CaseIterable {
    case terrestrial = "Tellurique"
    case gasGiant = "Géante Gazeuse"
    case iceGiant = "Géante de Glace"
    case dwarfPlanet = "Planète Naine"
    case star = "Étoile"
    
    var localizedName: String {
        return String(localized: String.LocalizationValue(self.rawValue))
    }
}

// MARK: - Planet Model

/// Represents a celestial body in the solar system with scientific data
/// Data sourced from NASA Planetary Fact Sheets
struct Planet: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let type: PlanetType
    
    // Physical Properties
    /// Surface gravity relative to Earth (Earth = 1.0)
    let gravity: Double
    
    /// Mean distance from the Sun in millions of kilometers (AU converted)
    let distanceFromSun: Double
    
    /// Mean surface/cloud-top temperature in Celsius
    let meanTemperature: Double
    
    /// Length of a solar day in Earth hours
    let dayDurationHours: Double
    
    /// Atmospheric pressure at surface in Bar (Earth = 1.0)
    /// For gas giants, this is measured at the 1-bar level
    let atmosphericPressure: Double?
    
    /// Primary atmospheric composition (e.g., "96% CO2, 3.5% N2")
    let atmosphereComposition: String
    
    /// Orbital period around the Sun in Earth days
    let orbitalPeriodDays: Double
    
    /// Number of known moons
    let moonCount: Int
    
    /// Whether this body has ring system
    let hasRings: Bool
    
    // MARK: - UI Properties
    
    /// Primary gradient colors for the background theme
    let themeColors: [String] // Hex codes stored for Codable compatibility
    
    /// SF Symbol name for the planet icon
    let symbolName: String
    
    // MARK: - Computed Properties
    
    /// Converts theme color hex strings to SwiftUI Colors
    var gradientColors: [Color] {
        themeColors.map { Color(hex: $0) }
    }
    
    /// Distance from Sun formatted with unit
    var formattedDistance: String {
        if distanceFromSun >= 1000 {
            return String(format: "%.1f Mrd km", distanceFromSun / 1000)
        }
        return String(format: "%.1f M km", distanceFromSun)
    }
    
    /// Day duration formatted appropriately
    var formattedDayDuration: String {
        if dayDurationHours < 24 {
            return String(format: "%.1f heures", dayDurationHours)
        } else if dayDurationHours < 48 {
            return String(format: "%.1f heure", dayDurationHours)
        } else {
            let days = dayDurationHours / 24
            return String(format: "%.0f jours terrestres", days)
        }
    }
    
    /// Gravity formatted with Earth comparison
    var formattedGravity: String {
        String(format: "%.2f g", gravity)
    }
    
    /// Temperature with unit
    var formattedTemperature: String {
        String(format: "%.0f°C", meanTemperature)
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Initialize Color from hex string (supports #RRGGBB and RRGGBB formats)
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (128, 128, 128) // Fallback gray
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}


// MARK: - Planet Comparison & Sorting

extension Planet {
    /// Compare planets by distance from Sun (for ordering in PageView)
    static func < (lhs: Planet, rhs: Planet) -> Bool {
        lhs.distanceFromSun < rhs.distanceFromSun
    }
}

// MARK: - Cinematic Scale

extension Planet {
    /// Relative scale for visual representation (Cinematic Scale)
    /// Earth = 1.0
    var relativeScale: Float {
        switch id {
        case "sun": return 5.0
        case "jupiter": return 2.8
        case "saturn": return 2.5
        case "uranus", "neptune": return 1.8
        case "earth", "venus": return 1.0
        case "mars": return 0.6
        case "mercury", "pluto", "moon": return 0.4
        default: return 1.0
        }
    }
}
