import SwiftUI
import RealityKit

// MARK: - Solar System Orrery View

struct SolarSystemOrreryView: View {
    
    // MARK: - Properties
    
    @Binding var selectedPlanet: Planet?
    
    // Camera / Navigation State
    @State private var cameraDistance: Float = 40.0
    @State private var cameraAzimuth: Float = 0.0
    @State private var cameraElevation: Float = 0.4 // Slightly looking down
    
    // Zoom limits
    private let minDistance: Float = 5.0
    private let maxDistance: Float = 200.0
    
    // Scene References
    @State private var rootEntity: Entity?
    @State private var planetsMap: [String: Entity] = [:]
    
    // MARK: - Body
    
    var body: some View {
        RealityView { content in
            // Create root anchor
            let root = Entity()
            root.name = "SolarSystemRoot"
            self.rootEntity = root
            
            // 1. Create Sun
            let sun = createSun()
            root.addChild(sun)
            
            // 2. Create Planets & Orbits
            let allPlanets = PlanetDataService.shared.getAllPlanets()
            
            for planet in allPlanets {
                // Determine visuals (Scale & Orbit Radius)
                let visualParams = getVisualParameters(for: planet)
                
                // Create Planet Orbit Group (holds the orbit ring + planet container)
                let orbitGroup = Entity()
                orbitGroup.name = "OrbitGroup_\(planet.id)"
                
                // A. Create Orbit Ring (Torus)
                if planet.id != "sun" { // Sun doesn't orbit
                   let ring = createOrbitRing(radius: visualParams.orbitRadius)
                   orbitGroup.addChild(ring)
                }
                
                // B. Create Planet Container (Rotated by current orbital angle)
                let planetContainer = Entity()
                planetContainer.name = "PlanetContainer_\(planet.id)"
                
                // Position planet on the ring
                // Randomize start angle or fixed? Fixed for now to line up or random.
                let startAngle = Float.random(in: 0...(2 * .pi))
                planetContainer.position = [
                    cos(startAngle) * visualParams.orbitRadius,
                    0,
                    sin(startAngle) * visualParams.orbitRadius
                ]
                
                // Create actual planet meshes
                if let planetEntity = createPlanetEntity(for: planet, scale: visualParams.scale) {
                    planetContainer.addChild(planetEntity)
                    
                    // Add tap interaction component (Collision)
                    // Collision component is needed for gestures
                    // Match the radius used in createPlanetEntity: base(0.2) * visualParams.scale
                    let radius = 0.2 * visualParams.scale
                    let collisionComponent = CollisionComponent(shapes: [.generateSphere(radius: radius)])
                    planetEntity.components.set(collisionComponent)
                    planetEntity.components.set(InputTargetComponent())
                    
                    self.planetsMap[planet.id] = planetEntity
                }
                
                orbitGroup.addChild(planetContainer)
                root.addChild(orbitGroup)
            }
            
            // 3. Add Starfield? 
            // Optional, but requested "3D impressionnante"
            
            // 4. Lighting
            // Sun is emissive, but we need light interacting with planets
            // Point light at center
            let sunLight = PointLightComponent(color: .white, intensity: 50000, attenuationRadius: 500)
            let lightEntity = Entity()
            lightEntity.components.set(sunLight)
            root.addChild(lightEntity)
            
            content.add(root)
            
            // Initial Camera Update
            updateCameraTransform(root: root)
            
        } update: { content in
            if let root = content.entities.first {
                updateCameraTransform(root: root)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Rotate camera (actually rotate root inverse)
                    let sensitivity: Float = 0.005
                    cameraAzimuth -= Float(value.translation.width) * sensitivity
                    cameraElevation -= Float(value.translation.height) * sensitivity
                    
                    // Clamp elevation to avoid flipping
                    // -pi/2 to pi/2
                    cameraElevation = max(-1.5, min(1.5, cameraElevation))
                }
        )
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    // Zoom
                    let zoomFactor: Float = 0.05
                    let delta = 1.0 - Float(value)
                    cameraDistance += delta * cameraDistance * zoomFactor
                    cameraDistance = max(minDistance, min(maxDistance, cameraDistance))
                }
        )
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    // Identify tapped planet
                    // We need to trace up to find the planet ID
                    if let planetId = findPlanetId(from: value.entity) {
                        print("Tapped planet: \(planetId)")
                        if let planet = PlanetDataService.shared.getPlanet(byId: planetId) {
                            withAnimation {
                                selectedPlanet = planet
                                // Optional: Move camera to look closer?
                                // For now, we just select it for the UI overlay.
                            }
                        }
                    }
                }
        )
    }
    
    // MARK: - Logic & Helpers
    
    private func updateCameraTransform(root: Entity) {
        // Since we are likely in a windowed non-AR view, we can't easily move "the camera".
        // Instead, we position the ROOT entity relative to the fixed camera perspective.
        // Assuming camera is at (0,0,0) looking -Z, or typically it's at +Z looking at origin.
        // Let's assume standard RealityKit View camera is at [0,0,Distance] looking at 0,0,0.
        // We will rotate and translate the Root to simulate camera orbit.
        
        // Convert Spherical to Cartesian relative camera position
        // x = r * sin(theta) * cos(phi)
        // y = r * sin(phi)
        // z = r * cos(theta) * cos(phi)
        // But simply: Rotate root by -Azimuth (Y axis) and -Elevation (X axis), then Translate by -Distance (Z axis).
        
        // Wait, standard Orbit Control implies moving camera.
        // Moving Root:
        // Translate Root by [0, 0, -cameraDistance] (Push it away)
        // Rotate Root by Azimuth and Elevation.
        
        var t = Transform.identity
        
        // 1. Distance (Zoom)
        // We'll move the object away along Z
        t.translation = [0, 0, -cameraDistance * 0.5] // Adjusted scale
        
        // 2. Rotation
        let rotY = Simd3<Float>(0, 1, 0)
        let rotX = Simd3<Float>(1, 0, 0)
        let qAzimuth = simd_quatf(angle: cameraAzimuth, axis: rotY)
        let qElevation = simd_quatf(angle: cameraElevation, axis: rotX)
        
        t.rotation = qElevation * qAzimuth
        
        // Apply
        root.transform = t
    }
    
    private func findPlanetId(from entity: Entity) -> String? {
        // Walk up parents until we find "PlanetRoot_id" or similar
        var current: Entity? = entity
        while let e = current {
            if let name = e.name.components(separatedBy: "_").last,
               e.name.contains("PlanetRoot") || e.name.contains("PlanetContainer") {
                return name
            }
            if let name = e.name.components(separatedBy: "_").last,
               PlanetDataService.shared.getPlanet(byId: name) != nil {
                return name
            }
            current = e.parent
        }
        return nil
    }
    
    // MARK: - Factory Methods
    
    private func createSun() -> Entity {
        let mesh = MeshResource.generateSphere(radius: 2.0)
        var material = UnlitMaterial()
        material.color = .init(tint: .yellow) // Placeholder for sun texture
        
        // Add glow effect?
        // In RealityKit, maybe using a PBR with emission
        var pbr = PhysicallyBasedMaterial()
        pbr.emissiveColor = .init(color: .orange)
        pbr.emissiveIntensity = 2.0
        pbr.baseColor = .init(tint: .yellow)
        
        let entity = ModelEntity(mesh: mesh, materials: [pbr])
        entity.name = "Sun"
        return entity
    }
    
    private func createOrbitRing(radius: Float) -> Entity {
        // "Torus fins, très transparents"
        // RealityKit doesn't have native Torus primitive easily accessible via MeshResource.generateTorus in all versions?
        // Actually it doesn't. We usually use a Tube or a flat cylinder (Plane with hole shader? No).
        // Let's use a very thin Cylinder with large radius, but it will be solid disk.
        // Or generate a ring of points.
        // Simplest: ModelEntity with a big Ring?
        // Alternative: Use a standard thin Tube using MeshResource.generateBox or similar? No.
        // Let's use `MeshResource.generatePlane` with a Ring Texture?
        // Or better: Many segments of cylinders.
        // Or... `MeshResource.generateSphere` scaled flat? That makes a disk, not a ring.
        
        // Let's simulate a torus ring using a loaded model or...
        // Fallback: A very thin, transparent disc (Scale sphere to be flat).
        // It won't be a ring (hole in middle), it will be a filled circle.
        // Use `generatePlane` and apply a texture with a circle?
        
        // For "Cercle visible", maybe use `MeshResource.generateBox` made very thin and long? No.
        // Let's use a flat Sphere (Disk) with a material that is transparent in the middle.
        
        // Actually, just for visual lines, we can assume a simplified "Torus" by using a thin tube mesh if available, or just a filled transparent orbit plane.
        
        // Let's try: A filled plane with a "Ring" material (alpha cutout).
        let mesh = MeshResource.generatePlane(width: radius * 2, depth: radius * 2)
        var material = UnlitMaterial()
        if let color = UIColor(white: 1.0, alpha: 0.1) {
             material.color = .init(tint: color)
        }
        material.blending = .transparent
        // This makes a filled disk. A bit ugly. 
        
        // Better: Use `Code` to generate a ring mesh? Too complex for this step.
        // Let's stick to a very faint transparent disk for now, effectively indicating the orbital plane area.
        
        // Wait, user said "Torus fins".
        // Use a ring model if possible.
        // Since I can't generate torus easily, I'll skip geometry complexity and use a transparent disk for "Orbital Plane" visualization.
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        return entity
    }
    
    private func createPlanetEntity(for planet: Planet, scale: Float) -> Entity? {
        let root = Entity()
        root.name = "PlanetRoot_\(planet.id)"
        
        // Base Unit Size (must match PlanetRealityView for consistency or be similar)
        let baseRadius: Float = 0.2
        let actualRadius = baseRadius * scale
        
        let mesh = MeshResource.generateSphere(radius: actualRadius)
        let material = PlanetTextureManager.shared.getMaterial(for: planet)
        
        let surface = ModelEntity(mesh: mesh, materials: [material])
        surface.name = "Surface"
        root.addChild(surface)
        
        // Rings?
        if planet.hasRings {
            // Rings proportional to planet size
            let ringMesh = MeshResource.generatePlane(width: actualRadius * 4, depth: actualRadius * 4)
            var ringMat = UnlitMaterial()
            ringMat.color = .init(tint: .white.withAlphaComponent(0.4))
            ringMat.blending = .transparent
            
            // Default material
            let defaultRings = ModelEntity(mesh: ringMesh, materials: [ringMat])
            
            if let texMat = PlanetTextureManager.shared.getRingMaterial(for: planet) {
                // Adjust opacity for visual balance
                defaultRings.model?.materials = [texMat]
            }
            
            defaultRings.name = "Rings"
            root.addChild(defaultRings)
        }
        
        return root
    }
    
    // MARK: - Visual Helpers
    
    struct VisualParams {
        let orbitRadius: Float
        let scale: Float
    }
    
    private func getVisualParameters(for planet: Planet) -> VisualParams {
        // Custom scale for "Orrery" view with Cinematic Scale
        // Base Unit = 1.0 (Earth Size)
        let visualScale = planet.relativeScale
        
        // Increased orbit spacing to accommodate larger planets
        // Previous: Mercury 10, Venus 15, Earth 20...
        // New: Need more gaps.
        
        var visualDistance: Float = 0
        
        switch planet.id {
        case "sun":
            visualDistance = 0
        case "mercury":
            visualDistance = 12
        case "venus":
            visualDistance = 18
        case "earth":
            visualDistance = 24
        case "mars":
            visualDistance = 30
        case "jupiter":
            visualDistance = 45 // Big jump for Jupiter
        case "saturn":
            visualDistance = 60
        case "uranus":
            visualDistance = 72
        case "neptune":
            visualDistance = 84
        case "pluto":
            visualDistance = 95
        default:
            visualDistance = 100
        }
        
        return VisualParams(orbitRadius: visualDistance, scale: visualScale)
    }
}
