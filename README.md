<img src="./Logo.png" width="128"> 

# Metallic

`Metallic` brings a collection of SwiftUI shaders

## See Also

- [Engine](https://github.com/nathantannar4/Engine)
- [Turbocharger](https://github.com/nathantannar4/Turbocharger)
- [Transmission](https://github.com/nathantannar4/Transmission)
- [Ignition](https://github.com/nathantannar4/Ignition)

## Requirements

- Deployment target: iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0 or visionOS 1.0
- Xcode 16.4+

## Installation

### Xcode Projects

Select `File` -> `Swift Packages` -> `Add Package Dependency` and enter `https://github.com/nathantannar4/Metallic`.

### Swift Package Manager Projects

You can add `Metallic` as a package dependency in your `Package.swift` file:

```swift
let package = Package(
    //...
    dependencies: [
        .package(url: "https://github.com/nathantannar4/Metallic"),
    ],
    targets: [
        .target(
            name: "YourPackageTarget",
            dependencies: [
                .product(name: "Metallic", package: "Metallic"),
            ],
            //...
        ),
        //...
    ],
    //...
)
```

## License

Distributed under the BSD 2-Clause License. See ``LICENSE.md`` for more information.
