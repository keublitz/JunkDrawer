import SwiftUI
import OSLog

#if os(iOS)
public typealias PlatformColor = UIColor
#elseif os(macOS)
public typealias PlatformColor = NSColor
#endif

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
/// * Initialize the red, blue, green, and alpha values manually:
/// ```swift
/// ColorData(r: 1.0, g: 0.0, b: 0.0) // Returns red
/// ColorData(r: 0.0, g: 1.0, b: 0.0) // Returns green
/// ColorData(r: 1.0, g: 0.0, b: 1.0) // Returns purple
/// ```
///
/// * Initialize with the color value:
/// ```swift
/// ColorData(.blue)
/// ColorData(uiColor: .blue)
/// ```
///
/// * Use the static `.of` function:
/// ```swift
/// ColorData.of(Color.blue)
/// ```
///
/// * Use the `.data` extension directly on the color object:
/// ```swift
/// let blue: Color = .blue
/// let data: ColorData = blue.data
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
/// ## Encoding
/// Colors can be encoded using either hexadecimal (0 to 255) or float (0 to 1) values. Initializers default to float values, but can be set to hexadecimal with the `encoder` enum.
///
/// ```swift
/// ColorData(encoder: .float, r: 1, g: 0.5, b: 0.25)
/// ColorData(encoder: .hex, r: 255, g: 128, b: 64)
/// ```
///
/// Alpha values are also encoded into `ColorData` and decoded into all usable color classes, so even colors with opacity modifiers can be encoded as is.
///
/// ```swift
/// let fullOrange: Color = .orange
/// let opaqueOrange: Color = .orange.opacity(0.5)
///
/// let fullOrangeData = ColorData.of(fullOrange)
/// let opaqueOrangeData = ColorData.of(opaqueOrange)
///
/// print(fullOrangeData.hex)    // Returns #FF9230FF
/// print(opaqueOrangeData.hex)  // Returns #FF923080
/// ```
public struct ColorData: Codable, Equatable {
    /// The hexadecimal code of the color.
    public let hex: String
    
    /// The red value of the color.
    public let r: Float
    
    /// The green value of the color.
    public let g: Float
    
    /// The blue value of the color.
    public let b: Float
    
    /// The opacity of the color, expressed as a decimal out of 1.0.
    public let a: Float
    
    /// - Parameter encoder: An enum to declare that values will be encoded with hexadecimal (0 to 255) or float (0.0 to 1.0) values. Defaults to float.
    /// - Parameter r: The red value of the color.
    /// - Parameter g: The green value of the color.
    /// - Parameter b: The blue value of the color.
    /// - Parameter alpha: The opacity of the color, expressed as a decimal out of 1.0. Defaults to 1.0 (full opacity).
    public init(encoder: ValueEncoder = .float, r: Float, g: Float, b: Float, alpha: Float = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = alpha
        
        var uiColor = NativeColor.clear
        
        switch encoder {
        case .float:
            guard r >= 0 && r <= 1,
                  g >= 0 && g <= 1,
                  b >= 0 && b <= 1,
                  alpha >= 0 && alpha <= 1 else {
                logger.fatalError("Value overflow, all values encoded in float must be between 0.0 and 1.0. (r: \(r), g: \(g), b: \(b), alpha: \(alpha))")
            }
            
            uiColor = NativeColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(alpha))
        case .hexadecimal:
            guard r >= 0 && r <= 255,
                  g >= 0 && g <= 255,
                  b >= 0 && b <= 255,
                  alpha >= 0 && alpha <= 1 else {
                logger.fatalError("Value overflow, all values encoded in hexadecimal must be between 0 and 255. (r: \(r), g: \(g), b: \(b), alpha: \(alpha))")
            }
            
            let floatR = CGFloat(Int(r) / 255)
            let floatG = CGFloat(Int(g) / 255)
            let floatB = CGFloat(Int(b) / 255)
            let floatA = CGFloat(alpha)
            
            uiColor = NativeColor(red: floatR, green: floatG, blue: floatB, alpha: floatA)
        }
        
        self.hex = uiColor.hex
    }
    
    /// - Parameter color: The `Color` to encode as data.
    public init(_ color: Color) {
        let data = color.data
        
        guard data.floatValuesAreValid else {
            logger.fatalError("Value overflow, all values must be between 0 and 1. (r: \(data.r), g: \(data.g), b: \(data.b), alpha: \(data.a))")
        }
        
        self.r = data.r
        self.g = data.g
        self.b = data.b
        self.a = data.a
        
        let uiColor = PlatformColor(red: CGFloat(data.r), green: CGFloat(data.g), blue: CGFloat(data.b), alpha: CGFloat(data.a))
        
        self.hex = uiColor.hex
    }
    
    #if os(iOS)
    /// - Parameter uiColor: The `UIColor` to encode as data.
    public init(uiColor: UIColor) {
        let data = uiColor.data
        
        guard data.floatValuesAreValid else {
            logger.fatalError("Value overflow, all values must be between 0 and 1. (r: \(data.r), g: \(data.g), b: \(data.b), alpha: \(data.a))")
        }
        
        self.r = data.r
        self.g = data.g
        self.b = data.b
        self.a = data.a
        
        let uiColorSet = UIColor(red: CGFloat(data.r), green: CGFloat(data.g), blue: CGFloat(data.b), alpha: CGFloat(data.a))
        self.hex = uiColorSet.hex
    }
    #elseif os(macOS)
    public init(nsColor: NSColor) {
        let data = nsColor.data
        
        guard data.floatValuesAreValid else {
            logger.fatalError("Value overflow, all values must be between 0 and 1. (r: \(data.r), g: \(data.g), b: \(data.b), alpha: \(data.a))")
        }
        
        self.r = data.r
        self.g = data.g
        self.b = data.b
        self.a = data.a
        
        let nsColorSet = NSColor(red: CGFloat(data.r), green: CGFloat(data.g), blue: CGFloat(data.b), alpha: CGFloat(data.a))
        self.hex = nsColorSet.hex
    }
    #endif
    
    public static func == (lhs: ColorData, rhs: ColorData) -> Bool {
        let hexesMatch: Bool = lhs.hex == rhs.hex
        
        let valuesMatch: Bool = lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.a == rhs.a
        
        return hexesMatch && valuesMatch
    }
    
    // Checks that all color values will not overflow.
    private var floatValuesAreValid: Bool {
        self.r >= 0 && self.r <= 1 &&
        self.g >= 0 && self.g <= 1 &&
        self.b >= 0 && self.b <= 1 &&
        self.a >= 0 && self.a <= 1
    }
}

/// The type of value to use for encoding color.
public enum ValueEncoder {
    /// Encoding color with hexadecimal values between 0 and 255.
    case hexadecimal
    /// Encoding color with floating point values between 0.0 and 1.0.
    case float
}

// MARK: - Extensions

public extension ColorData {
    /// An empty value.
    ///
    /// - Returns: A `ColorData` object with all values set to zero, equivalent to `.clear`.
    static var empty: ColorData { ColorData(r: 0, g: 0, b: 0, alpha: 0) }
    
    static func of(_ color: Color) -> Self { return color.data }
    
    #if os(iOS)
    static func of(uiColor: PlatformColor) -> Self { return uiColor.data }
    #elseif os(macOS)
    static func of(nsColor: PlatformColor) -> Self { return nsColor.data }
    #endif
}

// MARK: - Protocols

/// A protocol for the various types that can express color values.
public protocol Colorful {
    /// The data of the color value.
    var data: ColorData { get }
    
    /// The color value expressed visually.
    var color: Color { get }
    
    #if os(iOS)
    /// The color value expressed visually.
    var uiColor: UIColor { get }
    #elseif os(macOS)
    var nsColor: NSColor { get }
    #endif
    
    /// The hexadecimal string of the color value.
    ///
    /// ## Example:
    /// ```swift
    /// print(Color.purple.hex) // Returns "#A020F0"
    /// ```
    var hex: String { get }
}

extension Color: Colorful {
    /// - Parameter hex: The six- or eight-digit hexadecimal string.
    /// - Parameter alpha: The opacity value of the color, represented as a value between 0 and 1. Defaults to 1.
    /// - Returns: An optional `Color` value that returns nil if the hexadecimal string cannot be decoded.
    public init?(hex: String, alpha: CGFloat = 1.0) {
        // Clean whitespaces, newlines, and the pound sign from the input.
        let hexadecimal = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        // 64-bit integer to scan hexadecimal value into.
        var rgb = UInt64()
        
        // Check that a value can be scanned from the hexadecimal string and stored in var rgb.
        guard Scanner(string: hexadecimal).scanHexInt64(&rgb) else {
            logger.error("Cannot scan value from hexadecimal string (\(hex)).")
            return nil
        }
        
        // If the hexadecimal string has eight characters, scan each byte (two characters) for a value that can be decoded into a floating point between 0-1.
        
        // Example:
        // [#00]0AF9FF -> #00 is equal to 0, those first two characters represent red, so r = 0.
        // #000AF9[FF] -> FF is equal to 1, so a = 1.
        if hexadecimal.count == 8 {
            let r = CGFloat((rgb >> 24) & 0xFF) / 255.0
            let g = CGFloat((rgb >> 16) & 0xFF) / 255.0
            let b = CGFloat((rgb >> 8) & 0xFF) / 255.0
            let a = CGFloat(rgb & 0xFF) / 255.0
            
            self.init(red: r, green: g, blue: b, opacity: a)
        }
        // If hexadecimal count is not 8 (doesn't have opacity value), decode just RGB values.
        else if hexadecimal.count == 6 {
            // Pass alpha value through mutable variable to ensure valid value.
            var opacity: CGFloat = 1.0
            
            if alpha >= 0 && alpha <= 1 {
                opacity = alpha
            }
            
            let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
            let b = CGFloat(rgb & 0xFF) / 255.0
            
            self.init(red: r, green: g, blue: b, opacity: Double(opacity))
        }
        else {
            logger.error("Cannot return color value from \(hex). Hexadecimal string must contain either six or eight characters exactly.")
            return nil
        }
    }
    
    public var data: ColorData {
        let nativeColor = self.nativeColor
        
        var rVal: CGFloat = 0
        
        var bVal: CGFloat = 0
        
        var gVal: CGFloat = 0
        
        var aVal: CGFloat = 0
        
        #if os(iOS)
        guard nativeColor.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal) else {
            logger.error("Could not convert color [\(self.hex)] to RGB color space. Returning empty ColorData value.")
            return .empty
        }
        #elseif os(macOS)
        nativeColor.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal)
        #endif
        
        return ColorData(r: Float(rVal), g: Float(gVal), b: Float(bVal), alpha: Float(aVal))
    }
    
    public var color: Color { self }
    
    #if os(iOS)
    public var uiColor: UIColor { UIColor(self) }
    fileprivate var nativeColor: UIColor { UIColor(self) }
    #elseif os(macOS)
    public var nsColor: NSColor { NSColor(self) }
    fileprivate var nativeColor: NSColor { NSColor(self) }
    #endif
    
    public var hex: String {
        // Ensure that the RGBA values can be recreated.
        guard let components = NativeColor(self).cgColor.components, components.count >= 4 else {
            logger.error("Can't get components of color to create hexadecimal code.")
            return "nil"
        }
        
        // Do some byte-pointer stuff that I'm too tired to explain right now.
        let r = Int((components[0] * 255.0).rounded()) & 0xFF
        let g = Int((components[1] * 255.0).rounded()) & 0xFF
        let b = Int((components[2] * 255.0).rounded()) & 0xFF
        let a = Int((components[3] * 255.0).rounded()) & 0xFF
        
        // Display in hexadecimal format.
        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
    }
}

#if os(iOS)
extension UIColor: Colorful {
    /// - Parameter hex: The six- or eight-digit hexadecimal string.
    /// - Parameter alpha: The opacity value of the color, represented as a value between 0 and 1. Defaults to 1.
    /// - Returns: An optional `Color` value that returns nil if the hexadecimal string cannot be decoded.
    public convenience init?(hex: String, alpha: CGFloat = 1.0) {
        let hexadecimal = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        var rgb = UInt64()
        
        guard Scanner(string: hexadecimal).scanHexInt64(&rgb) else {
            logger.error("Unable to return color from \(hex) — can't scan 64-bit integer value from the hex string.")
            return nil
        }
        
        if hexadecimal.count == 8 {
            let r = CGFloat((rgb >> 24) & 0xFF) / 255.0
            let g = CGFloat((rgb >> 16) & 0xFF) / 255.0
            let b = CGFloat((rgb >> 8) & 0xFF) / 255.0
            let a = CGFloat(rgb & 0xFF) / 255.0
            
            self.init(red: r, green: g, blue: b, alpha: a)
        }
        else if hexadecimal.count == 6 {
            var opacity: CGFloat = 1.0
            
            if alpha >= 0 && alpha <= 1 {
                opacity = alpha
            }
            
            let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
            let b = CGFloat(rgb & 0xFF) / 255.0
            
            self.init(red: r, green: g, blue: b, alpha: opacity)
        }
        else {
            logger.error("Cannot return color value from \(hex): hexadecimal string must contain either six or eight characters exactly.")
            return nil
        }
    }
    
    public var data: ColorData {
        var rVal: CGFloat = 0
        
        var bVal: CGFloat = 0
        
        var gVal: CGFloat = 0
        
        var aVal: CGFloat = 0
        
        guard self.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal) else {
            logger.error("Could not return RGB color space components for \(self.hex). Returning empty ColorData value.")
            return .empty
        }
        
        return ColorData(r: Float(rVal), g: Float(gVal), b: Float(bVal), alpha: Float(aVal))
    }
    
    public var color: Color { Color(uiColor: self) }
    
    public var uiColor: UIColor { self }
    
    public var hex: String {
        return hexFromSRGBComponents(of: self.cgColor)
    }
}
#elseif os(macOS)
extension NSColor: Colorful {
    /// - Parameter hex: The six- or eight-digit hexadecimal string.
    /// - Parameter alpha: The opacity value of the color, represented as a value between 0 and 1. Defaults to 1.
    /// - Returns: An optional `Color` value that returns nil if the hexadecimal string cannot be decoded.
    public convenience init?(hex: String, alpha: CGFloat = 1.0) {
        let hexadecimal = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        var rgb = UInt64()
        
        guard Scanner(string: hexadecimal).scanHexInt64(&rgb) else {
            logger.error("Unable to return color from \(hex) — can't scan 64-bit integer value from the hex string.")
            return nil
        }
        
        if hexadecimal.count == 8 {
            let r = CGFloat((rgb >> 24) & 0xFF) / 255.0
            let g = CGFloat((rgb >> 16) & 0xFF) / 255.0
            let b = CGFloat((rgb >> 8) & 0xFF) / 255.0
            let a = CGFloat(rgb & 0xFF) / 255.0
            
            self.init(red: r, green: g, blue: b, alpha: a)
        }
        else if hexadecimal.count == 6 {
            var opacity: CGFloat = 1.0
            
            if alpha >= 0 && alpha <= 1 {
                opacity = alpha
            }
            
            let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
            let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
            let b = CGFloat(rgb & 0xFF) / 255.0
            
            self.init(red: r, green: g, blue: b, alpha: opacity)
        }
        else {
            logger.error("Cannot return color value from \(hex): hexadecimal string must contain either six or eight characters exactly.")
            return nil
        }
    }
    
    public var data: ColorData {
        var rVal: CGFloat = 0
        
        var bVal: CGFloat = 0
        
        var gVal: CGFloat = 0
        
        var aVal: CGFloat = 0
        
        self.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal)
        
        return ColorData(r: Float(rVal), g: Float(gVal), b: Float(bVal), alpha: Float(aVal))
    }
    
    public var color: Color { Color(nsColor: self) }
    
    public var nsColor: NSColor { self }
    
    public var hex: String {
        return hexFromSRGBComponents(of: self.cgColor)
    }
}

fileprivate func getNSComponents(from nsColor: NSColor) -> ColorData {
    guard let srgb = nsColor.usingColorSpace(.sRGB) else { return .empty }
    
    var r: CGFloat = 0,
        g: CGFloat = 0,
        b: CGFloat = 0,
        a: CGFloat = 0
    
    srgb.getRed(&r, green: &g, blue: &b, alpha: &a)
    
    return ColorData.init(r: Float(r), g: Float(g), b: Float(b), alpha: Float(a))
}
#endif

#if os(macOS)
@available(macOS 12.0, *)
#endif
extension CGColor: Colorful {
    public var data: ColorData {
        var rVal: CGFloat = 0
        
        var bVal: CGFloat = 0
        
        var gVal: CGFloat = 0
        
        var aVal: CGFloat = 0
        
        #if os(iOS)
        let uiColor = UIColor(cgColor: self)
        
        guard uiColor.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal) else {
            logger.warning("Could not return RGB color space components for \(self.hex). Returning empty ColorData value.")
            return .empty
        }
        #elseif os(macOS)
        guard let nsColor = NSColor(cgColor: self) else { return .empty }
        
        nsColor.getRed(&rVal, green: &gVal, blue: &bVal, alpha: &aVal)
        #endif
        
        return ColorData(r: Float(rVal), g: Float(gVal), b: Float(bVal), alpha: Float(aVal))
    }
    
    public var color: Color { Color(cgColor: self) }
    
    #if os(iOS)
    public var uiColor: UIColor { UIColor(cgColor: self) }
    #elseif os(macOS)
    public var nsColor: NSColor { NSColor(cgColor: self) ?? .clear }
    #endif
    
    public var hex: String {
        return hexFromSRGBComponents(of: self)
    }
}

#if os(macOS)
@available(macOS 12.0, *)
#endif
extension CIColor: Colorful {
    public var data: ColorData { ColorData(r: Float(red), g: Float(green), b: Float(blue), alpha: Float(alpha)) }
    
    #if os(iOS)
    public var color: Color { Color(uiColor: self.uiColor) }
    
    public var uiColor: UIColor { UIColor(ciColor: self) }
    
    public var hex: String { self.uiColor.hex }
    #elseif os(macOS)
    public var color: Color { Color(nsColor: self.nsColor) }
    
    public var nsColor: NSColor { NSColor(ciColor: self) }
    
    public var hex: String { self.nsColor.hex }
    #endif
}

#if os(macOS)
@available(macOS 12.0, *)
#endif
extension ColorData: Colorful {
    public var data: ColorData { self }
    
    public var color: Color {
        guard let color = Color(hex: self.hex) else {
            logger.error("Could not create color for \(self.hex), returning clear color. Check other logs for more information.")
            return .clear
        }
        
        return color
    }
    
    #if os(iOS)
    public var uiColor: UIColor {
        guard let uiColor = UIColor(hex: self.hex) else {
            logger.error("Could not create color for \(self.hex), returning clear color. Check other logs for more information.")
            return .clear
        }
        
        return uiColor
    }
    #elseif os(macOS)
    public var nsColor: NSColor {
        guard let nsColor = NSColor(hex: self.hex) else {
            logger.error("Could not create color for \(self.hex), returning clear color. Check other logs for more information.")
            return .clear
        }
        
        return nsColor
    }
    #endif
}

// MARK: - Helper functions

fileprivate func hexFromSRGBComponents(of cgColor: CGColor) -> String {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        logger.error("Cannot create hexadecimal code — the sRGB color space couldn't be built.")
        return "null"
    }
    
    guard let rgbaColor = cgColor.converted(to: colorSpace, intent: .defaultIntent, options: nil) else {
        logger.error("Cannot create hexadecimal code - could not convert UIColor value to color space.")
        return "null"
    }
    
    guard let components = rgbaColor.components,
          components.count >= 4 else {
        logger.error("Cannot create hexadecimal code — sRGB color fewer than four components.")
        return "null"
    }
    
    let r = Int((components[0]) * 255.0)
    let g = Int((components[1]) * 255.0)
    let b = Int((components[2]) * 255.0)
    let a = Int((components[3]) * 255.0)
    
    return String(format: "#%02X%02X%02X%02X", r, g, b, a)
}
