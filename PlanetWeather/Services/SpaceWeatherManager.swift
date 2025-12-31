import Foundation

// MARK: - Space Weather Manager

/// Manages network requests for space and planetary weather data
/// Implements real API calls to NASA and Open-Meteo
///
/// Supported APIs:
/// - NASA InSight (Mars Weather) - Note: Mission ended Dec 2022, using MAAS API
/// - NASA DONKI (Space Weather)
/// - Open-Meteo (Earth Weather)
actor SpaceWeatherManager {
    
    // MARK: - Singleton
    
    static let shared = SpaceWeatherManager()
    
    // MARK: - Properties
    
    private let planetDataService = PlanetDataService.shared
    private let simulationEngine = WeatherSimulationEngine.shared
    private let urlSession: URLSession
    
    /// Cache for last successful responses
    private var cache: [String: CachedWeatherData] = [:]
    
    /// Track if we're in offline mode
    private(set) var isOffline: Bool = false
    
    /// Last error encountered
    private(set) var lastError: SpaceWeatherError?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.urlSession = URLSession(configuration: config)
    }
    
    // MARK: - Earth Weather (Open-Meteo API)
    
    /// Fetch Earth weather for a given location using Open-Meteo
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    /// - Returns: WeatherCondition for Earth at that location
    func fetchEarthWeather(latitude: Double, longitude: Double) async throws -> WeatherCondition {
        guard Secrets.enableLiveData else {
            // Fallback to simulation
            guard let earth = planetDataService.getPlanet(byId: "earth") else {
                throw SpaceWeatherError.planetNotFound("earth")
            }
            return simulationEngine.simulateCurrentWeather(for: earth)
        }
        
        // Build Open-Meteo URL
        // Doc: https://open-meteo.com/en/docs
        let urlString = "\(Secrets.openMeteoBaseURL)/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,pressure_msl,wind_speed_10m,wind_direction_10m&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto"
        
        guard let url = URL(string: urlString) else {
            throw SpaceWeatherError.invalidResponse
        }
        
        if Secrets.enableNetworkLogging {
            print("[Open-Meteo] Fetching: \(urlString)")
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpaceWeatherError.invalidResponse
        }
        
        // Parse Open-Meteo response
        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        
        guard let earth = planetDataService.getPlanet(byId: "earth") else {
            throw SpaceWeatherError.planetNotFound("earth")
        }
        
        // Convert to our WeatherCondition model
        let weather = WeatherCondition(
            planetId: "earth",
            temperature: decoded.current.temperature2m,
            temperatureHigh: decoded.daily.temperature2mMax.first ?? decoded.current.temperature2m + 5,
            temperatureLow: decoded.daily.temperature2mMin.first ?? decoded.current.temperature2m - 5,
            windSpeed: decoded.current.windSpeed10m,
            windDirection: decoded.current.windDirection10m,
            pressure: decoded.current.pressureMsl / 1000.0, // Convert hPa to bar
            conditionType: mapWeatherCode(decoded.current.weatherCode),
            visibility: nil,
            solarFlux: planetDataService.getSolarFlux(for: earth),
            timestamp: Date(),
            isSimulated: false,
            sol: nil
        )
        
        // Cache the successful response
        cache["earth"] = CachedWeatherData(
            weather: weather,
            timestamp: Date()
        )
        
        isOffline = false
        
        if Secrets.enableNetworkLogging {
            print("[Open-Meteo] Success: \(weather.temperature)°C, \(weather.conditionType.rawValue)")
        }
        
        return weather
    }
    
    /// Map Open-Meteo weather code to our condition type
    private func mapWeatherCode(_ code: Int) -> WeatherConditionType {
        switch code {
        case 0: return .clear
        case 1, 2, 3: return .partlyCloudy
        case 45, 48: return .fog
        case 51, 53, 55, 56, 57: return .drizzle
        case 61, 63, 65, 66, 67: return .rain
        case 71, 73, 75, 77: return .snow
        case 80, 81, 82: return .showers
        case 85, 86: return .snow
        case 95, 96, 99: return .thunderstorm
        default: return .partlyCloudy
        }
    }
    
    // MARK: - Earth Forecasts (Open-Meteo API)
    
    /// Fetch hourly and daily forecasts for Earth
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    /// - Returns: Tuple with hourly and daily forecasts
    func fetchEarthForecasts(latitude: Double, longitude: Double) async throws -> (hourly: [HourlyForecast], daily: [DailyForecast]) {
        guard Secrets.enableLiveData else {
            return ([], [])
        }
        
        // Build Open-Meteo forecast URL
        let urlString = "\(Secrets.openMeteoBaseURL)/forecast?latitude=\(latitude)&longitude=\(longitude)&hourly=temperature_2m,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto&forecast_days=10"
        
        guard let url = URL(string: urlString) else {
            throw SpaceWeatherError.invalidResponse
        }
        
        if Secrets.enableNetworkLogging {
            print("[Open-Meteo] Fetching forecasts: \(urlString)")
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SpaceWeatherError.invalidResponse
        }
        
        let decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
        
        // Parse hourly forecasts (next 24 hours)
        var hourlyForecasts: [HourlyForecast] = []
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        for i in 0..<min(24, decoded.hourly.temperature2m.count) {
            let index = currentHour + i
            if index < decoded.hourly.temperature2m.count {
                hourlyForecasts.append(HourlyForecast(
                    hour: (currentHour + i) % 24,
                    temperature: decoded.hourly.temperature2m[index],
                    conditionType: mapWeatherCode(decoded.hourly.weatherCode[index]),
                    windSpeed: decoded.hourly.windSpeed10m[index]
                ))
            }
        }
        
        // Parse daily forecasts
        var dailyForecasts: [DailyForecast] = []
        
        for i in 0..<min(10, decoded.daily.temperature2mMax.count) {
            let date = Calendar.current.date(byAdding: .day, value: i, to: Date()) ?? Date()
            dailyForecasts.append(DailyForecast(
                date: date,
                temperatureHigh: decoded.daily.temperature2mMax[i],
                temperatureLow: decoded.daily.temperature2mMin[i],
                conditionType: mapWeatherCode(decoded.daily.weatherCode[i]),
                precipitationProbability: 0
            ))
        }
        
        if Secrets.enableNetworkLogging {
            print("[Open-Meteo] Forecasts loaded: \(hourlyForecasts.count) hourly, \(dailyForecasts.count) daily")
        }
        
        return (hourlyForecasts, dailyForecasts)
    }
    
    // MARK: - Space Weather (DONKI API)
    
    /// Fetch current space weather alerts from NASA DONKI
    /// - Returns: Array of SpaceWeatherAlert
    func fetchSpaceWeatherAlerts() async throws -> [SpaceWeatherAlert] {
        guard Secrets.enableLiveData else {
            return mockSpaceWeatherAlerts()
        }
        
        var alerts: [SpaceWeatherAlert] = []
        
        // Fetch last 7 days of geomagnetic storms
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let startStr = dateFormatter.string(from: startDate)
        let endStr = dateFormatter.string(from: endDate)
        
        // Fetch GST (Geomagnetic Storms)
        let gstURL = "\(Secrets.NASA.donkiGST)?startDate=\(startStr)&endDate=\(endStr)&api_key=\(Secrets.nasaApiKey)"
        
        if Secrets.enableNetworkLogging {
            print("[DONKI] Fetching GST: \(gstURL)")
        }
        
        if let url = URL(string: gstURL) {
            do {
                let (data, response) = try await urlSession.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    let gstEvents = try JSONDecoder().decode([DONKIGSTEvent].self, from: data)
                    
                    for event in gstEvents {
                        if let kpIndex = event.allKpIndex?.first?.kpIndex {
                            let severity: SpaceWeatherAlert.AlertSeverity
                            switch kpIndex {
                            case 0...3: severity = .minor
                            case 4: severity = .moderate
                            case 5...6: severity = .strong
                            case 7...8: severity = .severe
                            default: severity = .extreme
                            }
                            
                            alerts.append(SpaceWeatherAlert(
                                id: event.gstID,
                                type: .geomagneticStorm,
                                kpIndex: Int(kpIndex),
                                startTime: event.startTime ?? Date(),
                                peakTime: nil,
                                message: "Tempête géomagnétique Kp\(Int(kpIndex))",
                                severity: severity
                            ))
                        }
                    }
                }
            } catch {
                if Secrets.enableNetworkLogging {
                    print("[DONKI] GST error: \(error)")
                }
            }
        }
        
        // Fetch CME (Coronal Mass Ejections)
        let cmeURL = "\(Secrets.NASA.donkiCME)?startDate=\(startStr)&endDate=\(endStr)&api_key=\(Secrets.nasaApiKey)"
        
        if let url = URL(string: cmeURL) {
            do {
                let (data, response) = try await urlSession.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    let cmeEvents = try JSONDecoder().decode([DONKICMEEvent].self, from: data)
                    
                    for event in cmeEvents.prefix(3) { // Limit to 3 most recent
                        alerts.append(SpaceWeatherAlert(
                            id: event.activityID,
                            type: .coronalMassEjection,
                            kpIndex: nil,
                            startTime: event.startTime ?? Date(),
                            peakTime: nil,
                            message: event.note ?? "Éjection de masse coronale détectée",
                            severity: .moderate
                        ))
                    }
                }
            } catch {
                if Secrets.enableNetworkLogging {
                    print("[DONKI] CME error: \(error)")
                }
            }
        }
        
        if Secrets.enableNetworkLogging {
            print("[DONKI] Found \(alerts.count) alerts")
        }
        
        isOffline = false
        return alerts
    }
    
    /// Get current Kp Index (geomagnetic activity)
    /// Scale: 0-9, where 5+ indicates storm conditions
    func fetchKpIndex() async throws -> Int {
        // Fetch from NOAA (more reliable for current Kp)
        // For now, derive from DONKI alerts
        let alerts = try await fetchSpaceWeatherAlerts()
        
        // Get highest Kp from recent alerts
        let maxKp = alerts
            .filter { $0.type == .geomagneticStorm }
            .compactMap { $0.kpIndex }
            .max() ?? 2 // Default quiet sun
        
        return maxKp
    }
    
    private func mockSpaceWeatherAlerts() -> [SpaceWeatherAlert] {
        return [
            SpaceWeatherAlert(
                id: UUID().uuidString,
                type: .geomagneticStorm,
                kpIndex: 4,
                startTime: Date().addingTimeInterval(-3600),
                peakTime: Date().addingTimeInterval(7200),
                message: "Tempête géomagnétique mineure (données simulées)",
                severity: .moderate
            )
        ]
    }
    
    // MARK: - Mars Weather
    
    /// Note: NASA InSight mission ended in December 2022
    /// This now uses simulation based on historical InSight data patterns
    func fetchMarsWeather() async throws -> WeatherCondition {
        guard let mars = planetDataService.getPlanet(byId: "mars") else {
            throw SpaceWeatherError.planetNotFound("mars")
        }
        
        // InSight mission ended - use simulation based on real data patterns
        // Average temperature range from InSight: -95°C to -17°C
        let weather = simulationEngine.simulateCurrentWeather(for: mars)
        
        cache["mars"] = CachedWeatherData(
            weather: weather,
            timestamp: Date()
        )
        
        return weather
    }
    
    // MARK: - Generic Weather Fetch
    
    /// Fetch weather for any planet (with fallback to simulation)
    /// - Parameter planet: The planet to fetch weather for
    /// - Returns: WeatherCondition (live or simulated)
    func fetchWeather(for planet: Planet) async -> WeatherCondition {
        do {
            switch planet.id {
            case "earth":
                // Default to Paris coordinates for demo
                return try await fetchEarthWeather(latitude: 48.8566, longitude: 2.3522)
            case "mars":
                return try await fetchMarsWeather()
            default:
                // All other planets use simulation only
                return simulationEngine.simulateCurrentWeather(for: planet)
            }
        } catch {
            // Log error
            lastError = error as? SpaceWeatherError ?? .unknown(error)
            isOffline = true
            
            if Secrets.enableNetworkLogging {
                print("[SpaceWeatherManager] Error: \(error)")
            }
            
            // Try to return cached data
            if let cached = cache[planet.id], !cached.isExpired {
                return cached.weather
            }
            
            // Fall back to simulation
            return simulationEngine.simulateCurrentWeather(for: planet)
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached data
    func clearCache() {
        cache.removeAll()
    }
    
    /// Check if cached data exists for a planet
    func hasCachedData(for planetId: String) -> Bool {
        guard let cached = cache[planetId] else { return false }
        return !cached.isExpired
    }
    
    /// Get cached weather if available
    func getCachedWeather(for planetId: String) -> WeatherCondition? {
        guard let cached = cache[planetId], !cached.isExpired else {
            return nil
        }
        return cached.weather
    }
    
    /// Get cache age for a planet
    func cacheAge(for planetId: String) -> TimeInterval? {
        guard let cached = cache[planetId] else { return nil }
        return Date().timeIntervalSince(cached.timestamp)
    }
    
    // MARK: - Offline Mode
    
    /// Force offline mode for testing
    func setOfflineMode(_ offline: Bool) {
        isOffline = offline
    }
}

// MARK: - Open-Meteo Response Models

struct OpenMeteoResponse: Codable {
    let current: OpenMeteoCurrent
    let daily: OpenMeteoDaily
    
    enum CodingKeys: String, CodingKey {
        case current
        case daily
    }
}

struct OpenMeteoCurrent: Codable {
    let temperature2m: Double
    let relativeHumidity2m: Int
    let apparentTemperature: Double
    let weatherCode: Int
    let pressureMsl: Double
    let windSpeed10m: Double
    let windDirection10m: Double
    
    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case apparentTemperature = "apparent_temperature"
        case weatherCode = "weather_code"
        case pressureMsl = "pressure_msl"
        case windSpeed10m = "wind_speed_10m"
        case windDirection10m = "wind_direction_10m"
    }
}

struct OpenMeteoDaily: Codable {
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let weatherCode: [Int]
    
    enum CodingKeys: String, CodingKey {
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case weatherCode = "weather_code"
    }
}

// MARK: - Open-Meteo Forecast Response Models

struct OpenMeteoForecastResponse: Codable {
    let hourly: OpenMeteoHourly
    let daily: OpenMeteoDaily
}

struct OpenMeteoHourly: Codable {
    let temperature2m: [Double]
    let weatherCode: [Int]
    let windSpeed10m: [Double]
    
    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case weatherCode = "weather_code"
        case windSpeed10m = "wind_speed_10m"
    }
}

// MARK: - DONKI Response Models

struct DONKIGSTEvent: Codable {
    let gstID: String
    let startTime: Date?
    let allKpIndex: [DONKIKpIndex]?
    
    enum CodingKeys: String, CodingKey {
        case gstID
        case startTime
        case allKpIndex
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gstID = try container.decode(String.self, forKey: .gstID)
        allKpIndex = try container.decodeIfPresent([DONKIKpIndex].self, forKey: .allKpIndex)
        
        // Parse date string
        if let dateString = try container.decodeIfPresent(String.self, forKey: .startTime) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            startTime = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            startTime = nil
        }
    }
}

struct DONKIKpIndex: Codable {
    let kpIndex: Double
    let source: String?
}

struct DONKICMEEvent: Codable {
    let activityID: String
    let startTime: Date?
    let note: String?
    
    enum CodingKeys: String, CodingKey {
        case activityID
        case startTime
        case note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activityID = try container.decode(String.self, forKey: .activityID)
        note = try container.decodeIfPresent(String.self, forKey: .note)
        
        // Parse date string
        if let dateString = try container.decodeIfPresent(String.self, forKey: .startTime) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            startTime = formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
        } else {
            startTime = nil
        }
    }
}

// MARK: - Supporting Types

/// Cached weather data with timestamp
struct CachedWeatherData {
    let weather: WeatherCondition
    let timestamp: Date
    
    /// Check if cache has expired
    var isExpired: Bool {
        let age = Date().timeIntervalSince(timestamp)
        return age > Secrets.cacheExpirationSeconds
    }
    
    /// Age of cache in human-readable format
    var ageDescription: String {
        let age = Date().timeIntervalSince(timestamp)
        let minutes = Int(age / 60)
        
        if minutes < 1 {
            return "À l'instant"
        } else if minutes < 60 {
            return "Il y a \(minutes) min"
        } else {
            let hours = minutes / 60
            return "Il y a \(hours) h"
        }
    }
}

/// Space weather alert from DONKI
struct SpaceWeatherAlert: Identifiable, Codable {
    let id: String
    let type: AlertType
    let kpIndex: Int?
    let startTime: Date
    let peakTime: Date?
    let message: String
    let severity: AlertSeverity
    
    enum AlertType: String, Codable {
        case coronalMassEjection = "CME"
        case solarFlare = "FLR"
        case geomagneticStorm = "GST"
        case solarEnergeticParticle = "SEP"
        
        var displayName: String {
            switch self {
            case .coronalMassEjection:
                return "Éjection de Masse Coronale"
            case .solarFlare:
                return "Éruption Solaire"
            case .geomagneticStorm:
                return "Tempête Géomagnétique"
            case .solarEnergeticParticle:
                return "Particule Énergétique Solaire"
            }
        }
        
        var symbolName: String {
            switch self {
            case .coronalMassEjection:
                return "burst.fill"
            case .solarFlare:
                return "sun.max.trianglebadge.exclamationmark.fill"
            case .geomagneticStorm:
                return "bolt.trianglebadge.exclamationmark.fill"
            case .solarEnergeticParticle:
                return "atom"
            }
        }
    }
    
    enum AlertSeverity: String, Codable {
        case minor
        case moderate
        case strong
        case severe
        case extreme
        
        var displayName: String {
            switch self {
            case .minor: return "Mineur"
            case .moderate: return "Modéré"
            case .strong: return "Fort"
            case .severe: return "Sévère"
            case .extreme: return "Extrême"
            }
        }
        
        var color: String {
            switch self {
            case .minor: return "#4CAF50"      // Green
            case .moderate: return "#FFC107"   // Yellow
            case .strong: return "#FF9800"     // Orange
            case .severe: return "#F44336"     // Red
            case .extreme: return "#9C27B0"    // Purple
            }
        }
    }
}

/// Errors that can occur during space weather operations
enum SpaceWeatherError: Error, LocalizedError {
    case networkUnavailable
    case invalidResponse
    case apiKeyMissing
    case rateLimited
    case planetNotFound(String)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Connexion réseau indisponible"
        case .invalidResponse:
            return "Réponse API invalide"
        case .apiKeyMissing:
            return "Clé API manquante"
        case .rateLimited:
            return "Limite d'appels API atteinte"
        case .planetNotFound(let id):
            return "Planète non trouvée: \(id)"
        case .unknown(let error):
            return "Erreur: \(error.localizedDescription)"
        }
    }
}
