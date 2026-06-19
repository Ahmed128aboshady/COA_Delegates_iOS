import SwiftUI

struct AppColors {
    static let primaryDarkBlue = Color(hex: 0x0A2342)
    static let accentRed = Color(hex: 0xC0392B)
    static let backgroundWhite = Color.white
    static let cardGray = Color(hex: 0xF5F5F5)
    static let successGreen = Color(hex: 0x27AE60)
    static let warningOrange = Color(hex: 0xF39C12)
    static let textPrimary = Color(hex: 0x1A1A2E)
    static let textSecondary = Color(hex: 0x6C757D)
    static let dividerGray = Color(hex: 0xE0E0E0)
    static let statusBlue = Color(hex: 0x2980B9)
    static let methodPurple = Color(hex: 0x8E44AD)
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
