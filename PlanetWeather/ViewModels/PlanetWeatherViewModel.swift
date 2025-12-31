import SwiftUI
import Combine
import CoreLocation

// MARK: - Planet Weather ViewModel

/// Main ViewModel for planet weather display
/// Connects Services layer to SwiftUI Views using MVVM pattern
@MainActor
final class PlanetWeatherViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently selected planet
    @Published var selectedPlanet: Planet
    
    /// Current weather condition for selected planet
    @Published var currentWeather: WeatherCondition?
    
    /// Hourly forecast (24 hours)
    @Published var hourlyForecast: [HourlyForecast] = []
    
    /// 10-day forecast
    @Published var dailyForecast: [DailyForecast] = []
    
    /// Loading state
    @Published var isLoading: Bool = false
    
    /// Error message if any
    @Published var errorMessage: String?
    
    /// Offline mode indicator
    @Published var isOffline: Bool = false
    
    /// Space weather alerts (for Sun view)
    @Published var spaceWeatherAlerts: [SpaceWeatherAlert] = []
    
    /// Moon phase data (for Earth view)
    @Published var moonPhaseData: MoonPhaseData?
    
    /// Current Kp Index (geomagnetic activity)
    @Published var kpIndex: Int = 0
    
    /// User's location name
    @Published var locationName: String = "Ma Position"
    
    // MARK: - Services
    
    private let planetDataService = PlanetDataService.shared
    private let astronomyHelper = AstronomyHelper.shared
    private let locationManager = LocationManager.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - All Planets
    
    /// All available planets for PageTabView
    let allPlanets: [Planet]
    
    // MARK: - Computed Properties
    
    /// Current solar time on the planet
    var solarTimeString: String {
        astronomyHelper.formattedSolarTime(for: selectedPlanet)
    }
    
    /// Is it daytime on current planet
    var isDaytime: Bool {
        astronomyHelper.isDaytime(on: selectedPlanet)
    }
    
    /// Sun elevation angle
    var sunElevation: Double {
        astronomyHelper.sunElevation(on: selectedPlanet)
    }
    
    /// Next eclipse info
    var nextEclipseString: String {
        astronomyHelper.getNextEclipseString()
    }
    
    /// Days until next eclipse
    var daysUntilEclipse: Int {
        astronomyHelper.daysUntilNextEclipse()
    }
    
    /// Galilean moon positions (for Jupiter)
    var galileanMoons: [String: Double] {
        astronomyHelper.galileanMoonPositions()
    }
    
    /// Theme gradient colors for current planet
    var themeGradient: LinearGradient {
        LinearGradient(
            colors: selectedPlanet.gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Primary theme color
    var primaryColor: Color {
        selectedPlanet.gradientColors.first ?? .blue
    }
    
    /// Secondary theme color
    var secondaryColor: Color {
        selectedPlanet.gradientColors.count > 1 ? selectedPlanet.gradientColors[1] : primaryColor
    }
    
    // MARK: - Initialization
    
    init(initialPlanet: Planet? = nil) {
        self.allPlanets = PlanetDataService.allPlanets
        self.selectedPlanet = initialPlanet ?? allPlanets.first(where: { $0.id == "earth" }) ?? allPlanets[0]
        
        // Subscribe to location updates
        setupLocationBinding()
        
        // Request location permission for Earth
        if selectedPlanet.id == "earth" {
            locationManager.requestPermission()
        }
        
        // Load initial data
        Task {
            await loadWeatherData()
        }
    }
    
    // MARK: - Location Binding
    
    private func setupLocationBinding() {
        // Update location name when it changes
        locationManager.$locationName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (name: String) in
                if self?.selectedPlanet.id == "earth" {
                    self?.locationName = name
                }
            }
            .store(in: &cancellables)
        
        // Reload weather when location updates
        locationManager.$location
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_: CLLocation?) in
                if self?.selectedPlanet.id == "earth" {
                    Task {
                        await self?.loadWeatherData()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Planet Selection
    
    /// Select a new planet and load its weather
    func selectPlanet(_ planet: Planet) {
        guard planet.id != selectedPlanet.id else { return }
        
        selectedPlanet = planet
        
        // Update location name display
        if planet.id == "earth" {
            locationName = locationManager.locationName
            locationManager.requestLocation()
        } else {
            locationName = planet.formattedDistance
        }
        
        Task {
            await loadWeatherData()
        }
    }
    
    /// Select planet by index (for PageTabView)
    func selectPlanet(at index: Int) {
        guard index >= 0 && index < allPlanets.count else { return }
        selectPlanet(allPlanets[index])
    }
    
    /// Get index of current planet
    var currentPlanetIndex: Int {
        allPlanets.firstIndex(where: { $0.id == selectedPlanet.id }) ?? 0
    }
    
    // MARK: - Data Loading
    
    /// Load all weather data for current planet
    func loadWeatherData() async {
        isLoading = true
        errorMessage = nil
        
        switch selectedPlanet.id {
        case "earth":
            await loadEarthWeather()
        case "sun":
            await loadSunData()
        default:
            await loadPlanetaryWeather()
        }
        
        isOffline = await SpaceWeatherManager.shared.isOffline
        isLoading = false
    }
    
    /// Load Earth weather with real API data
    private func loadEarthWeather() async {
        do {
            // Get user location
            let lat = locationManager.latitude
            let lon = locationManager.longitude
            
            // Fetch current weather
            currentWeather = try await SpaceWeatherManager.shared.fetchEarthWeather(
                latitude: lat,
                longitude: lon
            )
            
            // Fetch forecasts from API
            let forecasts = try await SpaceWeatherManager.shared.fetchEarthForecasts(
                latitude: lat,
                longitude: lon
            )
            hourlyForecast = forecasts.hourly
            dailyForecast = forecasts.daily
            
            // Load moon phase
            moonPhaseData = MoonPhaseData.current()
            
        } catch {
            errorMessage = error.localizedDescription
            // Use last cached weather
            if let cached = await SpaceWeatherManager.shared.getCachedWeather(for: "earth") {
                currentWeather = cached
            }
        }
    }
    
    /// Load Sun data (space weather)
    private func loadSunData() async {
        // Sun has no "weather" but space weather alerts
        currentWeather = planetDataService.getDefaultCondition(for: selectedPlanet)
        
        do {
            spaceWeatherAlerts = try await SpaceWeatherManager.shared.fetchSpaceWeatherAlerts()
            kpIndex = try await SpaceWeatherManager.shared.fetchKpIndex()
        } catch {
            spaceWeatherAlerts = []
            kpIndex = 2 // Quiet sun default
        }
        
        // Sun doesn't have hourly/daily forecasts
        hourlyForecast = []
        dailyForecast = []
    }
    
    /// Load planetary weather (uses scientific data + simulation for variation)
    private func loadPlanetaryWeather() async {
        // Get base condition from service
        let baseCondition = planetDataService.getDefaultCondition(for: selectedPlanet)
        
        // Apply diurnal variation based on solar time
        let solarTime = astronomyHelper.localSolarTime(for: selectedPlanet)
        let variation = calculateDiurnalVariation(base: baseCondition, solarTime: solarTime)
        currentWeather = variation
        
        // Generate forecasts based on planetary rotation
        hourlyForecast = generatePlanetaryHourlyForecast(base: baseCondition)
        dailyForecast = generatePlanetaryDailyForecast(base: baseCondition)
    }
    
    /// Calculate diurnal temperature variation
    private func calculateDiurnalVariation(base: WeatherCondition, solarTime: Double) -> WeatherCondition {
        let meanTemp = (base.temperatureHigh + base.temperatureLow) / 2.0
        let amplitude = (base.temperatureHigh - base.temperatureLow) / 2.0
        
        // Peak at noon (0.5), minimum at midnight (0.0)
        let phase = (solarTime - 0.25) * 2 * .pi
        let variation = sin(phase)
        
        // Apply thermal inertia factor
        let inertia = thermalInertiaFactor(for: selectedPlanet)
        let currentTemp = meanTemp + (amplitude * variation * inertia)
        
        return WeatherCondition(
            planetId: base.planetId,
            temperature: currentTemp,
            temperatureHigh: base.temperatureHigh,
            temperatureLow: base.temperatureLow,
            windSpeed: base.windSpeed,
            windDirection: base.windDirection,
            pressure: base.pressure,
            conditionType: base.conditionType,
            visibility: base.visibility,
            solarFlux: base.solarFlux,
            timestamp: Date(),
            isSimulated: false, // Based on real scientific data
            sol: selectedPlanet.id == "mars" ? calculateMartianSol() : nil
        )
    }
    
    /// Thermal inertia factor for day/night temperature swings
    private func thermalInertiaFactor(for planet: Planet) -> Double {
        switch planet.id {
        case "mercury": return 1.0     // No atmosphere
        case "venus": return 0.05       // Super thick atmosphere
        case "mars": return 0.85        // Thin atmosphere
        case "jupiter", "saturn", "uranus", "neptune": return 0.1
        case "pluto": return 0.7
        default: return 0.5
        }
    }
    
    /// Calculate current Martian Sol
    private func calculateMartianSol() -> Int {
        let landingDate = Date(timeIntervalSince1970: 1543263120) // InSight landing
        let daysSince = Date().timeIntervalSince(landingDate) / 86400
        return Int(daysSince / 1.02749)
    }
    
    /// Generate hourly forecast for planets
    private func generatePlanetaryHourlyForecast(base: WeatherCondition) -> [HourlyForecast] {
        var forecasts: [HourlyForecast] = []
        let now = Date()
        
        for hour in 0..<24 {
            let futureTime = now.addingTimeInterval(Double(hour) * 3600)
            let solarTime = astronomyHelper.localSolarTime(for: selectedPlanet, at: futureTime)
            
            let meanTemp = (base.temperatureHigh + base.temperatureLow) / 2.0
            let amplitude = (base.temperatureHigh - base.temperatureLow) / 2.0
            let phase = (solarTime - 0.25) * 2 * .pi
            let temp = meanTemp + amplitude * sin(phase) * thermalInertiaFactor(for: selectedPlanet)
            
            forecasts.append(HourlyForecast(
                hour: hour,
                temperature: temp,
                conditionType: base.conditionType,
                windSpeed: base.windSpeed
            ))
        }
        
        return forecasts
    }
    
    /// Generate daily forecast for planets
    private func generatePlanetaryDailyForecast(base: WeatherCondition) -> [DailyForecast] {
        var forecasts: [DailyForecast] = []
        
        for day in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: day, to: Date()) ?? Date()
            
            forecasts.append(DailyForecast(
                date: date,
                temperatureHigh: base.temperatureHigh,
                temperatureLow: base.temperatureLow,
                conditionType: base.conditionType,
                precipitationProbability: 0
            ))
        }
        
        return forecasts
    }
    
    /// Refresh weather data
    func refresh() async {
        await loadWeatherData()
    }
    
    // MARK: - Formatted Data for UI
    
    /// Main temperature display
    var temperatureDisplay: String {
        guard let weather = currentWeather else {
            return "--°"
        }
        return weather.formattedTemperature
    }
    
    /// Condition description
    var conditionDisplay: String {
        guard let weather = currentWeather else {
            return "Chargement..."
        }
        return weather.conditionType.localizedName
    }
    
    /// High/Low display
    var highLowDisplay: String {
        guard let weather = currentWeather else {
            return "H:--° L:--°"
        }
        return weather.formattedHighLow
    }
    
    /// Wind display
    var windDisplay: String {
        guard let weather = currentWeather else {
            return "-- km/h"
        }
        return weather.formattedWind
    }
    
    /// Pressure display
    var pressureDisplay: String {
        guard let weather = currentWeather else {
            return "-- Bar"
        }
        return weather.formattedPressure
    }
    
    /// Visibility display
    var visibilityDisplay: String {
        guard let weather = currentWeather else {
            return "--"
        }
        return weather.formattedVisibility
    }
    
    /// Solar flux display
    var solarFluxDisplay: String {
        guard let weather = currentWeather else {
            return "-- W/m²"
        }
        return String(format: "%.0f W/m²", weather.solarFlux)
    }
    
    /// UV index display
    var uvDisplay: String {
        guard let weather = currentWeather else {
            return "--"
        }
        return "\(weather.uvIndex) • \(weather.uvDescription)"
    }
    
    /// Data freshness indicator
    var dataFreshnessDisplay: String {
        guard let weather = currentWeather else {
            return ""
        }
        
        if weather.isSimulated {
            return "Données scientifiques"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: weather.timestamp, relativeTo: Date())
    }
    
    /// Mars Sol display
    var solDisplay: String? {
        guard selectedPlanet.id == "mars", let sol = currentWeather?.sol else {
            return nil
        }
        return "Sol \(sol)"
    }
}

// MARK: - Preview Helper

extension PlanetWeatherViewModel {
    /// Create a preview instance with mock data
    static var preview: PlanetWeatherViewModel {
        let vm = PlanetWeatherViewModel(initialPlanet: PlanetDataService.allPlanets[3]) // Earth
        return vm
    }
    
    /// Create a preview instance for a specific planet
    static func preview(for planetId: String) -> PlanetWeatherViewModel {
        let planet = PlanetDataService.allPlanets.first { $0.id == planetId } ?? PlanetDataService.allPlanets[0]
        let vm = PlanetWeatherViewModel(initialPlanet: planet)
        return vm
    }
}
