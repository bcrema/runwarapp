import SwiftUI

struct TileDetailsView: View {
    let tileId: String
    let owner: String
    let shieldIntegrity: Double // 0.0 to 1.0
    let isDisputed: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Drag Indicator
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Tile #\(tileId)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Image(systemName: "flag.fill") // Placeholder for avatar
                            .foregroundColor(.blue)
                        Text("Owner: \(owner)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                if isDisputed {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Disputed")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding(.horizontal)
            
            // Shield Bar
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Shield Integrity")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(Int(shieldIntegrity * 100))%")
                        .font(.caption)
                        .foregroundColor(shieldColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .frame(width: geometry.size.width, height: 8)
                            .opacity(0.1)
                            .foregroundColor(.gray)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .frame(width: geometry.size.width * CGFloat(shieldIntegrity), height: 8)
                            .foregroundColor(shieldColor)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal)
            
            // Actions
            Button(action: {
                // TODO: Set target action
            }) {
                Text("Set as Target")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
    var shieldColor: Color {
        if shieldIntegrity > 0.7 { return .green }
        if shieldIntegrity > 0.3 { return .yellow }
        return .red
    }
}

struct TileDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        TileDetailsView(tileId: "8291", owner: "Team Iron", shieldIntegrity: 0.8, isDisputed: true)
            .previewLayout(.sizeThatFits)
    }
}
