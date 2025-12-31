import Foundation
import RealityKit
import UIKit

// MARK: - Planet Texture Manager (Safe Mode)

/// Robust texture manager that loads from Bundle and never crashes.
/// Handles missing files gracefully with fallback materials.
@MainActor
final class PlanetTextureManager {
    
    // MARK: - Singleton
    
    static let shared = PlanetTextureManager()
    
    private init() {}
    
    // MARK: - Planet Colors (Fallback)
    
    private let planetColors: [String: UIColor] = [
        "sun": UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0),
        "mercury": UIColor(red: 0.6, green: 0.5, blue: 0.5, alpha: 1.0),
        "venus": UIColor(red: 0.9, green: 0.7, blue: 0.5, alpha: 1.0),
        "earth": UIColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1.0),
        "mars": UIColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0),
        "jupiter": UIColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0),
        "saturn": UIColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 1.0),
        "uranus": UIColor(red: 0.5, green: 0.8, blue: 0.9, alpha: 1.0),
        "neptune": UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 1.0),
        "pluto": UIColor(red: 0.7, green: 0.6, blue: 0.5, alpha: 1.0),
        "moon": UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
    ]
    
    // MARK: - Public Methods
    
    /// Get a safe material for a given planet
    func getMaterial(for planet: Planet) -> RealityKit.Material {
        let logicalName = mapToLogicalName(planet.id)
        let filename = "\(logicalName)_diffuse"
        
        // 1. Try to load texture from Bundle
        if let texture = loadTextureFromBundle(named: filename, extension: "jpg") {
            // Success! Use texture
            var material = SimpleMaterial()
            material.color = .init(texture: .init(texture))
            // Note: We intentionally avoid setting roughness/metallic to keep it safe for Simulator
            return material
        }
        
        // 2. Fallback: Color
        print("⚠️ [PlanetTextureManager] Fallback to color for: \(planet.name) (Missing: \(filename).jpg)")
        let color = planetColors[logicalName] ?? .gray
        return SimpleMaterial(color: color, isMetallic: false)
    }
    
    /// Get the atmosphere material
    func getAtmosphereMaterial(for planet: Planet) -> RealityKit.Material {
        let logicalName = mapToLogicalName(planet.id)
        
        // Special case for Venus atmosphere texture
        if logicalName == "venus", let texture = loadTextureFromBundle(named: "venus_atmosphere", extension: "jpg") {
             var material = UnlitMaterial()
             material.color = .init(texture: .init(texture))
             material.blending = .transparent(opacity: 0.9)
             return material
        }
        
        // Standard Atmosphere (Color-based)
        let baseColor = planetColors[logicalName] ?? .cyan
        var material = UnlitMaterial()
        material.color = .init(tint: baseColor.withAlphaComponent(0.2))
        material.blending = .transparent(opacity: 0.25)
        
        return material
    }
    
    /// Get the cloud material if available
    func getCloudMaterial(for planet: Planet) -> RealityKit.Material? {
        // Disabled for V1 stabilization
        return nil
    }

    /// Get the ring material (Saturn only for now)
    func getRingMaterial(for planet: Planet) -> RealityKit.Material? {
        let logicalName = mapToLogicalName(planet.id)
        
        if logicalName == "saturn" {
            // Try explicit ring texture first
            if let texture = loadTextureFromBundle(named: "saturn_ring", extension: "png") {
                 var material = UnlitMaterial()
                 material.color = .init(texture: .init(texture))
                 material.blending = .transparent(opacity: 0.8)
                 return material
            }
            
            // Fallback translucent ring
            var material = UnlitMaterial()
            material.color = .init(tint: UIColor(red: 0.8, green: 0.7, blue: 0.5, alpha: 0.6))
            material.blending = .transparent(opacity: 0.6)
            return material
        }
        
        return nil // No rings for others
    }
    
    /// Load background starmap safely
    func getStarfieldMaterial() -> RealityKit.Material {
        if let texture = loadTextureFromBundle(named: "starmap_background", extension: "jpg") {
            var material = UnlitMaterial()
            material.color = .init(texture: .init(texture))
            return material
        }
        
        // Fallback: Deep Space Black
        var material = UnlitMaterial()
        material.color = .init(tint: UIColor(displayP3Red: 0.02, green: 0.02, blue: 0.05, alpha: 1.0))
        return material
    }

    // MARK: - Private Helper
    
    private func loadTextureFromBundle(named filename: String, extension ext: String) -> TextureResource? {
        // 1. Check paths (Root and Textures subfolder)
        let potentialURLs = [
            Bundle.main.url(forResource: filename, withExtension: ext),
            Bundle.main.url(forResource: filename, withExtension: ext, subdirectory: "Textures")
        ].compactMap { $0 }
        
        guard let url = potentialURLs.first else {
            // Silent fail here, caller handles fallback logging if needed
            // print("❌ [PlanetTextureManager] File not found in Bundle: \(filename).\(ext)")
            return nil
        }
        
        // 2. Safely load
        do {
            // options: .init(semantic: .color) ensures proper sRGB/Linear handling
            return try TextureResource.load(contentsOf: url)
        } catch {
            print("🛑 [PlanetTextureManager] Failed to load texture at \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    /// Map internal ID to filename prefix
    private func mapToLogicalName(_ id: String) -> String {
        let input = id.lowercased()
        switch input {
        case "soleil", "sun": return "sun"
        case "mercure", "mercury": return "mercury"
        case "venus", "vénus": return "venus"
        case "terre", "earth": return "earth"
        case "mars": return "mars"
        case "jupiter": return "jupiter"
        case "saturne", "saturn": return "saturn"
        case "uranus": return "uranus"
        case "neptune": return "neptune"
        case "pluton", "pluto": return "pluto"
        case "lune", "moon": return "moon"
        default: return input
        }
    }
}

// MARK: - Settings

extension PlanetTextureManager {
    struct AtmosphereSettings {
        static let scaleMultiplier: Float = 1.025
    }
}
