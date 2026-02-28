import SwiftUI
import ColorThiefSwift
import Dialogue

final internal class ColorAlgorithm {
    private let image: UIImage
    
    private let size: CGSize
    
    internal init(
        _ image: UIImage,
        size: CGSize = CGSize(width: 64, height: 64)
    ) {
        self.image = image
        self.size = size
    }
    
    fileprivate func clamp<T: BinaryFloatingPoint>(_ value: T) -> Double {
        return min(max(Double(value), 0), 255)
    }
    
    fileprivate func clamp<T: BinaryInteger>(_ value: T) -> Double {
        return min(max(Double(value), 0), 255)
    }
    
    // The maximum distance two colors can be from each other (white to black).
    private var maxDistance: Double { sqrt(3 * pow(255, 2)) }
    
    private func colorsAreSimilar(
        by percentage: Double,
        _ lhs: MMCQ.Color,
        _ rhs: MMCQ.Color
    ) -> Bool {
        let redDiff = abs(Double(lhs.r) - Double(rhs.r))
        let greenDiff = abs(Double(lhs.g) - Double(rhs.g))
        let blueDiff = abs(Double(lhs.b) - Double(rhs.b))
        
        let distance: Double = sqrt(
            pow(redDiff, 2) +
            pow(greenDiff, 2) +
            pow(blueDiff, 2)
        )
        
        let similarity: Double = 1 - Double(distance / maxDistance)
        
        return similarity >= percentage
    }
    
    private func colorsAreSimilar(
        by percentage: Double,
        _ lhsColor: Color,
        _ rhsColor: Color
    ) -> Bool {
        let lhs = UIColor(lhsColor)
        let rhs = UIColor(rhsColor)
        
        var lhsRed: CGFloat = 0,
            lhsGreen: CGFloat = 0,
            lhsBlue: CGFloat = 0,
            lhsAlpha: CGFloat = 0,
        
            rhsRed: CGFloat = 0,
            rhsGreen: CGFloat = 0,
            rhsBlue: CGFloat = 0,
            rhsAlpha: CGFloat = 0
        
        lhs.getRed(&lhsRed, green: &lhsGreen, blue: &lhsBlue, alpha: &lhsAlpha)
        rhs.getRed(&rhsRed, green: &rhsGreen, blue: &rhsBlue, alpha: &rhsAlpha)
        
        let redDiff = abs(Double(lhsRed * 255) - Double(rhsRed * 255))
        let greenDiff = abs(Double(lhsGreen * 255) - Double(rhsGreen * 255))
        let blueDiff = abs(Double(lhsBlue * 255) - Double(rhsBlue * 255))
        
        let distance: Double = sqrt(
            pow(redDiff, 2) +
            pow(greenDiff, 2) +
            pow(blueDiff, 2)
        )
        
        let similarity: Double = 1 - (distance / maxDistance)
        
        return similarity >= percentage
    }
    
    internal var tempPrimary: Color?
    internal var tempSecondary: Color?
    internal var tempAccent: Color?
    
    /// The most prominent color of the image.
    internal func primary() -> Color {
        if let tempPrimary { return tempPrimary }
        
        guard let colorSource = image.nearestNeighbor(resizedTo: size),
              let palette = ColorThief.getPalette(from: colorSource, colorCount: 5, ignoreWhite: false) else {
            tempPrimary = .black
            return .black
        }
        
        guard let edgeColors = getEdgeColors(from: colorSource) else {
            tempPrimary = .black
            return .black
        }
        
        let leftSide = edgeColors[0]
        let bottomSide = edgeColors[1]
        let rightSide = edgeColors[2]
        let topSide = edgeColors[3]
        
        let leftSideAndBottomSideColorsAreSimilar = colorsAreSimilar(by: 0.667, leftSide, bottomSide)
        let rightSideAndTopSideColorsAreSimilar = colorsAreSimilar(by: 0.667, rightSide, topSide)
        
        if leftSideAndBottomSideColorsAreSimilar && rightSideAndTopSideColorsAreSimilar {
            let startR = Int((Int(leftSide.r) + Int(bottomSide.r)) / 2)
            let startG = Int((Int(leftSide.g) + Int(bottomSide.g)) / 2)
            let startB = Int((Int(leftSide.b) + Int(bottomSide.b)) / 2)
            
            let startColor = Color(
                red: clamp(startR) / 255.0,
                green: clamp(startG) / 255.0,
                blue: clamp(startB) / 255.0
            )
            
            tempPrimary = startColor
            return startColor
        }
        
        let red = Double(palette[0].r)
        let green = Double(palette[0].g)
        let blue = Double(palette[0].b)
        
        let startColor = Color(
            red: clamp(red) / 255.0,
            green: clamp(green) / 255.0,
            blue: clamp(blue) / 255.0
        )
        
        tempPrimary = startColor
        return startColor
    }
    
    /// The second-most prominent color of the image.
    internal func secondary() -> Color {
        if let tempSecondary { return tempSecondary }
        
        // The active primary value to use for computing
        var _tempPrimary: Color
        
        if let tempPrimary {
            _tempPrimary = tempPrimary
        }
        else {
            _tempPrimary = primary()
        }
        
        guard let colorSource = image.nearestNeighbor(resizedTo: size),
              let palette = ColorThief.getPalette(from: colorSource, colorCount: 5, ignoreWhite: false) else {
            tempSecondary = .black
            return .black
        }
        
        guard let edgeColors = getEdgeColors(from: colorSource) else {
            tempSecondary = .black
            return .black
        }
        
        let leftSide = edgeColors[0]
        let bottomSide = edgeColors[1]
        let rightSide = edgeColors[2]
        let topSide = edgeColors[3]
        
        let leftSideAndBottomSideColorsAreSimilar = colorsAreSimilar(by: 0.667, leftSide, bottomSide)
        let rightSideAndTopSideColorsAreSimilar = colorsAreSimilar(by: 0.667, rightSide, topSide)
        
        let leftAndRightIdentical = colorsAreSimilar(by: 0.95, leftSide, rightSide)
        let topAndBottomIdentical = colorsAreSimilar(by: 0.95, topSide, bottomSide)
        
        if leftSideAndBottomSideColorsAreSimilar && rightSideAndTopSideColorsAreSimilar {
            if leftAndRightIdentical || topAndBottomIdentical {
                tempSecondary = _tempPrimary
                return _tempPrimary
            }
            
            let endR = Int((Int(rightSide.r) + Int(topSide.r)) / 2)
            let endG = Int((Int(rightSide.r) + Int(topSide.g)) / 2)
            let endB = Int((Int(rightSide.r) + Int(topSide.b)) / 2)
            
            let endColor = Color(
                red: clamp(endR) / 255.0,
                green: clamp(endG) / 255.0,
                blue: clamp(endB) / 255.0
            )
            
            tempSecondary = endColor
            return endColor
        }
        
        let red = Double(palette[1].r)
        let green = Double(palette[1].g)
        let blue = Double(palette[1].b)
        
        let secondaryColor = Color(
            red: clamp(red) / 255.0,
            green: clamp(green) / 255.0,
            blue: clamp(blue) / 255.0
        )
        
        // If primary and secondary are too different to be aesthetically coherent, just copy primary.
        if similarity(lhs: secondaryColor, rhs: _tempPrimary) < 0.25 {
            tempSecondary = _tempPrimary
            return _tempPrimary
        }
        
        tempSecondary = secondaryColor
        return secondaryColor
    }
    
    /// The third-most prominent color of the image.
    internal func tertiary() -> Color {
        guard let colorSource = image.nearestNeighbor(resizedTo: size),
              let palette = ColorThief.getPalette(from: colorSource, colorCount: 5) else {
            return .white
        }
        
        var _tempAccent: Color = .clear
        var _tempPrimary: Color = .clear
        var _tempSecondary: Color = .clear
        
        if let tempPrimary {
            _tempPrimary = tempPrimary
        }
        else {
            _tempPrimary = primary()
        }
        
        if let tempSecondary {
            _tempSecondary = tempSecondary
        }
        else {
            _tempSecondary = secondary()
        }
        
        if let tempAccent {
            _tempAccent = tempAccent
        }
        else {
            _tempAccent = accent()
        }
        
        var primaryIsWhite: Bool { _tempAccent.isCloserToWhite }
        
        let middleOfBackground = middleColor(from: _tempPrimary, to: _tempSecondary)
        
        var backupColor: Color? {
            guard let fullPalette = ColorThief.getPalette(from: image, colorCount: 8) else { return nil }
            
            for color in fullPalette {
                if !colorsAreSimilar(by: 0.5, color.makeSwiftColor, middleOfBackground) && !color.makeUIColor().isPoor {
                    return color.makeSwiftColor
                }
                
                continue
            }
            // else
            return nil
        }
        
        let rawSecondary: Color = Color(
            red: clamp(palette[2].r) / 255,
            green: clamp(palette[2].g) / 255,
            blue: clamp(palette[2].b) / 255
        )
        
        if colorsAreSimilar(by: 0.5, middleOfBackground, rawSecondary) {
            if let backupColor { return backupColor }
            
            return _tempAccent.opacity(0.75)
        }
        
        let red = Double(palette[2].r)
        let green = Double(palette[2].g)
        let blue = Double(palette[2].b)
        
        let tertiary = Color(
            red: clamp(red) / 255.0,
            green: clamp(green) / 255.0,
            blue: clamp(blue) / 255.0
        )
        
        return tertiary
    }
    
    /// The accent color.
    ///
    /// - Returns: A near-monochromatic color, either near-to-pure white or near-to-pure black. Determined by whichever contrasts best against the other computed colors.
    internal func accent() -> Color {
        if let tempAccent { return tempAccent }
        
        var _tempPrimary: Color
        var _tempSecondary: Color
        
        if let tempPrimary {
            _tempPrimary = tempPrimary
        }
        else {
            _tempPrimary = primary()
        }
        
        if let tempSecondary {
            _tempSecondary = tempSecondary
        }
        else {
            _tempSecondary = secondary()
        }
        
        let middleOfBackground = middleColor(from: _tempPrimary, to: _tempSecondary)
        
        if middleOfBackground.isCloserToWhite {
            let brightestBunch = sortByBrightest()
            
            guard !brightestBunch.isEmpty else { return .black }
            
            for color in brightestBunch {
                if color.isOffBlack,
                   !colorsAreSimilar(by: 0.667, middleOfBackground, Color(color)) {
                    tempAccent = Color(color)
                    
                    return Color(color)
                }
                
                continue
            }
            
            tempAccent = .black
            return .black
        }
        else {
            let darkestBunch = sortByDarkest()
            
            guard !darkestBunch.isEmpty else { return .white }
            
            for color in darkestBunch {
                if color.isOffWhite,
                   !colorsAreSimilar(by: 0.667, middleOfBackground, Color(color)) {
                    tempAccent = Color(color)
                    
                    return Color(color)
                }
                
                continue
            }
            
            tempAccent = .white
            return .white
        }
    }
    
    // MARK: - Helpers
    
    private func similarity(
        lhs lhsColor: Color,
        rhs rhsColor: Color
    ) -> CGFloat {
        let lhs = UIColor(lhsColor)
        let rhs = UIColor(rhsColor)
        
        var lhsRed: CGFloat = 0,
            lhsGreen: CGFloat = 0,
            lhsBlue: CGFloat = 0,
        
            rhsRed: CGFloat = 0,
            rhsGreen: CGFloat = 0,
            rhsBlue: CGFloat = 0,
            
            // Don't need alpha, but need something to plug into .getRed()
            alpha_null: CGFloat = 0
        
        lhs.getRed(&lhsRed, green: &lhsGreen, blue: &lhsBlue, alpha: &alpha_null)
        rhs.getRed(&rhsRed, green: &rhsGreen, blue: &rhsBlue, alpha: &alpha_null)
        
        let redDiff = abs(Double(lhsRed * 255) - Double(rhsRed * 255))
        let greenDiff = abs(Double(lhsGreen * 255) - Double(rhsGreen * 255))
        let blueDiff = abs(Double(lhsBlue * 255) - Double(rhsBlue * 255))
        
        let distance: Double = sqrt(
            pow(redDiff, 2) +
            pow(greenDiff, 2) +
            pow(blueDiff, 2)
        )
        
        let similarity: Double = 1 - (distance / maxDistance)
        
        return similarity
    }
    
    private func sortByBrightest(colorCount: Int = 15) -> [UIColor] {
        guard let resized = image.nearestNeighbor(resizedTo: size),
              let palette = ColorThief.getPalette(from: resized, colorCount: colorCount) else { return [] }
        
        let sorted = palette.sorted { lhs, rhs in
            return rhs.brightness < lhs.brightness
        }
        
        return sorted.map { $0.makeUIColor() }
    }
    
    private func sortByDarkest(colorCount: Int = 15) -> [UIColor] {
        guard let palette = ColorThief.getPalette(from: image, colorCount: colorCount) else { return [] }
        
        let sorted = palette.sorted { lhs, rhs in
            return lhs.brightness < rhs.brightness
        }
        
        return sorted.map { $0.makeUIColor() }
    }
    
    private func getEdgeColors(from image: UIImage) -> [MMCQ.Color]? {
        let leftSide = image.crop(from: .left, 0.125)
        let rightSide = image.crop(from: .right, 0.125)
        let topSide = image.crop(from: .top, 0.125)
        let bottomSide = image.crop(from: .bottom, 0.125)
        
        guard let leftColor = ColorThief.getColor(from: leftSide),
              let rightColor = ColorThief.getColor(from: rightSide),
              let topColor = ColorThief.getColor(from: topSide),
              let bottomColor = ColorThief.getColor(from: bottomSide) else {
            return nil
        }
        
        return [leftColor, bottomColor, rightColor, topColor]
    }
}

// MARK: - Extensions

fileprivate extension CGFloat {
    var asPercentage: String {
        return "\((self * 1000).rounded() / 10)%"
    }
}

fileprivate extension Color {
    /// The color is closer in perception to white than black.
    ///
    /// ## Explanation
    /// A formula calculates perceived luminance of the `Color` based on the sensitivity of cone cells in human eyes. Green-sensitive cones contribute the most to perceived brightness, red-sensitive cones being second, and blue-sensitive third.
    ///
    /// ```swift
    /// let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
    /// ```
    ///
    /// 0.299 + 0.587 + 0.114 add up to 1.0; this is a shifting of ratios to prioritize the higher-sensitivity colors. The exact values derive from a formula for converting RGB values into YIQ values, a color space used for analog NTSC televisions.
    var isCloserToWhite: Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0,
            green: CGFloat = 0,
            blue: CGFloat = 0,
            alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        
        return luminance >= 0.6 // Color luminance is 6/10 or higher
    }
}

fileprivate extension MMCQ.Color {
    var brightness: CGFloat {
        let red = CGFloat(self.r) / 255
        let green = CGFloat(self.g) / 255
        let blue = CGFloat(self.b) / 255
        
        return (red * 299 + green * 587 + blue * 114) / 1000
    }
    
    var makeSwiftColor: Color {
        return Color(
            red: Double(self.r) / 255,
            green: Double(self.g) / 255,
            blue: Double(self.b) / 255
        )
    }
}

fileprivate extension UIColor {
    var hsb: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat)? {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: nil) else {
            return nil
        }
        return (h, s, b)
    }
    
    var isPoor: Bool {
        guard let hsb = self.hsb else { return true }
        
        let s = hsb.saturation
        let b = hsb.brightness
        
        // Too bright and desaturated
        if b > 0.90 && s < 0.15 { return true }
        
        // Muddy mid-tones
        if s < 0.20 && b >= 0.15 && b <= 0.70 { return true }
        
        // Saturation too low OR too close to black/white extremes
        if s < 0.15 || b < 0.12 || b > 0.92 { return true }
        
        return false
    }
    
    var isOffBlack: Bool {
        var red: CGFloat = 0,
            green: CGFloat = 0,
            blue: CGFloat = 0,
            alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Threshold for off-black is either
        // 1) all RGB values don't exceed 30, or
        // 2) all RGB values don't exceed 50 AND are all less than
        // 10 points apart (making it greyish)
        
        func RGBvaluesAreBelow(_ value: CGFloat) -> Bool {
            (red * 255 <= value) && (green * 255 <= value) && (blue * 255 <= value)
        }
        
        let lessThan10PointDifferenceBetweenAllValues: Bool = {
            abs(red - green) <= 10 && abs(red - blue) <= 10 && abs(green - blue) <= 10
        }()
        
        return RGBvaluesAreBelow(30) || RGBvaluesAreBelow(50) && lessThan10PointDifferenceBetweenAllValues
    }
    
    var isOffWhite: Bool {
        var red: CGFloat = 0,
            green: CGFloat = 0,
            blue: CGFloat = 0,
            alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Threshold for off-white is all RGB values don't fall
        // below 230 AND all values are less than 10 points apart
        
        let RGBvaluesAreAbove230: Bool = {
            (red * 255 >= 230) && (green * 255 >= 230) && (blue * 255 >= 230)
        }()
        
        let lessThan10PointDifferenceBetweenAllValues: Bool = {
            abs(red - green) <= 10 && abs(red - blue) <= 10 && abs(green - blue) <= 10
        }()
        
        return RGBvaluesAreAbove230 && lessThan10PointDifferenceBetweenAllValues
    }
}

