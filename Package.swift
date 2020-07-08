// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OCMock",
    defaultLocalization: "en",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "OCMock",
            targets: ["OCMock"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .target(name: "OCMock",
                dependencies: [],
                path: "Source",
                exclude: [
                    "Carthage/",
                    "Changes.txt",
                    "OCMock/en.lproj/",
                    "OCMock/OCMock-Info.plist",
                    "OCMock/OCMock-Prefix.pch",
                    "OCMockTests/",
                    "Cartfile",
                    "Cartfile.resolved",
                    "OCMockLibTests/OCMockLibTests-Info.plist",
                    "OCMockLib/OCMockLib-Prefix.pch",
                    "OCMockLibTests/OCMockLibTests-Prefix.pch",
                ],
                publicHeadersPath: "Public",
                cSettings: [
                    .headerSearchPath("./"),
                    .unsafeFlags(["-fno-objc-arc"])
                ],
                cxxSettings: nil,
                swiftSettings: nil,
                linkerSettings: nil
        ),
    ]
)

