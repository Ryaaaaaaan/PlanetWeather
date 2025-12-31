import Foundation

// MARK: - Weather Simulation Engine

/// Generates realistic weather simulations for planets without live data
/// Uses planetary rotation, solar distance, and atmospheric models
///
/// The engine creates "living" weather that changes throughout the planetary day,
/// making the app feel dynamic even with no network connection.
final class WeatherSimulationEngine {
    
    // MARK: - Singleton
    
    static let shared = WeatherSimulationEngine()
    
    private let astronomyHelper = AstronomyHelper.shared
    private let planetDataService = PlanetDataService.shared
    
    private init() {}
    
    // MARK: - Main Simulation Function
    
    /// Simulate current weather for a given planet
    /// - Parameters:
    ///   - planet: The planet to simulate weather for
    ///   - date: The date/time to simulate (default: now)
    /// - Returns: A WeatherCondition representing the current state
    func simulateCurrentWeather(for planet: Planet, at date: Date = Date()) -> WeatherCondition {
        // Get base condition from PlanetDataService
        let baseCondition = planetDataService.getDefaultCondition(for: planet)
        
        // Calculate day/night cycle position
        let solarTime = astronomyHelper.localSolarTime(for: planet, at: date)
        let isDaytime = astronomyHelper.isDaytime(on: planet, at: date)
        
        // Calculate temperature based on time of day
        let temperature = calculateTemperature(
            for: planet,
            baseCondition: baseCondition,
            solarTime: solarTime,
            isDaytime: isDaytime
        )
        
        // Add random noise for realism
        let noise = generateNoise(amplitude: 0.5)
        let currentTemp = temperature + noise
        
        // Calculate dynamic high/low for today
        let (todayHigh, todayLow) = calculateDailyRange(for: planet, baseCondition: baseCondition)
        
        // Calculate wind with variation
        let (windSpeed, windDirection) = calculateWind(
            for: planet,
            baseCondition: baseCondition,
            solarTime: solarTime
        )
        
        // Determine visibility based on conditions
        let visibility = calculateVisibility(for: planet, baseCondition: baseCondition)
        
        // Choose appropriate condition type based on time
        let conditionType = determineConditionType(
            for: planet,
            baseCondition: baseCondition,
            isDaytime: isDaytime
        )
        
        return WeatherCondition(
            planetId: planet.id,
            temperature: currentTemp,
            temperatureHigh: todayHigh,
            temperatureLow: todayLow,
            windSpeed: windSpeed,
            windDirection: windDirection,
            pressure: baseCondition.pressure,
            conditionType: conditionType,
            visibility: visibility,
            solarFlux: baseCondition.solarFlux,
            timestamp: date,
            isSimulated: true,
            sol: planet.id == "mars" ? calculateMartianSol(at: date) : nil
        )
    }
    
    // MARK: - Temperature Calculation
    
    /// Calculate temperature using sinusoidal diurnal variation
    /// Formula: T = T_mean + (Amplitude * sin(2π * (solarTime - 0.25)))
    /// Peak at noon (0.5), minimum at midnight (0.0)
    private func calculateTemperature(
        for planet: Planet,
        baseCondition: WeatherCondition,
        solarTime: Double,
        isDaytime: Bool
    ) -> Double {
        let tempHigh = baseCondition.temperatureHigh
        let tempLow = baseCondition.temperatureLow
        
        // Mean temperature
        let meanTemp = (tempHigh + tempLow) / 2.0
        
        // Amplitude of variation
        let amplitude = (tempHigh - tempLow) / 2.0
        
        // Sinusoidal variation: peak at solar noon (0.5), minimum at midnight (0.0 or 1.0)
        // Shift by -0.25 so that sin(0) = midnight minimum
        let phase = (solarTime - 0.25) * 2 * .pi
        let variation = sin(phase)
        
        // Apply planet-specific thermal inertia
        // Gas giants have lower variation due to internal heat
        let inertiaFactor = thermalInertiaFactor(for: planet)
        
        return meanTemp + (amplitude * variation * inertiaFactor)
    }
    
    /// Get thermal inertia factor (0 to 1) - how much temperature varies with day/night
    /// Lower = more stable temperatures (gas giants with internal heat)
    /// Higher = more extreme day/night swings (airless bodies)
    private func thermalInertiaFactor(for planet: Planet) -> Double {
        switch planet.id {
        case "mercury":
            return 1.0     // No atmosphere, extreme swings
        case "venus":
            return 0.05    // Super-thick atmosphere, very stable
        case "earth":
            return 0.6     // Moderate atmosphere
        case "mars":
            return 0.85    // Thin atmosphere
        case "jupiter", "saturn", "uranus", "neptune":
            return 0.1     // Internal heat sources, very stable
        case "pluto":
            return 0.7     // Thin atmosphere, moderate swing
        case "sun":
            return 0.0     // No variation (surface temperature constant)
        default:
            return 0.5
        }
    }
    
    // MARK: - Daily Range Calculation
    
    /// Calculate today's high and low with slight random variation
    private func calculateDailyRange(
        for planet: Planet,
        baseCondition: WeatherCondition
    ) -> (high: Double, low: Double) {
        let highNoise = generateNoise(amplitude: 1.0)
        let lowNoise = generateNoise(amplitude: 1.0)
        
        let high = baseCondition.temperatureHigh + highNoise
        let low = baseCondition.temperatureLow + lowNoise
        
        return (high, low)
    }
    
    // MARK: - Wind Calculation
    
    /// Calculate wind speed and direction with diurnal variation
    private func calculateWind(
        for planet: Planet,
        baseCondition: WeatherCondition,
        solarTime: Double
    ) -> (speed: Double, direction: Double) {
        // Base wind speed with some variation
        let baseSpeed = baseCondition.windSpeed
        
        // Wind tends to pick up during the day (convection)
        let dayFactor = 1.0 + 0.3 * sin((solarTime - 0.25) * 2 * .pi)
        
        // Add random gustiness
        let gust = generateNoise(amplitude: baseSpeed * 0.1)
        
        let speed = max(0, baseSpeed * dayFactor + gust)
        
        // Direction shifts slowly over time
        let baseDirection = baseCondition.windDirection
        let directionShift = generateNoise(amplitude: 15) // ±15 degrees
        let direction = (baseDirection + directionShift).truncatingRemainder(dividingBy: 360)
        
        return (speed, direction < 0 ? direction + 360 : direction)
    }
    
    // MARK: - Visibility Calculation
    
    /// Calculate visibility based on atmospheric conditions
    private func calculateVisibility(
        for planet: Planet,
        baseCondition: WeatherCondition
    ) -> Double? {
        guard let baseVisibility = baseCondition.visibility else {
            return nil
        }
        
        // Dust storms reduce visibility
        if baseCondition.conditionType == .dustStorm || baseCondition.conditionType == .dust {
            return baseVisibility * (0.3 + Double.random(in: 0...0.4))
        }
        
        // Add slight variation
        let variation = generateNoise(amplitude: baseVisibility * 0.1)
        return max(0.1, baseVisibility + variation)
    }
    
    // MARK: - Condition Type Determination
    
    /// Determine the appropriate weather condition based on time and planet
    private func determineConditionType(
        for planet: Planet,
        baseCondition: WeatherCondition,
        isDaytime: Bool
    ) -> WeatherConditionType {
        // Special handling for Sun (space weather)
        if planet.id == "sun" {
            return determineSolarCondition()
        }
        
        // For most planets, condition stays the same day/night
        return baseCondition.conditionType
    }
    
    /// Determine solar activity level (for Sun view)
    private func determineSolarCondition() -> WeatherConditionType {
        // Simulate solar activity with some randomness
        let activity = Double.random(in: 0...1)
        
        switch activity {
        case 0..<0.7:
            return .quiet
        case 0.7..<0.9:
            return .solarWind
        case 0.9..<0.98:
            return .solarFlare
        default:
            return .coronalMassEjection
        }
    }
    
    // MARK: - Mars Sol Calculation
    
    /// Calculate the current Martian Sol (day number) since InSight landing
    /// Reference: InSight landed on Sol 0 = November 26, 2018
    private func calculateMartianSol(at date: Date) -> Int {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents()
        components.year = 2018
        components.month = 11
        components.day = 26
        components.hour = 19
        components.minute = 52
        components.timeZone = TimeZone(identifier: "UTC")
        
        guard let landingDate = calendar.date(from: components) else {
            return 0
        }
        
        let earthDaysSinceLanding = date.timeIntervalSince(landingDate) / 86400
        // A Martian Sol is ~24.66 Earth hours
        let solsSinceLanding = earthDaysSinceLanding / 1.02749
        
        return max(0, Int(solsSinceLanding))
    }
    
    // MARK: - Noise Generation
    
    /// Generate random noise for realistic variation
    /// - Parameter amplitude: Maximum deviation (result will be ±amplitude)
    /// - Returns: Random value between -amplitude and +amplitude
    private func generateNoise(amplitude: Double) -> Double {
        return Double.random(in: -amplitude...amplitude)
    }
    
    // MARK: - Forecast Generation
    
    /// Generate hourly forecast for the next 24 (planetary) hours
    /// - Parameters:
    ///   - planet: The planet to forecast for
    ///   - startDate: Starting date (default: now)
    /// - Returns: Array of HourlyForecast items
    func generateHourlyForecast(for planet: Planet, from startDate: Date = Date()) -> [HourlyForecast] {
        var forecasts: [HourlyForecast] = []
        let calendar = Calendar.current
        
        // Calculate how many Earth hours per planetary hour
        let earthHoursPerPlanetaryHour = planet.dayDurationHours / 24.0
        
        for hour in 0..<24 {
            // Calculate the Earth time for this planetary hour
            let earthHoursOffset = Double(hour) * earthHoursPerPlanetaryHour
            guard let forecastDate = calendar.date(byAdding: .second, value: Int(earthHoursOffset * 3600), to: startDate) else {
                continue
            }
            
            let weather = simulateCurrentWeather(for: planet, at: forecastDate)
            
            forecasts.append(HourlyForecast(
                hour: hour,
                temperature: weather.temperature,
                conditionType: weather.conditionType,
                windSpeed: weather.windSpeed
            ))
        }
        
        return forecasts
    }
    
    /// Generate 10-day forecast
    /// - Parameters:
    ///   - planet: The planet to forecast for
    ///   - startDate: Starting date (default: now)
    /// - Returns: Array of DailyForecast items
    func generateDailyForecast(for planet: Planet, from startDate: Date = Date()) -> [DailyForecast] {
        var forecasts: [DailyForecast] = []
        let calendar = Calendar.current
        
        // For gas giants with short days, each "day" in forecast is still one Earth day
        // This makes it easier for users to understand
        
        for day in 0..<10 {
            guard let forecastDate = calendar.date(byAdding: .day, value: day, to: startDate) else {
                continue
            }
            
            // Simulate weather at noon of that day
            guard let noonDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: forecastDate) else {
                continue
            }
            
            let weather = simulateCurrentWeather(for: planet, at: noonDate)
            
            // Add some day-to-day variation
            let highVariation = generateNoise(amplitude: 3.0)
            let lowVariation = generateNoise(amplitude: 3.0)
            
            forecasts.append(DailyForecast(
                date: forecastDate,
                temperatureHigh: weather.temperatureHigh + highVariation,
                temperatureLow: weather.temperatureLow + lowVariation,
                conditionType: weather.conditionType,
                precipitationProbability: planet.id == "venus" ? 0.8 : 0.0
            ))
        }
        
        return forecasts
    }
}

// MARK: - Simulation Statistics

extension WeatherSimulationEngine {
    
    /// Get a summary of simulated weather for debugging/display
    func getSimulationSummary(for planet: Planet) -> String {
        let weather = simulateCurrentWeather(for: planet)
        let isDaytime = astronomyHelper.isDaytime(on: planet)
        let solarTime = astronomyHelper.formattedSolarTime(for: planet)
        
        return """
        [PLANET] \(planet.name)
        [TEMP] \(weather.formattedTemperature) (\(weather.formattedHighLow))
        [WIND] \(weather.formattedWind)
        [TIME] \(solarTime) - \(isDaytime ? "Jour" : "Nuit")
        [DATA] Simulé: \(weather.isSimulated ? "Oui" : "Non")
        """
    }
}
