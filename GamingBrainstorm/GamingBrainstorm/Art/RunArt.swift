//
//  RunArt.swift
//  Guardiões dos Biomas
//
//  Cenário e obstáculos das provas arcade. Tudo gerado, como o resto do jogo.
//

import SpriteKit

enum RunArt {
    private static var cache: [String: SKTexture] = [:]

    private static func cached(_ k: String, _ w: Int, _ h: Int,
                               _ body: @escaping (CGContext) -> Void) -> SKTexture {
        if let t = cache[k] { return t }
        let t = Draw.texture(width: w, height: h, body)
        cache[k] = t
        return t
    }

    // MARK: Fundo rolante

    /// Faixa vertical que se repete: pista central com vegetação nas laterais.
    static func pista(_ id: BiomeID) -> SKTexture {
        let p = Biome[id].palette
        return cached("pista_\(id.rawValue)", 560, 560) { ctx in
            Draw.fill(ctx, CGRect(x: 0, y: 0, width: 560, height: 560), p.foliageDark)

            // Corredor central por onde se corre.
            let corredor = CGRect(x: 90, y: 0, width: 380, height: 560)
            Draw.fill(ctx, corredor, p.ground)
            var rng = SeededRandom(seed: Biome[id].semente &+ 700)
            for _ in 0..<70 {
                let x = rng.cg(92, 466)
                let y = rng.cg(0, 558)
                Draw.circle(ctx, CGPoint(x: x, y: y), rng.cg(2, 6),
                            p.groundAlt.withAlphaComponent(0.55))
            }
            // Marcas das três faixas
            for x in [CGFloat(216), 344] {
                for i in 0..<14 {
                    Draw.roundRect(ctx, CGRect(x: x - 2, y: CGFloat(i) * 40 + 8,
                                               width: 4, height: 22),
                                   radius: 2, SKColor(white: 1, alpha: 0.07))
                }
            }
            // Vegetação densa nas bordas
            for lado in [CGFloat(0), 470] {
                for _ in 0..<26 {
                    let x = lado + rng.cg(0, 90)
                    let y = rng.cg(0, 560)
                    Draw.circle(ctx, CGPoint(x: x, y: y), rng.cg(14, 30), p.foliage)
                    Draw.circle(ctx, CGPoint(x: x - 5, y: y - 5), rng.cg(6, 14),
                                p.foliage.lighter(0.12))
                }
            }
        }
    }

    /// Fundo do rio, para a travessia.
    static func rio(_ id: BiomeID) -> SKTexture {
        let p = Biome[id].palette
        return cached("rio_\(id.rawValue)", 560, 560) { ctx in
            Draw.fill(ctx, CGRect(x: 0, y: 0, width: 560, height: 560), p.waterDeep)
            var rng = SeededRandom(seed: 4242)
            for _ in 0..<40 {
                let y = rng.cg(0, 560)
                Draw.line(ctx, from: CGPoint(x: rng.cg(0, 200), y: y),
                          to: CGPoint(x: rng.cg(300, 560), y: y + rng.cg(-4, 4)),
                          width: rng.cg(1.5, 3.5), SKColor(white: 1, alpha: 0.07))
            }
        }
    }

    // MARK: Obstáculos

    /// Obstáculo baixo: dá para saltar por cima.
    static func baixo(_ id: BiomeID) -> SKTexture {
        let p = Biome[id].palette
        return cached("baixo_\(id.rawValue)", 120, 64) { ctx in
            switch id {
            case .cerrado:
                // Cupinzeiro
                Draw.polygon(ctx, [CGPoint(x: 24, y: 60), CGPoint(x: 96, y: 60),
                                   CGPoint(x: 76, y: 8), CGPoint(x: 44, y: 8)],
                             SKColor(hex: 0x8A6A42))
                Draw.polygon(ctx, [CGPoint(x: 36, y: 56), CGPoint(x: 84, y: 56),
                                   CGPoint(x: 70, y: 18), CGPoint(x: 50, y: 18)],
                             SKColor(hex: 0xA07E52))
            case .pampa:
                // Raiz atravessada
                Draw.roundRect(ctx, CGRect(x: 8, y: 26, width: 104, height: 16),
                               radius: 8, SKColor(hex: 0x6A5238))
                Draw.roundRect(ctx, CGRect(x: 20, y: 30, width: 80, height: 6),
                               radius: 3, SKColor(hex: 0x8A6E4A))
            default:
                // Tronco caído
                Draw.roundRect(ctx, CGRect(x: 4, y: 24, width: 112, height: 22),
                               radius: 11, SKColor(hex: 0x5A4028))
                Draw.roundRect(ctx, CGRect(x: 12, y: 29, width: 96, height: 8),
                               radius: 4, SKColor(hex: 0x7A5A38))
                Draw.circle(ctx, CGPoint(x: 14, y: 35), 9, SKColor(hex: 0x8A6A44))
                Draw.circle(ctx, CGPoint(x: 14, y: 35), 4, SKColor(hex: 0x5A4028))
            }
            _ = p
        }
    }

    /// Obstáculo alto: não adianta saltar, tem que desviar de faixa.
    static func alto(_ id: BiomeID) -> SKTexture {
        let p = Biome[id].palette
        return cached("alto_\(id.rawValue)", 120, 150) { ctx in
            switch id {
            case .pampa:
                // Bloco de terra desabada
                Draw.roundRect(ctx, CGRect(x: 10, y: 20, width: 100, height: 120),
                               radius: 10, SKColor(hex: 0x5A4832))
                for i in 0..<5 {
                    Draw.line(ctx, from: CGPoint(x: 18, y: 40 + CGFloat(i) * 20),
                              to: CGPoint(x: 102, y: 46 + CGFloat(i) * 20),
                              width: 2, SKColor(hex: 0x3A2E20), round: false)
                }
            default:
                // Árvore fechando a faixa
                Draw.roundRect(ctx, CGRect(x: 50, y: 70, width: 20, height: 78),
                               radius: 6, SKColor(hex: 0x4A3A28))
                Draw.circle(ctx, CGPoint(x: 42, y: 60), 34, p.foliageDark)
                Draw.circle(ctx, CGPoint(x: 78, y: 62), 32, p.foliageDark)
                Draw.circle(ctx, CGPoint(x: 60, y: 40), 40, p.foliage)
                Draw.circle(ctx, CGPoint(x: 46, y: 28), 18, p.foliage.lighter(0.14))
            }
        }
    }

    /// Coletável da prova.
    static func premio(_ id: BiomeID) -> SKTexture {
        let p = Biome[id].palette
        return cached("premio_\(id.rawValue)", 48, 48) { ctx in
            let c = CGPoint(x: 24, y: 24)
            Draw.circle(ctx, c, 20, p.accent.withAlphaComponent(0.16))
            Draw.circle(ctx, c, 13, p.accent.withAlphaComponent(0.30))
            Draw.circle(ctx, c, 9, p.accent)
            Draw.circle(ctx, CGPoint(x: c.x - 3, y: c.y - 3), 3, .white)
        }
    }

    /// Parede de fogo que persegue na fuga do Cerrado.
    static func paredeDeFogo() -> SKTexture {
        cached("parede_fogo", 600, 180) { ctx in
            var rng = SeededRandom(seed: 99)
            Draw.fill(ctx, CGRect(x: 0, y: 90, width: 600, height: 90),
                      SKColor(hex: 0x2A1408, alpha: 0.85))
            for _ in 0..<90 {
                let x = rng.cg(0, 600)
                let alt = rng.cg(40, 110)
                Draw.polygon(ctx, [CGPoint(x: x, y: 170 - alt),
                                   CGPoint(x: x + rng.cg(14, 30), y: 176),
                                   CGPoint(x: x - rng.cg(14, 30), y: 176)],
                             rng.chance(0.5) ? SKColor(hex: 0xE8541E) : SKColor(hex: 0xF29A2E))
            }
            for _ in 0..<40 {
                let x = rng.cg(0, 600)
                Draw.polygon(ctx, [CGPoint(x: x, y: 150 - rng.cg(20, 60)),
                                   CGPoint(x: x + 12, y: 176), CGPoint(x: x - 12, y: 176)],
                             SKColor(hex: 0xF6D24E))
            }
        }
    }

    /// Lâmina do arado que desce sobre a galeria.
    static func lamina() -> SKTexture {
        cached("lamina", 130, 90) { ctx in
            Draw.polygon(ctx, [CGPoint(x: 4, y: 6), CGPoint(x: 126, y: 6),
                               CGPoint(x: 100, y: 78), CGPoint(x: 30, y: 78)],
                         SKColor(hex: 0x9AA0A6))
            Draw.polygon(ctx, [CGPoint(x: 30, y: 70), CGPoint(x: 100, y: 70),
                               CGPoint(x: 92, y: 84), CGPoint(x: 38, y: 84)],
                         SKColor(hex: 0xD8DCE0))
            Draw.roundRect(ctx, CGRect(x: 54, y: 0, width: 22, height: 14),
                           radius: 4, SKColor(hex: 0x4A4E54))
        }
    }

    /// Tronco boiando, base da travessia.
    static func troncoFlutuante(_ largura: Int) -> SKTexture {
        cached("tronco_\(largura)", largura, 70) { ctx in
            let w = CGFloat(largura)
            Draw.ellipse(ctx, CGRect(x: 4, y: 40, width: w - 8, height: 24),
                         SKColor(hex: 0x1A2E30, alpha: 0.5))
            Draw.roundRect(ctx, CGRect(x: 0, y: 14, width: w, height: 36),
                           radius: 18, SKColor(hex: 0x5A4028))
            Draw.roundRect(ctx, CGRect(x: 12, y: 22, width: w - 24, height: 10),
                           radius: 5, SKColor(hex: 0x7A5A38))
            Draw.circle(ctx, CGPoint(x: 18, y: 32), 12, SKColor(hex: 0x8A6A44))
            Draw.circle(ctx, CGPoint(x: 18, y: 32), 5, SKColor(hex: 0x4A3520))
            for i in 0..<3 {
                Draw.circle(ctx, CGPoint(x: w - 40 + CGFloat(i) * 14, y: 20), 5,
                            SKColor(hex: 0x3E6A38))
            }
        }
    }

    /// Vinheta escura da galeria: fecha a visão nas bordas.
    static func vinheta() -> SKTexture {
        cached("vinheta", 512, 512) { ctx in
            let c = CGPoint(x: 256, y: 256)
            for i in stride(from: 256, through: 110, by: -3) {
                let t = (CGFloat(i) - 110) / (256 - 110)
                Draw.circle(ctx, c, CGFloat(i), SKColor(white: 0.02, alpha: 0.06 * t))
            }
        }
    }
}
