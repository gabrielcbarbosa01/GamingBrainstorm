//
//  TerrainRenderer.swift
//  Guardiões dos Biomas
//
//  Cada chunk vira uma única textura: 16x16 tiles pintados em duas passadas
//  (chão e depois vegetação/obstáculos, que podem transbordar o tile).
//  Um sprite por chunk em vez de 256 — é o que mantém o mundo infinito fluido.
//

import SpriteKit

enum TerrainRenderer {

    static func chunkTexture(chunk: ChunkData, generator: WorldGenerator) -> SKTexture {
        let lado = Int(WorldMetrics.tileSize) * WorldMetrics.chunkTiles
        return Draw.texture(width: lado, height: lado) { ctx in
            desenharChunk(ctx, chunk: chunk, generator: generator)
        }
    }

    /// Pintura de um chunk. Separada para poder ser reaproveitada fora da cena
    /// (pré-visualização de arte, testes de geração).
    static func desenharChunk(_ ctx: CGContext, chunk: ChunkData, generator: WorldGenerator) {
        let n = WorldMetrics.chunkTiles
        let tile = WorldMetrics.tileSize
        let side = Int(tile) * n
        let p = generator.biome.palette
        let seed = generator.biome.semente
        do {
            // Fundo: evita costura visível entre chunks.
            Draw.fill(ctx, CGRect(x: 0, y: 0, width: CGFloat(side), height: CGFloat(side)), p.ground)

            /// Converte tile local em retângulo do canvas (CG cresce para baixo).
            func rect(_ lx: Int, _ ly: Int) -> CGRect {
                CGRect(x: CGFloat(lx) * tile, y: CGFloat(n - 1 - ly) * tile, width: tile, height: tile)
            }

            func worldTile(_ lx: Int, _ ly: Int) -> GridPoint {
                GridPoint(x: chunk.coord.x * n + lx, y: chunk.coord.y * n + ly)
            }

            // ---- Passada 1: chão ----
            for ly in 0..<n {
                for lx in 0..<n {
                    let w = worldTile(lx, ly)
                    let t = chunk.terrain(localX: lx, localY: ly)
                    drawGround(ctx, rect: rect(lx, ly), terrain: t, world: w,
                               palette: p, seed: seed, generator: generator)
                }
            }

            // ---- Passada 2: props (com margem de 1 tile vinda dos vizinhos) ----
            for ly in -1...n {
                for lx in -1...n {
                    let w = worldTile(lx, ly)
                    let t: Terrain
                    if lx >= 0, lx < n, ly >= 0, ly < n {
                        t = chunk.terrain(localX: lx, localY: ly)
                    } else {
                        t = generator.terrain(at: w)
                    }
                    drawProp(ctx, rect: rect(lx, ly), terrain: t, world: w, palette: p, seed: seed)
                }
            }
        }
    }

    // MARK: - Chão

    /// Cor plana de um tile. Isolada para que os vizinhos possam consultá-la
    /// na hora de dissolver a borda entre dois terrenos.
    /// Ruído suave de tonalidade. Usar hash por tile aqui produzia xadrez:
    /// tons vizinhos precisam ser parecidos, e só um campo contínuo dá isso.
    private static let tom = ValueNoise(seed: 90210)
    private static let tomLento = ValueNoise(seed: 60125)

    private static func variacao(_ w: GridPoint, escala: Double = 0.17) -> CGFloat {
        CGFloat((tom.sample(Double(w.x) * escala, Double(w.y) * escala) + 1) * 0.5)
    }

    private static func corDeChao(_ t: Terrain, world w: GridPoint,
                                  palette p: BiomePalette, seed: UInt64) -> SKColor {
        let v = variacao(w)
        switch t {
        case .agua:
            let deep = CGFloat((tomLento.sample(Double(w.x) * 0.07, Double(w.y) * 0.07) + 1) * 0.5)
            return p.waterDeep.blended(with: p.water, amount: deep)
        case .charco:
            return p.ground.blended(with: p.water, amount: 0.40 + v * 0.14)
        case .abismo:
            return SKColor(hex: 0x0A0C0E)
        case .areia:
            return p.sand.blended(with: p.ground, amount: v * 0.24)
        case .pedraChao:
            return p.rock.blended(with: p.ground, amount: 0.35 + v * 0.18)
        case .trilha:
            return p.ground.lighter(0.16).blended(with: p.sand, amount: 0.30)
        case .folhagem:
            return p.ground.blended(with: p.foliageDark, amount: 0.28 + v * 0.16)
        case .terra:
            return p.ground.blended(with: p.groundAlt, amount: v)
        case .gramaAlta, .grama:
            return p.grass.blended(with: p.grassAlt, amount: v)
        case .rocha:
            return p.ground.blended(with: p.rock, amount: 0.3)
        case .tronco:
            return p.grass.blended(with: p.foliageDark, amount: 0.22 + v * 0.16)
        case .cipos:
            return p.grass.blended(with: p.foliageDark, amount: 0.45)
        case .espinheiro:
            return p.ground.blended(with: p.sand, amount: 0.22 + v * 0.14)
        case .terraDura:
            return p.ground.darker(0.20).blended(with: p.sand, amount: 0.18)
        }
    }

    private static func drawGround(_ ctx: CGContext, rect: CGRect, terrain t: Terrain,
                                   world w: GridPoint, palette p: BiomePalette,
                                   seed: UInt64, generator: WorldGenerator) {
        let base = corDeChao(t, world: w, palette: p, seed: seed)
        Draw.fill(ctx, rect, base)

        var rng = Hashing.rng(w.x, w.y, seed &+ 63)

        // Detalhe específico do terreno.
        switch t {
        case .agua:
            let c = SKColor(white: 1, alpha: 0.10)
            for _ in 0..<2 {
                let y = rect.minY + rng.cg(6, rect.height - 6)
                Draw.line(ctx, from: CGPoint(x: rect.minX + rng.cg(2, 8), y: y),
                          to: CGPoint(x: rect.maxX - rng.cg(2, 8), y: y + rng.cg(-3, 3)),
                          width: rng.cg(1.4, 2.6), c)
            }

        case .charco:
            // Poças irregulares: sem isto o brejo vira um tabuleiro de xadrez.
            for _ in 0..<rng.int(1, 3) {
                let larg = rng.cg(12, 26)
                let alt = larg * rng.cg(0.45, 0.8)
                let x = rect.minX + rng.cg(0, rect.width - larg)
                let y = rect.minY + rng.cg(0, rect.height - alt)
                Draw.ellipse(ctx, CGRect(x: x, y: y, width: larg, height: alt),
                             p.water.darker(0.12).withAlphaComponent(rng.cg(0.35, 0.6)))
            }
            // Juncos na beira do brejo.
            if rng.chance(0.5) {
                for _ in 0..<3 {
                    let x = rect.minX + rng.cg(4, rect.width - 4)
                    let y = rect.minY + rng.cg(10, rect.height - 4)
                    Draw.line(ctx, from: CGPoint(x: x, y: y),
                              to: CGPoint(x: x + rng.cg(-3, 3), y: y - rng.cg(8, 15)),
                              width: 1.8, p.grass.darker(0.18))
                }
            }

        case .abismo:
            Draw.ellipse(ctx, rect.insetBy(dx: rect.width * 0.24, dy: rect.height * 0.24),
                         SKColor(hex: 0x000000, alpha: 0.85))

        case .areia:
            for _ in 0..<rng.int(0, 2) {
                Draw.circle(ctx, CGPoint(x: rect.minX + rng.cg(4, rect.width - 4),
                                         y: rect.minY + rng.cg(4, rect.height - 4)),
                            rng.cg(1.4, 2.6), p.sand.darker(0.14))
            }

        case .pedraChao:
            Draw.line(ctx, from: CGPoint(x: rect.minX, y: rect.minY + rng.cg(6, rect.height - 6)),
                      to: CGPoint(x: rect.maxX, y: rect.minY + rng.cg(6, rect.height - 6)),
                      width: 1.2, SKColor(white: 0, alpha: 0.12), round: false)

        case .trilha:
            for _ in 0..<rng.int(0, 3) {
                Draw.circle(ctx, CGPoint(x: rect.minX + rng.cg(3, rect.width - 3),
                                         y: rect.minY + rng.cg(3, rect.height - 3)),
                            rng.cg(1.6, 2.8), p.ground.darker(0.14))
            }

        case .folhagem:
            for _ in 0..<3 {
                let cx = rect.minX + rng.cg(5, rect.width - 5)
                let cy = rect.minY + rng.cg(5, rect.height - 5)
                Draw.leaf(ctx, from: CGPoint(x: cx - 5, y: cy),
                          to: CGPoint(x: cx + rng.cg(3, 6), y: cy + rng.cg(-3, 3)),
                          bulge: 3, p.foliage.darker(0.08).withAlphaComponent(0.5))
            }

        default:
            break
        }

        // Dissolve a borda com os vizinhos: alguns respingos da cor do vizinho
        // dentro deste tile. É o que tira o aspecto de tabuleiro.
        let vizinhos: [(Int, Int)] = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        for (dx, dy) in vizinhos {
            let nw = GridPoint(x: w.x + dx, y: w.y + dy)
            let nt = generator.terrain(at: nw)
            guard nt != t else { continue }
            let ncor = corDeChao(nt, world: nw, palette: p, seed: seed)
            var r2 = Hashing.rng(w.x &* 31 &+ dx, w.y &* 17 &+ dy, seed &+ 129)
            for _ in 0..<r2.int(2, 4) {
                // Encosta os respingos na borda compartilhada.
                let t01 = r2.cg(0, 1)
                let prof = r2.cg(0, rect.width * 0.34)
                let px: CGFloat, py: CGFloat
                if dx != 0 {
                    px = dx > 0 ? rect.maxX - prof : rect.minX + prof
                    py = rect.minY + t01 * rect.height
                } else {
                    // No canvas o Y cresce para baixo; o mundo cresce para cima.
                    px = rect.minX + t01 * rect.width
                    py = dy > 0 ? rect.minY + prof : rect.maxY - prof
                }
                Draw.circle(ctx, CGPoint(x: px, y: py), r2.cg(2.5, 6.5),
                            ncor.withAlphaComponent(0.85))
            }
        }
    }

    // MARK: - Props

    private static func drawProp(_ ctx: CGContext, rect: CGRect, terrain t: Terrain,
                                 world w: GridPoint, palette p: BiomePalette, seed: UInt64) {
        var rng = Hashing.rng(w.x, w.y, seed &+ 97)

        switch t {
        case .gramaAlta:
            for _ in 0..<7 {
                let x = rect.minX + rng.cg(4, rect.width - 4)
                let y = rect.minY + rng.cg(6, rect.height - 8)
                let h = rng.cg(9, 17)
                let cor = p.grass.darker(rng.cg(0.05, 0.28))
                Draw.line(ctx, from: CGPoint(x: x, y: y),
                          to: CGPoint(x: x + rng.cg(-4, 4), y: y - h), width: 2.2, cor)
            }

        case .tronco:
            arvore(ctx, rect: rect, palette: p, rng: &rng)

        case .rocha:
            pedra(ctx, rect: rect, palette: p, rng: &rng)

        case .cipos:
            cipoal(ctx, rect: rect, palette: p, rng: &rng)

        case .espinheiro:
            espinhos(ctx, rect: rect, palette: p, rng: &rng)

        case .terraDura:
            terraCompactada(ctx, rect: rect, palette: p, rng: &rng)

        case .grama:
            if rng.chance(0.10) {
                let x = rect.minX + rng.cg(8, rect.width - 8)
                let y = rect.minY + rng.cg(8, rect.height - 8)
                Draw.circle(ctx, CGPoint(x: x, y: y), 2.6, p.accent.withAlphaComponent(0.8))
            }

        default:
            break
        }
    }

    private static func arvore(_ ctx: CGContext, rect: CGRect, palette p: BiomePalette,
                               rng: inout SeededRandom) {
        let cx = rect.midX + rng.cg(-4, 4)
        let baseY = rect.maxY - rng.cg(4, 10)
        Draw.shadow(ctx, center: CGPoint(x: cx + 3, y: baseY + 2), w: rect.width * 0.8, h: 12, alpha: 0.22)

        // Tronco
        let alturaTronco = rng.cg(14, 22)
        Draw.roundRect(ctx, CGRect(x: cx - 3.5, y: baseY - alturaTronco, width: 7, height: alturaTronco),
                       radius: 3, SKColor(hex: 0x4A3A28))

        // Copa: três massas sobrepostas, a de trás mais escura.
        let topo = baseY - alturaTronco
        let r = rng.cg(15, 21)
        Draw.circle(ctx, CGPoint(x: cx - r * 0.45, y: topo - r * 0.25), r * 0.85, p.foliageDark)
        Draw.circle(ctx, CGPoint(x: cx + r * 0.42, y: topo - r * 0.15), r * 0.80, p.foliageDark)
        Draw.circle(ctx, CGPoint(x: cx, y: topo - r * 0.55), r, p.foliage)
        Draw.circle(ctx, CGPoint(x: cx - r * 0.28, y: topo - r * 0.80), r * 0.45,
                    p.foliage.lighter(0.14))
    }

    private static func pedra(_ ctx: CGContext, rect: CGRect, palette p: BiomePalette,
                              rng: inout SeededRandom) {
        let cx = rect.midX + rng.cg(-3, 3)
        let cy = rect.midY + rng.cg(-2, 4)
        Draw.shadow(ctx, center: CGPoint(x: cx + 2, y: cy + 10), w: rect.width * 0.7, h: 10)

        var pts: [CGPoint] = []
        let lados = rng.int(5, 7)
        let raio = rng.cg(13, 19)
        for i in 0..<lados {
            let a = Double(i) / Double(lados) * .pi * 2
            let rr = raio * rng.cg(0.72, 1.05)
            pts.append(CGPoint(x: cx + CGFloat(cos(a)) * rr, y: cy + CGFloat(sin(a)) * rr * 0.82))
        }
        Draw.polygon(ctx, pts, p.rock.darker(0.18))
        let topo = pts.map { CGPoint(x: $0.x * 0.82 + cx * 0.18, y: $0.y * 0.82 + (cy - 4) * 0.18) }
        Draw.polygon(ctx, topo, p.rock)
        Draw.circle(ctx, CGPoint(x: cx - raio * 0.3, y: cy - raio * 0.35), raio * 0.22,
                    p.rock.lighter(0.22))
    }

    private static func cipoal(_ ctx: CGContext, rect: CGRect, palette p: BiomePalette,
                               rng: inout SeededRandom) {
        // Cortina de cipós: só o mico-leão-dourado atravessa.
        Draw.fill(ctx, rect, p.foliageDark.withAlphaComponent(0.30))
        for _ in 0..<5 {
            let x = rect.minX + rng.cg(3, rect.width - 3)
            let curva = rng.cg(-7, 7)
            ctx.setStrokeColor(p.foliage.darker(rng.cg(0.0, 0.25)).cgColor)
            ctx.setLineWidth(rng.cg(2.4, 4.0))
            ctx.setLineCap(.round)
            ctx.move(to: CGPoint(x: x, y: rect.minY - 2))
            ctx.addQuadCurve(to: CGPoint(x: x + curva, y: rect.maxY + 2),
                             control: CGPoint(x: x + curva * 2.2, y: rect.midY))
            ctx.strokePath()
        }
        for _ in 0..<4 {
            let x = rect.minX + rng.cg(4, rect.width - 4)
            let y = rect.minY + rng.cg(4, rect.height - 4)
            Draw.leaf(ctx, from: CGPoint(x: x - 6, y: y), to: CGPoint(x: x + 6, y: y - 3),
                      bulge: 4, p.foliage.lighter(0.10))
        }
    }

    private static func espinhos(_ ctx: CGContext, rect: CGRect, palette p: BiomePalette,
                                 rng: inout SeededRandom) {
        // Cerrado espinhoso: só a investida do lobo-guará rompe.
        for _ in 0..<4 {
            let cx = rect.minX + rng.cg(8, rect.width - 8)
            let cy = rect.minY + rng.cg(8, rect.height - 8)
            let r = rng.cg(7, 12)
            Draw.circle(ctx, CGPoint(x: cx, y: cy), r * 0.55, p.foliageDark)
            for i in 0..<8 {
                let a = Double(i) / 8.0 * .pi * 2 + Double(rng.cg(0, 0.6))
                Draw.line(ctx,
                          from: CGPoint(x: cx, y: cy),
                          to: CGPoint(x: cx + CGFloat(cos(a)) * r, y: cy + CGFloat(sin(a)) * r),
                          width: 1.8, p.foliage.darker(0.12))
            }
        }
    }

    private static func terraCompactada(_ ctx: CGContext, rect: CGRect, palette p: BiomePalette,
                                        rng: inout SeededRandom) {
        // Crosta rachada: só o tuco-tuco escava.
        let base = p.ground.darker(0.22)
        Draw.roundRect(ctx, rect.insetBy(dx: 1, dy: 1), radius: 3, base)
        for _ in 0..<4 {
            let x1 = rect.minX + rng.cg(2, rect.width - 2)
            let y1 = rect.minY + rng.cg(2, rect.height - 2)
            Draw.line(ctx, from: CGPoint(x: x1, y: y1),
                      to: CGPoint(x: x1 + rng.cg(-14, 14), y: y1 + rng.cg(-14, 14)),
                      width: 1.6, SKColor(white: 0, alpha: 0.35), round: false)
        }
        Draw.circle(ctx, CGPoint(x: rect.midX + rng.cg(-6, 6), y: rect.midY + rng.cg(-6, 6)),
                    3.2, p.sand.darker(0.28))
    }
}
