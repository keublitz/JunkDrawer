import SwiftUI

@available(iOS 17.0, *)
final internal class ColorBlender {
    let lhs: Color
    let rhs: Color
    
    internal init(_ lhs: Colorful, _ rhs: Colorful) {
        self.lhs = lhs.color
        self.rhs = rhs.color
    }
    
    internal func blend(_ steps: Int) -> [Color] {
        guard lhs != rhs else { return [lhs, lhs, rhs] }
        
        let c1 = lhs.components
        let c2 = rhs.components
        
        return (0..<steps).map { i in
            let t = Double(i) / Double(steps - 1)
            
            return Color(
                red:        Double(c1.r + (c2.r - c1.r) * t),
                green:      Double(c1.g + (c2.g - c1.g) * t),
                blue:       Double(c1.b + (c2.b - c1.b) * t),
                opacity:    Double(c1.a + (c2.a - c1.a) * t)
                    
            )
        }
    }
    
    internal func blendData(_ steps: Int) -> [ColorData] {
        guard lhs != rhs else { return [lhs.data, lhs.data, rhs.data] }
        
        let c1 = lhs.components
        let c2 = rhs.components
        
        return (0..<steps).map { i in
            let t = Double(i) / Double(steps - 1)
            
            return ColorData(
                r:      Float(c1.r + (c2.r - c1.r) * t),
                g:      Float(c1.g + (c2.g - c1.g) * t),
                b:      Float(c1.b + (c2.b - c1.b) * t),
                alpha:  Float(c1.a + (c2.a - c1.a) * t)
            )
        }
    }
}

@available(iOS 17.0, *)
fileprivate extension Color {
    var components: (r: Double, g: Double, b: Double, a: Double) {
        let resolved = self.resolve(in: EnvironmentValues())
        
        return (
            r: Double(resolved.red),
            g: Double(resolved.green),
            b: Double(resolved.blue),
            a: Double(resolved.opacity)
        )
    }
}

@available(iOS 17.0, *)
public extension Color {
    func blend(with rhs: Color, steps: Int = 6) -> [Color] {
        ColorBlender(self, rhs).blend(steps)
    }
    
    func midpoints(with rhs: Color, steps: Int = 6) -> [Color] {
        blend(with: rhs, steps: steps).dropFirst().dropLast()
    }
}

@available(iOS 17.0, *)
public extension ColorData {
    func blend(with rhs: ColorData, steps: Int = 6) -> [ColorData] {
        return ColorBlender(self, rhs).blendData(steps)
    }
    
    func midpoints(with rhs: ColorData, steps: Int = 6) -> [ColorData] {
        blend(with: rhs, steps: steps).dropFirst().dropLast()
    }
}
