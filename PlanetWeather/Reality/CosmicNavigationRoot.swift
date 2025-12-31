import SwiftUI
import RealityKit
import UIKit

// MARK: - Cosmic Navigation Root (Main Container)

/// Main container view that hosts the immersive solar system experience
struct CosmicNavigationRoot: View {
    @State private var selectedPlanet: Planet?
    
    var body: some View {
        // Only the 3D view - no overlay popup
        SolarSystemOrreryView(selectedPlanet: $selectedPlanet)
            .ignoresSafeArea()
    }
}

#Preview {
    CosmicNavigationRoot()
}
