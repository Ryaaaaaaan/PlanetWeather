import SwiftUI

/// CosmicWeather - A Solar System Weather Experience
/// Inspired by Apple Weather App with Liquid Glass Design
///
/// Features:
/// - Real-time simulation of planetary weather
/// - NASA API integration for Mars and Space Weather
/// - Jean Meeus astronomical calculations
/// - Premium "Liquid Glass" UI design
@main
struct PlanetWeatherApp: App {
    
    var body: some Scene {
        WindowGroup {
            CosmicNavigationRoot()
        }
    }
}
