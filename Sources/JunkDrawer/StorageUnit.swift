import Foundation
import SwiftUI

/// A class that stores, updates, and retrieves data.
///
/// This class consists of generic save and load helpers, designed to decrease unnecessary verbosity and provide clear, readable direction on how the data is being handled, accessible through a lock-key system. To initialize a `StorageUnit`, create a <doc:StorageKey> by assigning a `UserDefaults` key or `URL` value, then use it to "unlock" the unit.
///
/// ```swift
/// let key = StorageKey("itemsArrayCache")
/// let unit = StorageUnit<Codable>(key)
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
///
/// ## Storing as JSON vs Data
///
/// Data can be stored as either a JSON dictionary or the raw `Data` type. Storing as raw data can be beneficial for exceptionally large objects, such as raw image data. By default, all data is encoded and decoded as JSON.
/// ```swift
/// let image: UIImage
/// let data = image.jpegData()
///
/// let photoLibraryURL: URL
/// let imageKey = photoLibraryURL.key
/// let imageUnit = StorageUnit<Data>(imageKey, rawData: true)
///
/// try? imageUnit.save(data)
/// var newData = try? imageUnit.load() // Returns as Data?
/// ```
///
/// - Parameter key: The key that determines which unit and what kind of data to read and write from.
/// - Parameter rawData: A boolean value indicating how to encode/decode the data. When `true`, data will encode/decode as a JSON dictionary. When `false`, data will decode/encode as `Data`. Defaults to `true`.
public final class StorageUnit<Storage: Codable>: Identifiable {
    // MARK: - Properties
    
    public var id: String { key.asString }
    
    // The String or URL value of the key.
    private var key: StorageKeyValue
    
    // The type of data to encode and decode.
    private let type = Storage.self
    
    // TRUE: the data is stored as a JSON dictionary.
    private let rawData: Bool
    
    // MARK: - Initializers
    
    public init(_ key: StorageKey, rawData: Bool = false) {
        self.key = key.value
        self.rawData = rawData
    }
    
    // MARK: - Helpers
    
    /// Saves data to the unit.
    ///
    /// - Parameter data: The data to encode and save.
    /// - Parameter encodeRawData: A boolean value for encoding into raw `Data`. `true` stores the raw data; `false` stores the data as a JSON dictionary. Defaults to `false`.
    ///
    /// - Note: When saving with `UserDefaults` (setting the `StorageKey` value to `String`), data will always encode as JSON.
    public func save(_ data: Storage, encodeRawData: Bool? = nil) throws {
        let encodeRaw = encodeRawData ?? self.rawData
        
        switch key {
        case let key as URL: try save(data as Storage, toURL: key, encodeRawData: encodeRaw)
        case let key as String: try save(data as Storage, toUserDefaultsKey: key)
        default: throw StorageUnitError.noKeyDefined
        }
    }
    
    // Encodes and saves data to a URL.
    private func save(_ data: Storage, toURL url: URL, encodeRawData: Bool? = nil) throws {
        let encodeRaw = encodeRawData ?? self.rawData
        
        if encodeRaw {
            guard let encodable = data as? Data else {
                throw StorageUnitError.cannotCastToData
            }
            try encodable.write(to: url)
        }
        else {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: url)
        }
    }
    
    // Encodes and saves data to a UserDefaults key.
    private func save(_ data: Storage, toUserDefaultsKey key: String) throws {
        let encoded = try JSONEncoder().encode(data)
        UserDefaults.standard.set(encoded, forKey: key)
    }
    
    /// Returns data from the unit.
    ///
    /// - Parameter decodeRawData: A boolean value for decoding into raw data. `true` loads the raw data; `false` decodes the data into a JSON dictionary. Defaults to `false`.
    /// - Returns: The `Codable` data previously saved to the unit.
    public func load(decodeRawData: Bool? = nil) throws -> Storage {
        let decodeRaw = decodeRawData ?? self.rawData
        
        switch key {
        case let key as URL:
            if decodeRaw {
                guard let data = try Data(contentsOf: key) as? Storage else {
                    throw StorageUnitError.cannotCastToData
                }
                
                return data
            }
            else {
                return try load(fromURL: key)
            }
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
    /// - Parameter decodeRawData: A boolean value for decoding into raw `Data`. `true` loads the raw data; `false` decodes the data into a JSON dictionary. Defaults to `false`.
    public func load(into data: inout Storage, decodeRawData: Bool? = nil) throws {
        let decodeRaw = decodeRawData ?? self.rawData
        
        switch key {
        case let key as URL:
            if decodeRaw {
                guard let storageData = try Data(contentsOf: key) as? Storage else {
                    throw StorageUnitError.cannotCastToData
                }
                
                data = storageData
            }
            else {
                data = try load(fromURL: key)
            }
        case let key as String: return try load(fromUserDefaultsKey: key, into: &data)
        default: throw StorageUnitError.noKeyDefined
        }
    }
    
    // Loads data from a UserDefaults key into an object.
    private func load(fromUserDefaultsKey userDefaultsKey: String, into data: inout Storage) throws {
        data = try load(fromUserDefaultsKey: userDefaultsKey)
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
/// With the <doc:Swift/String/key> extension, a key can be created directly from the `String` and/or `URL` element. This extension also supports explicit typing upfront or within the variable.
/// ```swift
/// let itemCacheURL: URL
/// let itemCacheKey: StorageKey = itemCacheURL.key
///
/// let itemCacheString: String = "itemCache"
/// var itemCacheKey: StorageKey = itemCacheString.key
/// ```
///
/// - Parameter value: The value of the key, expressible through `String` or `URL`.
/// - Parameter inputType: The type of data being stored.
public struct StorageKey: Identifiable, Equatable {
    public var id: String { value.asString }
    
    fileprivate let value: StorageKeyValue
    
    public init(_ value: StorageKeyValue) {
        self.value = value
    }
    
    public static func == (lhs: StorageKey, rhs: StorageKey) -> Bool {
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
    /// ## Example
    /// ```swift
    /// let cacheKey: StorageKey = "itemsCache".key()
    /// ```
    public var key: StorageKey { StorageKey(self) }
}

extension URL: StorageKeyValue {
    public var asString: String { self.absoluteString }
    public var asURL: URL? { self }
    
    /// Creates a key from the given `URL`.
    ///
    /// ## Example
    /// ```swift
    /// let cacheURL: URL
    /// let cacheKey: StorageKey = cacheURL.key
    /// ```
    public var key: StorageKey { StorageKey(self) }
}

fileprivate enum StorageUnitError: Error, LocalizedError {
    case noKeyDefined
    case unitIsEmpty(_: String)
    case cannotCastToData
    
    var errorDescription: String? {
        switch self {
        case .noKeyDefined: return "The key was not defined as either a String or URL. Check that StorageUnit is initialized with a StorageUnitKey value."
        case .unitIsEmpty: return "The unit linked to this key is empty."
        case .cannotCastToData: return "The given value cannot be cast to type Data."
        }
    }
}
