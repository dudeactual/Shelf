// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Shelf",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Shelf", targets: ["Shelf"])
    ],
    targets: [
        .target(
            name: "ShelfCore",
            path: "Sources/ShelfCore"
        ),
        .executableTarget(
            name: "Shelf",
            dependencies: [
                "ShelfCore"
            ],
            path: "Sources/Shelf"
        ),
        .executableTarget(
            name: "ShelfStorageChecks",
            dependencies: ["ShelfCore"],
            path: "Checks/ShelfStorageChecks"
        )
    ],
    swiftLanguageModes: [.v5]
)
