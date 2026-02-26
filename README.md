# JunkDrawer

A varied collection of Swift data structures.

<p>
  <img alt="GitHub Release" src="https://img.shields.io/github/v/release/keublitz/JunkDrawer">
</p>

## DecayingCache

A cache that deallocates it's least-called objects past a certain capacity.

### Parameters

- `capacity`: The maximum capacity of objects the cache will store before deallocating objects. Defaults to 512.
- `onDelete`: The action to perform when a key-value pair decays.

```swift
var headerImages = DecayingCache<String, ImageData>()
```

Take this cache for example, where the key describes a photo and the value is decoded into an image. When the user goes to view the cached photo, the key-value pair will be sent to the top-ranked placement in the cache order. Once the amount of images cached exceed the total capacity of the images the cache can carry, the least viewed image will deallocate.

The `onDelete` closure can be used to call functions at deallocation, allowing synchronous changes to variables such as internal timers and counters or references to data filesizes.

```swift
var itemsDeleted: Int = 0

let itemCache = DecayingCache<String, Item>(
  onDelete: {
    itemsDeleted += 1
    print("Item deleted.")
  }
)
```

Keep in mind that key-value pairs will only decay *after* the capacity is exceeded. In the event of `itemCache`, the 513th pair will be the one that starts the rotation.

For the sake of this example, `itemCache["Item_1"]` is the least used item.

```swift
var itemCache = DecayingCache<String, Item>()

for i in 1...512 {
  itemCache["Item_\(i)"] = .init()
}

print(itemCache["Item_1"]) // Returns the first item
print(itemCache.count) // 512

itemCache["Item_513"] = .init() // Now exceeding capacity

print(itemCache["Item_1"]) // Returns nil
print(itemCache.keys.last!) // Returns "Item_2" (Least called after Item_1)
```

### Helpers

- `count`: The current amount of objects in the cache.
- `keys`: A collection containing just the keys of the dictionary.
- `values`: A collection containing just the values of the dictionary.

> <b>Note:</b> When calling `keys` and/or `values` they will maintain the order of most-to-least recently used.

## RotatingCache

A cache that rotates out elements when a defined capacity is reached.

### Parameters
- `capacity`: The maximum capacity of items the cache will store before rotating items out. Defaults to 512.
- `onDelete`: The action to perform when a key-value pair is rotated out.

### Discussion
There's no priority of elements to keep other than how recently they were added to the cache. For persistent ranked caching based on how recently the element was called/referenced, see `DecayingCache`.

The `onDelete` closure can be used to call functions at deallocation, allowing synchronous changes to variables such as internal timers and counters or references to data filesizes.

```swift
var itemsDeleted: Int = 0

let itemCache = RotatingCache<String, Item>(
  capacity: 250,
  onDelete: {
    itemsDeleted += 1
    print("Item deleted.")
  }
)
```

Keep in mind that key-value pairs will only be evicted *after* the capacity is exceeded. In the event of `itemCache`, the 513th pair will be the one that starts the rotation.

```swift
for i in 1...250 {
  itemCache["Item_\(i)"] = .init()
}

print(itemCache["Item_1"]) // Returns the first item
print(itemCache.count) // Returns "250"

itemCache["Item_251"] = .init() // Now exceeding capacity

print(itemCache["Item_1"]) // Returns nil
print(itemCache.count) // Returns "250"
```

### Helpers

- `count`: The amount of items currently stored in the cache.
- `keys`: A collection containing just the keys of the dictionary.
- `values`: A collection containing just the values of the dictionary.

> <b>Note:</b> When calling `keys` and/or `values` they will maintain the order of most-to-least recently added.

## StorageUnit

A class that stores, updates, and retrieves data.

### Parameters
- `key`: The key that determines which unit and what kind of data to read and write from. Expressible as `String` or `URL`.

### Overview
This class consists of generic save and load helpers, designed to decrease unnecessary verbosity and provide clear, readable direction on how the data is being handled, accessible through a lock-key system. To initialize a `StorageUnit`, create a ``StorageKey`` by assigning a `UserDefaults` key or `URL` value and category of data to encode/decode, then use it to "unlock" the unit.

```swift
let key = StorageKey("userItems", [Item].self)
let unit = StorageUnit(key)
```

With the unit established, you can store and load data with sleek and easy helper functions.

### Helpers
- `save(_:)`: Saves data to the unit.
```swift
var items: [Item] = // ...
try unit.save(&items)
```

- `load()`: Returns data from the unit.
```swift
items = unit.load()
```

- `load(into:)`: Loads data from the unit into an object.
```swift
unit.load(into: &items)
```
