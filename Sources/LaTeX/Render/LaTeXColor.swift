import Foundation

extension LaTeXColor {
    convenience init?(hexString: String) {
        var hexSanitizedString = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        
        if hexSanitizedString.hasPrefix("#") {
            hexSanitizedString.removeFirst()
        }
        
        guard hexSanitizedString.count == 6 || hexSanitizedString.count == 8 else {
            return nil
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexSanitizedString).scanHexInt64(&rgbValue)
        
        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0
        var alpha: CGFloat = 1.0
        
        if hexSanitizedString.count == 8 {
            alpha = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
        }
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
