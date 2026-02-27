import SwiftUI
import Dialogue

/// A codable structure that can hold color data.
///
/// `Color` is a notoriously un-codable class, and cannot directly be stored in a codable data structure. `ColorData` provides a way to convert colors into a codable structure.
///
/// ```swift
/// struct Object: Codable {
///     let blue = Color.blue           // ❌ Won't conform
///     let blue = ColorData.of(.blue)  // ✅ Will conform
///
///     // Alternative Color -> ColorData helper:
///     let blue: ColorData = Color.blue.data
/// }
/// ```
///
/// In addition to converting colors to data, helper extensions can convert data back into usable color classes.
///
/// ```swift
/// let blue = Object.blue         // Returns as ColorData
/// let blue = Object.blue.color   // Returns as Color
/// let blue = Object.blue.uiColor // Returns as UIColor
/// ```
///
/// ## Encoding Opacity
/// Alpha values are also encoded into `ColorData` and decoded into all usable color classes, so even colors with opacity modifiers can be encoded as is.
///
/// ```swift
/// let fullOrange: Color = .orange
/// let opaqueOrange: Color = .orange.opacity(0.5)
///
/// let fullOrangeData = ColorData.of(fullOrange)!
/// let opaqueOrangeData = ColorData.of(opaqueOrange)!
///
/// print(fullOrangeData.hex!)    // Returns #FF9230FF
/// print(opaqueOrangeData.hex!)  // Returns #FF923080
/// ```
public struct ColorData: Codable, Equatable {
    /// The hexadecimal code of the color.
    public let hex: String
    
    // The red value of the color, expressed as a decimal out of 1.0.
    internal let r: Float
    
    // The green value of the color, expressed as a decimal out of 1.0.
    internal let g: Float
    
    // The blue value of the color, expressed as a decimal out of 1.0.
    internal let b: Float
    
    // The opacity of the color, expressed as a decimal out of 1.0.
    internal let alpha: Float
    
    public init(r: Float, g: Float, b: Float, alpha: Float = 1) {
        guard r >= 0 && r <= 1,
              g >= 0 && g <= 1,
              b >= 0 && b <= 1,
              alpha >= 0 && alpha <= 1 else {
            fatalError("Value overflow, all values must be between 0 and 1. (r: \(r), g: \(g), b: \(b), alpha: \(alpha))")
        }
        
        self.r = r
        
        self.g = g
        
        self.b = b
        
        self.alpha = alpha
        
        let uiColor = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(alpha))
        
        self.hex = uiColor.hex
    }
    
    public static func == (lhs: ColorData, rhs: ColorData) -> Bool {
        let hexesMatch: Bool = lhs.hex == rhs.hex
        
        let valuesMatch: Bool = lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.alpha == rhs.alpha
        
        return hexesMatch && valuesMatch
    }
}

// MARK: - Extensions

public extension ColorData {
    /// An empty value.
    ///
    /// - Returns: A `ColorData` object with red, green, and blue value set to 0, equivalent to black.
    static var empty: Self { ColorData(r: 0, g: 0, b: 0) }
    
    static func of(_ color: ShapeStyleColor) -> Self { return color.data }
    
    /// The color decoded from the data.
    ///
    /// - Returns: An optional `UIColor` value.
    var color: Color? {
        guard let color = Color(hex: self.hex) else { return nil }
        
        return color
    }
    
    /// The color decoded from the data.
    ///
    /// - Returns: An optional `UIColor` value.
    var uiColor: UIColor? {
        guard let uiColor = UIColor(hex: self.hex) else { return nil }
        
        return uiColor
    }
}

// MARK: - Protocols

/// A protocol for color variants of a ShapeStyle.
public protocol ShapeStyleColor {
    var data: ColorData { get }
}

extension Color: ShapeStyleColor {
    /// Stores the values of the color into a ColorData object.
    public var data: ColorData {
        let uiColor = UIColor(self)
        
        var rVal: CGFloat = 0
        
        var bVal: CGFloat = 0
        
        var gVal: CGFloat = 0
        
        var aVal: CGFloat = 0
        
        guard uiColor.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal) else {
            fatalError("Could not convert color to RGB color space.")
        }
        
        return ColorData(r: Float(rVal), g: Float(gVal), b: Float(bVal), alpha: Float(aVal))
    }
}

extension UIColor: ShapeStyleColor {
    /// Stores the values of the color into a ColorData object.
    public var data: ColorData {
        var rVal: CGFloat = 0
        
        var bVal: CGFloat = 0
        
        var gVal: CGFloat = 0
        
        var aVal: CGFloat = 0
        
        guard self.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal) else {
            fatalError("Could not convert color to RGB color space.")
        }
        
        return ColorData(r: Float(rVal), g: Float(gVal), b: Float(bVal), alpha: Float(aVal))
    }
}
