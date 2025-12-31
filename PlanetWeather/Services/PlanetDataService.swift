import Foundation

// MARK: - Planet Data Service

/// Provides static planetary data sourced from NASA Planetary Fact Sheets
/// https://nssdc.gsfc.nasa.gov/planetary/factsheet/
///
/// This service contains hardcoded scientific data for all planets in the solar system
/// plus Pluto and the Sun for space weather display.
final class PlanetDataService {
    
    // MARK: - Singleton
    
    static let shared = PlanetDataService()
    
    private init() {}
    
    // MARK: - Planets Data (NASA Fact Sheet Values)
    
    /// All celestial bodies in order from the Sun
    /// Data last updated: December 2024 from NASA GSFC Planetary Fact Sheets
    static let allPlanets: [Planet] = [
        // SOLEIL
        Planet(
            id: "sun",
            name: "Soleil",
            type: .star,
            gravity: 27.96,                          // 274 m/s² → 27.96g
            distanceFromSun: 0,                      // Reference point
            meanTemperature: 5505,                   // Surface (photosphere) temperature °C
            dayDurationHours: 609.12,                // Sidereal rotation at equator (25.38 days)
            atmosphericPressure: nil,                // N/A for star
            atmosphereComposition: "Hydrogène 73%, Hélium 25%",
            orbitalPeriodDays: 0,                    // Center of system
            moonCount: 0,
            hasRings: false,
            themeColors: ["#FF6B00", "#FFB800", "#FFF4E0"],
            symbolName: "sun.max.fill"
        ),
        
        // MERCURE
        Planet(
            id: "mercury",
            name: "Mercure",
            type: .terrestrial,
            gravity: 0.378,                          // 3.7 m/s²
            distanceFromSun: 57.9,                   // Million km
            meanTemperature: 167,                    // Mean °C (range: -180 to 430)
            dayDurationHours: 4222.6,                // Solar day in Earth hours
            atmosphericPressure: 0,                  // Essentially no atmosphere
            atmosphereComposition: "Traces: O2, Na, H2, He, K",
            orbitalPeriodDays: 87.97,
            moonCount: 0,
            hasRings: false,
            themeColors: ["#8C8C8C", "#B5B5B5", "#D4D4D4"],
            symbolName: "circle.fill"
        ),
        
        // VÉNUS
        Planet(
            id: "venus",
            name: "Vénus",
            type: .terrestrial,
            gravity: 0.907,                          // 8.87 m/s²
            distanceFromSun: 108.2,
            meanTemperature: 464,                    // Hottest planet (greenhouse effect)
            dayDurationHours: 2802.0,                // 116.75 Earth days (retrograde)
            atmosphericPressure: 92.0,               // 92 bar!
            atmosphereComposition: "CO2 96.5%, N2 3.5%",
            orbitalPeriodDays: 224.7,
            moonCount: 0,
            hasRings: false,
            themeColors: ["#E8B86D", "#C9A055", "#8B6914"],
            symbolName: "flame.fill"
        ),
        
        // TERRE
        Planet(
            id: "earth",
            name: "Terre",
            type: .terrestrial,
            gravity: 1.0,                            // Reference: 9.81 m/s²
            distanceFromSun: 149.6,                  // 1 AU
            meanTemperature: 15,                     // Global average
            dayDurationHours: 24.0,                  // Reference
            atmosphericPressure: 1.0,                // Reference: 1 bar
            atmosphereComposition: "N2 78%, O2 21%, Ar 0.9%",
            orbitalPeriodDays: 365.25,
            moonCount: 1,
            hasRings: false,
            themeColors: ["#1E90FF", "#4169E1", "#228B22"],
            symbolName: "globe.europe.africa.fill"
        ),
        
        // MARS
        Planet(
            id: "mars",
            name: "Mars",
            type: .terrestrial,
            gravity: 0.379,                          // 3.71 m/s²
            distanceFromSun: 227.9,
            meanTemperature: -65,                    // Range: -125 to 20°C
            dayDurationHours: 24.66,                 // Sol ≈ 24h 37min
            atmosphericPressure: 0.006,              // 0.6% of Earth
            atmosphereComposition: "CO2 95.3%, N2 2.7%, Ar 1.6%",
            orbitalPeriodDays: 687.0,
            moonCount: 2,                            // Phobos, Deimos
            hasRings: false,
            themeColors: ["#CD5C5C", "#B22222", "#8B0000"],
            symbolName: "circle.fill"
        ),
        
        // JUPITER
        Planet(
            id: "jupiter",
            name: "Jupiter",
            type: .gasGiant,
            gravity: 2.528,                          // 24.79 m/s²
            distanceFromSun: 778.5,
            meanTemperature: -110,                   // Cloud top temperature
            dayDurationHours: 9.93,                  // Fastest rotation
            atmosphericPressure: 1.0,                // Measured at 1-bar level by convention
            atmosphereComposition: "H2 89.8%, He 10.2%",
            orbitalPeriodDays: 4331.0,               // ~11.86 Earth years
            moonCount: 95,                           // As of 2024
            hasRings: true,                          // Faint rings
            themeColors: ["#D4A574", "#C19A6B", "#8B7355"],
            symbolName: "hurricane"
        ),
        
        // SATURNE
        Planet(
            id: "saturn",
            name: "Saturne",
            type: .gasGiant,
            gravity: 1.065,                          // 10.44 m/s²
            distanceFromSun: 1432.0,
            meanTemperature: -140,                   // Cloud top
            dayDurationHours: 10.7,                  // 10h 42min
            atmosphericPressure: 1.0,                // 1-bar level
            atmosphereComposition: "H2 96.3%, He 3.25%",
            orbitalPeriodDays: 10747.0,              // ~29.4 Earth years
            moonCount: 146,                          // As of 2024
            hasRings: true,                          // Iconic rings
            themeColors: ["#F4D03F", "#DAA520", "#B8860B"],
            symbolName: "circle.circle.fill"
        ),
        
        // URANUS
        Planet(
            id: "uranus",
            name: "Uranus",
            type: .iceGiant,
            gravity: 0.886,                          // 8.69 m/s²
            distanceFromSun: 2867.0,
            meanTemperature: -195,                   // Coldest planetary atmosphere
            dayDurationHours: 17.24,                 // Retrograde rotation
            atmosphericPressure: 1.0,                // 1-bar level
            atmosphereComposition: "H2 82.5%, He 15.2%, CH4 2.3%",
            orbitalPeriodDays: 30589.0,              // ~84 Earth years
            moonCount: 28,
            hasRings: true,
            themeColors: ["#87CEEB", "#5F9EA0", "#4682B4"],
            symbolName: "circle.fill"
        ),
        
        // NEPTUNE
        Planet(
            id: "neptune",
            name: "Neptune",
            type: .iceGiant,
            gravity: 1.137,                          // 11.15 m/s²
            distanceFromSun: 4515.0,
            meanTemperature: -200,
            dayDurationHours: 16.11,
            atmosphericPressure: 1.0,                // 1-bar level
            atmosphereComposition: "H2 80%, He 19%, CH4 1.5%",
            orbitalPeriodDays: 59800.0,              // ~164 Earth years
            moonCount: 16,
            hasRings: true,
            themeColors: ["#4169E1", "#0000CD", "#00008B"],
            symbolName: "circle.fill"
        ),
        
        // PLUTON
        Planet(
            id: "pluto",
            name: "Pluton",
            type: .dwarfPlanet,
            gravity: 0.063,                          // 0.62 m/s²
            distanceFromSun: 5906.4,                 // Mean (highly elliptical orbit)
            meanTemperature: -225,
            dayDurationHours: 153.3,                 // 6.39 Earth days (retrograde)
            atmosphericPressure: 0.00001,            // ~10 µbar
            atmosphereComposition: "N2 ~99%, CH4, CO traces",
            orbitalPeriodDays: 90560.0,              // 248 Earth years
            moonCount: 5,                            // Charon, Nix, Hydra, Kerberos, Styx
            hasRings: false,
            themeColors: ["#DEB887", "#D2B48C", "#8B7765"],
            symbolName: "snowflake"
        )
    ]
    
    // MARK: - Access Methods
    
    /// Get all planets sorted by distance from Sun
    func getAllPlanets() -> [Planet] {
        return PlanetDataService.allPlanets
    }
    
    /// Get a specific planet by ID
    func getPlanet(byId id: String) -> Planet? {
        return PlanetDataService.allPlanets.first { $0.id == id }
    }
    
    /// Get planets by type
    func getPlanets(ofType type: PlanetType) -> [Planet] {
        return PlanetDataService.allPlanets.filter { $0.type == type }
    }
    
    /// Get only "true" planets (excluding Sun and Pluto)
    func getClassicalPlanets() -> [Planet] {
        return PlanetDataService.allPlanets.filter { planet in
            planet.type != .star && planet.type != .dwarfPlanet
        }
    }
    
    /// Get planet index for PageTabView
    func getIndex(for planet: Planet) -> Int {
        return PlanetDataService.allPlanets.firstIndex { $0.id == planet.id } ?? 0
    }
    
    // MARK: - Solar Flux Calculation
    
    /// Calculate solar flux at a given distance from the Sun
    /// Uses inverse square law: Flux = L / (4π * d²)
    /// - Parameter distanceMillionKm: Distance from Sun in million km
    /// - Returns: Solar flux in W/m²
    func calculateSolarFlux(atDistance distanceMillionKm: Double) -> Double {
        guard distanceMillionKm > 0 else { return 0 }
        
        // Solar luminosity constant at Earth's distance (1 AU = 149.6 million km)
        let earthDistance = 149.6
        let earthFlux = 1361.0 // W/m² (Solar constant)
        
        // Inverse square law
        let ratio = earthDistance / distanceMillionKm
        return earthFlux * (ratio * ratio)
    }
    
    /// Get pre-calculated solar flux for a planet
    func getSolarFlux(for planet: Planet) -> Double {
        return calculateSolarFlux(atDistance: planet.distanceFromSun)
    }
}

// MARK: - Default Weather Conditions per Planet

extension PlanetDataService {
    
    /// Generate default/typical weather condition for a planet
    /// Used when no live data is available
    func getDefaultCondition(for planet: Planet) -> WeatherCondition {
        let solarFlux = getSolarFlux(for: planet)
        
        switch planet.id {
        case "sun":
            return WeatherCondition(
                planetId: planet.id,
                temperature: 5505,
                temperatureHigh: 5505,
                temperatureLow: 5505,
                windSpeed: 400,  // Solar wind ~400 km/s average
                windDirection: 0,
                pressure: nil,
                conditionType: .quiet,
                visibility: nil,
                solarFlux: solarFlux
            )
            
        case "mercury":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: 430,
                temperatureLow: -180,
                windSpeed: 0,
                windDirection: 0,
                pressure: 0,
                conditionType: .noAtmosphere,
                visibility: nil,
                solarFlux: solarFlux
            )
            
        case "venus":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: 471,
                temperatureLow: 446,
                windSpeed: 360,  // Cloud-top winds
                windDirection: 90,
                pressure: 92,
                conditionType: .acidRain,
                visibility: 1,
                solarFlux: solarFlux
            )
            
        case "earth":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: 20,
                temperatureLow: 10,
                windSpeed: 15,
                windDirection: 45,
                pressure: 1.0,
                conditionType: .partlyCloudy,
                visibility: 50,
                solarFlux: solarFlux
            )
            
        case "mars":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: -20,
                temperatureLow: -100,
                windSpeed: 30,
                windDirection: 180,
                pressure: 0.006,
                conditionType: .dust,
                visibility: 40,
                solarFlux: solarFlux
            )
            
        case "jupiter":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: -108,
                temperatureLow: -145,
                windSpeed: 550,  // Equatorial jet stream
                windDirection: 90,
                pressure: 1.0,
                conditionType: .anticyclonicStorm,
                visibility: 0,
                solarFlux: solarFlux
            )
            
        case "saturn":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: -130,
                temperatureLow: -180,
                windSpeed: 1800,  // Fastest winds in solar system
                windDirection: 90,
                pressure: 1.0,
                conditionType: .bandedClouds,
                visibility: 0,
                solarFlux: solarFlux
            )
            
        case "uranus":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: -193,
                temperatureLow: -224,
                windSpeed: 900,
                windDirection: 270,
                pressure: 1.0,
                conditionType: .methaneClouds,
                visibility: 0,
                solarFlux: solarFlux
            )
            
        case "neptune":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: -200,
                temperatureLow: -220,
                windSpeed: 2100,  // Fastest planetary winds
                windDirection: 90,
                pressure: 1.0,
                conditionType: .diamondRain,
                visibility: 0,
                solarFlux: solarFlux
            )
            
        case "pluto":
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: -220,
                temperatureLow: -240,
                windSpeed: 3,
                windDirection: 0,
                pressure: 0.00001,
                conditionType: .extremeCold,
                visibility: 100,
                solarFlux: solarFlux
            )
            
        default:
            return WeatherCondition(
                planetId: planet.id,
                temperature: planet.meanTemperature,
                temperatureHigh: planet.meanTemperature + 10,
                temperatureLow: planet.meanTemperature - 10,
                windSpeed: 0,
                windDirection: 0,
                pressure: planet.atmosphericPressure,
                conditionType: .clear,
                visibility: nil,
                solarFlux: solarFlux
            )
        }
    }
}
