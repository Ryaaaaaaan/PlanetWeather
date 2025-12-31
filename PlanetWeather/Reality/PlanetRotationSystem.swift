import RealityKit
import Combine
import Foundation

// MARK: - Planet Rotation System

/// Manages realistic planet rotation with axial tilt and variable speeds
@MainActor
final class PlanetRotationSystem: ObservableObject {
    
    // MARK: - Rotation Data (Realistic values scaled for visibility)
    
    /// timeScale: 1 Earth day = 10 seconds in app
    private static let timeScale: Double = 8640
    
    /// (period in app seconds, tilt in radians, direction: 1=normal, -1=retrograde)
    static let rotationData: [String: (period: Double, tilt: Float, direction: Float)] = [
        "sun":     (period: 25 * 24 * 3600 / timeScale, tilt: 0.126, direction: 1),
        "mercury": (period: 59 * 24 * 3600 / timeScale, tilt: 0.0005, direction: 1),
        "venus":   (period: 243 * 24 * 3600 / timeScale, tilt: 3.096, direction: -1),  // Retrograde
        "earth":   (period: 24 * 3600 / timeScale, tilt: 0.408, direction: 1),
        "mars":    (period: 24.6 * 3600 / timeScale, tilt: 0.440, direction: 1),
        "jupiter": (period: 9.9 * 3600 / timeScale, tilt: 0.054, direction: 1),
        "saturn":  (period: 10.5 * 3600 / timeScale, tilt: 0.466, direction: 1),
        "uranus":  (period: 17.2 * 3600 / timeScale, tilt: 1.706, direction: -1),  // Retrograde
        "neptune": (period: 16.1 * 3600 / timeScale, tilt: 0.494, direction: 1),
        "pluto":   (period: 6.4 * 24 * 3600 / timeScale, tilt: 2.138, direction: 1)
    ]
    
    // MARK: - State
    
    private var startTime: Date = Date()
    private var surfaceEntities: [String: Entity] = [:]
    private var initialRotations: [String: simd_quatf] = [:]
    
    @Published var speedMultiplier: Float = 1.0
    @Published var isPaused: Bool = false
    
    // MARK: - Registration
    
    /// Register a planet's surface entity for rotation
    /// - Parameters:
    ///   - id: Planet identifier
    ///   - rootEntity: The planet's root entity (will search for Surface child)
    func registerPlanet(id: String, rootEntity: Entity) {
        // Find the Surface entity inside the root
        let surfaceName = "Surface"
        guard let surface = rootEntity.children.first(where: { $0.name == surfaceName }) else {
            // If no Surface child, use the root itself (for Sun)
            surfaceEntities[id] = rootEntity
            applyInitialTilt(to: rootEntity, planetId: id)
            return
        }
        
        surfaceEntities[id] = surface
        applyInitialTilt(to: surface, planetId: id)
    }
    
    private func applyInitialTilt(to entity: Entity, planetId: String) {
        guard let data = Self.rotationData[planetId] else { return }
        
        // Apply axial tilt around X axis
        let tiltRotation = simd_quatf(angle: data.tilt, axis: SIMD3<Float>(1, 0, 0))
        initialRotations[planetId] = tiltRotation
        entity.transform.rotation = tiltRotation
    }
    
    // MARK: - Update (Call every frame)
    
    func update() {
        guard !isPaused else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        
        for (planetId, surface) in surfaceEntities {
            guard let data = Self.rotationData[planetId],
                  let initialRotation = initialRotations[planetId] else { continue }
            
            // Calculate current rotation angle
            let rotationSpeed = (2 * Float.pi) / Float(data.period)  // Radians per second
            let currentAngle = rotationSpeed * Float(elapsed) * speedMultiplier * data.direction
            
            // Spin rotation around local Y axis
            let spinRotation = simd_quatf(angle: currentAngle, axis: SIMD3<Float>(0, 1, 0))
            
            // Combine: tilt first, then spin
            surface.transform.rotation = initialRotation * spinRotation
        }
    }
    
    // MARK: - Controls
    
    func reset() {
        startTime = Date()
    }
    
    func setSpeed(_ multiplier: Float) {
        speedMultiplier = multiplier
    }
    
    func togglePause() {
        isPaused.toggle()
    }
}
