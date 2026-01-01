import SwiftUI
import RealityKit

// MARK: - Planet Full View (360° Rotation)

/// Full-screen 360° view of a planet with drag rotation and name below
struct PlanetFullView: View {
    let planet: Planet
    @Environment(\.dismiss) private var dismiss
    
    // Rotation state
    @State private var rotationAngle: Float = 0
    @State private var rotationVelocity: Float = 0.002  // Auto-rotation speed
    @State private var isDragging: Bool = false
    @State private var displayLink: Timer?
    
    var body: some View {
        ZStack {
            // Layer 0: Starfield background
            Color.black.ignoresSafeArea()
            
            // Generated stars
            Canvas { context, size in
                for _ in 0..<200 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let radius = CGFloat.random(in: 0.5...2)
                    let opacity = Double.random(in: 0.3...1.0)
                    let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                    context.fill(Ellipse().path(in: rect), with: .color(.white.opacity(opacity)))
                }
            }
            .ignoresSafeArea()
            
            // Layer 1: 360° Planet (centered)
            GeometryReader { geometry in
                RealityView { content in
                    let size = min(geometry.size.width, geometry.size.height)
                    let radius: Float = Float(size * 0.35)
                    
                    let mesh = MeshResource.generateSphere(radius: radius)
                    let material = PlanetTextureManager.shared.getMaterial(for: planet)
                    
                    let planetEntity = ModelEntity(mesh: mesh, materials: [material])
                    planetEntity.name = "FullPlanet360"
                    planetEntity.position = SIMD3<Float>(0, 0, -radius * 0.5)
                    
                    // Apply axial tilt
                    if let data = PlanetRotationSystem.rotationData[planet.id] {
                        planetEntity.transform.rotation = simd_quatf(angle: data.tilt, axis: SIMD3<Float>(0, 0, 1))
                    }
                    
                    content.add(planetEntity)
                    
                    // Lighting
                    let sunLight = DirectionalLight()
                    sunLight.light.intensity = 15000
                    sunLight.light.color = .white
                    sunLight.look(at: SIMD3<Float>(0, 0, 0), from: SIMD3<Float>(5, 2, 5), relativeTo: nil)
                    content.add(sunLight)
                    
                    // Ambient light
                    let ambientEntity = Entity()
                    ambientEntity.components.set(PointLightComponent(color: .white, intensity: 500, attenuationRadius: 500))
                    ambientEntity.position = SIMD3<Float>(-3, 0, 3)
                    content.add(ambientEntity)
                    
                } update: { content in
                    if let entity = content.entities.first(where: { $0.name == "FullPlanet360" }) {
                        let tilt = PlanetRotationSystem.rotationData[planet.id]?.tilt ?? 0
                        let tiltQuat = simd_quatf(angle: tilt, axis: SIMD3<Float>(0, 0, 1))
                        let spinQuat = simd_quatf(angle: rotationAngle, axis: SIMD3<Float>(0, 1, 0))
                        entity.transform.rotation = tiltQuat * spinQuat
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        rotationAngle += Float(value.translation.width) * 0.005
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            
            // Layer 2: Planet name at bottom
            VStack {
                Spacer()
                
                Text(planet.name.uppercased())
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tracking(4)
                    .foregroundStyle(.white.opacity(0.85))
                    .shadow(color: .black.opacity(0.5), radius: 8, y: 2)
                    .padding(.bottom, 100)
            }
            
            // Layer 3: Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
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
            startAutoRotation()
        }
        .onDisappear {
            stopAutoRotation()
        }
    }
    
    private func startAutoRotation() {
        displayLink = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
            if !isDragging {
                rotationAngle += rotationVelocity
            }
        }
        RunLoop.main.add(displayLink!, forMode: .common)
    }
    
    private func stopAutoRotation() {
        displayLink?.invalidate()
        displayLink = nil
    }
}

#Preview {
    PlanetFullView(planet: Planet(
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
