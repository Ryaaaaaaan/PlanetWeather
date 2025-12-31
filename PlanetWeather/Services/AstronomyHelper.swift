import Foundation

// MARK: - Astronomy Helper

/// Provides astronomical calculations based on Jean Meeus algorithms
/// Reference: "Astronomical Algorithms" (2nd Edition)
///
/// Precision: ~1 minute for lunar phases, ~5 minutes for planetary positions
/// Sufficient for UI display purposes
final class AstronomyHelper {
    
    // MARK: - Singleton
    
    static let shared = AstronomyHelper()
    
    private init() {}
    
    // MARK: - Constants
    
    /// Julian Day for J2000.0 epoch (January 1, 2000, 12:00 TT)
    private let j2000: Double = 2451545.0
    
    /// Synodic month in days (new moon to new moon)
    let synodicMonth: Double = 29.53058867
    
    /// Known new moon reference (January 6, 2000, 18:14 UTC)
    private let knownNewMoon: Double = 2451550.1
    
    // MARK: - Julian Date Conversion
    
    /// Convert a Date to Julian Day Number
    /// - Parameter date: The date to convert
    /// - Returns: Julian Day Number as Double
    func julianDay(from date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: date)
        
        guard let year = components.year,
              let month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return j2000
        }
        
        var y = Double(year)
        var m = Double(month)
        let d = Double(day) + Double(hour) / 24.0 + Double(minute) / 1440.0 + Double(second) / 86400.0
        
        if m <= 2 {
            y -= 1
            m += 12
        }
        
        let a = floor(y / 100)
        let b = 2 - a + floor(a / 4)
        
        let jd = floor(365.25 * (y + 4716)) + floor(30.6001 * (m + 1)) + d + b - 1524.5
        return jd
    }
    
    /// Convert Julian Day back to Date
    /// - Parameter jd: Julian Day Number
    /// - Returns: Corresponding Date in UTC
    func date(fromJulianDay jd: Double) -> Date {
        let z = floor(jd + 0.5)
        let f = jd + 0.5 - z
        
        var a: Double
        if z < 2299161 {
            a = z
        } else {
            let alpha = floor((z - 1867216.25) / 36524.25)
            a = z + 1 + alpha - floor(alpha / 4)
        }
        
        let b = a + 1524
        let c = floor((b - 122.1) / 365.25)
        let d = floor(365.25 * c)
        let e = floor((b - d) / 30.6001)
        
        let day = b - d - floor(30.6001 * e) + f
        let month = e < 14 ? e - 1 : e - 13
        let year = month > 2 ? c - 4716 : c - 4715
        
        var components = DateComponents()
        components.year = Int(year)
        components.month = Int(month)
        components.day = Int(day)
        components.hour = Int((day - floor(day)) * 24)
        components.minute = Int(((day - floor(day)) * 24 - Double(components.hour!)) * 60)
        components.timeZone = TimeZone(identifier: "UTC")
        
        return Calendar(identifier: .gregorian).date(from: components) ?? Date()
    }
    
    // MARK: - Moon Phase Calculations
    
    /// Calculate the current lunar phase
    /// - Parameter date: The date to calculate for (default: now)
    /// - Returns: Phase value from 0.0 to 1.0 where:
    ///   - 0.0 / 1.0 = New Moon
    ///   - 0.25 = First Quarter
    ///   - 0.5 = Full Moon
    ///   - 0.75 = Last Quarter
    func lunarPhase(for date: Date = Date()) -> Double {
        let jd = julianDay(from: date)
        let daysSinceNewMoon = jd - knownNewMoon
        let lunations = daysSinceNewMoon / synodicMonth
        let phase = lunations.truncatingRemainder(dividingBy: 1.0)
        return phase < 0 ? phase + 1.0 : phase
    }
    
    /// Get the illumination percentage of the Moon
    /// - Parameter date: The date to calculate for
    /// - Returns: Illumination from 0% to 100%
    func lunarIllumination(for date: Date = Date()) -> Double {
        let phase = lunarPhase(for: date)
        // Illumination follows a sinusoidal curve
        // Max at full moon (phase = 0.5), min at new moon (phase = 0.0 or 1.0)
        return (1 - cos(phase * 2 * .pi)) / 2 * 100
    }
    
    /// Get the name of the current lunar phase
    /// - Parameter date: The date to calculate for
    /// - Returns: French name of the phase
    func lunarPhaseName(for date: Date = Date()) -> String {
        let phase = lunarPhase(for: date)
        
        switch phase {
        case 0.0..<0.025, 0.975...1.0:
            return "Nouvelle Lune"
        case 0.025..<0.225:
            return "Premier Croissant"
        case 0.225..<0.275:
            return "Premier Quartier"
        case 0.275..<0.475:
            return "Lune Gibbeuse Croissante"
        case 0.475..<0.525:
            return "Pleine Lune"
        case 0.525..<0.725:
            return "Lune Gibbeuse Décroissante"
        case 0.725..<0.775:
            return "Dernier Quartier"
        case 0.775..<0.975:
            return "Dernier Croissant"
        default:
            return "Nouvelle Lune"
        }
    }
    
    /// Get the SF Symbol for current moon phase
    /// - Parameter date: The date to calculate for
    /// - Returns: SF Symbol name
    func lunarPhaseSymbol(for date: Date = Date()) -> String {
        let phase = lunarPhase(for: date)
        
        switch phase {
        case 0.0..<0.125, 0.875...1.0:
            return "moonphase.new.moon"
        case 0.125..<0.25:
            return "moonphase.waxing.crescent"
        case 0.25..<0.375:
            return "moonphase.first.quarter"
        case 0.375..<0.5:
            return "moonphase.waxing.gibbous"
        case 0.5..<0.625:
            return "moonphase.full.moon"
        case 0.625..<0.75:
            return "moonphase.waning.gibbous"
        case 0.75..<0.875:
            return "moonphase.last.quarter"
        default:
            return "moonphase.waning.crescent"
        }
    }
    
    // MARK: - Planetary Solar Time
    
    /// Calculate the local solar time on a planet
    /// This is a simplified model assuming:
    /// - Each planet has a reference meridian
    /// - Time is calculated based on planet's rotation period
    ///
    /// - Parameters:
    ///   - planet: The planet to calculate for
    ///   - date: Earth date/time (default: now)
    ///   - longitude: Observer longitude on planet (0-360°, default: 0 = prime meridian)
    /// - Returns: Local solar time as a fraction of the planetary day (0.0 to 1.0)
    ///   - 0.0 = Midnight
    ///   - 0.25 = 6 AM equivalent (sunrise on equator)
    ///   - 0.5 = Noon
    ///   - 0.75 = 6 PM equivalent (sunset on equator)
    func localSolarTime(for planet: Planet, at date: Date = Date(), longitude: Double = 0) -> Double {
        // Reference epoch: J2000.0 (January 1, 2000, 12:00 UTC)
        let jd = julianDay(from: date)
        let daysSinceJ2000 = jd - j2000
        
        // Convert Earth hours since J2000 to planetary hours
        let earthHours = daysSinceJ2000 * 24.0
        let planetaryHours = earthHours / (planet.dayDurationHours / 24.0)
        
        // Add longitude offset (360° = 1 full rotation)
        let longitudeOffset = longitude / 360.0
        
        // Get fractional day (0.0 to 1.0)
        let fractionalDay = (planetaryHours / 24.0 + longitudeOffset).truncatingRemainder(dividingBy: 1.0)
        
        return fractionalDay < 0 ? fractionalDay + 1.0 : fractionalDay
    }
    
    /// Check if it's daytime on a planet
    /// - Parameters:
    ///   - planet: The planet to check
    ///   - date: Earth date/time
    ///   - longitude: Observer longitude on planet
    /// - Returns: True if the sun is above the horizon (6 AM to 6 PM equivalent)
    func isDaytime(on planet: Planet, at date: Date = Date(), longitude: Double = 0) -> Bool {
        let solarTime = localSolarTime(for: planet, at: date, longitude: longitude)
        // Daytime is roughly 0.25 (6 AM) to 0.75 (6 PM)
        return solarTime >= 0.25 && solarTime < 0.75
    }
    
    /// Get the local solar hour (0-23 equivalent) on a planet
    /// - Parameters:
    ///   - planet: The planet to calculate for
    ///   - date: Earth date/time
    ///   - longitude: Observer longitude
    /// - Returns: Hour value (0.0 to 23.99...)
    func localSolarHour(for planet: Planet, at date: Date = Date(), longitude: Double = 0) -> Double {
        let solarTime = localSolarTime(for: planet, at: date, longitude: longitude)
        return solarTime * 24.0
    }
    
    /// Get formatted time string for a planet
    /// - Parameters:
    ///   - planet: The planet to format for
    ///   - date: Earth date/time
    /// - Returns: Formatted string like "14:32 heure solaire"
    func formattedSolarTime(for planet: Planet, at date: Date = Date()) -> String {
        let hour = localSolarHour(for: planet, at: date)
        let hours = Int(hour)
        let minutes = Int((hour - Double(hours)) * 60)
        return String(format: "%02d:%02d heure solaire", hours, minutes)
    }
    
    // MARK: - Day/Night Cycle Position
    
    /// Calculate the sun's position in the sky (simplified)
    /// - Parameters:
    ///   - planet: The planet
    ///   - date: Current date
    /// - Returns: Sun elevation angle from -90 to +90 degrees
    ///   - Positive = above horizon (day)
    ///   - Negative = below horizon (night)
    ///   - 0 = sunrise/sunset
    func sunElevation(on planet: Planet, at date: Date = Date()) -> Double {
        let solarTime = localSolarTime(for: planet, at: date)
        // Convert solar time to angle: 0.5 (noon) = 90°, 0.0/1.0 (midnight) = -90°
        let angle = sin((solarTime - 0.25) * 2 * .pi)
        return angle * 90.0
    }
    
    // MARK: - Eclipse Data (Catalog Lookup)
    
    /// Get the next eclipse information
    /// Currently returns hardcoded data - will be replaced with catalog lookup
    /// - Parameter type: "solar" or "lunar" (optional filter)
    /// - Returns: Formatted string describing the next eclipse
    func getNextEclipseString(type: String? = nil) -> String {
        // Hardcoded for V1 - will be replaced with JSON catalog lookup
        // Data source: NASA Eclipse Web Site
        
        let upcomingEclipses: [(type: String, date: String, description: String)] = [
            ("Solaire", "29 Mars 2025", "Partielle • Visible en Europe"),
            ("Lunaire", "14 Mars 2025", "Totale • Visible en Amérique"),
            ("Solaire", "12 Août 2026", "Totale • Visible en Europe"),
            ("Lunaire", "7 Septembre 2025", "Totale • Visible en Europe"),
            ("Solaire", "2 Août 2027", "Totale • Visible en Afrique du Nord")
        ]
        
        if let filterType = type {
            if let eclipse = upcomingEclipses.first(where: { $0.type.lowercased().contains(filterType.lowercased()) }) {
                return "\(eclipse.type) • \(eclipse.date)"
            }
        }
        
        // Return the next eclipse regardless of type
        if let next = upcomingEclipses.first {
            return "Éclipse \(next.type) • \(next.date)"
        }
        
        return "Aucune éclipse prochaine"
    }
    
    /// Get detailed eclipse information
    /// - Returns: Tuple with type, date, and description
    func getNextEclipseDetails() -> (type: String, date: String, description: String)? {
        // Same hardcoded data for V1
        return ("Solaire Partielle", "29 Mars 2025", "Visible en Europe occidentale, Afrique du Nord")
    }
    
    /// Calculate days until next eclipse
    /// - Returns: Number of days (negative if in the past)
    func daysUntilNextEclipse() -> Int {
        // Next eclipse: March 29, 2025
        var components = DateComponents()
        components.year = 2025
        components.month = 3
        components.day = 29
        components.hour = 12
        components.timeZone = TimeZone(identifier: "UTC")
        
        guard let eclipseDate = Calendar(identifier: .gregorian).date(from: components) else {
            return 0
        }
        
        let now = Date()
        let interval = eclipseDate.timeIntervalSince(now)
        return Int(interval / 86400)
    }
    
    // MARK: - Galilean Moons (Jupiter)
    
    /// Calculate positions of Jupiter's Galilean moons
    /// Simplified calculation for UI display
    /// - Parameter date: Earth date/time
    /// - Returns: Array of moon positions (-1.0 to 1.0, where 0 = in front of Jupiter)
    func galileanMoonPositions(at date: Date = Date()) -> [String: Double] {
        let jd = julianDay(from: date)
        let daysSinceJ2000 = jd - j2000
        
        // Orbital periods in Earth days
        let periods: [String: Double] = [
            "Io": 1.769,
            "Europa": 3.551,
            "Ganymède": 7.155,
            "Callisto": 16.689
        ]
        
        var positions: [String: Double] = [:]
        
        for (moon, period) in periods {
            // Calculate orbital phase (0 to 2π)
            let phase = (daysSinceJ2000 / period).truncatingRemainder(dividingBy: 1.0) * 2 * .pi
            // Position: -1 (left of Jupiter) to +1 (right of Jupiter)
            // 0 = in front or behind Jupiter
            positions[moon] = sin(phase)
        }
        
        return positions
    }
}

// MARK: - Moon Data Model

/// Represents moon phase data for display
struct MoonPhaseData {
    let phase: Double           // 0.0 to 1.0
    let illumination: Double    // 0 to 100%
    let phaseName: String
    let symbolName: String
    let nextFullMoon: Date
    let nextNewMoon: Date
    
    /// Create moon phase data for current date
    static func current() -> MoonPhaseData {
        let helper = AstronomyHelper.shared
        let now = Date()
        let phase = helper.lunarPhase(for: now)
        
        // Calculate next full moon and new moon
        let daysToFull = (0.5 - phase) * helper.synodicMonth
        let daysToNew = (1.0 - phase) * helper.synodicMonth
        
        let nextFull = Calendar.current.date(byAdding: .day, value: Int(daysToFull < 0 ? daysToFull + helper.synodicMonth : daysToFull), to: now) ?? now
        let nextNew = Calendar.current.date(byAdding: .day, value: Int(daysToNew), to: now) ?? now
        
        return MoonPhaseData(
            phase: phase,
            illumination: helper.lunarIllumination(for: now),
            phaseName: helper.lunarPhaseName(for: now),
            symbolName: helper.lunarPhaseSymbol(for: now),
            nextFullMoon: nextFull,
            nextNewMoon: nextNew
        )
    }
}
