import SwiftUI
import RealityKit

// MARK: - Planet View Mode

/// Defines the visual state and camera positioning for the planet
enum PlanetViewMode {
    /// Small size, full view (for Carousel)
    case icon
    
    /// Large size, zoomed in on horizon (for Weather/Limb view)
    case limb
    
    /// Full size, centered (for Explorer)
    case explorer
}

// MARK: - Planet Reality View

/// Core 3D component rendering a planet with PBR materials and volumetric atmosphere
struct PlanetRealityView: View {
    
    // MARK: - Properties
    
    /// The planet to render
    let planet: Planet
    
    /// Current visual mode
    let mode: PlanetViewMode
    
    /// Settings
    @State private var rotationAngle: Angle = .zero
    
    // MARK: - Constants
    
    private let planetRadius: Float = 1.0 // Normalized radius
    
    // MARK: - Body
    
    var body: some View {
        RealityView { content in
            // Create the planet root entity
            let planetRoot = Entity()
            planetRoot.name = "PlanetRoot_\(planet.id)"
            
            // 1. Create Surface Sphere
            let surface = createSurfaceEntity()
            planetRoot.addChild(surface)
            
            // 2. Create Cloud Layer (separate geometry, only if texture exists)
            if let cloudEntity = createCloudEntity() {
                planetRoot.addChild(cloudEntity)
            }
            
            // 3. Create Atmosphere (Glow/Fresnel)
            // Note: Even with clouds, we keep atmosphere for the "glow"
            if hasAtmosphere {
                let atmosphere = createAtmosphereEntity()
                planetRoot.addChild(atmosphere)
            }
            
            // 4. Create Ring System (if applicable)
            if planet.hasRings {
                let rings = createRingEntity()
                planetRoot.addChild(rings)
            }
            
            // Sunlight (Directional Light)
            // Essential for 3D volumetric feel. Safe now with sanitized materials.
            let sunlight = createSunLighting()
            planetRoot.addChild(sunlight)
            
            // Apply initial transform based on mode
            planetRoot.transform = transform(for: mode)
            
            content.add(planetRoot)
            
        } update: { content in
            // Update transform when mode changes
            if let root = content.entities.first(where: { $0.name == "PlanetRoot_\(planet.id)" }) {
                // Smoothly animate transition (RealityKit interpolation or manual logic)
                // For V1, we simply set it, animation is handled by SwiftUI transition on the View
                root.transform = transform(for: mode)
            }
        }
    }
    
    // MARK: - Entity Creation
    
    private func createSurfaceEntity() -> ModelEntity {
        // Base radius for Earth = 0.2m (approx 20cm in AR)
        let baseRadius: Float = 0.2
        let actualRadius = baseRadius * planet.relativeScale
        
        let mesh = MeshResource.generateSphere(radius: actualRadius)
        let material = PlanetTextureManager.shared.getMaterial(for: planet)
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Surface"
        
        return entity
    }
    
    private func createCloudEntity() -> ModelEntity? {
        guard let material = PlanetTextureManager.shared.getCloudMaterial(for: planet) else {
            return nil
        }
        
        let baseRadius: Float = 0.2
        let actualRadius = baseRadius * planet.relativeScale
        
        // Clouds are just slightly above surface
        let cloudRadius = actualRadius * 1.01
        let mesh = MeshResource.generateSphere(radius: cloudRadius)
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Clouds"
        
        return entity
    }

    private func createAtmosphereEntity() -> ModelEntity {
        let baseRadius: Float = 0.2
        let actualRadius = baseRadius * planet.relativeScale
        
        // Atmosphere scales relative to the PLANET size
        let atmosphereRadius = actualRadius * PlanetTextureManager.AtmosphereSettings.scaleMultiplier
        
        let mesh = MeshResource.generateSphere(radius: atmosphereRadius)
        let material = PlanetTextureManager.shared.getAtmosphereMaterial(for: planet)
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Atmosphere"
        return entity
    }
    
    private func createRingEntity() -> ModelEntity {
        // Flattened sphere or tube for rings
        // For V1, simple flattened translucent disk
        let mesh = MeshResource.generatePlane(width: planetRadius * 4, depth: planetRadius * 4)
        
        let material: RealityKit.Material
        if let textureMaterial = PlanetTextureManager.shared.getRingMaterial(for: planet) {
            material = textureMaterial
        } else {
            // Fallback generated rings
            var simpleMat = UnlitMaterial()
            if let hex = planet.themeColors.first, let color = UIColor(hex: hex) {
                simpleMat.color = .init(tint: color.withAlphaComponent(0.6))
            } else {
                simpleMat.color = .init(tint: .white.withAlphaComponent(0.4))
            }
            material = simpleMat
        }
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Rings"
        return entity
    }
    
    private func createSunLighting() -> Entity {
        let lightEntity = Entity()
        
        // Main Directional Light (The Sun)
        var sunLight = DirectionalLightComponent()
        sunLight.intensity = 20000 // High intensity for space
        sunLight.color = .white
        // sunLight.isRealWorldProxy = true // Disabled to prevent crash in non-AR window
        
        let sunEntity = Entity()
        sunEntity.components.set(sunLight)
        
        // Position light: coming from top-right-front usually looks good
        // But for "Limb" mode, we want it from behind-top
        sunEntity.position = [5, 5, 10]
        sunEntity.look(at: [0, 0, 0], from: sunEntity.position, relativeTo: nil)
        
        lightEntity.addChild(sunEntity)
        
        return lightEntity
    }
    
    // MARK: - Transforms & Positioning
    
    private func transform(for mode: PlanetViewMode) -> Transform {
        var t = Transform.identity
        
        switch mode {
        case .icon:
            // Small, rotating
            t.scale = SIMD3<Float>(repeating: 0.8)
            t.translation = [0, 0, 0]
            
        case .limb:
            // Giant, pushed down
            // We want to see the horizon
            t.scale = SIMD3<Float>(repeating: 4.0)
            t.translation = [0, -3.5, -2.0] // Down and back
            // Rotate to show limb (equator-ish if sun is top)
            // t.rotation = simd_quatf(angle: .pi / 6, axis: [1, 0, 0])
            
        case .explorer:
            // Standard size, centered
            t.scale = SIMD3<Float>(repeating: 1.5)
            t.translation = [0, 0, 0]
        }
        
        return t
    }
    
    // MARK: - Helpers
    
    private var hasAtmosphere: Bool {
        // Mercury has no atmosphere
        return planet.id != "mercury"
    }
}

// MARK: - UIColor Helper (Duplicated for preview, should be in shared extension)

private extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

#Preview {
    PlanetRealityView(planet: PlanetDataService.allPlanets[3], mode: .explorer) // Earth
}
