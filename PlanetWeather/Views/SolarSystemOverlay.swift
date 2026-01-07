import SwiftUI

// MARK: - Solar System Overlay

/// UI overlay for the Solar System Orrery view with Control Island
struct SolarSystemOverlay: View {
    
    @Binding var selectedPlanet: Planet?
    @Binding var currentDate: Date
    var onPlanetSelected: ((Planet) -> Void)?
    
    // Settings state
    @State private var showSettings: Bool = false
    @State private var showOrbits: Bool = true
    @State private var ambientMusic: Bool = false
    
    // Time travel indicator
    private var isTimeTraveling: Bool {
        abs(currentDate.timeIntervalSince(Date())) > 60 // More than 1 minute from now
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            // Control Island
            HStack(spacing: 0) {
                // 1. Planet Selector (Left)
                planetSelectorButton
                
                Spacer()
                
                // 2. Time Control (Center)
                timeControlButton
                
                Spacer()
                
                // 3. Settings (Right)
                settingsButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
    }
    
    // MARK: - Planet Selector Button
    
    private var planetSelectorButton: some View {
        Menu {
            ForEach(PlanetDataService.shared.getAllPlanets(), id: \.id) { planet in
                Button {
                    triggerHaptic()
                    selectedPlanet = planet
                    onPlanetSelected?(planet)
                } label: {
                    Label(planet.name, systemImage: planet.symbolName)
                }
            }
        } label: {
            Image(systemName: "list.bullet")
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .controlSize(.large)
    }
    
    // MARK: - Time Control Button
    
    private var timeControlButton: some View {
        Button {
            triggerHaptic()
            withAnimation(.easeInOut(duration: 0.5)) {
                currentDate = Date()
            }
        } label: {
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.title2)
                .foregroundStyle(isTimeTraveling ? .blue : .primary)
                .symbolEffect(.pulse, options: .repeating, isActive: isTimeTraveling)
                .frame(width: 44, height: 44)
        }
        .controlSize(.large)
    }
    
    // MARK: - Settings Button
    
    private var settingsButton: some View {
        Button {
            triggerHaptic()
            showSettings = true
        } label: {
            Image(systemName: "gearshape")
                .font(.title2)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .controlSize(.large)
    }
    
    // MARK: - Settings Sheet
    
    private var settingsSheet: some View {
        NavigationStack {
            List {
                Section("Affichage") {
                    Toggle("Afficher les Orbites", isOn: $showOrbits)
                }
                
                Section("Audio") {
                    Toggle("Musique d'ambiance", isOn: $ambientMusic)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        showSettings = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Haptic Feedback
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
}
