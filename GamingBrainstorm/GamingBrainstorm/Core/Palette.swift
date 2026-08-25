//
//  Palette.swift
//  Guardiões dos Biomas
//
//  Toda a arte do jogo é gerada em tempo de execução com CoreGraphics.
//  Este arquivo concentra as cores para que cada bioma tenha identidade visual
//  própria sem depender de nenhum asset externo.
//

import SpriteKit

/// Conveniência para escrever cores em hexadecimal ao longo do projeto.
extension SKColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        self.init(srgbRed: r, green: g, blue: b, alpha: alpha)
    }

    /// Mistura linear entre duas cores. Usado para variar tons de terreno.
    func blended(with other: SKColor, amount: CGFloat) -> SKColor {
        let a = self.usingColorSpace(.sRGB) ?? self
        let b = other.usingColorSpace(.sRGB) ?? other
        let t = max(0, min(1, amount))
        return SKColor(srgbRed: a.redComponent + (b.redComponent - a.redComponent) * t,
                       green: a.greenComponent + (b.greenComponent - a.greenComponent) * t,
                       blue: a.blueComponent + (b.blueComponent - a.blueComponent) * t,
                       alpha: a.alphaComponent + (b.alphaComponent - a.alphaComponent) * t)
    }

    func lighter(_ amount: CGFloat) -> SKColor { blended(with: .white, amount: amount) }
    func darker(_ amount: CGFloat) -> SKColor { blended(with: .black, amount: amount) }
}

/// Paleta de um bioma: as cores usadas para pintar o chão e a vegetação.
struct BiomePalette {
    let ground: SKColor      // tom base do solo
    let groundAlt: SKColor   // variação do solo (manchas, relevo)
    let grass: SKColor       // vegetação rasteira
    let grassAlt: SKColor
    let foliage: SKColor     // copa de árvores / arbustos
    let foliageDark: SKColor
    let water: SKColor
    let waterDeep: SKColor
    let rock: SKColor
    let sand: SKColor
    let accent: SKColor      // cor de destaque (UI, partículas, flores)
    let sky: SKColor         // cor de fundo da cena
}

enum Palette {
    // Interface
    static let ink = SKColor(hex: 0x11170F)
    static let parchment = SKColor(hex: 0xF3E7C9)
    static let gold = SKColor(hex: 0xE8B23A)
    static let danger = SKColor(hex: 0xC8442E)
    static let essence = SKColor(hex: 0x6FE3D0)

    static let mataAtlantica = BiomePalette(
        ground: SKColor(hex: 0x3D4A2A), groundAlt: SKColor(hex: 0x4A5A32),
        grass: SKColor(hex: 0x4E7A34), grassAlt: SKColor(hex: 0x5E8C3C),
        foliage: SKColor(hex: 0x2E5A2B), foliageDark: SKColor(hex: 0x1E3E1E),
        water: SKColor(hex: 0x3B7A8C), waterDeep: SKColor(hex: 0x25505E),
        rock: SKColor(hex: 0x5C5A52), sand: SKColor(hex: 0xB8A878),
        accent: SKColor(hex: 0xE8A33A), sky: SKColor(hex: 0x16210F))

    static let cerrado = BiomePalette(
        ground: SKColor(hex: 0x7A5A34), groundAlt: SKColor(hex: 0x8E6A3E),
        grass: SKColor(hex: 0xA89A44), grassAlt: SKColor(hex: 0xBFAE58),
        foliage: SKColor(hex: 0x6E7A38), foliageDark: SKColor(hex: 0x4E5828),
        water: SKColor(hex: 0x4E7E86), waterDeep: SKColor(hex: 0x2F5A60),
        rock: SKColor(hex: 0x8A6E56), sand: SKColor(hex: 0xC9AE74),
        accent: SKColor(hex: 0xE86A2E), sky: SKColor(hex: 0x2A1C10))

    static let pantanal = BiomePalette(
        ground: SKColor(hex: 0x4E6438), groundAlt: SKColor(hex: 0x5C7440),
        grass: SKColor(hex: 0x6E9448), grassAlt: SKColor(hex: 0x82A650),
        foliage: SKColor(hex: 0x3E6A38), foliageDark: SKColor(hex: 0x27482A),
        water: SKColor(hex: 0x3E8496), waterDeep: SKColor(hex: 0x255C6E),
        rock: SKColor(hex: 0x6E6A5A), sand: SKColor(hex: 0xC2AC7C),
        accent: SKColor(hex: 0x3A7ADE), sky: SKColor(hex: 0x12241F))

    static let amazonia = BiomePalette(
        ground: SKColor(hex: 0x33421F), groundAlt: SKColor(hex: 0x3E5026),
        grass: SKColor(hex: 0x3E7030), grassAlt: SKColor(hex: 0x4C8437),
        foliage: SKColor(hex: 0x214E24), foliageDark: SKColor(hex: 0x123419),
        water: SKColor(hex: 0x2E5E62), waterDeep: SKColor(hex: 0x1A3C42),
        rock: SKColor(hex: 0x4E4E48), sand: SKColor(hex: 0xA89468),
        accent: SKColor(hex: 0x5AD0A8), sky: SKColor(hex: 0x0D1A0F))

    static let pampa = BiomePalette(
        ground: SKColor(hex: 0x6E7A48), groundAlt: SKColor(hex: 0x7E8A54),
        grass: SKColor(hex: 0x8FA05A), grassAlt: SKColor(hex: 0xA2B268),
        foliage: SKColor(hex: 0x6A7C42), foliageDark: SKColor(hex: 0x4C5C30),
        water: SKColor(hex: 0x4A7E92), waterDeep: SKColor(hex: 0x2E5A6C),
        rock: SKColor(hex: 0x7A7466), sand: SKColor(hex: 0xC6B584),
        accent: SKColor(hex: 0xD8CE6A), sky: SKColor(hex: 0x1E2416))

    static let refugio = BiomePalette(
        ground: SKColor(hex: 0x5A5442), groundAlt: SKColor(hex: 0x6A6450),
        grass: SKColor(hex: 0x5E8046), grassAlt: SKColor(hex: 0x6E9052),
        foliage: SKColor(hex: 0x38602F), foliageDark: SKColor(hex: 0x24421F),
        water: SKColor(hex: 0x3E7E8E), waterDeep: SKColor(hex: 0x275A66),
        rock: SKColor(hex: 0x6E6A60), sand: SKColor(hex: 0xC0AE80),
        accent: SKColor(hex: 0xE8B23A), sky: SKColor(hex: 0x191E14))
}
