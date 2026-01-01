import SwiftUI
import RealityKit

// MARK: - Planet Detail View (Apple Weather iOS 26 Style)

/// Full-screen planet detail with half-sphere, liquid glass cards, and weather data
struct PlanetDetailView: View {
    let planet: Planet
    @Environment(\.dismiss) private var dismiss
    
    @State private var weatherData: PlanetWeatherData?
    
    // Navigation to 360° view
    @State private var showFullPlanetView: Bool = false
    
    // Screen dimensions
    private var screenWidth: CGFloat { UIScreen.main.bounds.width }
    private var screenHeight: CGFloat { UIScreen.main.bounds.height }
    
    var body: some View {
        ZStack {
            // ========================================
            // LAYER 0: Background (Starfield + Gradient)
            // ========================================
            PlanetBackground(planet: planet)
            
            // ========================================
            // LAYER 1: Half-Sphere 3D Planet (TAPPABLE)
            // ========================================
            PlanetHalfSphereView(planet: planet)
                .frame(width: screenWidth, height: screenHeight)
                .offset(x: -screenWidth * 0.4)  // 40% visible on screen
                .contentShape(Rectangle())
                .onTapGesture {
                    showFullPlanetView = true
                }
            
            // ========================================
            // LAYER 2: Gradient Overlay (Readability)
            // ========================================
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.2),
                    .black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            
            // ========================================
            // LAYER 3: Scrollable Content (Liquid Glass)
            // ========================================
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    PlanetWeatherHeader(
                        planetName: planet.name,
                        distance: planet.formattedDistance,
                        temperature: weatherData?.temperature ?? Int(planet.meanTemperature),
                        condition: weatherData?.condition ?? "--",
                        conditionIcon: weatherData?.conditionIcon ?? "questionmark.circle",
                        highTemp: weatherData?.highTemp ?? 0,
                        lowTemp: weatherData?.lowTemp ?? 0,
                        solarTime: weatherData?.solarTime ?? "--:--"
                    )
                    .padding(.top, 80)
                    .padding(.bottom, 40)
                    
                    // Hourly Forecast
                    PlanetHourlyForecastCard(forecasts: weatherData?.hourlyForecasts ?? [])
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    
                    // Info Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        
                        WeatherInfoCard(
                            icon: "wind",
                            title: "VENT",
                            value: "\(weatherData?.windSpeed ?? 0)",
                            unit: "km/h",
                            detail: weatherData?.windDirection != nil ? "Direction: \(weatherData!.windDirection)" : nil
                        )
                        
                        WeatherInfoCard(
                            icon: "aqi.medium",
                            title: "ATMOSPHÈRE",
                            value: weatherData?.pressure ?? "--",
                            unit: weatherData?.pressureUnit ?? "",
                            detail: weatherData?.atmosphereComposition
                        )
                        
                        WeatherInfoCard(
                            icon: "arrow.down.to.line",
                            title: "GRAVITÉ",
                            value: weatherData?.gravity ?? String(format: "%.2f", planet.gravity),
                            unit: "g"
                        )
                        
                        WeatherInfoCard(
                            icon: "sun.max",
                            title: "JOUR SOLAIRE",
                            value: weatherData?.solarDayDuration ?? planet.formattedDayDuration,
                            unit: ""
                        )
                        
                        WeatherInfoCard(
                            icon: "calendar",
                            title: "ANNÉE",
                            value: weatherData?.orbitalPeriod ?? "\(Int(planet.orbitalPeriodDays))",
                            unit: "jours"
                        )
                        
                        WeatherInfoCard(
                            icon: "moon.stars",
                            title: "LUNES",
                            value: "\(weatherData?.moonCount ?? planet.moonCount)",
                            unit: ""
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            // ========================================
            // LAYER 4: Back Button
            // ========================================
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            loadWeatherData()
        }
        .fullScreenCover(isPresented: $showFullPlanetView) {
            PlanetFullView(planet: planet)
        }
    }
    
    private func loadWeatherData() {
        weatherData = PlanetWeatherData.generate(for: planet)
    }
}

// MARK: - Planet Detail Container (Swipe Navigation)

/// Container with swipe navigation between planets
struct PlanetDetailContainerView: View {
    let planets: [Planet]
    @State private var selectedIndex: Int
    
    init(planets: [Planet], initialPlanet: Planet) {
        self.planets = planets
        self._selectedIndex = State(initialValue: planets.firstIndex(where: { $0.id == initialPlanet.id }) ?? 0)
    }
    
    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(planets.indices, id: \.self) { index in
                PlanetDetailView(planet: planets[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea()
    }
}

#Preview {
    PlanetDetailView(planet: Planet(
        id: "venus",
        name: "Vénus",
        type: .terrestrial,
        gravity: 0.91,
        distanceFromSun: 108.2,
        meanTemperature: 458,
        dayDurationHours: 2802,
        atmosphericPressure: 92,
        atmosphereComposition: "CO2 96.5%",
        orbitalPeriodDays: 225,
        moonCount: 0,
        hasRings: false,
        themeColors: ["E4C97A"],
        symbolName: "sparkles"
    ))
}
