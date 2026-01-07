import SwiftUI
import RealityKit
import UIKit

// MARK: - Orbital Mechanics Calculator

/// Utility for calculating planetary positions based on Keplerian orbital mechanics.
/// Uses simplified circular orbits for aesthetic "Orrery" visualization.
struct OrbitalMechanics {
    
    /// J2000 Epoch: January 1, 2000, 12:00 TT
    static let j2000: Date = {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = 12
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }()
    
    private static let secondsPerDay: Double = 86400.0
    
    /// Calculate the 3D position of a planet at a given date.
    static func position(for planet: Planet, at date: Date, visualRadius: Float) -> SIMD3<Float> {
        let daysElapsed = date.timeIntervalSince(j2000) / secondsPerDay
        
        guard planet.orbitalPeriod > 0 else { return .zero }
        
        let orbitsCompleted = daysElapsed / planet.orbitalPeriod
        let currentAngleDegrees = planet.initialLongitude + (orbitsCompleted * 360.0)
        let angleRadians = currentAngleDegrees * .pi / 180.0
        
        let x = Float(cos(angleRadians)) * visualRadius
        let z = Float(sin(angleRadians)) * visualRadius
        
        return SIMD3<Float>(x, 0, z)
    }
    
    /// Calculate the rotation angle (spin) for a planet at a given date.
    static func spinAngle(for planet: Planet, at date: Date) -> Float {
        let daysElapsed = date.timeIntervalSince(j2000) / secondsPerDay
        let rotationPeriodDays = planet.rotationPeriod / 24.0
        
        guard abs(rotationPeriodDays) > 0 else { return 0 }
        
        let direction: Double = rotationPeriodDays >= 0 ? 1.0 : -1.0
        let rotationsCompleted = daysElapsed / abs(rotationPeriodDays)
        let angleRadians = rotationsCompleted * 2.0 * .pi * direction
        
        return Float(angleRadians.truncatingRemainder(dividingBy: 2.0 * .pi))
    }
}


// MARK: - Camera Controller (Orbital + Inverse Transform)
@MainActor
final class CameraController: ObservableObject {
    
    // MARK: - Orbit State
    @Published private(set) var radius: Float = 140.0
    @Published private(set) var theta: Float = Float.pi / 4
    @Published private(set) var phi: Float = 0.4
    
    @Published private(set) var focusCenter: SIMD3<Float> = [0, 0, 0]
    
    // MARK: - Targets
    private var targetRadius: Float = 140.0
    private var targetTheta: Float = Float.pi / 4
    private var targetPhi: Float = 0.4
    private var targetFocusCenter: SIMD3<Float> = [0, 0, 0]
    
    // MARK: - Config
    private let minRadius: Float = 3.0
    private let maxRadius: Float = 800.0
    private let minPhi: Float = -Float.pi / 2 + 0.05
    private let maxPhi: Float = Float.pi / 2 - 0.05
    private let interpolationSpeed: Float = 0.1
    private let rotationSensitivity: Float = 0.005
    
    // MARK: - Computed Transform
    var cameraTransform: Transform {
        let hDistance = radius * cos(phi)
        let x = hDistance * sin(theta)
        let y = radius * sin(phi)
        let z = hDistance * cos(theta)
        
        let positionOffset = SIMD3<Float>(x, y, z)
        let finalPosition = focusCenter + positionOffset
        
        let eye = finalPosition
        let center = focusCenter
        let up: SIMD3<Float> = [0, 1, 0]
        
        let zAxis = simd_normalize(eye - center)
        let xAxis = simd_normalize(simd_cross(up, zAxis))
        let yAxis = simd_cross(zAxis, xAxis)
        
        let rotationMatrix = simd_float3x3(columns: (xAxis, yAxis, zAxis))
        
        return Transform(scale: .one, rotation: simd_quatf(rotationMatrix), translation: finalPosition)
    }
    
    // MARK: - Inverse Transform (Applied to world)
    var inverseCameraTransform: Transform {
        let cam = cameraTransform
        let inverseRotation = cam.rotation.inverse
        let inverseTranslation = inverseRotation.act(-cam.translation)
        return Transform(scale: .one, rotation: inverseRotation, translation: inverseTranslation)
    }
    
    // MARK: - Actions
    func dragOrbit(deltaX: Float, deltaY: Float) {
        targetTheta -= deltaX * rotationSensitivity
        targetPhi += deltaY * rotationSensitivity
        targetPhi = max(minPhi, min(maxPhi, targetPhi))
    }
    
    func zoom(deltaScale: Float) {
        let scaleFactor = 1.0 / deltaScale
        targetRadius *= Float(scaleFactor)
        targetRadius = max(minRadius, min(maxRadius, targetRadius))
    }
    
    func setFocus(center: SIMD3<Float>, radius: Float? = nil) {
        targetFocusCenter = center
        if let r = radius { targetRadius = r }
    }
    
    func resetSystem() {
        setFocus(center: [0,0,0], radius: 140)
        targetPhi = 0.4
        targetTheta = Float.pi / 4
    }
    
    /// Cinematic "Limb Shot" focus - UNIFORM APPARENT SIZE for all planets
    /// Using Sun as reference: all planets appear the same size as Sun does
    /// - Parameters:
    ///   - planetPosition: Current world position of the planet
    ///   - planetRadius: Visual radius of the planet
    func cinematicFocus(on planetPosition: SIMD3<Float>, planetRadius: Float) {
        // REFERENCE: Sun looks perfect at this configuration
        // Sun radius = 5.0 * 0.6 = 3.0
        // Sun appears great at distance ~5.0
        let sunRadius: Float = 3.0
        let sunIdealDistance: Float = 5.0
        
        // Scale camera distance proportionally to maintain same apparent size
        // distance / radius = constant (sunIdealDistance / sunRadius)
        let cameraDistance = planetRadius * (sunIdealDistance / sunRadius)
        
        // Horizontal offset to put planet on LEFT of screen (proportional to distance)
        let horizontalOffset = cameraDistance * 0.25
        
        // Slight elevation for cinematic composition
        let verticalOffset = cameraDistance * 0.08
        
        // Camera focus center (offset from planet)
        targetFocusCenter = planetPosition + SIMD3<Float>(horizontalOffset, verticalOffset, 0)
        
        // Set viewing distance
        targetRadius = cameraDistance
        
        // Camera angles for dramatic composition
        targetPhi = 0.04
        targetTheta = Float.pi / 12
        
        print("📷 Camera: radius=\(planetRadius), distance=\(cameraDistance)")
    }
    
    /// Check if camera is in detail mode (close to a planet)
    var isInDetailMode: Bool {
        return targetRadius < 50.0
    }
    
    // MARK: - Update
    func updateInterpolation() {
        let t = interpolationSpeed
        radius += (targetRadius - radius) * t
        theta += (targetTheta - theta) * t
        phi += (targetPhi - phi) * t
        focusCenter += (targetFocusCenter - focusCenter) * t
    }
}

// MARK: - View
struct SolarSystemOrreryView: View {
    
    @Binding var selectedPlanet: Planet?
    @Binding var currentDate: Date
    var onFocusPlanet: ((String) -> Void)? = nil
    
    @StateObject private var cameraController = CameraController()
    @StateObject private var rotationSystem = PlanetRotationSystem()
    
    // Selection State
    @State private var selectedPlanetId: String? = nil
    @State private var focusedPlanetId: String? = nil
    
    // Navigation State
    @State private var showPlanetDetail: Bool = false
    @State private var planetForDetail: Planet? = nil
    
    // Scene References
    @State private var solarSystemRoot: Entity?
    @State private var planetsMap: [String: Entity] = [:]
    @State private var planetRadii: [String: Float] = [:]
    @State private var arView: ARView?
    
    // Timer
    @State private var displayLink: Timer?
    
    // View Size (for ray-casting)
    @State private var viewSize: CGSize = .zero
    
    // Label position (updated each frame)
    @State private var labelScreenPosition: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: RealityView (3D Scene)
                RealityView { content in
                    // 1. Solar System Root
                    let root = Entity()
                    root.name = "SolarSystemRoot"
                    solarSystemRoot = root
                    content.add(root)
                    
                    // 2. Skybox
                    let skybox = createSkybox()
                    content.add(skybox)
                    
                    // 3. Sun
                    let sun = createSun()
                    root.addChild(sun)
                    planetsMap["sun"] = sun
                    planetRadii["sun"] = 5.0
                    
                    // 4. Planets
                    for planet in PlanetDataService.shared.getAllPlanets() where planet.id != "sun" {
                        let params = getVisualParameters(for: planet)
                        
                        let ring = createOrbitRing(radius: params.orbitRadius)
                        root.addChild(ring)
                        
                        // Use OrbitalMechanics for initial position (based on current date)
                        let initialPos = OrbitalMechanics.position(for: planet, at: Date(), visualRadius: params.orbitRadius)
                        
                        if let planetEntity = createPlanetEntity(for: planet, scale: params.scale) {
                            planetEntity.position = initialPos
                            addCollision(to: planetEntity, radius: 0.6 * params.scale)
                            root.addChild(planetEntity)
                            planetsMap[planet.id] = planetEntity
                            planetRadii[planet.id] = 0.6 * params.scale
                        }
                    }
                    
                    // 5. Light
                    let light = PointLightComponent(color: .white, intensity: 200_000, attenuationRadius: 2000)
                    let lightEntity = Entity()
                    lightEntity.components.set(light)
                    root.addChild(lightEntity)
                    
                    // 6. Initial transform
                    root.transform = cameraController.inverseCameraTransform
                    
                    // 7. Register planets for rotation
                    for (planetId, entity) in planetsMap {
                        rotationSystem.registerPlanet(id: planetId, rootEntity: entity)
                    }
                    
                    print("🚀 Scene initialized with Planet Rotation")
                }
                
                // Layer 2: Gesture Overlay
                GestureOverlay(
                    onPan: { delta in
                        cameraController.dragOrbit(deltaX: Float(delta.x), deltaY: Float(delta.y))
                    },
                    onPanEnded: { },
                    onPinch: { scale in
                        cameraController.zoom(deltaScale: Float(scale))
                    },
                    onPinchEnded: { },
                    onTap: { location in
                        handleTap(at: location, in: geometry.size)
                    },
                    onDoubleTap: { location in
                        handleDoubleTap(at: location, in: geometry.size)
                    }
                )
                
                // Layer 3: Planet Label (Minimalist)
                if let planetId = selectedPlanetId,
                   let planet = PlanetDataService.shared.getPlanet(byId: planetId) {
                    
                    PlanetLabelView(planetName: planet.name, isVisible: true)
                        .position(
                            x: labelScreenPosition.x,
                            y: labelScreenPosition.y + labelOffset(for: planetId)
                        )
                        .allowsHitTesting(false)
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: labelScreenPosition)
                }
            }
            .onAppear {
                viewSize = geometry.size
                startDisplayLink()
            }
            .onDisappear {
                stopDisplayLink()
            }
            .fullScreenCover(isPresented: $showPlanetDetail) {
                if let planet = planetForDetail {
                    PlanetDetailView(planet: planet)
                }
            }
            .onChange(of: selectedPlanet) { oldValue, newValue in
                if let newPlanet = newValue {
                    // Planet changed (via swipe or tap) -> Fly camera to new planet
                    if let entity = planetsMap[newPlanet.id] {
                        // Use visualBounds for accurate radius (accounts for scale)
                        let visualBounds = entity.visualBounds(relativeTo: entity)
                        let visualRadius = max(visualBounds.extents.x, visualBounds.extents.y, visualBounds.extents.z) / 2.0
                        
                        // Fallback to stored radius if visualBounds fails
                        let planetRadius = visualRadius > 0.01 ? visualRadius : (planetRadii[newPlanet.id] ?? 1.0)
                        
                        focusedPlanetId = newPlanet.id
                        selectedPlanetId = newPlanet.id
                        cameraController.cinematicFocus(on: entity.position, planetRadius: planetRadius)
                        print("🎬 Camera flying to: \(newPlanet.name) (radius: \(planetRadius))")
                    }
                } else if oldValue != nil {
                    // Planet deselected -> Reset camera to system view
                    focusedPlanetId = nil
                    selectedPlanetId = nil
                    cameraController.resetSystem()
                    print("📹 Camera reset to system view")
                }
            }
        }
    }
    
    // MARK: - Tap Handling with Ray-casting
    
    private func handleTap(at location: CGPoint, in size: CGSize) {
        if let planetId = findPlanet(at: location, in: size) {
            // Cinematic focus on tapped planet
            if let planet = PlanetDataService.shared.getPlanet(byId: planetId),
               let entity = planetsMap[planetId] {
                
                // Update binding for weather overlay
                selectedPlanet = planet
                selectedPlanetId = planetId
                focusedPlanetId = planetId
                
                // Trigger cinematic camera transition
                let planetRadius = planetRadii[planetId] ?? 1.0
                cameraController.cinematicFocus(on: entity.position, planetRadius: planetRadius)
                
                // Haptic feedback
                triggerSelectionHaptic()
                
                print("🎬 Cinematic focus on: \(planet.name)")
            }
        }
        // Tap on empty space = do nothing (no deselection needed)
    }
    
    private func handleDoubleTap(at location: CGPoint, in size: CGSize) {
        if let planetId = findPlanet(at: location, in: size) {
            focusOnPlanet(id: planetId)
        } else {
            focusedPlanetId = nil
            selectedPlanetId = nil
            selectedPlanet = nil
            cameraController.resetSystem()
        }
    }
    
    // MARK: - Planet Detection (Simplified distance-based)
    
    private func findPlanet(at screenLocation: CGPoint, in size: CGSize) -> String? {
        // Convert screen coordinates to normalized device coordinates
        let ndcX = Float((screenLocation.x / size.width) * 2 - 1)
        let ndcY = Float((1 - screenLocation.y / size.height) * 2 - 1)
        
        // Camera position and direction
        let camTransform = cameraController.cameraTransform
        let cameraPos = camTransform.translation
        
        // Calculate ray direction from camera through screen point
        let fov: Float = Float.pi / 3 // Approximate 60 degree FOV
        let aspect = Float(size.width / size.height)
        
        // Local ray direction (before camera rotation)
        let tanHalfFov = tan(fov / 2)
        let rayDirLocal = simd_normalize(SIMD3<Float>(
            ndcX * tanHalfFov * aspect,
            ndcY * tanHalfFov,
            -1 // Forward is -Z
        ))
        
        // Transform ray direction by camera rotation
        let rayDir = camTransform.rotation.act(rayDirLocal)
        
        // Find closest planet intersection
        var closestPlanetId: String? = nil
        var closestDistance: Float = .infinity
        
        for (planetId, planetEntity) in planetsMap {
            // Get planet world position (before inverse transform)
            let planetLocalPos = planetEntity.position
            
            // Ray-sphere intersection
            let planetRadius = planetRadii[planetId] ?? 1.0
            let hitRadius = planetRadius * 5.0 // Much larger hit area for easier selection
            
            // Vector from camera to planet center
            let toCenter = planetLocalPos - cameraPos
            
            // Project onto ray
            let tClosest = simd_dot(toCenter, rayDir)
            
            if tClosest < 0 { continue } // Planet is behind camera
            
            // Closest point on ray to planet center
            let closestPoint = cameraPos + rayDir * tClosest
            let distToCenter = simd_length(closestPoint - planetLocalPos)
            
            if distToCenter < hitRadius && tClosest < closestDistance {
                closestDistance = tClosest
                closestPlanetId = planetId
            }
        }
        
        return closestPlanetId
    }
    
    // MARK: - Selection
    
    private func selectPlanet(id: String) {
        // Deselect previous
        if let previousId = selectedPlanetId, let previousEntity = planetsMap[previousId] {
            removeHighlight(from: previousEntity)
        }
        
        selectedPlanetId = id
        
        // Apply highlight + change orbit center
        if let entity = planetsMap[id] {
            applyHighlight(to: entity)
            
            // Move orbit center to this planet
            let planetPos = entity.position
            let comfortableRadius = (planetRadii[id] ?? 1.0) * 12.0
            cameraController.setFocus(center: planetPos, radius: comfortableRadius)
        }
        
        // Update binding
        if let planet = PlanetDataService.shared.getPlanet(byId: id) {
            selectedPlanet = planet
        }
        
        // Haptic feedback for premium feel
        triggerSelectionHaptic()
        
        print("🪐 Selected + Orbit center: \(id)")
    }
    
    private func deselectPlanet() {
        if let previousId = selectedPlanetId, let previousEntity = planetsMap[previousId] {
            removeHighlight(from: previousEntity)
        }
        
        selectedPlanetId = nil
        selectedPlanet = nil
        
        // Return orbit center to sun
        cameraController.setFocus(center: [0, 0, 0], radius: 140)
        
        print("🪐 Deselected - Orbit center: Sun")
    }
    
    // MARK: - Focus
    
    func focusOnPlanet(id: String) {
        guard let planetEntity = planetsMap[id] else { return }
        
        selectPlanet(id: id)
        focusedPlanetId = id
        
        let planetPos = planetEntity.position
        let visualRadius = (planetRadii[id] ?? 1.0) * 8.0
        cameraController.setFocus(center: planetPos, radius: visualRadius)
        
        print("🎯 Focus on: \(id)")
    }
    
    // MARK: - Highlight Effects
    
    private func applyHighlight(to entity: Entity) {
        entity.scale = SIMD3<Float>(repeating: 1.15)
    }
    
    private func removeHighlight(from entity: Entity) {
        entity.scale = SIMD3<Float>(repeating: 1.0)
    }
    
    // MARK: - Collision for Ray-casting
    
    private func addCollision(to entity: Entity, radius: Float) {
        // Generate larger sphere for easier tap detection
        let shape = ShapeResource.generateSphere(radius: radius * 3.0)
        entity.components.set(CollisionComponent(shapes: [shape]))
        
        // Add InputTargetComponent for spatial tap gesture support
        entity.components.set(InputTargetComponent())
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerSelectionHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    // MARK: - Display Link
    
    private func startDisplayLink() {
        displayLink = Timer.scheduledTimer(withTimeInterval: 1/120.0, repeats: true) { _ in
            // Use bound currentDate for time travel support
            let animationDate = currentDate
            
            cameraController.updateInterpolation()
            
            if let root = solarSystemRoot {
                root.transform = cameraController.inverseCameraTransform
            }
            
            // Update planet positions using OrbitalMechanics
            for planet in PlanetDataService.shared.getAllPlanets() where planet.id != "sun" {
                if let entity = planetsMap[planet.id] {
                    let params = getVisualParameters(for: planet)
                    let newPos = OrbitalMechanics.position(for: planet, at: animationDate, visualRadius: params.orbitRadius)
                    entity.position = newPos
                    
                    // Apply spin rotation (rotate surface child)
                    if let surface = entity.children.first(where: { $0.name == "Surface" }) {
                        let spinAngle = OrbitalMechanics.spinAngle(for: planet, at: animationDate)
                        surface.transform.rotation = simd_quatf(angle: spinAngle, axis: SIMD3<Float>(0, 1, 0))
                    }
                }
            }
            
            // Follow focused planet with camera (Limb Shot tracking)
            if let focusId = focusedPlanetId,
               let focusedEntity = planetsMap[focusId] {
                // Use visualBounds for accurate radius
                let visualBounds = focusedEntity.visualBounds(relativeTo: focusedEntity)
                let visualRadius = max(visualBounds.extents.x, visualBounds.extents.y, visualBounds.extents.z) / 2.0
                let planetRadius = visualRadius > 0.01 ? visualRadius : (planetRadii[focusId] ?? 1.0)
                cameraController.cinematicFocus(on: focusedEntity.position, planetRadius: planetRadius)
            }
            
            // Update planet rotations (additional system if any)
            rotationSystem.update()
            
            // Update label position if planet is selected
            if let planetId = selectedPlanetId {
                updateLabelPosition(for: planetId)
            }
        }
    }
    
    // MARK: - 3D to 2D Projection
    
    private func updateLabelPosition(for planetId: String) {
        guard viewSize.width > 0, viewSize.height > 0 else { return }
        
        if let screenPos = projectToScreen(planetId: planetId, in: viewSize) {
            labelScreenPosition = screenPos
        }
    }
    
    private func projectToScreen(planetId: String, in size: CGSize) -> CGPoint? {
        guard let planetEntity = planetsMap[planetId] else { return nil }
        
        let planetPos = planetEntity.position
        let camTransform = cameraController.cameraTransform
        let cameraPos = camTransform.translation
        
        // Vector from camera to planet
        let relativePos = planetPos - cameraPos
        
        // Camera basis vectors
        let viewDir = camTransform.rotation.act(SIMD3<Float>(0, 0, -1))
        let rightDir = camTransform.rotation.act(SIMD3<Float>(1, 0, 0))
        let upDir = camTransform.rotation.act(SIMD3<Float>(0, 1, 0))
        
        // Depth (distance along view direction)
        let depth = simd_dot(relativePos, viewDir)
        guard depth > 0.1 else { return nil } // Behind camera
        
        // Project onto screen plane
        let fov: Float = .pi / 3 // 60 degrees
        let scale = 1.0 / (depth * tan(fov / 2))
        
        let screenX = simd_dot(relativePos, rightDir) * scale
        let screenY = simd_dot(relativePos, upDir) * scale
        
        // Convert to SwiftUI coordinates
        let x = CGFloat(screenX) * size.width / 2 + size.width / 2
        let y = -CGFloat(screenY) * size.height / 2 + size.height / 2
        
        return CGPoint(x: x, y: y)
    }
    
    private func labelOffset(for planetId: String) -> CGFloat {
        let radius = planetRadii[planetId] ?? 1.0
        let distance = cameraController.radius
        
        // Apparent size on screen (perspective)
        let apparentSize = CGFloat(radius / distance) * 600
        
        // Just below the planet
        return apparentSize + 35
    }
    
    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - Entity Factories
    
    private func createSkybox() -> Entity {
        let mesh = MeshResource.generateSphere(radius: 900)
        let material = PlanetTextureManager.shared.getStarfieldMaterial()
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.scale = [-1,1,1]
        entity.name = "Skybox"
        return entity
    }
    
    private func createSun() -> Entity {
        let mesh = MeshResource.generateSphere(radius: 5)
        if let sunPlanet = PlanetDataService.shared.getPlanet(byId: "sun") {
            let material = PlanetTextureManager.shared.getMaterial(for: sunPlanet)
            let entity = ModelEntity(mesh: mesh, materials: [material])
            entity.name = "PlanetRoot_sun"
            return entity
        }
        var pbr = PhysicallyBasedMaterial()
        pbr.emissiveColor = .init(color: .orange)
        pbr.emissiveIntensity = 5
        pbr.baseColor = .init(tint: .yellow)
        let entity = ModelEntity(mesh: mesh, materials: [pbr])
        entity.name = "PlanetRoot_sun"
        return entity
    }
    
    private func createOrbitRing(radius: Float) -> Entity {
        let mesh = MeshResource.generatePlane(width: radius*2, depth: radius*2)
        var material = UnlitMaterial()
        material.color = .init(tint: .white.withAlphaComponent(0.015))
        material.blending = .transparent(opacity: 0.03)
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    private func createPlanetEntity(for planet: Planet, scale: Float) -> Entity? {
        let root = Entity()
        root.name = "PlanetRoot_\(planet.id)"
        let radius: Float = 0.6 * scale
        let mesh = MeshResource.generateSphere(radius: radius)
        let material = PlanetTextureManager.shared.getMaterial(for: planet)
        let surface = ModelEntity(mesh: mesh, materials: [material])
        surface.name = "Surface"
        root.addChild(surface)
        
        if planet.hasRings {
            let ringMesh = MeshResource.generatePlane(width: radius*5, depth: radius*5)
            if let ringMat = PlanetTextureManager.shared.getRingMaterial(for: planet) {
                let rings = ModelEntity(mesh: ringMesh, materials: [ringMat])
                rings.name = "Rings"
                
                // Apply axial tilt to rings (they don't rotate with the surface, so we tilt them manually)
                if let data = PlanetRotationSystem.rotationData[planet.id] {
                    rings.transform.rotation = simd_quatf(angle: data.tilt, axis: SIMD3<Float>(1, 0, 0))
                }
                
                root.addChild(rings)
            }
        }
        return root
    }
    
    private func getVisualParameters(for planet: Planet) -> (orbitRadius: Float, scale: Float) {
        let scale = planet.relativeScale
        let distance: Float
        switch planet.id {
        case "sun": distance = 0
        case "mercury": distance = 15
        case "venus": distance = 22
        case "earth": distance = 30
        case "mars": distance = 40
        case "jupiter": distance = 60
        case "saturn": distance = 85
        case "uranus": distance = 110
        case "neptune": distance = 140
        case "pluto": distance = 170
        default: distance = 180
        }
        return (distance, scale)
    }
}