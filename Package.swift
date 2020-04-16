// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OCMock",
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
        .target(name: "OCMock", dependencies: [], path: "Source", exclude: [], sources: ["OCMock"], publicHeadersPath: "OCMock", cSettings: [.unsafeFlags(["-fno-objc-arc"])], cxxSettings: nil, swiftSettings: nil, linkerSettings: [.unsafeFlags(["OCMock", "CLANG_ENABLE_OBJC_WEAK=YES"], nil)]),
        /*.testTarget(name: "OCMockTests", dependencies: ["OCMock"], path: "Source", exclude: [], sources: ["OCMockTests"], cSettings: [.unsafeFlags(["-fno-objc-arc"])], cxxSettings: [.unsafeFlags(["-fno-objc-arc"])], swiftSettings: nil, linkerSettings: [.unsafeFlags(["OCMock", "CLANG_ENABLE_OBJC_WEAK=YES"], nil)])*/
    ]
)

