import SwiftUI

// MARK: - Solar System Carousel (State A)

/// A horizontal scrollable view showcasing the entire solar system
/// Acts as the main navigation menu (Orrery Mode)
struct SolarSystemCarouselView: View {
    
    // MARK: - Properties
    
    /// The currently selected planet (Binding to parent state)
    @Binding var selectedPlanet: Planet
    
    /// Callback when a planet is tapped
    var onPlanetSelect: (Planet) -> Void
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Spacer()
            
            // Horizontal ScrollView with snapping
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 40) {
                    ForEach(PlanetDataService.allPlanets) { planet in
                        PlanetCarouselItem(
                            planet: planet,
                            isSelected: selectedPlanet.id == planet.id,
                            onSelect: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedPlanet = planet
                                }
                                onPlanetSelect(planet)
                            }
                        )
                    }
                }
                .padding(.horizontal, UIScreen.main.bounds.width / 2 - 60) // Center first/last item
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .frame(height: 200)
            
            Spacer().frame(height: 50)
        }
        .background(Color.clear)
    }
}

// MARK: - Carousel Item

struct PlanetCarouselItem: View {
    let planet: Planet
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // 3D Planet Preview
            PlanetRealityView(planet: planet, mode: .icon)
                .frame(width: 120, height: 120)
                .scaleEffect(isSelected ? 1.2 : 0.8)
                .opacity(isSelected ? 1.0 : 0.6)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                .onTapGesture {
                    onSelect()
                }
            
            // Label
            Text(planet.name.uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .tracking(2)
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
        }
        .frame(width: 120)
    }
}

#Preview {
    SolarSystemCarouselView(
        selectedPlanet: .constant(PlanetDataService.allPlanets[3]),
        onPlanetSelect: { _ in }
    )
}
