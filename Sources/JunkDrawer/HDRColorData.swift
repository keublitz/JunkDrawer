import SwiftUI
import Dialogue

/// A codable structure that can hold HDR color data.
@available(*, deprecated, message: "HDRColorData is a work in progress and will not produce stable results. Avoid using for now.")
public struct HDRColorData: Codable, Equatable {
    private let r: Float
    
    private let g: Float
    
    private let b: Float
    
    private let alpha: Float
    
    public let sdr: ColorData
    
    public init(r: Float, g: Float, b: Float, alpha: Float = 1) {
        self.r = r
        self.g = g
        self.b = b
        self.alpha = alpha
        
        let SDRcolor = UIColor(
            red: CGFloat(min(r, 1)),
            green: CGFloat(min(g, 1)),
            blue: CGFloat(min(b, 1)),
            alpha: CGFloat(min(alpha, 1))
        )
        
        self.sdr = SDRcolor.data
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b && lhs.alpha == rhs.alpha
    }
}

//public extension HDRColorData {
//    var color: Color? {
//        guard let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB),
//              let cgColor = CGColor(colorSpace: colorSpace, components: [CGFloat(self.r), CGFloat(self.g), CGFloat(self.b), CGFloat(self.alpha)]) else {
//            return nil
//        }
//        
//        return Color(cgColor: cgColor)
//    }
//}
//
//public extension ColorData {
//    /// Returns data of the color converted to HDR by an amount of brightness.
//    ///
//    /// # Explanation
//    /// The luminance of the HDR color data is determined by a formula from the Rec. 709 standard, which is the color profile standard for HDTV and the basis for sRGB.
//    ///
//    /// ```swift
//    /// let luminance = r * 0.2126 + g * 0.7152 + b * 0.0722
//    /// ```
//    func hdr(brightness: Float = 1.5) -> HDRColorData {
//        // Rec. 709 luminance weight formula
//        let luminance = self.r * 0.2126 + self.g * 0.7152 + b * 0.0722
//        let boost = 1.0 + (brightness - 1.0) * luminance
//        
//        return HDRColorData(
//            r: self.r * boost,
//            g: self.g * boost,
//            b: self.b * boost,
//            alpha: self.alpha
//        )
//    }
//}
