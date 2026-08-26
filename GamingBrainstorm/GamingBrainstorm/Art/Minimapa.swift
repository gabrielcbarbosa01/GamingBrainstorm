//
//  Minimapa.swift
//  Guardiões dos Biomas
//
//  O recorte do terreno em volta do jogador. Desenhado uma vez num CGImage —
//  a versão anterior pintava milhares de retângulos num Canvas do SwiftUI a
//  cada redesenho, e era isso que travava a tela do mapa.
//

import SpriteKit
import AppKit

enum Minimapa {

    /// Lado do recorte, em tiles.
    static let lado = 81
    /// Pixels por tile na imagem gerada.
    private static let escala = 5

    private static var cache: [String: NSImage] = [:]

    static func imagem(bioma: BiomeID, centro: GridPoint, nivel: Int) -> NSImage {
        let chave = "\(bioma.rawValue)_\(centro.x)_\(centro.y)_\(nivel)"
        if let i = cache[chave] { return i }

        let gen = WorldGenerator(biome: Biome[bioma], dificuldade: nivel)
        let p = Biome[bioma].palette
        let px = lado * escala
        let meio = lado / 2

        guard let cg = Draw.cgImage(width: px, height: px, { ctx in
            for j in 0..<lado {
                for i in 0..<lado {
                    // O eixo Y do mundo cresce para cima; o da imagem, para baixo.
                    let t = GridPoint(x: centro.x + i - meio, y: centro.y + meio - j)
                    let cor = cor(de: gen.terrain(at: t), palette: p)
                    Draw.fill(ctx, CGRect(x: CGFloat(i * escala), y: CGFloat(j * escala),
                                          width: CGFloat(escala), height: CGFloat(escala)), cor)
                }
            }

            // Rosa dos ventos discreta no canto.
            let m = CGFloat(px) - 22
            Draw.polygon(ctx, [CGPoint(x: m, y: 10), CGPoint(x: m - 6, y: 24),
                               CGPoint(x: m + 6, y: 24)], Palette.parchment.withAlphaComponent(0.8))
        }) else { return NSImage(size: .zero) }

        let img = NSImage(cgImage: cg, size: NSSize(width: px, height: px))
        // O mundo é infinito: guardar tudo vazaria memória.
        if cache.count > 24 { cache.removeAll() }
        cache[chave] = img
        return img
    }

    static func cor(de t: Terrain, palette p: BiomePalette) -> SKColor {
        switch t {
        case .agua: return p.water
        case .charco: return p.water.blended(with: p.ground, amount: 0.5)
        case .abismo: return SKColor(hex: 0x0A0C0E)
        case .rocha: return p.rock
        case .tronco: return p.foliageDark
        case .cipos: return p.foliage.lighter(0.10)
        case .espinheiro: return p.accent.darker(0.35)
        case .terraDura: return p.ground.darker(0.30)
        case .areia: return p.sand
        case .pedraChao: return p.rock.lighter(0.15)
        case .trilha: return p.ground.lighter(0.22)
        case .folhagem: return p.ground.blended(with: p.foliageDark, amount: 0.4)
        case .terra: return p.ground
        case .gramaAlta: return p.grass.darker(0.12)
        case .grama: return p.grass
        }
    }
}
