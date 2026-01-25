import SwiftUI

struct Tile: Identifiable {
    let id: String
    let ownerName: String?
    let ownerColor: String? // Hex string
    let shield: Int // 0-100
    let isInDispute: Bool
    let isInCooldown: Bool
}

struct TileDetailsView: View {
    let tile: Tile
    
    // Design System Colors
    private let tealColor = Color(red: 0/255, green: 200/255, blue: 150/255)
    private let darkColor = Color(red: 30/255, green: 30/255, blue: 30/255)
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Territory #\(tile.id.prefix(6))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(darkColor)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: tile.ownerColor ?? "#CCCCCC"))
                            .frame(width: 8, height: 8)
                        
                        Text(tile.ownerName ?? "Neutral Territory")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                if tile.isInDispute {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Disputed")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.top, 24)
            
            // Shield Status
            VStack(spacing: 8) {
                HStack {
                    Text("Shield Integrity")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(tile.shield)%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(shieldColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(shieldColor)
                            .frame(width: (CGFloat(tile.shield) / 100.0) * geometry.size.width, height: 12)
                    }
                }
                .frame(height: 12)
                
                if tile.isInCooldown {
                    HStack {
                        Image(systemName: "clock")
                        Text("Shield regenerating...")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
            }
            .padding(.all, 16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            .padding(.horizontal)
            
            Spacer()
            
            // Action Button
            Button(action: {
                // TODO: Start Run targeting this tile
            }) {
                Text("Start Mission Here")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(tealColor)
                    .cornerRadius(16)
                    .shadow(color: tealColor.opacity(0.4), radius: 10, x: 0, y: 6)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color(UIColor.systemBackground))
    }
    
    var shieldColor: Color {
        if tile.shield > 70 { return tealColor }
        if tile.shield > 30 { return .yellow }
        return .red
    }
}

// Helper for Hex Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct TileDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TileDetailsView(tile: Tile(id: "8291-A", ownerName: "Team Iron", ownerColor: "#3498db", shield: 80, isInDispute: true, isInCooldown: false))
            .previewLayout(.sizeThatFits)
    }
}
