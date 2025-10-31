// swift-tools-version: 5.9

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-protocol-mirror",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
  ],
  products: [
    .library(
      name: "ProtocolMirror",
      targets: ["ProtocolMirrorMacros"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax", "509.0.0"..<"603.0.0"),
  ],
  targets: [
    .target(
      name: "ProtocolMirrorMacros",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .macro(
      name: "ProtocolMirrorPlugin",
      dependencies: [
        .product(name: "SwiftSyntax", package: "swift-syntax"),
        .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        .product(name: "SwiftDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftOperators", package: "swift-syntax"),
        .product(name: "SwiftParser", package: "swift-syntax"),
        .product(name: "SwiftParserDiagnostics", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
      ]
    ),
    .testTarget(
      name: "ProtocolMirrorTests",
      dependencies: [
        "ProtocolMirrorMacros",
        "ProtocolMirrorPlugin",
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)