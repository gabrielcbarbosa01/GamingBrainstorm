//
//  EnvironmentDecorations.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import SwiftUI

public struct TreeBillboardItem: Identifiable, Sendable {
    public let id: UUID
    public let x: Double
    public let y: Double
    public let scale: Double
    public let swayOffset: Double
    
    public init(id: UUID = UUID(), x: Double, y: Double, scale: Double = 1.0, swayOffset: Double = 0.0) {
        self.id = id
        self.x = x
        self.y = y
        self.scale = scale
        self.swayOffset = swayOffset
    }
}

public struct GroundFoliageItem: Identifiable, Sendable {
    public let id: UUID
    public let x: Double
    public let y: Double
    public let symbolName: String
    public let tintColor: Color
    public let size: Double
    
    public init(id: UUID = UUID(), x: Double, y: Double, symbolName: String, tintColor: Color, size: Double = 22.0) {
        self.id = id
        self.x = x
        self.y = y
        self.symbolName = symbolName
        self.tintColor = tintColor
        self.size = size
    }
}

public struct BiomeEnvironmentSet {
    public let trees: [TreeBillboardItem]
    public let foliage: [GroundFoliageItem]
    public let groundBaseColor: Color
    public let groundAccentColor: Color
    public let ambientAtmosphereColor: Color
    
    public static func environment(for biome: BiomeType) -> BiomeEnvironmentSet {
        switch biome {
        case .mataAtlantica:
            return BiomeEnvironmentSet(
                trees: [
                    TreeBillboardItem(x: -60, y: -45, scale: 1.25, swayOffset: 0.1),
                    TreeBillboardItem(x: -30, y: -65, scale: 1.1, swayOffset: 0.3),
                    TreeBillboardItem(x: 45, y: -50, scale: 1.35, swayOffset: 0.5),
                    TreeBillboardItem(x: 70, y: -20, scale: 1.0, swayOffset: 0.2),
                    TreeBillboardItem(x: -75, y: 15, scale: 1.15, swayOffset: 0.4),
                    TreeBillboardItem(x: -50, y: 55, scale: 1.3, swayOffset: 0.6),
                    TreeBillboardItem(x: 55, y: 45, scale: 1.2, swayOffset: 0.1),
                    TreeBillboardItem(x: 10, y: 65, scale: 1.05, swayOffset: 0.7),
                    TreeBillboardItem(x: -15, y: -25, scale: 0.95, swayOffset: 0.2)
                ],
                foliage: [
                    GroundFoliageItem(x: -20, y: -10, symbolName: "leaf.fill", tintColor: .green, size: 24),
                    GroundFoliageItem(x: 35, y: 10, symbolName: "sparkle", tintColor: .yellow, size: 18),
                    GroundFoliageItem(x: -40, y: 30, symbolName: "camera.macro", tintColor: .pink, size: 26),
                    GroundFoliageItem(x: 60, y: -10, symbolName: "leaf.circle.fill", tintColor: .mint, size: 22),
                    GroundFoliageItem(x: 15, y: -40, symbolName: "drop.fill", tintColor: .teal, size: 20)
                ],
                groundBaseColor: Color(red: 0.14, green: 0.32, blue: 0.18),
                groundAccentColor: Color(red: 0.22, green: 0.48, blue: 0.26),
                ambientAtmosphereColor: Color(red: 0.1, green: 0.25, blue: 0.15).opacity(0.3)
            )
            
        case .amazonia:
            return BiomeEnvironmentSet(
                trees: [
                    TreeBillboardItem(x: -70, y: -55, scale: 1.45, swayOffset: 0.2),
                    TreeBillboardItem(x: -20, y: -60, scale: 1.3, swayOffset: 0.4),
                    TreeBillboardItem(x: 50, y: -60, scale: 1.4, swayOffset: 0.1),
                    TreeBillboardItem(x: 75, y: -10, scale: 1.2, swayOffset: 0.5),
                    TreeBillboardItem(x: -65, y: 35, scale: 1.35, swayOffset: 0.3),
                    TreeBillboardItem(x: 60, y: 50, scale: 1.4, swayOffset: 0.6),
                    TreeBillboardItem(x: -10, y: 55, scale: 1.25, swayOffset: 0.2),
                    TreeBillboardItem(x: 25, y: 20, scale: 1.1, swayOffset: 0.8)
                ],
                foliage: [
                    GroundFoliageItem(x: -45, y: -20, symbolName: "drop.circle.fill", tintColor: .teal, size: 26),
                    GroundFoliageItem(x: 30, y: -15, symbolName: "leaf.arrow.circlepath", tintColor: .mint, size: 24),
                    GroundFoliageItem(x: -15, y: 25, symbolName: "camera.macro", tintColor: .green, size: 22),
                    GroundFoliageItem(x: 40, y: 30, symbolName: "water.waves", tintColor: .cyan, size: 28)
                ],
                groundBaseColor: Color(red: 0.08, green: 0.28, blue: 0.16),
                groundAccentColor: Color(red: 0.12, green: 0.40, blue: 0.22),
                ambientAtmosphereColor: Color(red: 0.05, green: 0.22, blue: 0.18).opacity(0.35)
            )
            
        case .cerrado:
            return BiomeEnvironmentSet(
                trees: [
                    TreeBillboardItem(x: -55, y: -40, scale: 1.0, swayOffset: 0.3),
                    TreeBillboardItem(x: 40, y: -45, scale: 1.1, swayOffset: 0.1),
                    TreeBillboardItem(x: -60, y: 40, scale: 0.95, swayOffset: 0.4),
                    TreeBillboardItem(x: 50, y: 35, scale: 1.05, swayOffset: 0.2),
                    TreeBillboardItem(x: 0, y: -60, scale: 0.9, swayOffset: 0.5)
                ],
                foliage: [
                    GroundFoliageItem(x: -30, y: -15, symbolName: "sun.max.fill", tintColor: .orange, size: 22),
                    GroundFoliageItem(x: 25, y: -10, symbolName: "circle.grid.cross.fill", tintColor: .brown, size: 20),
                    GroundFoliageItem(x: -10, y: 20, symbolName: "flame.fill", tintColor: .red.opacity(0.8), size: 24),
                    GroundFoliageItem(x: 35, y: 25, symbolName: "leaf.fill", tintColor: .orange, size: 20)
                ],
                groundBaseColor: Color(red: 0.42, green: 0.30, blue: 0.18),
                groundAccentColor: Color(red: 0.58, green: 0.42, blue: 0.24),
                ambientAtmosphereColor: Color(red: 0.5, green: 0.35, blue: 0.15).opacity(0.25)
            )
            
        case .pantanal:
            return BiomeEnvironmentSet(
                trees: [
                    TreeBillboardItem(x: -65, y: -45, scale: 1.15, swayOffset: 0.2),
                    TreeBillboardItem(x: 50, y: -50, scale: 1.2, swayOffset: 0.4),
                    TreeBillboardItem(x: -55, y: 45, scale: 1.1, swayOffset: 0.1),
                    TreeBillboardItem(x: 60, y: 40, scale: 1.25, swayOffset: 0.5)
                ],
                foliage: [
                    GroundFoliageItem(x: -25, y: -30, symbolName: "water.waves", tintColor: .cyan, size: 30),
                    GroundFoliageItem(x: 20, y: -20, symbolName: "drop.fill", tintColor: .blue, size: 24),
                    GroundFoliageItem(x: -35, y: 15, symbolName: "fish.fill", tintColor: .teal, size: 22),
                    GroundFoliageItem(x: 10, y: 35, symbolName: "water.waves", tintColor: .blue.opacity(0.8), size: 32)
                ],
                groundBaseColor: Color(red: 0.18, green: 0.36, blue: 0.32),
                groundAccentColor: Color(red: 0.24, green: 0.46, blue: 0.42),
                ambientAtmosphereColor: Color(red: 0.1, green: 0.3, blue: 0.35).opacity(0.3)
            )
            
        case .caatinga:
            return BiomeEnvironmentSet(
                trees: [
                    TreeBillboardItem(x: -50, y: -50, scale: 0.85, swayOffset: 0.1),
                    TreeBillboardItem(x: 45, y: -40, scale: 0.9, swayOffset: 0.3),
                    TreeBillboardItem(x: -45, y: 45, scale: 0.85, swayOffset: 0.2),
                    TreeBillboardItem(x: 55, y: 30, scale: 0.95, swayOffset: 0.4)
                ],
                foliage: [
                    GroundFoliageItem(x: -30, y: -10, symbolName: "sun.dust.fill", tintColor: .yellow, size: 24),
                    GroundFoliageItem(x: 25, y: 10, symbolName: "triangle.fill", tintColor: .brown, size: 20),
                    GroundFoliageItem(x: -15, y: 25, symbolName: "sparkles", tintColor: .orange, size: 22)
                ],
                groundBaseColor: Color(red: 0.52, green: 0.44, blue: 0.28),
                groundAccentColor: Color(red: 0.65, green: 0.54, blue: 0.34),
                ambientAtmosphereColor: Color(red: 0.6, green: 0.5, blue: 0.25).opacity(0.2)
            )
            
        case .pampa:
            return BiomeEnvironmentSet(
                trees: [
                    TreeBillboardItem(x: -60, y: -50, scale: 1.05, swayOffset: 0.4),
                    TreeBillboardItem(x: 50, y: -40, scale: 1.1, swayOffset: 0.2),
                    TreeBillboardItem(x: 0, y: 60, scale: 1.0, swayOffset: 0.5)
                ],
                foliage: [
                    GroundFoliageItem(x: -35, y: -20, symbolName: "wind", tintColor: .mint, size: 26),
                    GroundFoliageItem(x: 30, y: -10, symbolName: "leaf.fill", tintColor: .green, size: 20),
                    GroundFoliageItem(x: -20, y: 25, symbolName: "wind", tintColor: .teal, size: 24),
                    GroundFoliageItem(x: 40, y: 35, symbolName: "circle.hexagongrid.fill", tintColor: .brown, size: 18)
                ],
                groundBaseColor: Color(red: 0.30, green: 0.42, blue: 0.22),
                groundAccentColor: Color(red: 0.40, green: 0.55, blue: 0.30),
                ambientAtmosphereColor: Color(red: 0.25, green: 0.45, blue: 0.3).opacity(0.25)
            )
        }
    }
}
