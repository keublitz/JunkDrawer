import SwiftUI
import ColorThiefSwift

#if canImport(UIKit)
internal typealias NativeImage = UIImage
internal typealias NativeColor = UIColor
#elseif canImport(AppKit)
internal typealias NativeImage = NSImage
internal typealias NativeColor = NSColor
#endif

// MARK: - Color

// ForEachListView, ListView
internal let listViewBackgroundDark: Color = Color(#colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1))
internal let listViewBackgroundLight: Color = Color(#colorLiteral(red: 0.8823529412, green: 0.8823529412, blue: 0.8823529412, alpha: 1))

// MARK: - UIImage

internal extension UIImage {
    // ColorAlgorithm
    /// Scales an image down using nearest neighbor rescaling.
    func nearestNeighbor(resizedTo size: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            guard let cgContext = UIGraphicsGetCurrentContext() else { return }
            // no interpolation = nearest-neighbor
            cgContext.interpolationQuality = .none
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        
        return image
    }
}

// MARK: - View

public extension View {
    // ForEachListView, ListView
    func navigational(_ destination: () -> any View) -> some View {
        NavigationLink(destination: AnyView(destination())) {
            self.navigational
        }
    }
    
    // ForEachListView, ListView
    private var navigational: some View {
        HStack {
            self
            Spacer()
            Image(systemName: "chevron.right")
                .bold()
                .foregroundStyle(Color.secondary.opacity(0.75))
        }
    }
}

// MARK: - Lone extensions

// ColorAlgorithm

