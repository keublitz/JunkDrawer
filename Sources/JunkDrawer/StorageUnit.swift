import Foundation
import SwiftUI

/// A class that stores, updates, and retrieves data.
///
/// - Parameter key: The key that determines which unit and what kind of data to read and write from.
///
/// This class consists of generic save and load helpers, designed to decrease unnecessary verbosity and provide clear, readable direction on how the data is being handled, accessible through a lock-key system. To initialize a `StorageUnit`, create a <doc:StorageKey> by assigning a `UserDefaults` key or `URL` value and category of data to encode/decode, then use it to "unlock" the unit.
///
/// ```swift
/// let key = StorageKey("itemsArrayCache", [Item].self)
/// let unit = StorageUnit(key)
/// ```
///
/// With the unit established, you can store and load data with sleek and easy helper functions. Saving requires simply the data value in question placed in an inout initializer.
///
/// ```swift
/// var items: [Item] = // ...
/// try unit.save(items)
/// ```
///
/// Loading is even easier—just call the ``StorageUnit/load()`` function.
///
/// ```swift
/// items = unit.load()
/// ```
///
/// Alternatively, an inout parameter variant ``StorageUnit/load(into:)`` can be used.
/// ```swift
/// unit.load(into: &items)
/// ```
public final class StorageUnit<Storage: Codable>: Identifiable {
    // MARK: - Properties
    
    public var id: String { key.asString }
    
    // The String or URL value of the key.
    private var key: StorageKeyValue
    
    // The type of data to encode and decode.
    private let type: Storage.Type
    
    // MARK: - Initializers
    
    public init(_ key: StorageKey<Storage>) {
        self.key = key.value
        self.type = key.inputType
    }
    
    // MARK: - Helpers
    
    /// Saves data to the unit.
    ///
    /// - Parameter data: The data to encode and save.
    public func save(_ data: Storage) throws {
        switch key {
        case let key as URL: try save(data as Storage, toURL: key)
        case let key as String: try save(data as Storage, toUserDefaultsKey: key)
        default: throw StorageUnitError.noKeyDefined
        }
    }
    
    // Encodes and saves data to a URL.
    private func save(_ data: Storage, toURL url: URL) throws {
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: url)
    }
    
    // Encodes and saves data to a UserDefaults key.
    private func save(_ data: Storage, toUserDefaultsKey key: String) throws {
        let encoded = try JSONEncoder().encode(data)
        UserDefaults.standard.set(encoded, forKey: key)
    }
    
    /// Returns data from the unit.
    ///
    /// - Returns: The `Codable` data previously saved to the unit.
    public func load() throws -> Storage {
        switch key {
        case let key as URL: return try load(fromURL: key)
        case let key as String: return try load(fromUserDefaultsKey: key)
        default: throw StorageUnitError.noKeyDefined
        }
    }
    
    // Returns data from a URL.
    private func load(fromURL url: URL) throws -> Storage {
        let decoded = try Data(contentsOf: url)
        return try JSONDecoder().decode(type.self, from: decoded)
    }
    
    // Returns data from a UserDefaults key.
    private func load(fromUserDefaultsKey userDefaultsKey: String) throws -> Storage {
        if let userDefault = UserDefaults.standard.data(forKey: userDefaultsKey) {
            let decoded = try JSONDecoder().decode(type.self, from: userDefault)
            return decoded
        }
        else {
            throw StorageUnitError.unitIsEmpty(userDefaultsKey)
        }
    }
    
    /// Loads data from the unit into an object.
    ///
    /// - Parameter data: The object to load the value into.
    public func load(into data: inout Storage) throws {
        switch key {
        case let key as URL: return try load(fromURL: key, into: &data)
        case let key as String: return try load(fromUserDefaultsKey: key, into: &data)
        default: throw StorageUnitError.noKeyDefined
        }
    }
    
    // Loads data from a URL into an object.
    private func load(fromURL url: URL, into data: inout Storage) throws {
        data = try load(fromURL: url)
    }
    
    // Loads data from a UserDefaults key into an object.
    private func load(fromUserDefaultsKey userDefaultsKey: String, into data: inout Storage) throws {
        data = try load(fromUserDefaultsKey: userDefaultsKey)
    }
    
    public func clearOut() throws {
        switch key {
        case let key as URL: return try clearOut(url: key)
        case let key as String: return try clearOut(userDefaultsKey: key)
        default: throw StorageUnitError.noKeyDefined
        }
    }
    
    private func clearOut(userDefaultsKey: String) throws {
        guard let _ = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            throw StorageUnitError.unitIsEmpty(userDefaultsKey)
        }
        
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    private func clearOut(url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}

/// The key to initialize and call a <doc:StorageUnit>.
///
/// ## Calling Parameters
/// The default initializer takes in the `String` or `URL` value, and the data type.
/// ```swift
/// let itemCacheKey = StorageKey("itemKey", [Item].self)
/// ```
///
/// The second part of the initializer can be dropped if the key is explicitly typed.
/// ```swift
/// var itemCacheKey: StorageKey<[Item]> = StorageKey("itemCache")
/// ```
///
/// With the <doc:Swift/String/key()> extension, a key can be created directly from the `String` and/or `URL` element. This extension also supports explicit typing upfront or within the variable.
/// ```swift
/// let itemCacheURL: URL
/// let itemCacheKey = itemCacheURL.key([Item].self)
///
/// let itemCacheString: String = "itemCache"
/// var itemCacheKey: StorageKey<[Item]> = itemCacheString.key()
/// ```
///
/// - Parameter value: The value of the key, expressible through `String` or `URL`.
/// - Parameter inputType: The type of data being stored.
public struct StorageKey<Storage: Codable>: Identifiable, Equatable {
    public var id: String { value.asString }
    
    fileprivate let value: StorageKeyValue
    fileprivate let inputType: Storage.Type
    
    public init(_ value: StorageKeyValue, _ inputType: Storage.Type) {
        self.value = value
        self.inputType = inputType
    }
    
    public init(_ value: StorageKeyValue) {
        self.value = value
        self.inputType = Storage.self
    }
    
    public static func == (lhs: StorageKey<Storage>, rhs: StorageKey<Storage>) -> Bool {
        return lhs.id == rhs.id
    }
}

/// The key for getting and setting data within a <doc:StorageUnit>.
public protocol StorageKeyValue {
    /// Returns the key value as a String.
    var asString: String { get }
    
    /// Returns the key value as a URL.
    var asURL: URL? { get }
}

extension String: StorageKeyValue {
    /// Returns the key value as a `String`.
    public var asString: String { self }
    
    /// Returns the key value as a `URL`.
    public var asURL: URL? { URL(string: self) }
    
    /// Creates a key from the given `String`.
    ///
    /// ## Explicit Typing
    /// Value type must be explicitly defined when creating the key.
    ///
    /// ```swift
    /// let cacheKey: StorageKey<[Item]> = "itemsCache".key()
    /// ```
    public func key<T: Codable>() -> StorageKey<T> {
        StorageKey(self, T.self)
    }
    
    /// Creates a key from the given `String`.
    ///
    /// ##
    /// ```swift
    /// let itemsCacheKey = "itemsCache".key([Item].self)
    /// ```
    ///
    /// - Parameter type: The type of the value the related unit will store.
    public func key<T: Codable>(_ type: T.Type) -> StorageKey<T> {
        StorageKey(self, type)
    }
}

extension URL: StorageKeyValue {
    public var asString: String { self.absoluteString }
    public var asURL: URL? { self }
    
    /// Creates a key from the given `URL`.
    ///
    /// ## Explicit Typing
    /// Value type must be explicitly defined when creating the key.
    ///
    /// ```swift
    /// let cacheURL: URL
    /// let cacheKey: StorageKey<[Item]> = cacheURL.key()
    /// ```
    public func key<T: Codable>() -> StorageKey<T> {
        StorageKey(self, T.self)
    }
    
    /// Creates a key from the given `URL`.
    ///
    /// ##
    /// ```swift
    /// let cacheURL: URL
    /// let cacheKey = cacheURL.key([Items].self)
    /// ```
    ///
    /// - Parameter type: The type of the value the related unit will store.
    public func key<T: Codable>(_ type: T.Type) -> StorageKey<T> {
        StorageKey(self, type)
    }
}

fileprivate enum StorageUnitError: Error, LocalizedError {
    case noKeyDefined
    case unitIsEmpty(_: String)
    
    var errorDescription: String? {
        switch self {
        case .noKeyDefined: return "The key was not defined as either a String or URL. Check that StorageUnit is initialized with a StorageUnitKey value."
        case .unitIsEmpty: return "The unit linked to this key is empty."
        }
    }
}
