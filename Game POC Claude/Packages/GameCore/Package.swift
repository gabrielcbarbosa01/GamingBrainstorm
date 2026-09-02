// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GameCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "GameCore", targets: ["GameCore"])
    ],
    targets: [
        // REGRA DE ARQUITETURA: este alvo nao pode importar SceneKit, RealityKit,
        // AppKit, SwiftUI ou qualquer framework de render. Apenas Foundation/simd.
        .target(name: "GameCore")
    ],
    swiftLanguageModes: [.v5]
)
