//
//  Planta.swift
//  Guardiões dos Biomas
//
//  A planta do santuário — o que a Planta e a Bússola revelam. Sem a Planta
//  só aparece o que você já pisou; com ela, o desenho inteiro; com a Bússola,
//  o que há dentro de cada sala.
//

import SpriteKit
import AppKit

enum PlantaArt {

    private static let celula: CGFloat = 54
    private static let vao: CGFloat = 16

    static func imagem(santuario s: Santuario, estado: GameState, bioma: BiomeID) -> NSImage {
        let xs = s.salas.keys.map { $0.x }, ys = s.salas.keys.map { $0.y }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max() else { return NSImage(size: .zero) }

        let cols = maxX - minX + 1, rows = maxY - minY + 1
        let w = CGFloat(cols) * (celula + vao) + vao
        let h = CGFloat(rows) * (celula + vao) + vao
        let temMapa = estado.temMapa(bioma)
        let temBussola = estado.temBussola(bioma)
        let p = Biome[bioma].palette

        guard let cg = Draw.cgImage(width: Int(w), height: Int(h), { ctx in
            Draw.fill(ctx, CGRect(x: 0, y: 0, width: w, height: h), SKColor(hex: 0x0E1210))

            func retangulo(_ c: GridPoint) -> CGRect {
                // Y do mundo cresce para cima; o da imagem, para baixo.
                CGRect(x: vao + CGFloat(c.x - minX) * (celula + vao),
                       y: vao + CGFloat(maxY - c.y) * (celula + vao),
                       width: celula, height: celula)
            }

            for (coord, sala) in s.salas {
                let visitada = estado.salaVisitada(bioma, coord)
                guard visitada || temMapa else { continue }
                let r = retangulo(coord)

                // Ligações entre salas, com a cara da porta
                for (d, tipo) in sala.portas {
                    let viz = GridPoint(x: coord.x + d.passo.x, y: coord.y + d.passo.y)
                    guard s.salas[viz] != nil else { continue }
                    let cor: SKColor
                    switch tipo {
                    case .trancada: cor = Palette.gold
                    case .selada: cor = Biome[bioma].animal.corPrimaria
                    case .doGuardiao: cor = Palette.danger
                    default: cor = p.rock.lighter(0.2)
                    }
                    let esp: CGFloat = tipo == .aberta || tipo == .fechada ? 5 : 8
                    switch d {
                    case .norte: Draw.fill(ctx, CGRect(x: r.midX - esp/2, y: r.minY - vao,
                                                       width: esp, height: vao + 2), cor)
                    case .sul: Draw.fill(ctx, CGRect(x: r.midX - esp/2, y: r.maxY - 2,
                                                     width: esp, height: vao + 2), cor)
                    case .leste: Draw.fill(ctx, CGRect(x: r.maxX - 2, y: r.midY - esp/2,
                                                       width: vao + 2, height: esp), cor)
                    case .oeste: Draw.fill(ctx, CGRect(x: r.minX - vao, y: r.midY - esp/2,
                                                       width: vao + 2, height: esp), cor)
                    }
                }

                // A sala
                let preenchida = visitada
                Draw.roundRect(ctx, r, radius: 6,
                               preenchida ? p.ground.lighter(0.18)
                                          : SKColor(hex: 0x1E2620))
                Draw.roundRect(ctx, r.insetBy(dx: 3, dy: 3), radius: 4,
                               preenchida ? p.ground.lighter(0.30)
                                          : SKColor(hex: 0x232C25))

                // Conteúdo: só com a Bússola, ou se já foi visto.
                guard temBussola || visitada else { continue }
                let c = CGPoint(x: r.midX, y: r.midY)
                switch sala.conteudo {
                case .entrada:
                    Draw.polygon(ctx, [CGPoint(x: c.x, y: c.y + 10), CGPoint(x: c.x - 9, y: c.y - 6),
                                       CGPoint(x: c.x + 9, y: c.y - 6)], Palette.parchment)
                case .chefe:
                    Draw.circle(ctx, c, 12, Palette.danger)
                    Draw.circle(ctx, CGPoint(x: c.x - 4, y: c.y - 2), 3, .black)
                    Draw.circle(ctx, CGPoint(x: c.x + 4, y: c.y - 2), 3, .black)
                case .amuleto:
                    Draw.circle(ctx, c, 11, Biome[bioma].animal.corPrimaria)
                    Draw.circle(ctx, c, 6, Biome[bioma].animal.corSecundaria)
                case .bau(let t):
                    let aberto = estado.bauAberto(bioma, coord)
                    let cor: SKColor
                    switch t {
                    case .chaveDoGuardiao: cor = Palette.danger
                    case .mapa, .bussola: cor = Palette.essence
                    default: cor = Palette.gold
                    }
                    Draw.roundRect(ctx, CGRect(x: c.x - 9, y: c.y - 7, width: 18, height: 14),
                                   radius: 3, aberto ? cor.darker(0.45) : cor)
                case .chave:
                    Draw.circle(ctx, CGPoint(x: c.x, y: c.y - 4), 5, Palette.gold)
                    Draw.roundRect(ctx, CGRect(x: c.x - 2, y: c.y - 1, width: 4, height: 11),
                                   radius: 1, Palette.gold)
                case .puzzle:
                    for i in 0..<3 {
                        Draw.circle(ctx, CGPoint(x: c.x - 8 + CGFloat(i) * 8, y: c.y), 3,
                                    Palette.essence)
                    }
                case .inimigos:
                    if !estado.salaLimpa(bioma, coord) {
                        Draw.polygon(ctx, [CGPoint(x: c.x, y: c.y - 9),
                                           CGPoint(x: c.x + 8, y: c.y + 6),
                                           CGPoint(x: c.x - 8, y: c.y + 6)],
                                     Palette.danger.withAlphaComponent(0.8))
                    }
                case .vazia: break
                }
            }

            // Onde você está
            if s.salas[estado.salaAtual] != nil {
                let r = retangulo(estado.salaAtual)
                for i in 0..<3 {
                    let o = CGFloat(i) * 2
                    Draw.roundRect(ctx, r.insetBy(dx: -o, dy: -o), radius: 7,
                                   Palette.parchment.withAlphaComponent(0.0))
                }
                ctx.setStrokeColor(Palette.parchment.cgColor)
                ctx.setLineWidth(3)
                ctx.addPath(CGPath(roundedRect: r.insetBy(dx: -2, dy: -2),
                                   cornerWidth: 7, cornerHeight: 7, transform: nil))
                ctx.strokePath()
            }
        }) else { return NSImage(size: .zero) }
        return NSImage(cgImage: cg, size: NSSize(width: w, height: h))
    }
}
