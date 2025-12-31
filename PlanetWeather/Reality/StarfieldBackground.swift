import SwiftUI
import RealityKit

// MARK: - Starfield Background

/// Immersion component providing a 360° starfield background
/// Uses a giant inverted sphere with an unlit material to simulate infinite space
struct StarfieldBackground: View {
    
    // MARK: - Properties
    
    /// Radius of the background sphere (in meters)
    private let sphereRadius: Float = 100.0 // Reduced for testing
    
    // MARK: - Body
    
    var body: some View {
        RealityView { content in
            // Create the sky dome entity
            let skyDome = createSkyDome()
            content.add(skyDome)
        }
    }
    
    // MARK: - Entity Creation
    
    /// Create the starfield entity
    private func createSkyDome() -> Entity {
        // Create a giant sphere mesh
        let mesh = MeshResource.generateSphere(radius: sphereRadius)
        
        // Use centralized safe material loader
        let material = PlanetTextureManager.shared.getStarfieldMaterial()
        
        let entity = ModelEntity(mesh: mesh, materials: [material])
        
        // Invert the sphere so we see it from inside
        entity.scale = SIMD3<Float>(-1, 1, 1)
        
        return entity
    }
}

#Preview {
    StarfieldBackground()
}
