import SwiftUI
import RealityKit

// MARK: - Planet Half Sphere View (3D RealityKit)

/// Large half-visible sphere for planet detail background
struct PlanetHalfSphereView: View {
    let planet: Planet
    
    @State private var rotationAngle: Float = 0
    @State private var displayLink: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            RealityView { content in
                // Calculate sphere size based on screen
                let screenHeight = Float(geometry.size.height)
                let radius: Float = screenHeight * 0.5
                
                // Create planet sphere
                let mesh = MeshResource.generateSphere(radius: radius)
                let material = PlanetTextureManager.shared.getMaterial(for: planet)
                
                let entity = ModelEntity(mesh: mesh, materials: [material])
                entity.name = "HalfPlanet_\(planet.id)"
                
                // Position: slightly behind camera plane
                entity.position = SIMD3<Float>(0, 0, -radius * 0.7)
                
                // Apply axial tilt
                if let data = PlanetRotationSystem.rotationData[planet.id] {
                    entity.transform.rotation = simd_quatf(angle: data.tilt, axis: SIMD3<Float>(0, 0, 1))
                }
                
                content.add(entity)
                
                // Directional light from right side (creates day/night effect)
                let sunLight = DirectionalLight()
                sunLight.light.intensity = 15000
                sunLight.light.color = .white
                sunLight.look(at: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(8, 2, 4), relativeTo: nil)
                content.add(sunLight)
                
                // Ambient light for dark side visibility
                let ambientEntity = Entity()
                ambientEntity.components.set(PointLightComponent(color: .white, intensity: 300, attenuationRadius: 1000))
                ambientEntity.position = SIMD3<Float>(-5, 0, 3)
                content.add(ambientEntity)
                
            } update: { content in
                // Apply rotation animation
                if let entity = content.entities.first(where: { $0.name == "HalfPlanet_\(planet.id)" }) {
                    let tilt = PlanetRotationSystem.rotationData[planet.id]?.tilt ?? 0
                    let tiltQuat = simd_quatf(angle: tilt, axis: SIMD3<Float>(0, 0, 1))
                    let spinQuat = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 1, 0))
                    entity.transform.rotation = tiltQuat * spinQuat
                }
            }
        }
        .onAppear {
            startRotation()
        }
        .onDisappear {
            stopRotation()
        }
    }
    
    private func startRotation() {
        displayLink = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
            // Slow rotation: ~1 turn in 40 seconds
            rotationAngle += 0.0025
            if rotationAngle > .pi * 2 {
                rotationAngle -= .pi * 2
            }
        }
        RunLoop.main.add(displayLink!, forMode: .common)
    }
    
    private func stopRotation() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        PlanetHalfSphereView(planet: Planet(
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
        .offset(x: -UIScreen.main.bounds.width * 0.4)
    }
}
