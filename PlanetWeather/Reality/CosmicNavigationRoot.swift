import SwiftUI
import RealityKit
import UIKit

// MARK: - Cosmic Navigation Root (Main Container with Native TabBar)

/// Main container view using native iOS TabView
struct CosmicNavigationRoot: View {
    @State private var selectedTab: Int = 0
    @State private var selectedPlanet: Planet?
    @State private var currentDate: Date = Date()
    @State private var dragOffset: CGFloat = 0
    
    // All planets for swipe navigation (excluding sun)
    private var navigablePlanets: [Planet] {
        PlanetDataService.shared.getAllPlanets().filter { $0.id != "sun" }
    }
    
    // Current planet index for carousel navigation
    private var currentPlanetIndex: Int {
        guard let planet = selectedPlanet else { return 0 }
        return navigablePlanets.firstIndex(where: { $0.id == planet.id }) ?? 0
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Solar System (Orrery) with Fullscreen Floating UI
            ZStack {
                // 3D Orrery View (Background)
                SolarSystemOrreryView(
                    selectedPlanet: $selectedPlanet,
                    currentDate: $currentDate
                )
                .ignoresSafeArea()
                
                // Fullscreen Floating Weather UI (when planet is selected)
                if let planet = selectedPlanet {
                    PlanetWeatherFullscreenView(
                        planet: planet,
                        weatherData: PlanetWeatherData.generate(for: planet),
                        onDismiss: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedPlanet = nil
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: selectedPlanet)
            // Global Swipe Gesture on ROOT ZStack
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        // Only horizontal swipe
                        guard abs(value.translation.width) > 50,
                              abs(value.translation.height) < 40,
                              selectedPlanet != nil else {
                            dragOffset = 0
                            return
                        }
                        
                        if value.translation.width < 0 {
                            swipeToNextPlanet()
                        } else {
                            swipeToPreviousPlanet()
                        }
                        dragOffset = 0
                    }
            )
            .tabItem {
                Label("Système", systemImage: "dot.circle.viewfinder")
            }
            .tag(0)
            
            // Tab 2: Exploration (Planet List)
            PlanetListView(selectedPlanet: $selectedPlanet)
                .tabItem {
                    Label("Explorer", systemImage: "globe.europe.africa")
                }
                .tag(1)
            
            // Tab 3: Settings
            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gearshape")
                }
                .tag(2)
        }
    }
    
    // MARK: - Swipe Navigation
    
    private func swipeToNextPlanet() {
        let nextIndex = (currentPlanetIndex + 1) % navigablePlanets.count
        triggerHaptic()
        withAnimation(.easeInOut(duration: 0.5)) {
            selectedPlanet = navigablePlanets[nextIndex]
        }
    }
    
    private func swipeToPreviousPlanet() {
        let prevIndex = (currentPlanetIndex - 1 + navigablePlanets.count) % navigablePlanets.count
        triggerHaptic()
        withAnimation(.easeInOut(duration: 0.5)) {
            selectedPlanet = navigablePlanets[prevIndex]
        }
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Planet Weather Fullscreen View (Apple Weather Style)

/// Fullscreen scrollable view with floating header and glass modules
struct PlanetWeatherFullscreenView: View {
    let planet: Planet
    let weatherData: PlanetWeatherData
    var onDismiss: (() -> Void)?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Flexible spacer pushes content down
                Spacer()
                
                // Floating Header (NO BACKGROUND - directly on 3D)
                floatingHeader
                    .padding(.top, 60) // Below Dynamic Island
                
                // Glass Modules
                hourlyForecastModule
                
                metricsGridModules
                
                additionalInfoModules
                
                // Swipe hint
                swipeHint
                    .padding(.bottom, 100)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Floating Header (No Background)
    
    private var floatingHeader: some View {
        VStack(spacing: 4) {
            // Planet Name (starts just below Dynamic Island)
            Text(planet.name)
                .font(.system(size: 32, weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 4)
            
            // Distance
            HStack(spacing: 4) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.system(size: 12))
                Text(planet.formattedDistance)
                    .font(.system(size: 14))
            }
            .foregroundStyle(.white.opacity(0.7))
            .shadow(color: .black.opacity(0.3), radius: 2)
            
            // Giant Temperature
            Text("\(weatherData.temperature)°")
                .font(.system(size: 96, weight: .thin))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.4), radius: 6)
            
            // Condition
            HStack(spacing: 6) {
                Image(systemName: weatherData.conditionIcon)
                    .font(.system(size: 18))
                Text(weatherData.condition)
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundStyle(.white.opacity(0.9))
            .shadow(color: .black.opacity(0.3), radius: 2)
            
            // High / Low + Solar Time
            HStack(spacing: 12) {
                Text("H:\(weatherData.highTemp)° L:\(weatherData.lowTemp)°")
                    .font(.system(size: 15, weight: .semibold))
                
                Text("•")
                
                HStack(spacing: 4) {
                    Image(systemName: "sun.min")
                        .font(.system(size: 12))
                    Text("\(weatherData.solarTime)")
                }
            }
            .foregroundStyle(.white.opacity(0.6))
            .shadow(color: .black.opacity(0.2), radius: 2)
        }
    }
    
    // MARK: - Hourly Forecast Module (Glass)
    
    private var hourlyForecastModule: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("PRÉVISIONS HORAIRES", systemImage: "clock")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .textCase(.uppercase)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 18) {
                    ForEach(weatherData.hourlyForecasts) { forecast in
                        VStack(spacing: 6) {
                            Text(forecast.hour)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                            
                            Image(systemName: forecast.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(.yellow)
                            
                            Text("\(forecast.temperature)°")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 50)
                    }
                }
                .padding(.vertical, 10)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 15))
    }
    
    // MARK: - Metrics Grid Modules (Glass)
    
    private var metricsGridModules: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            WeatherInfoCard(
                icon: "wind",
                title: "VENT",
                value: "\(weatherData.windSpeed)",
                unit: "km/h",
                detail: "Direction: \(weatherData.windDirection)"
            )
            
            WeatherInfoCard(
                icon: "aqi.medium",
                title: "ATMOSPHÈRE",
                value: weatherData.pressure,
                unit: weatherData.pressureUnit,
                detail: weatherData.atmosphereComposition
            )
        }
    }
    
    // MARK: - Additional Info Modules
    
    private var additionalInfoModules: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            WeatherInfoCard(
                icon: "arrow.down.to.line",
                title: "GRAVITÉ",
                value: weatherData.gravity,
                unit: "g"
            )
            
            WeatherInfoCard(
                icon: "clock",
                title: "JOUR SOLAIRE",
                value: weatherData.solarDayDuration,
                unit: ""
            )
            
            WeatherInfoCard(
                icon: "moon.stars",
                title: "LUNES",
                value: "\(weatherData.moonCount)",
                unit: ""
            )
            
            WeatherInfoCard(
                icon: "circle.circle",
                title: "PÉRIODE ORBITALE",
                value: weatherData.orbitalPeriod,
                unit: "jours"
            )
        }
    }
    
    // MARK: - Swipe Hint
    
    private var swipeHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "chevron.left")
            Text("Glisser pour naviguer")
            Image(systemName: "chevron.right")
        }
        .font(.caption)
        .foregroundStyle(.white.opacity(0.4))
        .padding(.top, 20)
    }
}

// MARK: - Planet List View (Exploration Tab)

struct PlanetListView: View {
    @Binding var selectedPlanet: Planet?
    
    var body: some View {
        NavigationStack {
            List(PlanetDataService.shared.getAllPlanets(), id: \.id) { planet in
                NavigationLink {
                    PlanetDetailView(planet: planet)
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: planet.symbolName)
                            .font(.title2)
                            .foregroundStyle(Color(hex: planet.themeColors.first ?? "#FFFFFF"))
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(planet.name)
                                .font(.headline)
                            Text(planet.type.localizedName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(planet.formattedDistance)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Explorer")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var showOrbits: Bool = true
    @State private var ambientMusic: Bool = false
    @State private var hapticFeedback: Bool = true
    
    var body: some View {
        NavigationStack {
            List {
                Section("Affichage") {
                    Toggle("Afficher les Orbites", isOn: $showOrbits)
                    Toggle("Retour Haptique", isOn: $hapticFeedback)
                }
                
                Section("Audio") {
                    Toggle("Musique d'ambiance", isOn: $ambientMusic)
                }
                
                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Réglages")
        }
    }
}

#Preview {
    CosmicNavigationRoot()
}
