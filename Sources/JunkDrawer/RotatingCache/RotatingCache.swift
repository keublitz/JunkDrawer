/// A cache dictionary that rotates out elements when a defined capacity is reached.
///
/// ## Parameters
/// - `capacity`: The maximum capacity of items the cache will store before rotating items out. Defaults to 512.
/// - `onDelete`: The action to perform when a key-value pair is rotated out.
///
/// ## Discussion
/// There's no priority of elements to keep other than how recently they were added to the cache. For persistent ranked caching based on
/// how recently the element was called/referenced, see ``DecayingCache``.
///
/// The `onDelete` closure can be used to call functions at deallocation, allowing synchronous changes to variables such as internal timers
/// and counters or references to data filesizes.
///
/// ```swift
/// var itemsDeleted: Int = 0
///
/// let itemCache = RotatingCache<String, Item>(
///     capacity: 250,
///     onDelete: {
///         itemsDeleted += 1
///         print("Item deleted.")
///     }
/// )
/// ```
///
/// Keep in mind that key-value pairs will only be rotated out *after* the capacity is exceeded. In the event of `itemCache`, the 251st pair
/// will be the one that starts the rotation.
///
/// ```swift
/// for i in 1...250 {
///     itemCache["Item_\(i)"] = .init()
/// }
///
/// print(itemCache.count) // Returns "250"
/// print(itemCache["Item_1"]) // Returns the first item
///
/// itemCache["Item_251"] = .init() // Now exceeding capacity
///
/// print(itemCache["Item_1"]) // Returns nil
/// print(itemCache.keys.first!) // Returns "Item_2"
/// print(itemCache.count) // Returns "250"
/// ```
public struct RotatingCache<Key: Hashable, Value> {
    // MARK: - Properties
    
    private var dict: [Key: Value] = [:]
    private var order: [Key] = []
    
    /// The maximum capacity of key-value pairs the cache will store before rotating.
    private let capacity: Int
    
    /// The action to perform when a key-value pair is rotated out.
    private let onDelete: ((Key) -> Void)?
    
    public init(capacity: Int = 512, onDelete: ((Key) -> Void)? = nil) {
        self.capacity = max(1, capacity)
        self.onDelete = onDelete
    }
    
    // MARK: - Dictionary interface
    
    public subscript(key: Key) -> Value? {
        get { return dict[key] }
        set {
            if let newValue {
                let isNewKey: Bool = dict[key] == nil
                dict[key] = newValue
                
                if isNewKey {
                    order.append(key)
                    
                    if order.count > capacity {
                        let evictedKey = order.removeFirst()
                        // Perform onDelete action with key before totally erasing from cache.
                        onDelete?(evictedKey)
                        dict[evictedKey] = nil
                    }
                }
            }
            else {
                // If no value was set, manually remove the key-value pair from the dictionary.
                dict[key] = nil
                if let index = order.firstIndex(of: key) {
                    order.remove(at: index)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    /// The amount of items currently stored in the cache.
    public var count: Int {
        return dict.count
    }
    
    /// A collection containing just the keys of the dictionary.
    ///
    /// > NOTE: This array is ordered from most-to-least recently added.
    public var keys: [Key] { order.reversed() }
    
    /// A collection containing just the values of the dictionary.
    ///
    /// > NOTE: This array is ordered from most-to-least recently added.
    public var values: [Value] {
        var arr: [Value] = []
        
        for key in order {
            if let val = dict[key] {
                arr.append(val)
            }
        }
        
        return arr.reversed()
    }
}

// MARK: - Empty initializer

public extension RotatingCache {
    /// An empty cache.
    static var empty: Self { .init() }
}
