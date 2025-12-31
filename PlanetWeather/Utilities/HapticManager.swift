import SwiftUI
import CoreHaptics

// MARK: - Haptic Manager

/// Centralized haptic feedback manager for premium tactile experience
/// Provides consistent haptic patterns throughout the app
final class HapticManager {
    
    // MARK: - Singleton
    
    static let shared = HapticManager()
    
    // MARK: - Properties
    
    private var engine: CHHapticEngine?
    private var supportsHaptics: Bool = false
    
    // MARK: - Initialization
    
    private init() {
        setupEngine()
    }
    
    private func setupEngine() {
        // Check device capability
        supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        
        guard supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            
            // Handle engine reset
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                } catch {
                    print("Haptic engine reset failed: \(error)")
                }
            }
            
            // Handle engine stop
            engine?.stoppedHandler = { reason in
                print("Haptic engine stopped: \(reason)")
            }
            
        } catch {
            print("Haptic engine creation failed: \(error)")
        }
    }
    
    // MARK: - Simple Feedback (UIKit-based)
    
    /// Light tap for subtle interactions (button presses, small changes)
    func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// Medium tap for confirmations
    func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// Heavy impact for important events (alerts, warnings)
    func heavyImpact() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// Soft impact for gentle transitions
    func softImpact() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// Rigid impact for definitive actions
    func rigidImpact() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// Success notification
    func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// Warning notification
    func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// Error notification
    func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// Selection changed (for pickers, page changes)
    func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Planet Navigation Haptics
    
    /// Haptic for swiping between planets
    /// Provides a satisfying "soft lock" feeling
    func planetSwipe() {
        softImpact()
    }
    
    /// Haptic when landing on a new planet page
    func planetLanded() {
        rigidImpact()
    }
    
    // MARK: - Weather Alert Haptics
    
    /// Haptic for minor weather alerts
    func minorAlert() {
        lightTap()
    }
    
    /// Haptic for moderate weather alerts
    func moderateAlert() {
        mediumTap()
    }
    
    /// Haptic for severe weather alerts (storms, CME)
    func severeAlert() {
        heavyImpact()
        
        // Follow up with a rumble pattern for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.mediumTap()
        }
    }
    
    // MARK: - Custom Haptic Patterns (CoreHaptics)
    
    /// Play a custom "cosmic" pattern for special events
    func cosmicPulse() {
        guard supportsHaptics, let engine = engine else {
            // Fallback to simple haptic
            heavyImpact()
            return
        }
        
        do {
            // Create a pattern of increasing intensity
            var events: [CHHapticEvent] = []
            
            // Initial soft pulse
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 0.2
            ))
            
            // Peak impact
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.2
            ))
            
            // Fade out
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0.25,
                duration: 0.3
            ))
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
        } catch {
            print("Cosmic pulse haptic failed: \(error)")
            heavyImpact()
        }
    }
    
    /// Play a "storm warning" pattern
    func stormWarning() {
        guard supportsHaptics, let engine = engine else {
            severeAlert()
            return
        }
        
        do {
            var events: [CHHapticEvent] = []
            
            // Three rapid pulses
            for i in 0..<3 {
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
                    ],
                    relativeTime: Double(i) * 0.15
                ))
            }
            
            // Final heavy impact
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.6
            ))
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            
        } catch {
            print("Storm warning haptic failed: \(error)")
            severeAlert()
        }
    }
    
    // MARK: - Engine Control
    
    /// Prepare the engine (call before intensive haptic use)
    func prepare() {
        guard supportsHaptics else { return }
        
        do {
            try engine?.start()
        } catch {
            print("Failed to prepare haptic engine: \(error)")
        }
    }
    
    /// Stop the engine (for power saving in background)
    func stop() {
        engine?.stop()
    }
}

// MARK: - SwiftUI View Modifier

/// Convenience modifier for haptic feedback on tap
struct HapticTapModifier: ViewModifier {
    let style: HapticStyle
    
    enum HapticStyle {
        case light, medium, heavy, soft, rigid, selection
    }
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        switch style {
                        case .light:
                            HapticManager.shared.lightTap()
                        case .medium:
                            HapticManager.shared.mediumTap()
                        case .heavy:
                            HapticManager.shared.heavyImpact()
                        case .soft:
                            HapticManager.shared.softImpact()
                        case .rigid:
                            HapticManager.shared.rigidImpact()
                        case .selection:
                            HapticManager.shared.selectionChanged()
                        }
                    }
            )
    }
}

extension View {
    /// Add haptic feedback on tap
    func hapticFeedback(_ style: HapticTapModifier.HapticStyle = .light) -> some View {
        modifier(HapticTapModifier(style: style))
    }
}
