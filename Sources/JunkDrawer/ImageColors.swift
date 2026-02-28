import SwiftUI

final public class ImagePalette {
    private let image: UIImage
    
    public init(_ image: UIImage) {
        self.image = image
    }
    
    public var data: [ColorData] { image.colorData }
    
    public subscript(rank: ColorRanking) -> ColorData {
        switch rank {
        case .primary: return data[0]
        case .secondary: return data[1]
        case .tertiary: return data[2]
        case .accent: return data[3]
        }
    }
    
    public subscript(rank: ColorRanking) -> Color? {
        switch rank {
        case .primary: return data[0].color
        case .secondary: return data[1].color
        case .tertiary: return data[2].color
        case .accent: return data[3].color
        }
    }
    
    public subscript(rank: ColorRanking) -> UIColor? {
        switch rank {
        case .primary: return data[0].uiColor
        case .secondary: return data[1].uiColor
        case .tertiary: return data[2].uiColor
        case .accent: return data[3].uiColor
        }
    }
}

public enum ColorRanking {
    /// The most prominent color in the image.
    case primary
    /// The second-most prominent color in the image.
    case secondary
    /// The third-most prominent color in the image.
    case tertiary
    /// The accent color.
    case accent
}

public enum ColorReturnType {
    /// Return as `Swift.Color`.
    case color
    /// Return as `UIColor`.
    case uiColor
    /// Return as `ColorData`.
    case colorData
}

internal extension UIImage {
    var colorData: [ColorData] {
        var arr: [ColorData] = []
        
        let alg = ColorAlgorithm(self)
        
        arr.append(alg.primary().data)
        arr.append(alg.secondary().data)
        arr.append(alg.tertiary().data)
        arr.append(alg.accent().data)
        
        return arr
    }
}
