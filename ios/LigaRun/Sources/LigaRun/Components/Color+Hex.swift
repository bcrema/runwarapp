import SwiftUI

extension Color {
    init(hex: String) {
        let hexSanitized = hex
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        var int: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&int)

        let r, g, b: Double
        switch hexSanitized.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 0.42; g = 0.4; b = 0.45
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
