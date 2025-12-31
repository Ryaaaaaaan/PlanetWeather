import SwiftUI

struct PlanetInfoOverlay: View {
    @Binding var selectedPlanet: Planet?
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text("Système Solaire")
                    .font(.system(.largeTitle, design: .rounded))
                    .bold()
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                
                Spacer()
                
                // Example Toolbar Button
                Button {
                    // Settings or Reset
                    withAnimation {
                        selectedPlanet = nil
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.gray.opacity(0.5))
            }
            .padding()
            
            Spacer()
            
            // Planet Info Panel (Only if selected)
            if let planet = selectedPlanet {
                VStack(alignment: .leading, spacing: 16) {
                    // Title Row
                    HStack {
                        Image(systemName: planet.symbolName)
                            .font(.largeTitle)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color(hex: planet.themeColors.first ?? "#FFFFFF"))
                        
                        Text(planet.name)
                            .font(.system(.title, design: .rounded))
                            .bold()
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                selectedPlanet = nil
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Info Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        InfoItem(icon: "thermometer.medium", title: "Temp", value: planet.formattedTemperature)
                        InfoItem(icon: "scalemass", title: "Gravité", value: planet.formattedGravity)
                        InfoItem(icon: "clock", title: "Jour", value: planet.formattedDayDuration)
                        InfoItem(icon: "ruler", title: "Distance", value: planet.formattedDistance)
                    }
                    
                    // Native Action Button
                    Button {
                        // Action: Explore more details?
                    } label: {
                        HStack {
                            Text("Explorer Détails")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.top, 8)
                }
                .padding(24)
                .background(.regularMaterial) // Native material
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

// Helper View
struct InfoItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)
        }
    }
}
