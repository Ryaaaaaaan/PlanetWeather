import Foundation

// MARK: - Planet Weather Data

/// Weather-like data model for planet detail view (Apple Weather iOS 26 style)
struct PlanetWeatherData {
    
    // MARK: - Temperature
    let temperature: Int           // Current "temperature" in Celsius
    let highTemp: Int              // Daily high
    let lowTemp: Int               // Daily low
    
    // MARK: - Condition
    let condition: String          // e.g., "Pluie acide", "Tempête de poussière"
    let conditionIcon: String      // SF Symbol name
    
    // MARK: - Atmosphere
    let pressure: String           // e.g., "92.000"
    let pressureUnit: String       // e.g., "Bar"
    let atmosphereComposition: String  // e.g., "CO2 96.5%, N2 3.5%"
    
    // MARK: - Wind
    let windSpeed: Int             // km/h
    let windDirection: String      // e.g., "E", "NW"
    
    // MARK: - Physical Properties
    let gravity: String            // e.g., "0.91"
    let solarDayDuration: String   // e.g., "117 jours"
    let orbitalPeriod: String      // e.g., "225"
    let moonCount: Int
    
    // MARK: - Time
    let solarTime: String          // e.g., "14:32"
    
    // MARK: - Hourly Forecasts
    let hourlyForecasts: [PlanetHourlyForecast]
}

// MARK: - Planet Hourly Forecast (distinct from WeatherCondition.HourlyForecast)

struct PlanetHourlyForecast: Identifiable {
    let id = UUID()
    let hour: String               // e.g., "Minuit", "1h", "14h"
    let icon: String               // SF Symbol
    let temperature: Int
}

// MARK: - Static Data Generator

extension PlanetWeatherData {
    
    /// Generate realistic weather data for each planet
    static func generate(for planet: Planet) -> PlanetWeatherData {
        switch planet.id {
        case "sun":
            return PlanetWeatherData(
                temperature: 5500,
                highTemp: 5778,
                lowTemp: 5500,
                condition: "Couronne solaire",
                conditionIcon: "sun.max.fill",
                pressure: "N/A",
                pressureUnit: "",
                atmosphereComposition: "H 73%, He 25%",
                windSpeed: 400,
                windDirection: "Radial",
                gravity: "28.0",
                solarDayDuration: "25 jours",
                orbitalPeriod: "N/A",
                moonCount: 0,
                solarTime: "--:--",
                hourlyForecasts: generateSunForecasts()
            )
            
        case "mercury":
            return PlanetWeatherData(
                temperature: 167,
                highTemp: 430,
                lowTemp: -180,
                condition: "Extrêmes thermiques",
                conditionIcon: "thermometer.sun.fill",
                pressure: "0",
                pressureUnit: "Bar",
                atmosphereComposition: "Quasi inexistante",
                windSpeed: 0,
                windDirection: "--",
                gravity: "0.38",
                solarDayDuration: "176 jours",
                orbitalPeriod: "88",
                moonCount: 0,
                solarTime: "12:00",
                hourlyForecasts: generateMercuryForecasts()
            )
            
        case "venus":
            return PlanetWeatherData(
                temperature: 458,
                highTemp: 471,
                lowTemp: 447,
                condition: "Pluie acide",
                conditionIcon: "cloud.rain",
                pressure: "92.000",
                pressureUnit: "Bar",
                atmosphereComposition: "CO2 96.5%, N2 3.5%",
                windSpeed: 405,
                windDirection: "E",
                gravity: "0.91",
                solarDayDuration: "117 jours",
                orbitalPeriod: "225",
                moonCount: 0,
                solarTime: "07:59",
                hourlyForecasts: generateVenusForecasts()
            )
            
        case "earth":
            return PlanetWeatherData(
                temperature: 15,
                highTemp: 22,
                lowTemp: 8,
                condition: "Partiellement nuageux",
                conditionIcon: "cloud.sun",
                pressure: "1.013",
                pressureUnit: "Bar",
                atmosphereComposition: "N2 78%, O2 21%",
                windSpeed: 25,
                windDirection: "SW",
                gravity: "1.00",
                solarDayDuration: "24 heures",
                orbitalPeriod: "365",
                moonCount: 1,
                solarTime: "14:32",
                hourlyForecasts: generateEarthForecasts()
            )
            
        case "mars":
            return PlanetWeatherData(
                temperature: -63,
                highTemp: -5,
                lowTemp: -87,
                condition: "Tempête de poussière",
                conditionIcon: "wind",
                pressure: "0.006",
                pressureUnit: "Bar",
                atmosphereComposition: "CO2 95%, N2 2.7%",
                windSpeed: 120,
                windDirection: "NW",
                gravity: "0.38",
                solarDayDuration: "24h 37min",
                orbitalPeriod: "687",
                moonCount: 2,
                solarTime: "10:15",
                hourlyForecasts: generateMarsForecasts()
            )
            
        case "jupiter":
            return PlanetWeatherData(
                temperature: -110,
                highTemp: -108,
                lowTemp: -145,
                condition: "Grande Tache Rouge",
                conditionIcon: "hurricane",
                pressure: ">1000",
                pressureUnit: "Bar",
                atmosphereComposition: "H2 89%, He 10%",
                windSpeed: 550,
                windDirection: "Zonales",
                gravity: "2.53",
                solarDayDuration: "9h 56min",
                orbitalPeriod: "4333",
                moonCount: 95,
                solarTime: "06:42",
                hourlyForecasts: generateJupiterForecasts()
            )
            
        case "saturn":
            return PlanetWeatherData(
                temperature: -139,
                highTemp: -130,
                lowTemp: -178,
                condition: "Vents violents",
                conditionIcon: "wind",
                pressure: ">1000",
                pressureUnit: "Bar",
                atmosphereComposition: "H2 96%, He 3%",
                windSpeed: 1800,
                windDirection: "E",
                gravity: "1.07",
                solarDayDuration: "10h 33min",
                orbitalPeriod: "10759",
                moonCount: 146,
                solarTime: "18:20",
                hourlyForecasts: generateSaturnForecasts()
            )
            
        case "uranus":
            return PlanetWeatherData(
                temperature: -197,
                highTemp: -193,
                lowTemp: -224,
                condition: "Calme glacial",
                conditionIcon: "snowflake",
                pressure: ">1000",
                pressureUnit: "Bar",
                atmosphereComposition: "H2 83%, He 15%, CH4 2%",
                windSpeed: 900,
                windDirection: "Rétrograde",
                gravity: "0.89",
                solarDayDuration: "17h 14min",
                orbitalPeriod: "30687",
                moonCount: 28,
                solarTime: "22:05",
                hourlyForecasts: generateUranusForecasts()
            )
            
        case "neptune":
            return PlanetWeatherData(
                temperature: -201,
                highTemp: -198,
                lowTemp: -218,
                condition: "Vents supersoniques",
                conditionIcon: "tornado",
                pressure: ">1000",
                pressureUnit: "Bar",
                atmosphereComposition: "H2 80%, He 19%, CH4 1%",
                windSpeed: 2100,
                windDirection: "W",
                gravity: "1.14",
                solarDayDuration: "16h 6min",
                orbitalPeriod: "60190",
                moonCount: 16,
                solarTime: "03:47",
                hourlyForecasts: generateNeptuneForecasts()
            )
            
        case "pluto":
            return PlanetWeatherData(
                temperature: -229,
                highTemp: -218,
                lowTemp: -240,
                condition: "Atmosphère gelée",
                conditionIcon: "snowflake",
                pressure: "0.00001",
                pressureUnit: "Bar",
                atmosphereComposition: "N2, CH4, CO traces",
                windSpeed: 0,
                windDirection: "--",
                gravity: "0.06",
                solarDayDuration: "6.4 jours",
                orbitalPeriod: "90560",
                moonCount: 5,
                solarTime: "05:12",
                hourlyForecasts: generatePlutoForecasts()
            )
            
        default:
            return generateDefault()
        }
    }
    
    // MARK: - Forecast Generators
    
    private static func generateVenusForecasts() -> [PlanetHourlyForecast] {
        let hours = ["Minuit", "1h", "2h", "3h", "4h", "5h", "6h", "7h", "8h", "9h", "10h", "11h"]
        return hours.map { hour in
            PlanetHourlyForecast(hour: hour, icon: "cloud.rain", temperature: 458 + Int.random(in: -5...5))
        }
    }
    
    private static func generateSunForecasts() -> [PlanetHourlyForecast] {
        let hours = ["Minuit", "1h", "2h", "3h", "4h", "5h", "6h", "7h", "8h", "9h", "10h", "11h"]
        return hours.map { hour in
            PlanetHourlyForecast(hour: hour, icon: "sun.max.fill", temperature: 5500 + Int.random(in: -100...100))
        }
    }
    
    private static func generateMercuryForecasts() -> [PlanetHourlyForecast] {
        let hours = ["Jour", "+1h", "+2h", "+3h", "+4h", "+5h", "Nuit", "+1h", "+2h", "+3h", "+4h", "+5h"]
        let temps = [430, 425, 400, 350, 200, 0, -100, -150, -170, -180, -175, -160]
        return zip(hours, temps).map { PlanetHourlyForecast(hour: $0, icon: $1 > 0 ? "sun.max.fill" : "moon.fill", temperature: $1) }
    }
    
    private static func generateEarthForecasts() -> [PlanetHourlyForecast] {
        let hours = ["14h", "15h", "16h", "17h", "18h", "19h", "20h", "21h", "22h", "23h", "0h", "1h"]
        let icons = ["cloud.sun", "sun.max", "sun.max", "cloud.sun", "cloud", "cloud", "moon.stars", "moon.stars", "moon", "moon", "moon", "moon"]
        let temps = [22, 24, 23, 20, 17, 14, 12, 10, 9, 8, 8, 7]
        return zip(zip(hours, icons), temps).map { PlanetHourlyForecast(hour: $0.0, icon: $0.1, temperature: $1) }
    }
    
    private static func generateMarsForecasts() -> [PlanetHourlyForecast] {
        let hours = ["10h", "11h", "12h", "13h", "14h", "15h", "16h", "17h", "18h", "19h", "20h", "21h"]
        return hours.enumerated().map { i, hour in
            let temp = -40 + (i < 6 ? i * 5 : (12 - i) * 5) - 25
            return PlanetHourlyForecast(hour: hour, icon: "wind", temperature: temp)
        }
    }
    
    private static func generateJupiterForecasts() -> [PlanetHourlyForecast] {
        let hours = ["6h", "7h", "8h", "9h", "10h", "11h", "12h", "13h", "14h", "15h", "16h", "0h"]
        return hours.map { hour in
            PlanetHourlyForecast(hour: hour, icon: "hurricane", temperature: -110 + Int.random(in: -10...10))
        }
    }
    
    private static func generateSaturnForecasts() -> [PlanetHourlyForecast] {
        let hours = ["18h", "19h", "20h", "21h", "22h", "23h", "0h", "1h", "2h", "3h", "4h", "5h"]
        return hours.map { hour in
            PlanetHourlyForecast(hour: hour, icon: "wind", temperature: -139 + Int.random(in: -15...15))
        }
    }
    
    private static func generateUranusForecasts() -> [PlanetHourlyForecast] {
        let hours = ["22h", "23h", "0h", "1h", "2h", "3h", "4h", "5h", "6h", "7h", "8h", "9h"]
        return hours.map { hour in
            PlanetHourlyForecast(hour: hour, icon: "snowflake", temperature: -197 + Int.random(in: -10...10))
        }
    }
    
    private static func generateNeptuneForecasts() -> [PlanetHourlyForecast] {
        let hours = ["3h", "4h", "5h", "6h", "7h", "8h", "9h", "10h", "11h", "12h", "13h", "14h"]
        return hours.map { hour in
            PlanetHourlyForecast(hour: hour, icon: "tornado", temperature: -201 + Int.random(in: -8...8))
        }
    }
    
    private static func generatePlutoForecasts() -> [PlanetHourlyForecast] {
        let hours = ["5h", "6h", "7h", "8h", "9h", "10h", "11h", "12h", "13h", "14h", "15h", "16h"]
        return hours.map { hour in
            PlanetHourlyForecast(hour: hour, icon: "snowflake", temperature: -229 + Int.random(in: -5...5))
        }
    }
    
    private static func generateDefault() -> PlanetWeatherData {
        PlanetWeatherData(
            temperature: 0,
            highTemp: 10,
            lowTemp: -10,
            condition: "Inconnu",
            conditionIcon: "questionmark.circle",
            pressure: "--",
            pressureUnit: "",
            atmosphereComposition: "--",
            windSpeed: 0,
            windDirection: "--",
            gravity: "--",
            solarDayDuration: "--",
            orbitalPeriod: "--",
            moonCount: 0,
            solarTime: "--:--",
            hourlyForecasts: []
        )
    }
}
