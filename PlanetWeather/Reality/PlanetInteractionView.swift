import SwiftUI
import RealityKit

// MARK: - Planet Interaction View (State C)

/// Explorer mode allowing full interaction with the planet model
/// Supports rotation (DragGesture) and Zoom (MagnificationGesture)
struct PlanetInteractionView: View {
    
    // MARK: - Properties
    
    let planet: Planet
    
    /// User interaction callbacks
    var onDismiss: () -> Void
    
    // MARK: - State
    
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    
    @State private var currentRotation: Angle = .zero
    @State private var finalRotation: Angle = .zero
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Close Button
            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
            .zIndex(100)
            
            // Interactive 3D Planet
            PlanetRealityView(planet: planet, mode: .explorer)
                .scaleEffect(currentScale)
                .rotation3DEffect(currentRotation, axis: (x: 0, y: 1, z: 0))
                .gesture(
                    SimultaneousGesture(
                        // Zoom Gesture
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / finalScale
                                currentScale = finalScale * delta
                            }
                            .onEnded { value in
                                finalScale = value
                                currentScale = finalScale
                            },
                        // Rotation Gesture
                        DragGesture()
                            .onChanged { value in
                                let delta = Angle(degrees: Double(value.translation.width))
                                currentRotation = finalRotation + delta
                            }
                            .onEnded { value in
                                let delta = Angle(degrees: Double(value.translation.width))
                                finalRotation = finalRotation + delta
                                currentRotation = finalRotation
                            }
                    )
                )
            
            // Info Overlay
            VStack {
                Spacer()
                Text("Mode Explorateur")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
            }
        }
    }
}

#Preview {
    PlanetInteractionView(planet: PlanetDataService.allPlanets[3], onDismiss: {})
}
