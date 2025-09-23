import SwiftUI

enum AppTheme {
    static let background = Color("Background", bundle: .main)
    static let primary = Color("Primary", bundle: .main)
    static let accent = Color("AccentColor", bundle: .main)
    static let link = Color("LinkBlue", bundle: .main)
    static let mutedText = Color.secondary
    static let gradient = LinearGradient(colors: [Color(red: 0.0, green: 0.2, blue: 0.4), Color(red: 0.0, green: 0.76, blue: 0.66)], startPoint: .top, endPoint: .bottom)

    static func configureAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "Primary") ?? UIColor(red: 0.0, green: 0.2, blue: 0.4, alpha: 1.0)
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(named: "AccentColor") ?? UIColor(red: 0.06, green: 0.83, blue: 0.75, alpha: 1.0)
    }
}
