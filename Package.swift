// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "swift-sharing",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
    .tvOS(.v16),
    .watchOS(.v9),
    .macCatalyst(.v16),
  ],
  products: [
    .library(
      name: "Sharing",
      targets: ["Sharing"]
    )
  ],
  dependencies: [
    // Use forks with Android cross-compilation fixes
    .package(url: "https://github.com/svobodamarek/combine-schedulers", from: "1.0.0"),
    // OpenCombine for Android (Combine replacement).
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0"),
    .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.3.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
    .package(url: "https://github.com/svobodamarek/swift-dependencies", from: "1.5.1"),
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-perception", "1.4.1"..<"3.0.0"),
    .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.4.3"),
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.0.0"),
    // Provide SwiftUI module on Android via Skip.
    .package(url: "https://source.skip.tools/skip-fuse-ui.git", from: "1.0.0"),
  ],
  targets: [
    .target(
      name: "Sharing",
      dependencies: [
        "Sharing1",
        "Sharing2",
        .product(name: "CombineSchedulers", package: "combine-schedulers"),
        .product(name: "OpenCombine", package: "OpenCombine", condition: .when(platforms: [.android])),
        .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
        .product(name: "CustomDump", package: "swift-custom-dump"),
        .product(name: "Dependencies", package: "swift-dependencies"),
        .product(name: "IdentifiedCollections", package: "swift-identified-collections"),
        .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
        .product(name: "PerceptionCore", package: "swift-perception"),
        // Makes SwiftUI importable in this module on Android.
        .product(name: "SkipFuseUI", package: "skip-fuse-ui"),
      ],
      resources: [
        .process("PrivacyInfo.xcprivacy")
      ]
    ),
    .testTarget(
      name: "SharingTests",
      dependencies: [
        "Sharing",
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
      ],
      exclude: ["Sharing.xctestplan"]
    ),
    .target(
      name: "Sharing1",
      path: "Sources/VersionMarkerModules/Sharing1"
    ),
    .target(
      name: "Sharing2",
      path: "Sources/VersionMarkerModules/Sharing2"
    ),
  ],
  swiftLanguageModes: [.v6]
)
