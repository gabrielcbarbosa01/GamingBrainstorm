//
//  SalaArt.swift
//  Guardiões dos Biomas
//
//  Desenho 2.5D das salas: o piso visto de cima, e as paredes com uma FACE
//  frontal virada para a câmera. É a face que dá volume — sem ela, tudo volta
//  a parecer um tabuleiro plano.
//

import SpriteKit

enum SalaArt {

    private static var cache: [String: SKTexture] = [:]

    static var margem: CGFloat { SalaMetrics.tile }
    static var topoExtra: CGFloat { SalaMetrics.faceParede }

    static var tamanhoTextura: CGSize {
        CGSize(width: SalaMetrics.tamanho.width + margem * 2,
               height: SalaMetrics.tamanho.height + margem * 2 + topoExtra)
    }

    /// Onde fica o centro do PISO dentro da textura, em fração — a parede do
    /// fundo é mais alta que a da frente, então a sala não é simétrica.
    static var ancoraInterior: CGPoint {
        let h = tamanhoTextura.height
        let centroDeCima = topoExtra + margem + SalaMetrics.tamanho.height / 2
        return CGPoint(x: 0.5, y: 1 - centroDeCima / h)
    }

    /// Uma sala inteira. Cada santuário tem arquitetura própria: a Copa é feita
    /// de troncos e cipós, as Veredas de rocha laterítica, os Ocos de manduvis
    /// alagados, os Lagos de sapopemas, as Dunas de areia estratificada.
    static func sala(_ bioma: BiomeID, variante: Int) -> SKTexture {
        let chave = "sala_\(bioma.rawValue)_\(variante)"
        if let t = cache[chave] { return t }
        let p = Biome[bioma].palette
        let tam = tamanhoTextura
        let yCoroa = topoExtra
        let yPiso = topoExtra + margem
        let interior = CGRect(x: margem, y: yPiso,
                              width: SalaMetrics.tamanho.width,
                              height: SalaMetrics.tamanho.height)

        let t = Draw.texture(width: Int(tam.width), height: Int(tam.height)) { ctx in
            var rng = SeededRandom(seed: UInt64(variante) &+ Biome[bioma].semente)
            Draw.fill(ctx, CGRect(origin: .zero, size: tam), SKColor(hex: 0x070A06))

            let face = CGRect(x: 0, y: 0, width: tam.width, height: topoExtra)
            desenharFace(ctx, face, bioma, p, &rng)
            desenharCoroa(ctx, CGRect(x: 0, y: yCoroa, width: tam.width, height: margem),
                          bioma, p, &rng)
            desenharPiso(ctx, interior, bioma, p, &rng)
            desenharLaterais(ctx, interior, tam, bioma, p, &rng)
            decorar(ctx, interior, bioma, p, &rng)
            oclusao(ctx, interior)
        }
        cache[chave] = t
        return t
    }

    // MARK: - Parede do fundo (a face que dá altura)

    private static func desenharFace(_ ctx: CGContext, _ r: CGRect, _ b: BiomeID,
                                     _ p: BiomePalette, _ rng: inout SeededRandom) {
        switch b {
        case .mataAtlantica, .amazonia:
            // Muralha de troncos. Na Amazônia eles viram sapopemas: raízes
            // tabulares que se abrem como barbatanas na base.
            Draw.fill(ctx, r, SKColor(hex: 0x0E1410))
            var x: CGFloat = -10
            while x < r.maxX {
                let w = rng.cg(46, 84)
                let cor = SKColor(hex: 0x4A3A28).blended(with: p.foliageDark,
                                                         amount: rng.cg(0, 0.4))
                Draw.roundRect(ctx, CGRect(x: x, y: -6, width: w, height: r.height + 8),
                               radius: 10, cor)
                // Estrias verticais da casca
                for _ in 0..<3 {
                    let lx = x + rng.cg(6, w - 6)
                    Draw.line(ctx, from: CGPoint(x: lx, y: 0), to: CGPoint(x: lx + rng.cg(-4, 4), y: r.maxY),
                              width: rng.cg(1.5, 3), SKColor(white: 0, alpha: 0.22))
                }
                Draw.line(ctx, from: CGPoint(x: x + 4, y: 0), to: CGPoint(x: x + 4, y: r.maxY),
                          width: 3, SKColor(white: 1, alpha: 0.07))
                if b == .amazonia {
                    // Sapopema: barbatana triangular saindo do tronco.
                    Draw.polygon(ctx, [CGPoint(x: x + w * 0.5, y: r.maxY - 30),
                                       CGPoint(x: x + w + rng.cg(6, 20), y: r.maxY),
                                       CGPoint(x: x + w * 0.5, y: r.maxY)],
                                 cor.darker(0.18))
                }
                x += w - rng.cg(2, 10)
            }
            // Cipós descendo entre os troncos
            for _ in 0..<Int(r.width / 46) {
                let cx = rng.cg(0, r.width)
                let comp = rng.cg(r.height * 0.4, r.height * 0.95)
                ctx.setStrokeColor(p.foliage.darker(0.12).cgColor)
                ctx.setLineWidth(rng.cg(2.5, 4.5))
                ctx.move(to: CGPoint(x: cx, y: 0))
                ctx.addQuadCurve(to: CGPoint(x: cx + rng.cg(-16, 16), y: comp),
                                 control: CGPoint(x: cx + rng.cg(-24, 24), y: comp * 0.6))
                ctx.strokePath()
                for k in 0..<3 {
                    let ly = comp * CGFloat(k + 1) / 4
                    Draw.leaf(ctx, from: CGPoint(x: cx, y: ly),
                              to: CGPoint(x: cx + rng.cg(-14, 14), y: ly + rng.cg(4, 12)),
                              bulge: 4, p.foliage)
                }
            }
            // Bromélias agarradas
            for _ in 0..<Int(r.width / 130) {
                let bx = rng.cg(10, r.width - 10), by = rng.cg(10, r.height - 14)
                for i in 0..<7 {
                    let a = Double(i) / 7 * .pi * 2
                    Draw.leaf(ctx, from: CGPoint(x: bx, y: by),
                              to: CGPoint(x: bx + CGFloat(cos(a)) * 16, y: by + CGFloat(sin(a)) * 12),
                              bulge: 4, p.grass.darker(0.08))
                }
                Draw.circle(ctx, CGPoint(x: bx, y: by), 4, p.accent)
            }

        case .cerrado:
            // Barranco de laterita: estratos horizontais e fendas verticais.
            Draw.fill(ctx, r, SKColor(hex: 0x6A3A22))
            var y: CGFloat = 0
            while y < r.maxY {
                let h = rng.cg(9, 18)
                let tom = SKColor(hex: 0x8A4A28).blended(with: SKColor(hex: 0xB0703A),
                                                         amount: rng.cg(0, 1))
                Draw.fill(ctx, CGRect(x: 0, y: y, width: r.width, height: h), tom)
                Draw.line(ctx, from: CGPoint(x: 0, y: y), to: CGPoint(x: r.width, y: y),
                          width: 1.5, SKColor(white: 0, alpha: 0.20), round: false)
                y += h
            }
            for _ in 0..<Int(r.width / 70) {
                let fx = rng.cg(0, r.width)
                ctx.setStrokeColor(SKColor(hex: 0x3A1E12, alpha: 0.75).cgColor)
                ctx.setLineWidth(rng.cg(3, 7))
                ctx.move(to: CGPoint(x: fx, y: 0))
                ctx.addLine(to: CGPoint(x: fx + rng.cg(-14, 14), y: r.maxY))
                ctx.strokePath()
            }
            // Cupinzeiros encostados na base da parede
            for _ in 0..<Int(r.width / 150) {
                let cx = rng.cg(20, r.width - 20)
                Draw.polygon(ctx, [CGPoint(x: cx - 18, y: r.maxY),
                                   CGPoint(x: cx + 18, y: r.maxY),
                                   CGPoint(x: cx + 6, y: r.maxY - rng.cg(24, 40)),
                                   CGPoint(x: cx - 6, y: r.maxY - rng.cg(24, 40))],
                             SKColor(hex: 0x7A5230))
            }

        case .pantanal:
            // Manduvis com oco: cada buraco escuro é um berçário de arara.
            Draw.fill(ctx, r, SKColor(hex: 0x14201A))
            var x: CGFloat = -6
            while x < r.maxX {
                let w = rng.cg(64, 104)
                Draw.roundRect(ctx, CGRect(x: x, y: -6, width: w, height: r.height + 8),
                               radius: 14, SKColor(hex: 0x6A5A44).blended(with: p.rock,
                                                                          amount: rng.cg(0, 0.5)))
                Draw.line(ctx, from: CGPoint(x: x + 6, y: 0), to: CGPoint(x: x + 6, y: r.maxY),
                          width: 4, SKColor(white: 1, alpha: 0.09))
                if rng.chance(0.55) {
                    // O oco
                    let oy = rng.cg(r.height * 0.3, r.height * 0.66)
                    Draw.ellipse(ctx, CGRect(x: x + w * 0.28, y: oy, width: w * 0.44, height: 30),
                                 SKColor(hex: 0x0A0C0A))
                    Draw.ellipse(ctx, CGRect(x: x + w * 0.32, y: oy + 4, width: w * 0.36, height: 22),
                                 SKColor(hex: 0x1A140E))
                    if rng.chance(0.4) {
                        Draw.circle(ctx, CGPoint(x: x + w * 0.5, y: oy + 16), 6,
                                    SKColor(hex: 0x2F6FD8))
                    }
                }
                x += w - rng.cg(0, 8)
            }

        case .pampa:
            // Corte de duna: estratos de areia com raízes expostas.
            Draw.fill(ctx, r, SKColor(hex: 0xB8A578))
            var y: CGFloat = 0
            var i = 0
            while y < r.maxY {
                let h = rng.cg(7, 15)
                let tom = SKColor(hex: 0xC6B584).blended(with: SKColor(hex: 0x9A8A5E),
                                                         amount: CGFloat(i % 3) * 0.3 + rng.cg(0, 0.3))
                // Estrato ondulado, não uma faixa reta
                ctx.setFillColor(tom.cgColor)
                ctx.move(to: CGPoint(x: 0, y: y))
                var xx: CGFloat = 0
                while xx < r.width {
                    ctx.addQuadCurve(to: CGPoint(x: xx + 60, y: y + rng.cg(-3, 3)),
                                     control: CGPoint(x: xx + 30, y: y + rng.cg(-6, 6)))
                    xx += 60
                }
                ctx.addLine(to: CGPoint(x: r.width, y: y + h))
                ctx.addLine(to: CGPoint(x: 0, y: y + h))
                ctx.closePath()
                ctx.fillPath()
                y += h
                i += 1
            }
            // Raízes penduradas na beirada
            for _ in 0..<Int(r.width / 40) {
                let rx = rng.cg(0, r.width)
                ctx.setStrokeColor(SKColor(hex: 0x6A5238, alpha: 0.85).cgColor)
                ctx.setLineWidth(rng.cg(1.5, 3))
                ctx.move(to: CGPoint(x: rx, y: 0))
                ctx.addQuadCurve(to: CGPoint(x: rx + rng.cg(-10, 10), y: rng.cg(20, r.height * 0.7)),
                                 control: CGPoint(x: rx + rng.cg(-14, 14), y: r.height * 0.3))
                ctx.strokePath()
            }

        case .refugio:
            Draw.fill(ctx, r, p.rock.darker(0.4))
        }
    }

    // MARK: - Coroamento (a espessura do muro vista de cima)

    private static func desenharCoroa(_ ctx: CGContext, _ r: CGRect, _ b: BiomeID,
                                      _ p: BiomePalette, _ rng: inout SeededRandom) {
        switch b {
        case .mataAtlantica, .amazonia:
            Draw.fill(ctx, r, p.foliageDark)
            for _ in 0..<Int(r.width / 22) {
                Draw.circle(ctx, CGPoint(x: rng.cg(0, r.width), y: rng.cg(r.minY, r.maxY)),
                            rng.cg(10, 22), p.foliage.blended(with: p.grass, amount: rng.cg(0, 0.6)))
            }
        case .cerrado:
            Draw.fill(ctx, r, SKColor(hex: 0x9A6A3E))
            for _ in 0..<Int(r.width / 16) {
                let gx = rng.cg(0, r.width)
                Draw.line(ctx, from: CGPoint(x: gx, y: r.maxY),
                          to: CGPoint(x: gx + rng.cg(-5, 5), y: r.maxY - rng.cg(8, 18)),
                          width: 2, p.grass.darker(0.1))
            }
        case .pantanal:
            Draw.fill(ctx, r, p.foliage.darker(0.1))
            for _ in 0..<Int(r.width / 26) {
                Draw.circle(ctx, CGPoint(x: rng.cg(0, r.width), y: rng.cg(r.minY, r.maxY)),
                            rng.cg(9, 18), p.foliage.lighter(0.12))
            }
        case .pampa:
            Draw.fill(ctx, r, SKColor(hex: 0xA8985E))
            for _ in 0..<Int(r.width / 12) {
                let gx = rng.cg(0, r.width)
                Draw.line(ctx, from: CGPoint(x: gx, y: r.maxY),
                          to: CGPoint(x: gx + rng.cg(-6, 6), y: r.maxY - rng.cg(10, 22)),
                          width: 2, p.grass.darker(0.05))
            }
        case .refugio:
            Draw.fill(ctx, r, p.rock.lighter(0.16))
        }
        Draw.fill(ctx, CGRect(x: 0, y: r.maxY - 5, width: r.width, height: 5),
                  SKColor(white: 0, alpha: 0.30))
    }

    // MARK: - Piso

    private static func desenharPiso(_ ctx: CGContext, _ r: CGRect, _ b: BiomeID,
                                     _ p: BiomePalette, _ rng: inout SeededRandom) {
        let tile = SalaMetrics.tile
        switch b {
        case .mataAtlantica:
            // Estrado de tábuas sobre a copa.
            Draw.fill(ctx, r, SKColor(hex: 0x6A5238))
            var y = r.minY
            while y < r.maxY {
                let h = tile * 0.62
                Draw.fill(ctx, CGRect(x: r.minX, y: y, width: r.width, height: h - 3),
                          SKColor(hex: 0x8A6E4A).blended(with: SKColor(hex: 0x6A5238),
                                                         amount: rng.cg(0, 0.7)))
                // Nós e emendas
                // Veio da madeira ao longo da tábua
                for _ in 0..<3 {
                    let vy = y + rng.cg(4, h - 8)
                    Draw.line(ctx, from: CGPoint(x: r.minX, y: vy),
                              to: CGPoint(x: r.maxX, y: vy + rng.cg(-2, 2)),
                              width: 1.2, SKColor(white: 0, alpha: 0.13), round: false)
                }
                var x = r.minX + rng.cg(0, 120)
                while x < r.maxX {
                    Draw.line(ctx, from: CGPoint(x: x, y: y), to: CGPoint(x: x, y: y + h - 3),
                              width: 3, SKColor(white: 0, alpha: 0.32), round: false)
                    if rng.chance(0.3) {
                        Draw.ellipse(ctx, CGRect(x: x + rng.cg(14, 50), y: y + h * 0.3,
                                                 width: 11, height: 7),
                                     SKColor(hex: 0x5A4028))
                    }
                    x += rng.cg(110, 190)
                }
                y += h
            }
            for _ in 0..<28 {
                let lx = rng.cg(r.minX, r.maxX), ly = rng.cg(r.minY, r.maxY)
                Draw.leaf(ctx, from: CGPoint(x: lx - 8, y: ly),
                          to: CGPoint(x: lx + 8, y: ly + rng.cg(-4, 4)),
                          bulge: 4, p.foliage.withAlphaComponent(0.55))
            }

        case .cerrado:
            // Terra rachada.
            Draw.fill(ctx, r, SKColor(hex: 0xA0703E))
            for ty in 0..<SalaMetrics.altura {
                for tx in 0..<SalaMetrics.largura {
                    let c = CGRect(x: r.minX + CGFloat(tx) * tile, y: r.minY + CGFloat(ty) * tile,
                                   width: tile, height: tile)
                    Draw.fill(ctx, c, SKColor(hex: 0xA0703E)
                        .blended(with: SKColor(hex: 0x8A5A30), amount: rng.cg(0, 0.55)))
                }
            }
            // Rede de rachaduras
            for _ in 0..<70 {
                var x = rng.cg(r.minX, r.maxX), y = rng.cg(r.minY, r.maxY)
                ctx.setStrokeColor(SKColor(hex: 0x5A3418, alpha: 0.6).cgColor)
                ctx.setLineWidth(rng.cg(1, 2.4))
                ctx.move(to: CGPoint(x: x, y: y))
                for _ in 0..<3 {
                    x += rng.cg(-40, 40); y += rng.cg(-40, 40)
                    ctx.addLine(to: CGPoint(x: x, y: y))
                }
                ctx.strokePath()
            }
            for _ in 0..<34 {
                let gx = rng.cg(r.minX, r.maxX), gy = rng.cg(r.minY, r.maxY)
                for _ in 0..<4 {
                    Draw.line(ctx, from: CGPoint(x: gx, y: gy),
                              to: CGPoint(x: gx + rng.cg(-8, 8), y: gy - rng.cg(8, 18)),
                              width: 2, p.grass.darker(rng.cg(0, 0.2)))
                }
            }

        case .pantanal, .amazonia:
            // Lâmina d'água sobre banco de areia.
            let seco = b == .pantanal ? p.sand : p.ground.lighter(0.1)
            Draw.fill(ctx, r, seco)
            // Grão da areia, para o banco não ficar chapado
            for _ in 0..<420 {
                Draw.circle(ctx, CGPoint(x: rng.cg(r.minX, r.maxX), y: rng.cg(r.minY, r.maxY)),
                            rng.cg(1.5, 4), seco.darker(rng.cg(0.04, 0.14)))
            }

            // Poças: cada uma é um aglomerado de elipses, senão viram bolhas
            // perfeitas e o alagado parece desenho técnico.
            for _ in 0..<7 {
                let cx = rng.cg(r.minX + 40, r.maxX - 40)
                let cy = rng.cg(r.minY + 30, r.maxY - 30)
                var partes: [CGRect] = []
                for _ in 0..<rng.int(3, 5) {
                    let w = rng.cg(110, 230), h = rng.cg(70, 150)
                    partes.append(CGRect(x: cx + rng.cg(-90, 90) - w / 2,
                                         y: cy + rng.cg(-50, 50) - h / 2,
                                         width: w, height: h))
                }
                // Beirada molhada primeiro, depois o fundo
                for q in partes {
                    Draw.ellipse(ctx, q.insetBy(dx: -8, dy: -6),
                                 p.water.lighter(0.12).withAlphaComponent(0.5))
                }
                for q in partes {
                    Draw.ellipse(ctx, q, p.water.withAlphaComponent(0.80))
                }
                for q in partes {
                    Draw.ellipse(ctx, q.insetBy(dx: 16, dy: 12),
                                 p.waterDeep.withAlphaComponent(0.60))
                }
                for k in 0..<3 {
                    let q = partes[rng.int(0, partes.count - 1)]
                    Draw.line(ctx, from: CGPoint(x: q.minX + 26, y: q.midY + CGFloat(k - 1) * 16),
                              to: CGPoint(x: q.maxX - 26, y: q.midY + CGFloat(k - 1) * 16 + rng.cg(-4, 4)),
                              width: 2, SKColor(white: 1, alpha: 0.14))
                }
            }
            if b == .pantanal {
                // Vitórias-régias: disco com um talho fino, não uma fatia inteira.
                for _ in 0..<14 {
                    let lx = rng.cg(r.minX, r.maxX), ly = rng.cg(r.minY, r.maxY)
                    let raio = rng.cg(13, 24)
                    Draw.circle(ctx, CGPoint(x: lx + 2, y: ly + 3), raio,
                                SKColor(hex: 0x0A0C0A, alpha: 0.25))
                    Draw.circle(ctx, CGPoint(x: lx, y: ly), raio, p.grass.darker(0.06))
                    Draw.circle(ctx, CGPoint(x: lx - raio * 0.25, y: ly - raio * 0.25),
                                raio * 0.55, p.grass.lighter(0.10))
                    // Nervuras
                    for k in 0..<5 {
                        let a = Double(k) / 5 * .pi * 2
                        Draw.line(ctx, from: CGPoint(x: lx, y: ly),
                                  to: CGPoint(x: lx + CGFloat(cos(a)) * raio * 0.9,
                                              y: ly + CGFloat(sin(a)) * raio * 0.9),
                                  width: 1.2, p.grass.darker(0.22))
                    }
                    // O talho característico
                    Draw.polygon(ctx, [CGPoint(x: lx, y: ly),
                                       CGPoint(x: lx + raio, y: ly - 3),
                                       CGPoint(x: lx + raio, y: ly + 3)],
                                 p.water.withAlphaComponent(0.85))
                }
            } else {
                // Raízes rasteiras cruzando o piso
                for _ in 0..<14 {
                    var x = rng.cg(r.minX, r.maxX), y = rng.cg(r.minY, r.maxY)
                    ctx.setStrokeColor(SKColor(hex: 0x4A3A28, alpha: 0.85).cgColor)
                    ctx.setLineWidth(rng.cg(4, 9))
                    ctx.setLineCap(.round)
                    ctx.move(to: CGPoint(x: x, y: y))
                    for _ in 0..<3 {
                        x += rng.cg(-90, 90); y += rng.cg(-50, 50)
                        ctx.addLine(to: CGPoint(x: x, y: y))
                    }
                    ctx.strokePath()
                }
            }

        case .pampa:
            // Areia com marcas de vento e montículos de galeria.
            Draw.fill(ctx, r, SKColor(hex: 0xD2C08C))
            for i in 0..<46 {
                let y = r.minY + CGFloat(i) * (r.height / 46)
                ctx.setStrokeColor(SKColor(hex: 0xB8A578, alpha: 0.55).cgColor)
                ctx.setLineWidth(rng.cg(2, 4))
                ctx.move(to: CGPoint(x: r.minX, y: y))
                var xx = r.minX
                while xx < r.maxX {
                    ctx.addQuadCurve(to: CGPoint(x: xx + 90, y: y + rng.cg(-4, 4)),
                                     control: CGPoint(x: xx + 45, y: y + rng.cg(-9, 9)))
                    xx += 90
                }
                ctx.strokePath()
            }
            for _ in 0..<7 {
                let mx = rng.cg(r.minX + 40, r.maxX - 40), my = rng.cg(r.minY + 40, r.maxY - 40)
                Draw.ellipse(ctx, CGRect(x: mx - 34, y: my - 16, width: 68, height: 32),
                             SKColor(hex: 0xC0AC78))
                Draw.ellipse(ctx, CGRect(x: mx - 22, y: my - 11, width: 44, height: 22),
                             SKColor(hex: 0xA8946A))
                Draw.ellipse(ctx, CGRect(x: mx - 9, y: my - 5, width: 18, height: 11),
                             SKColor(hex: 0x3A3020))
            }
            for _ in 0..<40 {
                let gx = rng.cg(r.minX, r.maxX), gy = rng.cg(r.minY, r.maxY)
                for _ in 0..<3 {
                    Draw.line(ctx, from: CGPoint(x: gx, y: gy),
                              to: CGPoint(x: gx + rng.cg(-7, 7), y: gy - rng.cg(10, 22)),
                              width: 2, p.grass.darker(rng.cg(0, 0.25)))
                }
            }

        case .refugio:
            Draw.fill(ctx, r, p.ground.lighter(0.2))
        }
    }

    // MARK: - Paredes laterais

    private static func desenharLaterais(_ ctx: CGContext, _ interior: CGRect, _ tam: CGSize,
                                         _ b: BiomeID, _ p: BiomePalette,
                                         _ rng: inout SeededRandom) {
        let m = margem
        for lado in [CGFloat(0), interior.maxX] {
            let faixa = CGRect(x: lado, y: interior.minY, width: m, height: interior.height)
            switch b {
            case .mataAtlantica, .amazonia:
                Draw.fill(ctx, faixa, SKColor(hex: 0x4A3A28))
                var yy = faixa.minY
                while yy < faixa.maxY {
                    let h = rng.cg(50, 90)
                    Draw.roundRect(ctx, CGRect(x: lado + 2, y: yy + 2, width: m - 4,
                                               height: min(h, faixa.maxY - yy) - 4),
                                   radius: 8, SKColor(hex: 0x5A4630)
                                    .blended(with: p.foliageDark, amount: rng.cg(0, 0.5)))
                    yy += h
                }
            case .cerrado:
                Draw.fill(ctx, faixa, SKColor(hex: 0x8A5A30))
                var yy = faixa.minY
                while yy < faixa.maxY {
                    let h = rng.cg(10, 18)
                    Draw.fill(ctx, CGRect(x: lado, y: yy, width: m, height: h),
                              SKColor(hex: 0x9A6A3A).blended(with: SKColor(hex: 0x6A3A22),
                                                             amount: rng.cg(0, 1)))
                    yy += h
                }
            case .pantanal:
                Draw.fill(ctx, faixa, SKColor(hex: 0x5A4E3A))
                var yy = faixa.minY
                while yy < faixa.maxY {
                    let h = rng.cg(60, 110)
                    Draw.roundRect(ctx, CGRect(x: lado + 3, y: yy + 3, width: m - 6,
                                               height: min(h, faixa.maxY - yy) - 6),
                                   radius: 12, SKColor(hex: 0x6A5A44))
                    yy += h
                }
            case .pampa:
                Draw.fill(ctx, faixa, SKColor(hex: 0xB8A578))
                var yy = faixa.minY
                while yy < faixa.maxY {
                    let h = rng.cg(8, 16)
                    Draw.fill(ctx, CGRect(x: lado, y: yy, width: m, height: h),
                              SKColor(hex: 0xC6B584).blended(with: SKColor(hex: 0x9A8A5E),
                                                             amount: rng.cg(0, 1)))
                    yy += h
                }
            case .refugio:
                Draw.fill(ctx, faixa, p.rock)
            }
        }
        // Parede da frente: só o topo aparece.
        let frente = CGRect(x: 0, y: interior.maxY, width: tam.width, height: m)
        switch b {
        case .mataAtlantica, .amazonia: Draw.fill(ctx, frente, SKColor(hex: 0x4A3A28))
        case .cerrado: Draw.fill(ctx, frente, SKColor(hex: 0x8A5A30))
        case .pantanal: Draw.fill(ctx, frente, SKColor(hex: 0x5A4E3A))
        case .pampa: Draw.fill(ctx, frente, SKColor(hex: 0xB8A578))
        case .refugio: Draw.fill(ctx, frente, p.rock)
        }
    }

    /// Vegetação e detritos soltos pela sala. Ficam longe do centro e das
    /// soleiras, para não atrapalhar baús, inimigos e passagem.
    private static func decorar(_ ctx: CGContext, _ r: CGRect, _ b: BiomeID,
                                _ p: BiomePalette, _ rng: inout SeededRandom) {
        let centro = CGPoint(x: r.midX, y: r.midY)

        func lugar() -> CGPoint? {
            for _ in 0..<8 {
                let q = CGPoint(x: rng.cg(r.minX + 30, r.maxX - 30),
                                y: rng.cg(r.minY + 30, r.maxY - 30))
                // longe do centro (baú/chefe) e das soleiras
                if hypot(q.x - centro.x, q.y - centro.y) < 120 { continue }
                if abs(q.x - centro.x) < 80 && (q.y < r.minY + 70 || q.y > r.maxY - 70) { continue }
                if abs(q.y - centro.y) < 80 && (q.x < r.minX + 70 || q.x > r.maxX - 70) { continue }
                return q
            }
            return nil
        }

        func touceira(_ c: CGPoint, _ cor: SKColor, _ n: Int, _ alt: CGFloat) {
            Draw.ellipse(ctx, CGRect(x: c.x - 16, y: c.y - 5, width: 32, height: 12),
                         SKColor(white: 0, alpha: 0.20))
            for _ in 0..<n {
                let x = c.x + rng.cg(-13, 13)
                Draw.line(ctx, from: CGPoint(x: x, y: c.y),
                          to: CGPoint(x: x + rng.cg(-9, 9), y: c.y - rng.cg(alt * 0.6, alt)),
                          width: rng.cg(2, 3.5), cor.darker(rng.cg(0, 0.22)))
            }
        }

        switch b {
        case .mataAtlantica:
            for _ in 0..<9 {
                guard let c = lugar() else { continue }
                if rng.chance(0.45) {
                    // Samambaia: fronde arqueada
                    Draw.ellipse(ctx, CGRect(x: c.x - 20, y: c.y - 6, width: 40, height: 14),
                                 SKColor(white: 0, alpha: 0.22))
                    for k in 0..<6 {
                        let a = Double(k) / 6 * .pi - .pi / 2
                        Draw.leaf(ctx, from: c,
                                  to: CGPoint(x: c.x + CGFloat(cos(a)) * 30,
                                              y: c.y - 12 + CGFloat(sin(a)) * 22),
                                  bulge: 6, p.foliage.darker(rng.cg(0, 0.2)))
                    }
                } else if rng.chance(0.5) {
                    // Bromélia no estrado
                    for k in 0..<8 {
                        let a = Double(k) / 8 * .pi * 2
                        Draw.leaf(ctx, from: c,
                                  to: CGPoint(x: c.x + CGFloat(cos(a)) * 19,
                                              y: c.y + CGFloat(sin(a)) * 13),
                                  bulge: 5, p.grass.darker(rng.cg(0, 0.18)))
                    }
                    Draw.circle(ctx, c, 5, p.accent)
                } else {
                    // Galho caído
                    Draw.line(ctx, from: CGPoint(x: c.x - 26, y: c.y),
                              to: CGPoint(x: c.x + 26, y: c.y + rng.cg(-8, 8)),
                              width: 7, SKColor(hex: 0x5A4028))
                    Draw.line(ctx, from: CGPoint(x: c.x + 8, y: c.y),
                              to: CGPoint(x: c.x + 22, y: c.y - 16), width: 4,
                              SKColor(hex: 0x5A4028))
                }
            }

        case .cerrado:
            for _ in 0..<11 {
                guard let c = lugar() else { continue }
                if rng.chance(0.5) {
                    touceira(c, p.grass, rng.int(6, 10), 30)
                } else if rng.chance(0.55) {
                    // Pedra de laterita
                    Draw.ellipse(ctx, CGRect(x: c.x - 18, y: c.y - 4, width: 36, height: 13),
                                 SKColor(white: 0, alpha: 0.24))
                    Draw.ellipse(ctx, CGRect(x: c.x - 16, y: c.y - 14, width: 32, height: 22),
                                 SKColor(hex: 0x8A4A28))
                    Draw.ellipse(ctx, CGRect(x: c.x - 10, y: c.y - 12, width: 16, height: 10),
                                 SKColor(hex: 0xA9663A))
                } else {
                    // Cupinzeiro
                    Draw.polygon(ctx, [CGPoint(x: c.x - 15, y: c.y + 6),
                                       CGPoint(x: c.x + 15, y: c.y + 6),
                                       CGPoint(x: c.x + 5, y: c.y - 30),
                                       CGPoint(x: c.x - 5, y: c.y - 30)],
                                 SKColor(hex: 0x7A5230))
                    Draw.polygon(ctx, [CGPoint(x: c.x - 9, y: c.y + 4),
                                       CGPoint(x: c.x + 2, y: c.y + 4),
                                       CGPoint(x: c.x - 1, y: c.y - 24)],
                                 SKColor(hex: 0x94663E))
                }
            }

        case .pantanal:
            for _ in 0..<11 {
                guard let c = lugar() else { continue }
                if rng.chance(0.6) {
                    touceira(c, p.grass.darker(0.05), rng.int(8, 13), 42)   // junco
                } else {
                    // Tronco boiando
                    Draw.ellipse(ctx, CGRect(x: c.x - 34, y: c.y - 2, width: 68, height: 18),
                                 p.water.withAlphaComponent(0.35))
                    Draw.roundRect(ctx, CGRect(x: c.x - 30, y: c.y - 9, width: 60, height: 18),
                                   radius: 9, SKColor(hex: 0x5A4028))
                    Draw.roundRect(ctx, CGRect(x: c.x - 22, y: c.y - 5, width: 44, height: 6),
                                   radius: 3, SKColor(hex: 0x7A5A38))
                }
            }

        case .amazonia:
            for _ in 0..<10 {
                guard let c = lugar() else { continue }
                if rng.chance(0.45) {
                    // Folha gigante
                    Draw.ellipse(ctx, CGRect(x: c.x - 24, y: c.y - 4, width: 48, height: 14),
                                 SKColor(white: 0, alpha: 0.22))
                    Draw.leaf(ctx, from: CGPoint(x: c.x - 26, y: c.y),
                              to: CGPoint(x: c.x + 26, y: c.y - 6), bulge: 18,
                              p.foliage.darker(rng.cg(0, 0.18)))
                    Draw.line(ctx, from: CGPoint(x: c.x - 24, y: c.y),
                              to: CGPoint(x: c.x + 24, y: c.y - 6), width: 2,
                              p.foliageDark)
                } else if rng.chance(0.5) {
                    // Raiz saliente
                    ctx.setStrokeColor(SKColor(hex: 0x4A3A28).cgColor)
                    ctx.setLineWidth(rng.cg(7, 12))
                    ctx.setLineCap(.round)
                    ctx.move(to: CGPoint(x: c.x - 40, y: c.y))
                    ctx.addQuadCurve(to: CGPoint(x: c.x + 40, y: c.y + rng.cg(-14, 14)),
                                     control: CGPoint(x: c.x, y: c.y + rng.cg(-26, 26)))
                    ctx.strokePath()
                } else {
                    for k in 0..<3 {
                        let q = CGPoint(x: c.x + CGFloat(k) * 12 - 12, y: c.y + rng.cg(-6, 6))
                        Draw.ellipse(ctx, CGRect(x: q.x - 7, y: q.y - 4, width: 14, height: 7),
                                     SKColor(hex: 0xD8C89A))
                        Draw.roundRect(ctx, CGRect(x: q.x - 2, y: q.y, width: 4, height: 9),
                                       radius: 1.5, SKColor(hex: 0xB0A078))
                    }
                }
            }

        case .pampa:
            for _ in 0..<13 {
                guard let c = lugar() else { continue }
                if rng.chance(0.62) {
                    touceira(c, p.grass, rng.int(7, 12), 34)
                } else if rng.chance(0.5) {
                    // Concha
                    Draw.ellipse(ctx, CGRect(x: c.x - 9, y: c.y - 6, width: 18, height: 12),
                                 SKColor(hex: 0xE8DCC0))
                    for k in 0..<4 {
                        Draw.line(ctx, from: CGPoint(x: c.x, y: c.y + 5),
                                  to: CGPoint(x: c.x - 7 + CGFloat(k) * 4.5, y: c.y - 5),
                                  width: 1.2, SKColor(hex: 0xC0B090))
                    }
                } else {
                    // Pedrinhas trazidas pelo vento
                    for _ in 0..<4 {
                        Draw.ellipse(ctx, CGRect(x: c.x + rng.cg(-18, 18), y: c.y + rng.cg(-12, 12),
                                                 width: rng.cg(6, 12), height: rng.cg(4, 8)),
                                     SKColor(hex: 0x9A8A6A))
                    }
                }
            }

        case .refugio:
            break
        }
    }

    private static func oclusao(_ ctx: CGContext, _ interior: CGRect) {
        for i in 0..<16 {
            let a = 0.30 - CGFloat(i) * 0.019
            guard a > 0 else { break }
            let o = CGFloat(i) * 2
            Draw.fill(ctx, CGRect(x: interior.minX, y: interior.minY + o,
                                  width: interior.width, height: 2),
                      SKColor(white: 0, alpha: a))
            Draw.fill(ctx, CGRect(x: interior.minX + o, y: interior.minY,
                                  width: 2, height: interior.height),
                      SKColor(white: 0, alpha: a * 0.65))
            Draw.fill(ctx, CGRect(x: interior.maxX - o - 2, y: interior.minY,
                                  width: 2, height: interior.height),
                      SKColor(white: 0, alpha: a * 0.65))
            Draw.fill(ctx, CGRect(x: interior.minX, y: interior.maxY - o - 2,
                                  width: interior.width, height: 2),
                      SKColor(white: 0, alpha: a * 0.45))
        }
    }

    /// Vão de porta. O batente é feito do material do santuário — cipó na
    /// Copa, rocha nas Veredas, tronco nos Ocos, raiz nos Lagos, areia nas
    /// Dunas — e por cima vem o estado da porta.
    static func porta(_ tipo: TipoPorta, _ dir: Direcao, _ bioma: BiomeID) -> SKTexture {
        let chave = "porta_\(tipo)_\(dir.rawValue)_\(bioma.rawValue)"
        if let t = cache[chave] { return t }
        let p = Biome[bioma].palette
        let horizontal = dir == .norte || dir == .sul
        let w = horizontal ? 146 : 96
        let h = horizontal ? 96 : 146

        let t = Draw.texture(width: w, height: h) { ctx in
            let r = CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h))
            var rng = SeededRandom(seed: UInt64(dir.rawValue) &+ Biome[bioma].semente)

            // Vão escuro ao fundo
            Draw.roundRect(ctx, r.insetBy(dx: 10, dy: 10), radius: 8, SKColor(hex: 0x07090A))

            // --- Batente, com o material do santuário ---
            switch bioma {
            case .mataAtlantica:
                // Dois troncos e uma verga de madeira, com cipós pendurados.
                Draw.roundRect(ctx, CGRect(x: 0, y: 0, width: 18, height: r.height),
                               radius: 8, SKColor(hex: 0x5A4630))
                Draw.roundRect(ctx, CGRect(x: r.maxX - 18, y: 0, width: 18, height: r.height),
                               radius: 8, SKColor(hex: 0x5A4630))
                Draw.roundRect(ctx, CGRect(x: 0, y: 0, width: r.width, height: 16),
                               radius: 6, SKColor(hex: 0x6A5238))
                for _ in 0..<6 {
                    let cx = rng.cg(16, r.width - 16)
                    ctx.setStrokeColor(p.foliage.cgColor)
                    ctx.setLineWidth(rng.cg(2, 3.5))
                    ctx.move(to: CGPoint(x: cx, y: 12))
                    ctx.addQuadCurve(to: CGPoint(x: cx + rng.cg(-8, 8), y: rng.cg(30, 62)),
                                     control: CGPoint(x: cx + rng.cg(-12, 12), y: 30))
                    ctx.strokePath()
                }
            case .cerrado:
                // Fenda aberta na laterita, com estratos visíveis no batente.
                var y: CGFloat = 0
                while y < r.height {
                    let hh = rng.cg(8, 15)
                    let tom = SKColor(hex: 0x9A6A3A).blended(with: SKColor(hex: 0x6A3A22),
                                                             amount: rng.cg(0, 1))
                    Draw.fill(ctx, CGRect(x: 0, y: y, width: 16, height: hh), tom)
                    Draw.fill(ctx, CGRect(x: r.maxX - 16, y: y, width: 16, height: hh), tom)
                    y += hh
                }
                Draw.fill(ctx, CGRect(x: 0, y: 0, width: r.width, height: 14),
                          SKColor(hex: 0x8A5A30))
            case .pantanal:
                // Passagem entre dois manduvis, com raízes na base.
                Draw.roundRect(ctx, CGRect(x: -2, y: 0, width: 22, height: r.height),
                               radius: 11, SKColor(hex: 0x6A5A44))
                Draw.roundRect(ctx, CGRect(x: r.maxX - 20, y: 0, width: 22, height: r.height),
                               radius: 11, SKColor(hex: 0x6A5A44))
                for lado in [CGFloat(9), r.maxX - 9] {
                    for _ in 0..<3 {
                        ctx.setStrokeColor(SKColor(hex: 0x4A3E2E).cgColor)
                        ctx.setLineWidth(rng.cg(2, 4))
                        ctx.move(to: CGPoint(x: lado, y: r.maxY - rng.cg(0, 20)))
                        ctx.addQuadCurve(to: CGPoint(x: lado + rng.cg(-18, 18), y: r.maxY),
                                         control: CGPoint(x: lado, y: r.maxY - 6))
                        ctx.strokePath()
                    }
                }
            case .amazonia:
                // Arco formado por duas sapopemas que se encontram no alto.
                Draw.polygon(ctx, [CGPoint(x: 0, y: r.maxY), CGPoint(x: 26, y: r.maxY),
                                   CGPoint(x: 16, y: 0), CGPoint(x: 0, y: 0)],
                             SKColor(hex: 0x4A3A28))
                Draw.polygon(ctx, [CGPoint(x: r.maxX, y: r.maxY), CGPoint(x: r.maxX - 26, y: r.maxY),
                                   CGPoint(x: r.maxX - 16, y: 0), CGPoint(x: r.maxX, y: 0)],
                             SKColor(hex: 0x4A3A28))
                Draw.roundRect(ctx, CGRect(x: 0, y: 0, width: r.width, height: 14),
                               radius: 6, SKColor(hex: 0x3E3222))
            case .pampa:
                // Boca de túnel escavada na duna, com raízes penduradas.
                Draw.ellipse(ctx, CGRect(x: -6, y: -10, width: r.width + 12, height: r.height + 20),
                             SKColor(hex: 0xB8A578))
                Draw.ellipse(ctx, r.insetBy(dx: 12, dy: 12), SKColor(hex: 0x07090A))
                for _ in 0..<7 {
                    let rx = rng.cg(16, r.width - 16)
                    ctx.setStrokeColor(SKColor(hex: 0x6A5238, alpha: 0.9).cgColor)
                    ctx.setLineWidth(rng.cg(1.5, 3))
                    ctx.move(to: CGPoint(x: rx, y: 10))
                    ctx.addLine(to: CGPoint(x: rx + rng.cg(-6, 6), y: rng.cg(24, 50)))
                    ctx.strokePath()
                }
            case .refugio:
                Draw.roundRect(ctx, r.insetBy(dx: 4, dy: 4), radius: 8, p.rock.lighter(0.1))
            }

            // --- Estado da porta, por cima do batente ---
            let vao = r.insetBy(dx: 18, dy: 16)
            switch tipo {
            case .aberta:
                // Só escuridão e um degrau de luz na soleira.
                Draw.fill(ctx, CGRect(x: vao.minX, y: vao.maxY - 6,
                                      width: vao.width, height: 6),
                          SKColor(white: 1, alpha: 0.08))
            case .fechada:
                Draw.roundRect(ctx, vao, radius: 5, p.rock.darker(0.12))
                let n = horizontal ? 5 : 4
                for i in 0..<n {
                    if horizontal {
                        let x = vao.minX + CGFloat(i) * (vao.width / CGFloat(n)) + 4
                        Draw.line(ctx, from: CGPoint(x: x, y: vao.minY + 4),
                                  to: CGPoint(x: x, y: vao.maxY - 4), width: 4,
                                  p.rock.darker(0.32))
                    } else {
                        let y = vao.minY + CGFloat(i) * (vao.height / CGFloat(n)) + 4
                        Draw.line(ctx, from: CGPoint(x: vao.minX + 4, y: y),
                                  to: CGPoint(x: vao.maxX - 4, y: y), width: 4,
                                  p.rock.darker(0.32))
                    }
                }
            case .trancada:
                Draw.roundRect(ctx, vao, radius: 5, SKColor(hex: 0x5A4630))
                Draw.roundRect(ctx, vao.insetBy(dx: 5, dy: 5), radius: 4, SKColor(hex: 0x6E5638))
                Draw.circle(ctx, CGPoint(x: r.midX, y: r.midY), 16, Palette.gold)
                Draw.circle(ctx, CGPoint(x: r.midX, y: r.midY + 3), 6, SKColor(hex: 0x2A2018))
                Draw.roundRect(ctx, CGRect(x: r.midX - 3.5, y: r.midY - 13, width: 7, height: 13),
                               radius: 2, SKColor(hex: 0x2A2018))
            case .selada:
                Draw.roundRect(ctx, vao, radius: 5, p.foliageDark)
                let a = Biome[bioma].animal
                Draw.circle(ctx, CGPoint(x: r.midX, y: r.midY), 21,
                            a.corPrimaria.withAlphaComponent(0.9))
                Draw.circle(ctx, CGPoint(x: r.midX, y: r.midY), 13, a.corSecundaria)
                for i in 0..<8 {
                    let ang = Double(i) / 8 * .pi * 2
                    Draw.line(ctx, from: CGPoint(x: r.midX + CGFloat(cos(ang)) * 21,
                                                 y: r.midY + CGFloat(sin(ang)) * 21),
                              to: CGPoint(x: r.midX + CGFloat(cos(ang)) * 29,
                                          y: r.midY + CGFloat(sin(ang)) * 29),
                              width: 3, a.corPrimaria)
                }
            case .doGuardiao:
                // A porta do fundo: pesada, com a cara do bicho em relevo.
                Draw.roundRect(ctx, vao, radius: 5, SKColor(hex: 0x2E2A26))
                Draw.roundRect(ctx, vao.insetBy(dx: 4, dy: 4), radius: 4, SKColor(hex: 0x3E3830))
                let a = Biome[bioma].animal
                Draw.circle(ctx, CGPoint(x: r.midX, y: r.midY), 26, SKColor(hex: 0x1A1814))
                Draw.circle(ctx, CGPoint(x: r.midX, y: r.midY), 22, a.corPrimaria.darker(0.2))
                // Olhos do selo, virados para quem chega
                Draw.circle(ctx, CGPoint(x: r.midX - 8, y: r.midY - 4), 5, Palette.gold)
                Draw.circle(ctx, CGPoint(x: r.midX + 8, y: r.midY - 4), 5, Palette.gold)
                Draw.circle(ctx, CGPoint(x: r.midX - 8, y: r.midY - 4), 2.4, .black)
                Draw.circle(ctx, CGPoint(x: r.midX + 8, y: r.midY - 4), 2.4, .black)
                // Fechadura grande embaixo
                Draw.roundRect(ctx, CGRect(x: r.midX - 5, y: r.midY + 8, width: 10, height: 16),
                               radius: 3, Palette.gold)
                Draw.circle(ctx, CGPoint(x: r.midX, y: r.midY + 12), 4, SKColor(hex: 0x1A1814))
                // Correntes nas bordas
                for i in 0..<4 {
                    let y = vao.minY + CGFloat(i) * (vao.height / 4) + 8
                    Draw.circle(ctx, CGPoint(x: vao.minX + 6, y: y), 4, SKColor(hex: 0x8A8A82))
                    Draw.circle(ctx, CGPoint(x: vao.maxX - 6, y: y), 4, SKColor(hex: 0x8A8A82))
                }
            }
        }
        cache[chave] = t
        return t
    }

    /// Baú fechado e aberto, com face frontal para combinar com as paredes.
    static func bau(aberto: Bool) -> SKTexture {
        let chave = "bau_\(aberto)"
        if let t = cache[chave] { return t }
        let t = Draw.texture(width: 76, height: 78) { ctx in
            Draw.shadow(ctx, center: CGPoint(x: 38, y: 70), w: 56, h: 16, alpha: 0.3)
            // Corpo
            Draw.roundRect(ctx, CGRect(x: 10, y: 30, width: 56, height: 38), radius: 5,
                           SKColor(hex: 0x6A4E2E))
            Draw.roundRect(ctx, CGRect(x: 14, y: 34, width: 48, height: 30), radius: 4,
                           SKColor(hex: 0x8A6A3E))
            // Tampa
            if aberto {
                Draw.roundRect(ctx, CGRect(x: 8, y: 4, width: 60, height: 18), radius: 8,
                               SKColor(hex: 0x5A4028))
                Draw.roundRect(ctx, CGRect(x: 16, y: 32, width: 44, height: 12), radius: 4,
                               SKColor(hex: 0x2A2018))
                Draw.circle(ctx, CGPoint(x: 38, y: 38), 12, Palette.gold.withAlphaComponent(0.35))
            } else {
                Draw.roundRect(ctx, CGRect(x: 8, y: 18, width: 60, height: 22), radius: 9,
                               SKColor(hex: 0x7A5A38))
                Draw.roundRect(ctx, CGRect(x: 12, y: 22, width: 52, height: 14), radius: 6,
                               SKColor(hex: 0x9A7A4A))
            }
            // Ferragens
            Draw.roundRect(ctx, CGRect(x: 32, y: aberto ? 26 : 30, width: 12, height: 16),
                           radius: 3, Palette.gold)
            Draw.roundRect(ctx, CGRect(x: 16, y: 30, width: 5, height: 36), radius: 2,
                           SKColor(hex: 0x4A3A28))
            Draw.roundRect(ctx, CGRect(x: 55, y: 30, width: 5, height: 36), radius: 2,
                           SKColor(hex: 0x4A3A28))
        }
        cache[chave] = t
        return t
    }

    static func chave() -> SKTexture {
        if let t = cache["chave"] { return t }
        let t = Draw.texture(width: 44, height: 44) { ctx in
            Draw.circle(ctx, CGPoint(x: 22, y: 22), 18, Palette.gold.withAlphaComponent(0.16))
            Draw.circle(ctx, CGPoint(x: 22, y: 13), 8, Palette.gold)
            Draw.circle(ctx, CGPoint(x: 22, y: 13), 4, SKColor(hex: 0x2A2018))
            Draw.roundRect(ctx, CGRect(x: 19, y: 18, width: 6, height: 18), radius: 2, Palette.gold)
            Draw.roundRect(ctx, CGRect(x: 25, y: 27, width: 8, height: 5), radius: 2, Palette.gold)
            Draw.roundRect(ctx, CGRect(x: 25, y: 33, width: 6, height: 4), radius: 2, Palette.gold)
        }
        cache["chave"] = t
        return t
    }

    /// Coração de vida — aqui é um fruto, que combina com o tema.
    static func coracao(_ estado: Int) -> SKTexture {   // 2 cheio, 1 meio, 0 vazio
        let chave = "coracao_\(estado)"
        if let t = cache[chave] { return t }
        let t = Draw.texture(width: 40, height: 40) { ctx in
            let cheio = SKColor(hex: 0xD8443E)
            let vazio = SKColor(hex: 0x3A2A28)
            func fruto(_ cor: SKColor, metade: Bool) {
                ctx.saveGState()
                if metade { ctx.clip(to: CGRect(x: 0, y: 0, width: 20, height: 40)) }
                Draw.circle(ctx, CGPoint(x: 14, y: 17), 9, cor)
                Draw.circle(ctx, CGPoint(x: 26, y: 17), 9, cor)
                Draw.polygon(ctx, [CGPoint(x: 5, y: 20), CGPoint(x: 35, y: 20),
                                   CGPoint(x: 20, y: 36)], cor)
                ctx.restoreGState()
            }
            fruto(vazio, metade: false)
            if estado == 2 { fruto(cheio, metade: false) }
            if estado == 1 { fruto(cheio, metade: true) }
            // Folhinha
            Draw.leaf(ctx, from: CGPoint(x: 20, y: 10), to: CGPoint(x: 30, y: 4),
                      bulge: 3, SKColor(hex: 0x4E7A34))
            Draw.line(ctx, from: CGPoint(x: 20, y: 12), to: CGPoint(x: 20, y: 4),
                      width: 2, SKColor(hex: 0x3A5A24))
        }
        cache[chave] = t
        return t
    }

    /// Escada de saída do santuário, na sala de entrada.
    static func saida(_ bioma: BiomeID) -> SKTexture {
        let chave = "saida_\(bioma.rawValue)"
        if let t = cache[chave] { return t }
        let p = Biome[bioma].palette
        let t = Draw.texture(width: 96, height: 96) { ctx in
            Draw.ellipse(ctx, CGRect(x: 6, y: 20, width: 84, height: 68),
                         SKColor(hex: 0x07090A))
            // Degraus descendo para fora
            for i in 0..<5 {
                let inset = CGFloat(i) * 8
                Draw.roundRect(ctx, CGRect(x: 14 + inset, y: 26 + CGFloat(i) * 11,
                                           width: 68 - inset * 2, height: 10),
                               radius: 3, p.rock.lighter(0.22 - CGFloat(i) * 0.04))
            }
            // Luz do lado de fora
            Draw.ellipse(ctx, CGRect(x: 26, y: 8, width: 44, height: 26),
                         Palette.gold.withAlphaComponent(0.22))
            Draw.ellipse(ctx, CGRect(x: 34, y: 12, width: 28, height: 16),
                         Palette.gold.withAlphaComponent(0.35))
        }
        cache[chave] = t
        return t
    }

    /// Portal que se abre depois de vencer o Guardião.
    static func portalDeVolta(_ bioma: BiomeID) -> SKTexture {
        let chave = "volta_\(bioma.rawValue)"
        if let t = cache[chave] { return t }
        let a = Biome[bioma].animal
        let t = Draw.texture(width: 120, height: 120) { ctx in
            let c = CGPoint(x: 60, y: 60)
            for i in stride(from: CGFloat(54), through: 10, by: -8) {
                Draw.circle(ctx, c, i, a.corPrimaria.withAlphaComponent(0.16))
            }
            Draw.circle(ctx, c, 30, a.corSecundaria.withAlphaComponent(0.8))
            Draw.circle(ctx, c, 20, Palette.parchment.withAlphaComponent(0.9))
            for i in 0..<10 {
                let ang = Double(i) / 10 * .pi * 2
                Draw.line(ctx, from: CGPoint(x: c.x + CGFloat(cos(ang)) * 32,
                                             y: c.y + CGFloat(sin(ang)) * 32),
                          to: CGPoint(x: c.x + CGFloat(cos(ang)) * 48,
                                      y: c.y + CGFloat(sin(ang)) * 48),
                          width: 4, a.corPrimaria)
            }
        }
        cache[chave] = t
        return t
    }

    /// Placa de interruptor do puzzle.
    static func interruptor(_ ligado: Bool) -> SKTexture {
        let chave = "sw_\(ligado)"
        if let t = cache[chave] { return t }
        let t = Draw.texture(width: 56, height: 44) { ctx in
            Draw.ellipse(ctx, CGRect(x: 2, y: 8, width: 52, height: 32),
                         SKColor(hex: 0x3A342A))
            Draw.ellipse(ctx, CGRect(x: 6, y: ligado ? 14 : 6, width: 44, height: 26),
                         ligado ? Palette.essence : SKColor(hex: 0x6A6458))
            if ligado {
                Draw.ellipse(ctx, CGRect(x: 14, y: 19, width: 28, height: 14),
                             Palette.essence.lighter(0.35))
            }
        }
        cache[chave] = t
        return t
    }
}
