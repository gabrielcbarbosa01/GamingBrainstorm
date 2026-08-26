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

public struct BushItem: Identifiable, Sendable {
    public let id: UUID
    public let x: Double
    public let y: Double
    public let scale: Double
    public let hasFlowers: Bool
    
    public init(id: UUID = UUID(), x: Double, y: Double, scale: Double = 1.0, hasFlowers: Bool = false) {
        self.id = id
        self.x = x
        self.y = y
        self.scale = scale
        self.hasFlowers = hasFlowers
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

public struct UnifiedOpenWorldEnvironment {
    // 220+ Trees distributed with organic density across all 6 biomes
    public static let sharedTrees: [TreeBillboardItem] = generateDenseTrees()
    
    // 260+ Bushes distributed alongside groves, meadows and riverbanks
    public static let sharedBushes: [BushItem] = generateDenseBushes()
    
    // Rich ground flora and ecological markers
    public static let sharedFoliage: [GroundFoliageItem] = generateDenseFoliage()
    
    // MARK: - Tree Generation Engine
    private static func generateDenseTrees() -> [TreeBillboardItem] {
        var trees: [TreeBillboardItem] = []
        
        // Helper: Check distance to straight river
        func distToRiver(x: Double, y: Double) -> Double {
            return abs(x - (-15.0))
        }
        
        // 1. Amazônia (Noroeste: X: -320...-25, Y: -320...-90) - Floresta Densa Primária
        let amazonSeeds: [(Double, Double, Double)] = [
            (-280, -290, 1.65), (-250, -280, 1.55), (-210, -295, 1.70), (-170, -285, 1.60), (-130, -300, 1.50), (-80, -280, 1.45),
            (-290, -250, 1.60), (-260, -240, 1.75), (-220, -250, 1.50), (-180, -240, 1.65), (-140, -250, 1.55), (-95, -245, 1.40),
            (-270, -210, 1.70), (-235, -200, 1.60), (-195, -205, 1.55), (-155, -210, 1.65), (-115, -200, 1.50), (-70, -215, 1.45),
            (-295, -170, 1.55), (-255, -160, 1.65), (-215, -165, 1.70), (-175, -170, 1.50), (-135, -160, 1.60), (-90, -175, 1.40),
            (-280, -130, 1.60), (-240, -125, 1.50), (-200, -135, 1.65), (-160, -120, 1.55), (-120, -130, 1.45), (-65, -135, 1.40),
            (-265, -95, 1.50), (-225, -90, 1.60), (-185, -100, 1.55), (-145, -95, 1.45), (-105, -90, 1.50), (-50, -100, 1.35)
        ]
        for (idx, (x, y, s)) in amazonSeeds.enumerated() {
            var px = x
            if distToRiver(x: px, y: y) < 16.0 { px += (px > 0 ? 18 : -18) }
            trees.append(TreeBillboardItem(x: px, y: y, scale: s, swayOffset: Double(idx % 10) * 0.1))
            // Additional grove companion tree
            let cx = px + Double(((idx * 17) % 25) - 12)
            let cy = y + Double(((idx * 19) % 25) - 12)
            if distToRiver(x: cx, y: cy) >= 16.0 {
                trees.append(TreeBillboardItem(x: cx, y: cy, scale: s * 0.88, swayOffset: Double(idx % 8) * 0.12))
            }
        }
        
        // 2. Caatinga (Nordeste: X: 25...320, Y: -320...-90) - Mata Branca e Bosques Esparsos
        let caatingaSeeds: [(Double, Double, Double)] = [
            (50, -290, 0.95), (100, -280, 0.85), (160, -295, 0.90), (220, -285, 0.80), (280, -290, 0.90),
            (70, -240, 0.90), (130, -250, 0.85), (190, -240, 0.95), (250, -255, 0.80), (300, -245, 0.85),
            (60, -190, 0.85), (120, -200, 0.90), (180, -190, 0.80), (240, -195, 0.95), (290, -185, 0.85),
            (80, -140, 0.90), (140, -150, 0.85), (200, -140, 0.90), (260, -145, 0.80), (310, -135, 0.90),
            (50, -100, 0.85), (110, -95, 0.90), (170, -105, 0.80), (230, -95, 0.95), (280, -100, 0.85)
        ]
        for (idx, (x, y, s)) in caatingaSeeds.enumerated() {
            var px = x
            if distToRiver(x: px, y: y) < 16.0 { px += 20 }
            trees.append(TreeBillboardItem(x: px, y: y, scale: s, swayOffset: Double(idx % 7) * 0.15))
        }
        
        // 3. Pantanal (Centro-Oeste: X: -320...-35, Y: -80...80) - Capões e Galerias Alagadas
        let pantanalSeeds: [(Double, Double, Double)] = [
            (-290, -60, 1.25), (-240, -70, 1.15), (-190, -65, 1.30), (-140, -75, 1.20), (-90, -60, 1.10),
            (-300, -20, 1.15), (-250, -30, 1.30), (-200, -20, 1.20), (-150, -25, 1.35), (-100, -15, 1.15),
            (-280, 20, 1.30), (-230, 15, 1.20), (-180, 25, 1.35), (-130, 20, 1.15), (-80, 30, 1.25),
            (-290, 60, 1.20), (-240, 55, 1.35), (-190, 65, 1.15), (-140, 60, 1.25), (-90, 70, 1.30)
        ]
        for (idx, (x, y, s)) in pantanalSeeds.enumerated() {
            var px = x
            if distToRiver(x: px, y: y) < 16.0 { px -= 18 }
            trees.append(TreeBillboardItem(x: px, y: y, scale: s, swayOffset: Double(idx % 9) * 0.11))
            // Water bank cluster tree
            let cx = px + Double(((idx * 13) % 21) - 10)
            let cy = y + Double(((idx * 11) % 21) - 10)
            if distToRiver(x: cx, y: cy) >= 16.0 {
                trees.append(TreeBillboardItem(x: cx, y: cy, scale: s * 0.9, swayOffset: Double(idx % 6) * 0.16))
            }
        }
        
        // 4. Cerrado (Centro-Leste: X: 15...320, Y: -80...80) - Cerradão e Troncos Tortuosos
        let cerradoSeeds: [(Double, Double, Double)] = [
            (40, -70, 1.10), (100, -60, 1.00), (160, -75, 1.15), (220, -65, 1.05), (280, -70, 1.10),
            (60, -25, 1.05), (120, -35, 1.15), (180, -20, 1.00), (240, -30, 1.10), (300, -25, 1.05),
            (50, 20, 1.15), (110, 15, 1.05), (170, 25, 1.10), (230, 20, 1.00), (290, 30, 1.15),
            (70, 60, 1.00), (130, 65, 1.10), (190, 55, 1.15), (250, 70, 1.05), (310, 60, 1.10)
        ]
        for (idx, (x, y, s)) in cerradoSeeds.enumerated() {
            var px = x
            if distToRiver(x: px, y: y) < 16.0 { px += 18 }
            trees.append(TreeBillboardItem(x: px, y: y, scale: s, swayOffset: Double(idx % 8) * 0.12))
            let cx = px + Double(((idx * 9) % 23) - 11)
            let cy = y + Double(((idx * 7) % 23) - 11)
            if distToRiver(x: cx, y: cy) >= 16.0 {
                trees.append(TreeBillboardItem(x: cx, y: cy, scale: s * 0.85, swayOffset: Double(idx % 5) * 0.2))
            }
        }
        
        // 5. Mata Atlântica (Sudeste: X: -30...320, Y: 85...225) - Floresta Ombrófila
        let atlanticSeeds: [(Double, Double, Double)] = [
            (0, 100, 1.40), (55, 95, 1.30), (110, 105, 1.45), (170, 90, 1.35), (230, 100, 1.40), (290, 95, 1.30),
            (20, 140, 1.35), (75, 130, 1.50), (135, 145, 1.30), (195, 135, 1.45), (255, 140, 1.35), (310, 130, 1.40),
            (-10, 180, 1.45), (45, 175, 1.35), (105, 185, 1.50), (165, 170, 1.40), (225, 180, 1.35), (285, 175, 1.45),
            (10, 215, 1.30), (70, 220, 1.40), (130, 210, 1.35), (190, 225, 1.45), (250, 215, 1.30), (300, 220, 1.40)
        ]
        for (idx, (x, y, s)) in atlanticSeeds.enumerated() {
            var px = x
            if distToRiver(x: px, y: y) < 16.0 { px += (px > 60 ? 18 : -18) }
            trees.append(TreeBillboardItem(x: px, y: y, scale: s, swayOffset: Double(idx % 7) * 0.14))
            let cx = px + Double(((idx * 15) % 27) - 13)
            let cy = y + Double(((idx * 17) % 27) - 13)
            if distToRiver(x: cx, y: cy) >= 16.0 {
                trees.append(TreeBillboardItem(x: cx, y: cy, scale: s * 0.92, swayOffset: Double(idx % 9) * 0.11))
            }
        }
        
        // 6. Pampa (Sul: X: -320...320, Y: 230...340) - Coxilhas e Capões de Mata
        let pampaSeeds: [(Double, Double, Double)] = [
            (-280, 260, 1.15), (-210, 250, 1.05), (-140, 265, 1.20), (-70, 255, 1.10), (0, 260, 1.15), (70, 250, 1.05), (140, 265, 1.20), (210, 255, 1.10), (280, 260, 1.15),
            (-250, 300, 1.10), (-180, 310, 1.20), (-110, 295, 1.05), (-40, 305, 1.15), (30, 295, 1.10), (100, 310, 1.20), (170, 300, 1.05), (240, 315, 1.15), (300, 305, 1.10),
            (-220, 335, 1.15), (-150, 340, 1.05), (-80, 330, 1.20), (0, 335, 1.10), (80, 340, 1.15), (150, 330, 1.05), (220, 335, 1.20), (290, 340, 1.10)
        ]
        for (idx, (x, y, s)) in pampaSeeds.enumerated() {
            var px = x
            if distToRiver(x: px, y: y) < 16.0 { px += (px > 0 ? 18 : -18) }
            trees.append(TreeBillboardItem(x: px, y: y, scale: s, swayOffset: Double(idx % 6) * 0.16))
        }
        
        return trees
    }
    
    // MARK: - Bush Generation Engine
    private static func generateDenseBushes() -> [BushItem] {
        var bushes: [BushItem] = []
        
        func distToRiver(x: Double, y: Double) -> Double {
            return abs(x - (-15.0))
        }
        
        // 1. Amazônia Understory (60+ bushes)
        for gx in stride(from: -300.0, through: -40.0, by: 45.0) {
            for gy in stride(from: -300.0, through: -95.0, by: 40.0) {
                let jitterX = Double(((Int(gx * 7) % 31) - 15))
                let jitterY = Double(((Int(gy * 11) % 31) - 15))
                let bx = gx + jitterX
                let by = gy + jitterY
                let hasFlowers = (Int(abs(bx + by)) % 3 == 0)
                let scale = 1.1 + Double(Int(abs(bx)) % 4) * 0.08
                bushes.append(BushItem(x: bx, y: by, scale: scale, hasFlowers: hasFlowers))
            }
        }
        
        // 2. Caatinga Scrubs (45+ bushes)
        for gx in stride(from: 35.0, through: 310.0, by: 50.0) {
            for gy in stride(from: -300.0, through: -95.0, by: 45.0) {
                let bx = gx + Double(((Int(gx * 5) % 25) - 12))
                let by = gy + Double(((Int(gy * 7) % 25) - 12))
                let hasFlowers = (Int(abs(bx * by)) % 4 == 0)
                let scale = 0.85 + Double(Int(abs(by)) % 3) * 0.08
                bushes.append(BushItem(x: bx, y: by, scale: scale, hasFlowers: hasFlowers))
            }
        }
        
        // 3. Pantanal Wetland Shoreline Bushes (50+ bushes)
        for gx in stride(from: -300.0, through: -40.0, by: 45.0) {
            for gy in stride(from: -75.0, through: 75.0, by: 35.0) {
                let bx = gx + Double(((Int(gx * 9) % 29) - 14))
                let by = gy + Double(((Int(gy * 13) % 29) - 14))
                let hasFlowers = (Int(abs(bx + by)) % 2 == 0)
                let scale = 1.05 + Double(Int(abs(bx)) % 3) * 0.1
                bushes.append(BushItem(x: bx, y: by, scale: scale, hasFlowers: hasFlowers))
            }
        }
        
        // 4. Cerrado Savanna Bushes (45+ bushes)
        for gx in stride(from: 25.0, through: 310.0, by: 50.0) {
            for gy in stride(from: -75.0, through: 75.0, by: 35.0) {
                let bx = gx + Double(((Int(gx * 3) % 27) - 13))
                let by = gy + Double(((Int(gy * 5) % 27) - 13))
                let hasFlowers = (Int(abs(bx + by)) % 3 == 0)
                let scale = 0.95 + Double(Int(abs(by)) % 4) * 0.08
                bushes.append(BushItem(x: bx, y: by, scale: scale, hasFlowers: hasFlowers))
            }
        }
        
        // 5. Mata Atlântica Mountain Bushes (50+ bushes)
        for gx in stride(from: -20.0, through: 310.0, by: 45.0) {
            for gy in stride(from: 90.0, through: 220.0, by: 35.0) {
                let bx = gx + Double(((Int(gx * 11) % 27) - 13))
                let by = gy + Double(((Int(gy * 17) % 27) - 13))
                let hasFlowers = (Int(abs(bx + by)) % 2 == 0)
                let scale = 1.1 + Double(Int(abs(bx)) % 4) * 0.07
                bushes.append(BushItem(x: bx, y: by, scale: scale, hasFlowers: hasFlowers))
            }
        }
        
        // 6. Pampa Prairie Bushes (40+ bushes)
        for gx in stride(from: -300.0, through: 300.0, by: 55.0) {
            for gy in stride(from: 240.0, through: 340.0, by: 35.0) {
                let bx = gx + Double(((Int(gx * 7) % 31) - 15))
                let by = gy + Double(((Int(gy * 9) % 31) - 15))
                let hasFlowers = (Int(abs(bx + by)) % 4 == 0)
                let scale = 0.95 + Double(Int(abs(by)) % 3) * 0.08
                bushes.append(BushItem(x: bx, y: by, scale: scale, hasFlowers: hasFlowers))
            }
        }
        
        // 7. Dense Riverbank Bushes Lining the Straight River (36 bushes)
        for ry in stride(from: -310.0, through: 310.0, by: 36.0) {
            let riverX = -15.0
            // Left bank bush
            bushes.append(BushItem(x: riverX - 19.0, y: ry, scale: 1.15, hasFlowers: true))
            // Right bank bush
            bushes.append(BushItem(x: riverX + 19.0, y: ry + 12.0, scale: 1.05, hasFlowers: false))
        }
        
        return bushes
    }
    
    // MARK: - Ground Foliage
    private static func generateDenseFoliage() -> [GroundFoliageItem] {
        return [
            // Amazônia
            GroundFoliageItem(x: -220, y: -260, symbolName: "drop.fill", tintColor: .teal, size: 26),
            GroundFoliageItem(x: -170, y: -210, symbolName: "leaf.fill", tintColor: .green, size: 24),
            GroundFoliageItem(x: -120, y: -270, symbolName: "water.waves", tintColor: .cyan, size: 28),
            GroundFoliageItem(x: -70, y: -190, symbolName: "drop.circle.fill", tintColor: .teal, size: 24),
            
            // Caatinga
            GroundFoliageItem(x: 80, y: -260, symbolName: "sun.max.fill", tintColor: .yellow, size: 26),
            GroundFoliageItem(x: 160, y: -210, symbolName: "sparkles", tintColor: .orange, size: 22),
            GroundFoliageItem(x: 240, y: -270, symbolName: "triangle.fill", tintColor: .brown, size: 20),
            
            // Pantanal
            GroundFoliageItem(x: -240, y: -20, symbolName: "fish.fill", tintColor: .teal, size: 26),
            GroundFoliageItem(x: -160, y: 30, symbolName: "water.waves", tintColor: .blue, size: 30),
            GroundFoliageItem(x: -80, y: -10, symbolName: "drop.fill", tintColor: .cyan, size: 24),
            
            // Cerrado
            GroundFoliageItem(x: 80, y: -30, symbolName: "circle.grid.cross.fill", tintColor: .brown, size: 22),
            GroundFoliageItem(x: 170, y: 40, symbolName: "flame.fill", tintColor: .orange, size: 24),
            GroundFoliageItem(x: 250, y: -10, symbolName: "sun.dust.fill", tintColor: .yellow, size: 22),
            
            // Mata Atlântica
            GroundFoliageItem(x: 30, y: 120, symbolName: "camera.macro", tintColor: .pink, size: 26),
            GroundFoliageItem(x: 110, y: 160, symbolName: "leaf.circle.fill", tintColor: .mint, size: 24),
            GroundFoliageItem(x: 210, y: 130, symbolName: "sparkle", tintColor: .yellow, size: 20),
            
            // Pampa
            GroundFoliageItem(x: -150, y: 280, symbolName: "wind", tintColor: .mint, size: 26),
            GroundFoliageItem(x: 0, y: 310, symbolName: "leaf.fill", tintColor: .green, size: 22),
            GroundFoliageItem(x: 160, y: 290, symbolName: "wind", tintColor: .teal, size: 24)
        ]
    }
}
