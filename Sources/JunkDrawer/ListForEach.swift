import SwiftUI

public struct ListForEach<Data: RandomAccessCollection, ID: Hashable, Content: View>: View where Data.Element: Identifiable {
    // MARK: - Properties
    
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    @ViewBuilder private let content: (Data.Element) -> Content
    
    // MARK: - Initializers
    
    public init(_ data: Data, @ViewBuilder _ content: @escaping (Data.Element) -> Content) where Data.Element: Identifiable, ID == Data.Element.ID {
        self.data = data
        self.id = \Data.Element.id
        self.content = content
    }
    
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder _ content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = id
        self.content = content
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack (alignment: .leading, spacing: 8) {
            ForEach(data, id: id) { item in
                content(item)
                if !isLast(item) {
                    Divider()
                }
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .background(listBackground)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    
    private func isLast(_ item: Data.Element) -> Bool {
        guard let lastItem = data.last else { return false }
        
        return item[keyPath: id] == lastItem[keyPath: id]
    }
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var listBackground: Color {
        switch colorScheme {
        case .dark: return listViewBackgroundDark
        case .light: return listViewBackgroundLight
        @unknown default: return .clear
        }
    }
}

