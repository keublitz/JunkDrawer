# JunkDrawer

A varied collection of Swift data structures.

<p>
  <img alt="GitHub Release" src="https://img.shields.io/github/v/release/keublitz/JunkDrawer">
</p>

## ColorData

A codable structure that can hold color data.

### Overview

Colors are notriously un-codable classes, and cannot be directly stored in a codable data structure. `ColorData` provides a way to convert colors into data that conforms to Codable.

```swift
struct Object: Codable {
    let blue = Color.blue             // ❌ Won't conform
    let blue = ColorData(Color.blue)  // ✅ Will conform
}
```

### Initializing

`ColorData` can be initialized in multiple ways:

- Use the static `.of` function (requires explicit typing):
```swift
ColorData.of(Color.blue)
```

- Initialize with the color value:
```swift
ColorData(.blue)           
ColorData(uiColor: .blue)
```

- Use the `.data` extension directly on the color object:
```swift
let blue: Color = .blue
let data: ColorData = blue.data
```

- Set the red, green, blue, and alpha values manually:
```swift
ColorData(r: 1.0, g: 0.0, b: 0.0) // Returns red
ColorData(r: 0.0, g: 1.0, b: 0.0) // Returns green
ColorData(r: 1.0, g: 0.0, b: 1.0) // Returns purple
```

Once initialized, helper extensions can convert data back into usable color classes.

```swift
let blueData: ColorData = Object.blue
let blue: Color = Object.blue.color!
let blueUI: UIColor = Object.blue.uiColor!
```

### Encoding Opacity

Alpha values are also encoded into `ColorData` and decoded into all usable color classes, so even colors with opacity modifiers can be encoded as is.

```swift
let fullOrange: Color = .orange
let opaqueOrange: Color = .orange.opacity(0.5)

let fullOrangeData = ColorData.of(fullOrange)
let opaqueOrangeData = ColorData.of(opaqueOrange)

print(fullOrangeData.hex!)    // Returns #FF9230FF
print(opaqueOrangeData.hex!)  // Returns #FF923080
```

## DecayingCache

A cache that deallocates it's least-called objects past a certain capacity.

### Parameters

- `capacity`: The maximum capacity of objects the cache will store before deallocating objects. Defaults to 512.
- `onDelete`: The action to perform when a key-value pair decays.

This rolling dictionary allows cached objects to automatically "decay" by keeping a ranking of most-to-least recently called and deallocating those at the bottom after a defined capacity is exceeded.

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
- `remainingSlots`: The amount of empty slots in the cache.
- `keys`: A collection containing just the keys of the dictionary, sorted by most-to-least recently called.
- `values`: A collection containing just the values of the dictionary, sorted by most-to-least recently called.
- `removeAll()`: Removes all key-value pairs from the cache.

## RotatingCache

A cache that rotates out elements when a defined capacity is reached.

### Parameters
- `capacity`: The maximum capacity of items the cache will store before rotating items out. Defaults to 512.
- `onDelete`: The action to perform when a key-value pair is rotated out.

### Discussion
There's no priority of elements to keep other than how recently they were added to the cache. For persistent ranked caching based on how recently the element was called/referenced, use `DecayingCache`.

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

- `count`: The current amount of objects in the cache.
- `remainingSlots`: The amount of empty slots in the cache.
- `keys`: A collection containing just the keys of the dictionary, sorted by most-to-least recently added.
- `values`: A collection containing just the values of the dictionary, sorted by most-to-least recently added.
- `removeAll()`: Removes all key-value pairs from the cache.

> [!NOTE]
> When calling `keys` and/or `values` they will maintain the order of most-to-least recently added.

## StorageUnit

A class that stores, updates, and retrieves data.

### Parameters
- `key`: The key that determines which unit and what kind of data to read and write from. Expressible as `String` or `URL`.

### Overview
This class consists of generic save and load helpers, designed to decrease unnecessary verbosity and provide clear, readable direction on how the data is being handled, accessible through a lock-key system. To initialize a `StorageUnit`, create a `StorageKey` by assigning a `UserDefaults` key or `URL` value, then use it to "unlock" the unit.

```swift
let key = StorageKey("itemsArrayCache")
let unit = StorageUnit<[Item]>(key)
```

### Storing as JSON vs Data

Data can be stored as either a JSON dictionary or the raw `Data` type. The most efficient option will be automatically chosen. Storing as raw data can be beneficial for exceptionally large objects, such as raw image data. By default, all data is encoded and decoded as JSON.

```swift
let image: UIImage
let data = image.jpegData(compressionQuality: 0.8)

let photoLibraryURL: URL
let imageKey = photoLibraryURL.key
let imageUnit = StorageUnit<Data>(imageKey, rawData: true)

try? imageUnit.save(data)
var newData = try! imageUnit.load() // Returns as Data
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

- `load(into:)`: Loads data from the unit directly into an object.
```swift
unit.load(into: &items)
```

## StorageKey

The key to initialize and call a `StorageUnit`.

### Parameters

- `value`: The value of the key, expressible through `String` or `URL`.

### Overview

All a key needs to be created is the `String` of the `UserDefaults` key or a `URL` point to a directory.

```swift
let itemCacheString = "itemCache"
let itemCacheKey = StorageKey(itemCacheString)
// OR:
let itemCacheURL: URL
let itemCacheKey = StorageKey(itemCacheURL)
```

With the `.key` extension, a key can be create directly from the `String` or `URL` element.

```swift
let itemCacheString = "itemCache"
let itemCacheKey = itemCacheString.key
// OR:
let itemCacheURL: URL
let itemCacheKey: itemCacheURL.key
```
