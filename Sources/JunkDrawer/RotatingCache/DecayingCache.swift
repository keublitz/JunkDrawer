// A node to use in a doubly linked list.
private final class DLLNode<Key: Hashable, Value>: Equatable {
    let key: Key
    var value: Value
    var prev: DLLNode<Key, Value>?
    var next: DLLNode<Key, Value>?
    
    init(key: Key, value: Value) {
        self.key = key
        self.value = value
    }
    
    static func == (lhs: DLLNode<Key, Value>, rhs: DLLNode<Key, Value>) -> Bool {
        return lhs.key == rhs.key
    }
}

/// A cache that deallocates it's least-called objects past a certain capacity.
///
/// ## Parameters
/// - `capacity`: The maximum capacity of objects the cache will store before objects decay. Defaults to 512.
/// - `onDelete`: The action to perform when a key-value pair decays.
///
/// ## Discussion
/// This rolling dictionary allows cached objects to automatically "decay" by keeping a ranking of most-to-least recently called and
/// deallocating those at the bottom after a defined capacity is exceeded.
///
/// ```swift
/// var headerImages = DecayingCache<String, ImageData>()
/// ```
///
/// Take this cache for example, where the key describes a photo and the value is decoded into an image. When the user goes to view the
/// cached photo, the key-value pair will be sent to the top-ranked placement in the cache order. Once the amount of images cached exceed
/// the total capacity of the images the cache can carry, the least viewed image will deallocate.
///
/// The `onDelete` closure can be used to call functions at deallocation, allowing changes to variables such as internal timers and
/// counters or references to data filesizes.
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
/// Keep in mind that key-value pairs will only be evicted *after* the capacity is exceeded. In the event of `itemCache`, the 251st pair will
/// be the one that starts the rotation.
///
/// For the sake of this example, `itemCache["Item_1"]` is the least-used item.
/// ```swift
/// var itemCache = DecayingCache<String, Item>()
///
/// for i in 1...512 {
///     itemCache["Item_\(i)"] = .init()
/// }
///
/// print(itemCache["Item_1"]) // Returns the first item
/// print(itemCache.count) // Returns "512"
///
/// itemCache["Item_513"] = .init() // Now exceeding capacity
///
/// print(itemCache["Item_1"]) // Returns nil
/// print(itemCache.first!.key) // Returns value of "Item_2"
/// print(itemCache.count) // Returns "512"
/// ```
public final class DecayingCache<Key: Hashable, Value> {
    // MARK: - Properties
    
    private typealias Node = DLLNode<Key, Value>
    
    // The dictionary of keys and doubly linked list nodes.
    private var dict: [Key: Node] = [:]
    
    private var head: Node? // Most recently used.
    private var tail: Node? // Least recently used.
    
    /// The maximum capacity of key-value pairs the cache will store before rotating.
    private let capacity: Int
    
    /// The action to perform when a key-value pair is rotated out.
    private var onDelete: ((Key) -> Void)?
    
    public init(capacity: Int = 512, onDelete: ((Key) -> Void)? = nil) {
        self.capacity = max(1, capacity)
        self.onDelete = onDelete
    }
    
    // MARK: - Dictionary logic
    
    public subscript(key: Key) -> Value? {
        get {
            // If it exists, reading it makes it the most recently used.
            guard let node = dict[key] else { return nil }
            // ...so move it to the head!
            moveToHead(node)
            return node.value
        }
        set {
            if let newValue {
                // If the node exists in the cache...
                if let node = dict[key] {
                    // ...update it —— which makes it the most recently used.
                    node.value = newValue
                    moveToHead(node)
                }
                // Else, if a brand new value is being introduced to the cache...
                else {
                    // Create and cache the new node.
                    let newNode = Node(key: key, value: newValue)
                    dict[key] = newNode
                    addToHead(newNode)
                    
                    // If over capacity, evict the tail end of the dictionary.
                    if dict.count > capacity, let leastUsed = tail {
                        // Perform onDelete action with key before totally erasing from cache.
                        onDelete?(leastUsed.key)
                        
                        removeNode(leastUsed)
                        dict.removeValue(forKey: leastUsed.key)
                    }
                }
            }
            else {
                // If user is assigning nil, manually delete the key.
                if let node = dict[key] {
                    removeNode(node)
                    dict.removeValue(forKey: key)
                }
            }
        }
    }
    
    /// The current amount of objects in the cache.
    public var count: Int { dict.count }
    
    /// The values of the current cache rotation, ranked from most to least recently called.
    public var currentValues: [Value] {
        var result: [Value] = []
        var current = head
        while let node = current {
            result.append(node.value)
            current = node.next
        }
        return result
    }
    
    /// The keys of the current cache rotation, ranked from most to least recently called.
    public var currentKeys: [Key] {
        var result: [Key] = []
        var current = head
        while let node = current {
            result.append(node.key)
            current = node.next
        }
        return result
    }
    
    /// A string representing the current order of a dictionary element.
    ///
    /// ## Paramaters
    /// - `of`: The dictionary element.
    ///
    /// ## Example
    /// ```swift
    /// let cache: DecayingCache<Int, String>
    ///
    /// print(cache.viewCurrentOrder(of: .keys))
    /// // Returns "[1, 2, 3]"
    ///
    /// print(cache.viewCurrentOrder(of: .values))
    /// // Returns "["a", "b", "c"]"
    /// ```
    public func viewCurrentOrder(of element: DictionaryElement) -> String {
        switch element {
        case .keys:
            return currentKeys.debugDescription
        case .values:
            return currentValues.debugDescription
        }
    }
    
    // MARK: - Helpers (node logic)
    
    private func addToHead(_ node: Node) {
        // Let node = A. Existing structure is [B] -> [C] <-> [D] etc.
        
        // Point the new node (A) towards the current head (B).
        // [A] -> [B] -> [C] <-> [D] <-> [...]
        node.next = head
        
        // New node (A) is at the front, so give it no previous value.
        // ** nil <- ** [A] -> [B] -> [C] <-> [D] <-> [...]
        node.prev = nil
        
        // If there was an existing head...
        if let currentHead = head {
            // [A] <-> [B] <-> [C] <-> [D] <-> [...]
            //     ^ ...point it (B) back to the node.
            currentHead.prev = node
        }
        
        // Set the new node (A) as head.
        head = node
        
        // If the list was empty, the new node is alone, which means it's both head and tail.
        // nil <- [head/tail] -> nil
        if tail == nil {
            tail = node
        }
    }
    
    private func removeNode(_ node: Node) {
        // Remove node C from [A] -> [B] <-> [C] <-> [D].
        
        // If the node before this one (B) exists...
        if let previousNode = node.prev {
            // ...bridge it over the removed node (C).
            // [A] -> [B] <-> [C] <-> [D] ==> [A] -> [B][C] <-> [D]
            //                                          ^ still there because we haven't removed the .prev
            //                                            relationship yet
            previousNode.next = node.next
        }
        // If there is no previous node, then the next node is now the head.
        else {
            // nil <- [C] <-> [D] ==> [D]
            head = node.next
        }
        
        // If the node has a successor (D), bridge it back over the removed node (C).
        if let nextNode = node.next {
            // [A] -> [B][C] <-> [D] ==> [A] -> [B] <-> [D]
            //                                    ^ /now/ we remove the .prev relationship!
            nextNode.prev = node.prev
        }
        // If there is no further node, then the previous node is now the tail.
        else {
            // [B] <-> [C] -> nil ==> [B]
            tail = node.prev
        }
        // [A] -> [B] <-> [D] :: [C] is no longer reachable through .next or .prev, will deallocate.
    }
    
    private func moveToHead(_ node: Node) {
        // Do nothing if the node is already at the head.
        guard node != head else { return }
        
        // Else, pluck it out of its current place and put it at the head.
        removeNode(node)
        addToHead(node)
    }
}

// MARK: - Empty initializer

public extension DecayingCache {
    /// An empty cache.
    static var empty: Self { .init() }
}

// MARK: - Miscellaneous

/// The elements of a dictionary.
public enum DictionaryElement {
    /// The dictionary's keys.
    case keys
    /// The dictionary's values.
    case values
}

/// A cache where objects that do not spark joy—or rather, get called the least—are automatically deallocated past a certain capacity.
public typealias KonmariCache<Key: Hashable, Value> = DecayingCache<Key, Value>
