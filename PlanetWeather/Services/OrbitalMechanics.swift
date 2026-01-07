import Foundation
import simd

// MARK: - Orbital Mechanics Calculator

/// Utility for calculating planetary positions based on Keplerian orbital mechanics.
/// Uses simplified circular orbits for aesthetic "Orrery" visualization.
struct OrbitalMechanics {
    
    // MARK: - Constants
    
    /// J2000 Epoch: January 1, 2000, 12:00 TT (Terrestrial Time)
    static let j2000: Date = {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar(identifier: .gregorian).date(from: components)!
    }()
    
    /// Seconds per day
    private static let secondsPerDay: Double = 86400.0
    
    // MARK: - Position Calculation
    
    /// Calculate the 3D position of a planet at a given date.
    /// - Parameters:
    ///   - planet: The planet to calculate position for.
    ///   - date: The target date.
    ///   - visualRadius: The visual orbital radius (from cinematic scale).
    /// - Returns: Position as SIMD3<Float> on the XZ plane (Y = 0).
    static func position(for planet: Planet, at date: Date, visualRadius: Float) -> SIMD3<Float> {
        // Days elapsed since J2000
        let daysElapsed = date.timeIntervalSince(j2000) / secondsPerDay
        
        // Calculate current angle
        // angle = initialLongitude + (daysElapsed / orbitalPeriod) * 360
        let orbitsCompleted = daysElapsed / planet.orbitalPeriod
        let currentAngleDegrees = planet.initialLongitude + (orbitsCompleted * 360.0)
        
        // Convert to radians
        let angleRadians = currentAngleDegrees * .pi / 180.0
        
        // Calculate position on XZ plane (Y = 0 for flat orbits)
        let x = Float(cos(angleRadians)) * visualRadius
        let z = Float(sin(angleRadians)) * visualRadius
        
        return SIMD3<Float>(x, 0, z)
    }
    
    // MARK: - Rotation Calculation
    
    /// Calculate the rotation angle (spin) for a planet at a given date.
    /// - Parameters:
    ///   - planet: The planet to calculate spin for.
    ///   - date: The target date.
    /// - Returns: Rotation angle in radians around Y axis.
    static func spinAngle(for planet: Planet, at date: Date) -> Float {
        // Days elapsed since J2000
        let daysElapsed = date.timeIntervalSince(j2000) / secondsPerDay
        
        // Rotation period in days (convert from hours)
        let rotationPeriodDays = planet.rotationPeriod / 24.0
        
        // Handle retrograde rotation (negative period means backwards)
        let rotationsCompleted = daysElapsed / abs(rotationPeriodDays)
        let direction: Double = rotationPeriodDays >= 0 ? 1.0 : -1.0
        
        // Angle in radians
        let angleRadians = rotationsCompleted * 2.0 * .pi * direction
        
        return Float(angleRadians.truncatingRemainder(dividingBy: 2.0 * .pi))
    }
}
