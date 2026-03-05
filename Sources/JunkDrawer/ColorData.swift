import SwiftUI
import Dialogue

/// A codable structure that can hold color data.
///
/// Colors are notoriously un-codable classes, and cannot directly be stored in a codable data structure. `ColorData` provides a way to convert colors into data that conforms to Codable.
///
/// ```swift
/// struct Object: Codable {
///     let blue = Color.blue             // ❌ Won't conform
///     let blue = ColorData(Color.blue)  // ✅ Will conform
/// }
/// ```
///
/// ## Initializing
///
/// `ColorData` can be initialized in multiple ways:
///
/// * Use the static `.of` function (requires explicit typing):
/// ```swift
/// ColorData.of(Color.blue)
/// ```
///
/// * Initialize with the color value:
/// ```swift
/// ColorData(.blue)
/// ColorData(uiColor: .blue)
/// ```
///
/// * Use the `.data` extension directly on the color object:
/// ```swift
/// let blue: Color = .blue
/// let data: ColorData = blue.data
/// ```
///
/// * Set the red, blue, green, and alpha values manually:
/// ```swift
/// ColorData(r: 1.0, g: 0.0, b: 0.0) // Returns red
/// ColorData(r: 0.0, g: 1.0, b: 0.0) // Returns green
/// ColorData(r: 1.0, g: 0.0, b: 1.0) // Returns purple
/// ```
///
/// Once initialized, helper extensions can convert data back into usable color classes.
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
/// let fullOrangeData = ColorData.of(fullOrange)
/// let opaqueOrangeData = ColorData.of(opaqueOrange)
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
    
    /// - Parameter r: The red value of the color, expressed as a decimal out of 1.0.
    /// - Parameter g: The green value of the color, expressed as a decimal out of 1.0.
    /// - Parameter b: The blue value of the color, expressed as a decimal out of 1.0.
    /// - Parameter alpha: The opacity of the color, expressed as a decimal out of 1.0. Defaults to 1.0 (full opacity).
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
    
    /// - Parameter color: The `Color` to encode as data.
    public init(_ color: Color) {
        let data = color.data
        
        guard data.valuesAreValid else {
            fatalError("Value overflow, all values must be between 0 and 1. (r: \(data.r), g: \(data.g), b: \(data.b), alpha: \(data.alpha))")
        }
        
        self.r = data.r
        self.g = data.g
        self.b = data.b
        self.alpha = data.alpha
        
        let uiColor = UIColor(red: CGFloat(data.r), green: CGFloat(data.g), blue: CGFloat(data.b), alpha: CGFloat(data.alpha))
        self.hex = uiColor.hex
    }
    
    /// - Parameter uiColor: The `UIColor` to encode as data.
    public init(uiColor: UIColor) {
        let data = uiColor.data
        
        guard data.valuesAreValid else {
            fatalError("Value overflow, all values must be between 0 and 1. (r: \(data.r), g: \(data.g), b: \(data.b), alpha: \(data.alpha))")
        }
        
        self.r = data.r
        self.g = data.g
        self.b = data.b
        self.alpha = data.alpha
        
        let uiColorSet = UIColor(red: CGFloat(data.r), green: CGFloat(data.g), blue: CGFloat(data.b), alpha: CGFloat(data.alpha))
        self.hex = uiColorSet.hex
    }
    
    public static func == (lhs: ColorData, rhs: ColorData) -> Bool {
        let hexesMatch: Bool = lhs.hex == rhs.hex
        
        let valuesMatch: Bool = lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.alpha == rhs.alpha
        
        return hexesMatch && valuesMatch
    }
    
    // Checks that all color values will not overflow.
    private var valuesAreValid: Bool {
        self.r >= 0 && self.r <= 1 &&
        self.g >= 0 && self.g <= 1 &&
        self.b >= 0 && self.b <= 1 &&
        self.alpha >= 0 && self.alpha <= 1
    }
}

// MARK: - Extensions

public extension ColorData {
    /// An empty value.
    ///
    /// - Returns: A `ColorData` object with red, green, and blue value set to zero, equivalent to black.
    static var empty: ColorData { ColorData(r: 0, g: 0, b: 0) }
    
    static func of(_ color: Color) -> Self { return color.data }
    
    /// The color decoded from the data.
    ///
    /// - Returns: An optional `Color` value.
    var color: Color? {
        guard let color = Color(hex: self.hex) else { return nil }
        
        return color
    }
    
    /// The color decoded from the data. Falls back to `.clear` if color decoding fails.
    ///
    /// - Returns: A `Color` value, returning `.clear` if decoding fails.
    /// - Important: Recommended for use only if `init?(hex:)` is guaranteed to *not* return nil. Otherwise, use the optional type <doc:color>.
    var safeColor: Color {
        guard let color = Color(hex: self.hex) else { return .clear }
        
        return color
    }
    
    /// The color decoded from the data.
    ///
    /// - Returns: An optional `UIColor` value.
    var uiColor: UIColor? {
        guard let uiColor = UIColor(hex: self.hex) else { return nil }
        
        return uiColor
    }
    
    /// The color decoded from the data. Falls back to `.clear` if color decoding fails.
    ///
    /// - Returns: A `UIColor` value, returning `.clear` if decoding fails.
    /// - Important: Recommended for use only if `init?(hex:)` is guaranteed to *not* return nil. Otherwise, use the optional type <doc:color>.
    var safeUIColor: UIColor {
        guard let uiColor = UIColor(hex: self.hex) else { return .clear }
        
        return uiColor
    }
}

// MARK: - Protocols

/// A protocol for color variants of a ShapeStyle.
public protocol ShapeStyleColor {
    var data: ColorData { get }
    
    var color: Color { get }
    
    var uiColor: UIColor { get }
}

extension Color: ShapeStyleColor {
    /// Stores the values of the color into a ColorData object.
    public var data: ColorData {
        let uiColor = self.uiColor
        
        var rVal: CGFloat = 0
        
        var bVal: CGFloat = 0
        
        var gVal: CGFloat = 0
        
        var aVal: CGFloat = 0
        
        guard uiColor.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal) else {
            fatalError("Could not convert color to RGB color space.")
        }
        
        return ColorData(r: Float(rVal), g: Float(gVal), b: Float(bVal), alpha: Float(aVal))
    }
    
    public var color: Color { self }
    
    public var uiColor: UIColor { UIColor(self) }
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
    
    public var color: Color { Color(uiColor: self) }
    
    public var uiColor: UIColor { self }
}
