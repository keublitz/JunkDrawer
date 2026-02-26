import Foundation
import SwiftUI

/// A class that stores, updates, and retrieves data.
///
/// - Parameter key: The key that determines which unit and what kind of data to read and write from.
///
/// This class consists of generic save and load helpers, designed to decrease unnecessary verbosity and provide clear, readable direction on how the data is being handled, accessible through a lock-key system. To initialize a `StorageUnit`, create a ``StorageKey`` by assigning a `UserDefaults` key or `URL` value and category of data to encode/decode, then use it to "unlock" the unit.
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
/// Loading is even easier—just call the `.load()` function.
///
/// ```swift
/// items = unit.load()
/// ```
///
/// Alternatively, an inout parameter variant `.load(into:)` can be used.
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
    
    // Loads data from a URL into an in
    private func load(fromURL url: URL, into data: inout Storage) throws {
        data = try load(fromURL: url)
    }
    
    private func load(fromUserDefaultsKey userDefaultsKey: String, into data: inout Storage) throws {
        data = try load(fromUserDefaultsKey: userDefaultsKey)
    }
}

/// The key to initialize and call a `StorageUnit`.
///
/// - Parameter value: The value of the key, expressible through `String` or `URL`.
/// - Parameter inputType: The type of data being stored.
///
/// ## Example
/// ```swift
/// let itemKey = StorageUnitKey("itemKey", Item.self)
/// ```
public struct StorageKey<Storage: Codable>: Identifiable {
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
}

/// The key for getting and setting data within a `StorageUnit`.
public protocol StorageKeyValue {
    var asString: String { get }
}

extension String: StorageKeyValue {
    /// Returns a
    public var asString: String { self }
}

extension URL: StorageKeyValue {
    public var asString: String { self.absoluteString }
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
