import Foundation

// MARK: - Weather Condition Type Enum

/// Represents various weather phenomena across the solar system
/// Includes both terrestrial and extraterrestrial conditions
enum WeatherConditionType: String, Codable, CaseIterable {
    // Terrestrial & Mars Conditions
    case clear = "Clair"
    case partlyCloudy = "Partiellement nuageux"
    case cloudy = "Nuageux"
    case dustStorm = "Tempête de poussière"
    case dust = "Poussière en suspension"
    case fog = "Brouillard"

    case frost = "Givre"
    
    // Earth Standard Conditions
    case drizzle = "Bruine"
    case rain = "Pluie"
    case showers = "Averses"
    case snow = "Neige"
    case thunderstorm = "Orage"
    
    // Venus-like Conditions
    case acidRain = "Pluie acide"
    case sulfuricClouds = "Nuages sulfuriques"
    case extremeGreenhouse = "Effet de serre extrême"
    
    // Gas Giant Conditions
    case hurricaneStorm = "Tempête cyclonique"
    case anticyclonicStorm = "Tempête anticyclonique"
    case bandedClouds = "Bandes nuageuses"
    case ammoniaClouds = "Nuages d'ammoniac"
    case methaneClouds = "Nuages de méthane"
    case diamondRain = "Pluie de diamants"
    
    // Space Weather (Sun & General)
    case solarWind = "Vent solaire"
    case solarFlare = "Éruption solaire"
    case geomagneticStorm = "Tempête géomagnétique"
    case coronalMassEjection = "Éjection de masse coronale"
    case quiet = "Calme solaire"
    
    // Extreme Conditions
    case extremeCold = "Froid extrême"
    case extremeHeat = "Chaleur extrême"
    case noAtmosphere = "Pas d'atmosphère"
    case cryovolcanism = "Cryovolcanisme"
    
    // MARK: - Computed Properties
    
    var localizedName: String {
        return String(localized: String.LocalizationValue(self.rawValue))
    }
    
    /// SF Symbol name for the weather condition
    var symbolName: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy:
            return "cloud.fill"
        case .dustStorm:
            return "sun.dust.fill"
        case .dust:
            return "aqi.medium"
        case .fog:
            return "cloud.fog.fill"
        case .frost:
            return "snowflake"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .rain:
            return "cloud.rain.fill"
        case .showers:
            return "cloud.heavyrain.fill"
        case .snow:
            return "snow"
        case .thunderstorm:
            return "cloud.bolt.rain.fill"
        case .acidRain:
            return "cloud.rain.fill"
        case .sulfuricClouds:
            return "smoke.fill"
        case .extremeGreenhouse:
            return "thermometer.sun.fill"
        case .hurricaneStorm:
            return "hurricane"
        case .anticyclonicStorm:
            return "tropicalstorm"
        case .bandedClouds:
            return "cloud.fill"
        case .ammoniaClouds:
            return "cloud.fill"
        case .methaneClouds:
            return "cloud.fill"
        case .diamondRain:
            return "sparkles"
        case .solarWind:
            return "wind"
        case .solarFlare:
            return "sun.max.trianglebadge.exclamationmark.fill"
        case .geomagneticStorm:
            return "bolt.trianglebadge.exclamationmark.fill"
        case .coronalMassEjection:
            return "burst.fill"
        case .quiet:
            return "sun.min.fill"
        case .extremeCold:
            return "thermometer.snowflake"
        case .extremeHeat:
            return "thermometer.sun.fill"
        case .noAtmosphere:
            return "circle.dashed"
        case .cryovolcanism:
            return "mountain.2.fill"
        }
    }
    
    /// Severity level for UI styling (0-3)
    var severity: Int {
        switch self {
        case .clear, .quiet, .partlyCloudy:
            return 0
        case .cloudy, .dust, .fog, .frost, .bandedClouds, .ammoniaClouds, .methaneClouds, .drizzle:
            return 1
        case .dustStorm, .acidRain, .sulfuricClouds, .hurricaneStorm, .anticyclonicStorm, .solarWind, .extremeCold, .extremeHeat, .diamondRain, .cryovolcanism, .rain, .showers, .snow:
            return 2
        case .extremeGreenhouse, .solarFlare, .geomagneticStorm, .coronalMassEjection, .noAtmosphere, .thunderstorm:
            return 3
        }
    }
}

// MARK: - Weather Condition Model

/// Current weather state for a celestial body
/// Combines simulated and real-time data when available
struct WeatherCondition: Codable, Equatable {
    /// Unique identifier
    let id: UUID
    
    /// Planet ID this condition belongs to
    let planetId: String
    
    /// Current temperature in Celsius
    let temperature: Double
    
    /// Temperature variation (high for the day)
    let temperatureHigh: Double
    
    /// Temperature variation (low for the day)
    let temperatureLow: Double
    
    /// Wind speed in km/h
    let windSpeed: Double
    
    /// Wind direction in degrees (0-360, 0 = North)
    let windDirection: Double
    
    /// Atmospheric pressure in Bar (relative to Earth sea level)
    let pressure: Double?
    
    /// Current weather condition type
    let conditionType: WeatherConditionType
    
    /// Visibility in kilometers (nil if not applicable)
    let visibility: Double?
    
    /// Solar flux at planet surface in W/m² (inverse square law from Sun)
    let solarFlux: Double
    
    /// Timestamp of this weather reading
    let timestamp: Date
    
    /// Whether this data is from live API or simulation
    let isSimulated: Bool
    
    /// Sol number for Mars (nil for other planets)
    let sol: Int?
    
    // MARK: - Computed Properties
    
    /// Formatted temperature string
    var formattedTemperature: String {
        String(format: "%.0f°", temperature)
    }
    
    /// Formatted high/low range
    var formattedHighLow: String {
        String(format: "H:%.0f° L:%.0f°", temperatureHigh, temperatureLow)
    }
    
    /// Formatted wind with direction
    var formattedWind: String {
        let direction = windDirectionCardinal
        return String(format: "%@ %.0f km/h", direction, windSpeed)
    }
    
    /// Cardinal direction from degrees
    var windDirectionCardinal: String {
        let directions = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
        let index = Int((windDirection + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return directions[index]
    }
    
    /// Formatted pressure
    var formattedPressure: String {
        guard let pressure = pressure else { return "N/A" }
        if pressure < 0.01 {
            return String(format: "%.2e Bar", pressure)
        }
        return String(format: "%.3f Bar", pressure)
    }
    
    /// Formatted visibility
    var formattedVisibility: String {
        guard let visibility = visibility else { return "N/A" }
        if visibility > 100 {
            return "Excellente"
        } else if visibility > 50 {
            return String(format: "%.0f km", visibility)
        } else if visibility > 10 {
            return "Réduite"
        } else {
            return "Très faible"
        }
    }
    
    /// UV Index equivalent based on solar flux
    var uvIndex: Int {
        // Earth receives ~1361 W/m² at atmosphere top
        // We map flux to UV index scale (0-11+)
        let earthFlux = 1361.0
        let ratio = solarFlux / earthFlux
        return min(Int(ratio * 11), 15)
    }
    
    /// UV Index description
    var uvDescription: String {
        switch uvIndex {
        case 0...2:
            return "Faible"
        case 3...5:
            return "Modéré"
        case 6...7:
            return "Élevé"
        case 8...10:
            return "Très élevé"
        default:
            return "Extrême"
        }
    }
    
    // MARK: - Initializers
    
    init(
        id: UUID = UUID(),
        planetId: String,
        temperature: Double,
        temperatureHigh: Double,
        temperatureLow: Double,
        windSpeed: Double,
        windDirection: Double,
        pressure: Double?,
        conditionType: WeatherConditionType,
        visibility: Double? = nil,
        solarFlux: Double,
        timestamp: Date = Date(),
        isSimulated: Bool = true,
        sol: Int? = nil
    ) {
        self.id = id
        self.planetId = planetId
        self.temperature = temperature
        self.temperatureHigh = temperatureHigh
        self.temperatureLow = temperatureLow
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.pressure = pressure
        self.conditionType = conditionType
        self.visibility = visibility
        self.solarFlux = solarFlux
        self.timestamp = timestamp
        self.isSimulated = isSimulated
        self.sol = sol
    }
}

// MARK: - Hourly Forecast

/// Represents a single hour in the forecast
struct HourlyForecast: Codable, Identifiable {
    let id: UUID
    let hour: Int // 0-23
    let temperature: Double
    let conditionType: WeatherConditionType
    let windSpeed: Double
    
    init(id: UUID = UUID(), hour: Int, temperature: Double, conditionType: WeatherConditionType, windSpeed: Double) {
        self.id = id
        self.hour = hour
        self.temperature = temperature
        self.conditionType = conditionType
        self.windSpeed = windSpeed
    }
    
    var formattedHour: String {
        if hour == 0 {
            return "Minuit"
        } else if hour == 12 {
            return "Midi"
        }
        return "\(hour)h"
    }
}

// MARK: - Daily Forecast

/// Represents a single day in the 10-day forecast
struct DailyForecast: Codable, Identifiable {
    let id: UUID
    let date: Date
    let temperatureHigh: Double
    let temperatureLow: Double
    let conditionType: WeatherConditionType
    let precipitationProbability: Double // 0-1
    
    init(
        id: UUID = UUID(),
        date: Date,
        temperatureHigh: Double,
        temperatureLow: Double,
        conditionType: WeatherConditionType,
        precipitationProbability: Double = 0
    ) {
        self.id = id
        self.date = date
        self.temperatureHigh = temperatureHigh
        self.temperatureLow = temperatureLow
        self.conditionType = conditionType
        self.precipitationProbability = precipitationProbability
    }
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).capitalized
    }
}
