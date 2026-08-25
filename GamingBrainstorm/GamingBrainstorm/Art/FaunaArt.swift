//
//  FaunaArt.swift
//  Guardiões dos Biomas
//
//  Cinco arquétipos de corpo parametrizados por cor e proporção. É o que
//  permite quinze espécies distintas sem quinze rotinas de desenho.
//

import SpriteKit
import AppKit

enum FaunaArt {

    static let canvas: CGFloat = 64
    private static var cache: [String: [SKTexture]] = [:]
    private static var imagens: [String: NSImage] = [:]

    /// Dois quadros por espécie: respiração e passo. Fauna de fundo não precisa
    /// de mais, e assim o custo de memória fica desprezível.
    static func quadros(_ spec: FaunaSpec) -> [SKTexture] {
        if let q = cache[spec.id] { return q }
        let q = (0..<4).map { i -> SKTexture in
            let t = CGFloat(i) / 4
            return Draw.texture(width: Int(canvas), height: Int(canvas)) { ctx in
                desenhar(spec, fase: sin(t * .pi * 2), ctx)
            }
        }
        cache[spec.id] = q
        return q
    }

    static func retrato(_ spec: FaunaSpec) -> NSImage {
        if let i = imagens[spec.id] { return i }
        guard let cg = Draw.cgImage(width: Int(canvas), height: Int(canvas), { ctx in
            desenhar(spec, fase: 0.3, ctx)
        }) else { return NSImage(size: .zero) }
        let img = NSImage(cgImage: cg, size: NSSize(width: canvas, height: canvas))
        imagens[spec.id] = img
        return img
    }

    /// Entrada pública, usada pelas ferramentas de pré-visualização.
    static func desenharPublico(_ s: FaunaSpec, fase: CGFloat, _ ctx: CGContext) {
        desenhar(s, fase: fase, ctx)
    }

    private static func desenhar(_ s: FaunaSpec, fase: CGFloat, _ ctx: CGContext) {
        let cx = canvas / 2
        Draw.shadow(ctx, center: CGPoint(x: cx, y: canvas - 10), w: 30 * s.escala, h: 10, alpha: 0.20)
        Draw.transformed(ctx, pivot: CGPoint(x: cx, y: canvas - 12),
                         scaleX: s.escala, scaleY: s.escala) { c in
            switch s.corpo {
            case .quadrupede: quadrupede(c, s, fase)
            case .ave: ave(c, s, fase)
            case .reptil: reptil(c, s, fase)
            case .aquatico: aquatico(c, s, fase)
            case .pendurado: pendurado(c, s, fase)
            }
        }
    }

    // MARK: Arquétipos

    private static func quadrupede(_ ctx: CGContext, _ s: FaunaSpec, _ f: CGFloat) {
        let cx = canvas / 2
        // Patas em oposição
        for (i, dx) in [CGFloat(-11), -4, 4, 11].enumerated() {
            let fase = i % 2 == 0 ? f : -f
            Draw.roundRect(ctx, CGRect(x: cx + dx - 2.5 + fase * 3, y: 40,
                                       width: 5, height: 16), radius: 2.5, s.corB)
        }
        // Cauda
        Draw.line(ctx, from: CGPoint(x: cx + 14, y: 36),
                  to: CGPoint(x: cx + 24, y: 26 - f * 4), width: 5, s.corA)
        // Corpo e cabeça
        Draw.ellipse(ctx, CGRect(x: cx - 17, y: 26, width: 34, height: 20), s.corA)
        Draw.ellipse(ctx, CGRect(x: cx - 12, y: 32, width: 22, height: 12), s.corA.lighter(0.10))
        Draw.roundRect(ctx, CGRect(x: cx - 20, y: 18, width: 14, height: 14), radius: 6, s.corA)
        // Focinho: o do tamanduá é um tubo, e é isso que o identifica.
        let focinho: CGFloat = s.traco == .focinhoLongo ? 20 : 10
        Draw.roundRect(ctx, CGRect(x: cx - 17 - focinho, y: 23, width: focinho, height: 7),
                       radius: 3.5, s.corB)
        // Orelha e olho
        Draw.polygon(ctx, [CGPoint(x: cx - 16, y: 20), CGPoint(x: cx - 19, y: 11),
                           CGPoint(x: cx - 10, y: 18)], s.corB)
        Draw.circle(ctx, CGPoint(x: cx - 16, y: 24), 1.8, SKColor(hex: 0x14100C))
        Draw.circle(ctx, CGPoint(x: cx - 17 - focinho + 3, y: 26), 1.4, s.corDetalhe)
        if s.traco == .focinhoLongo {
            // Faixa clara diagonal do bandeira
            Draw.line(ctx, from: CGPoint(x: cx - 12, y: 28), to: CGPoint(x: cx + 10, y: 40),
                      width: 4, s.corDetalhe.withAlphaComponent(0.85))
        }
    }

    private static func ave(_ ctx: CGContext, _ s: FaunaSpec, _ f: CGFloat) {
        let cx = canvas / 2
        // Pernas longas
        Draw.line(ctx, from: CGPoint(x: cx - 3, y: 40), to: CGPoint(x: cx - 5 + f * 3, y: 56),
                  width: 2.6, s.corDetalhe)
        Draw.line(ctx, from: CGPoint(x: cx + 3, y: 40), to: CGPoint(x: cx + 5 - f * 3, y: 56),
                  width: 2.6, s.corDetalhe)
        // Cauda e corpo
        Draw.polygon(ctx, [CGPoint(x: cx + 8, y: 30), CGPoint(x: cx + 22, y: 34),
                           CGPoint(x: cx + 8, y: 40)], s.corB)
        Draw.ellipse(ctx, CGRect(x: cx - 13, y: 22, width: 28, height: 22), s.corA)
        // Asa dobrada
        Draw.leaf(ctx, from: CGPoint(x: cx - 6, y: 26), to: CGPoint(x: cx + 12, y: 38),
                  bulge: 5, s.corB)
        // Pescoço: comprido na ema e no tuiuiú, curto no resto.
        let alturaCabeca: CGFloat = s.traco == .pescocoLongo ? 4 : 13
        Draw.line(ctx, from: CGPoint(x: cx - 6, y: 26),
                  to: CGPoint(x: cx - 10, y: alturaCabeca + f * 2), width: 6, s.corA)
        Draw.circle(ctx, CGPoint(x: cx - 11, y: alturaCabeca - 2 + f * 2), 7, s.corA)

        // Bico: o do tucano é quase metade do corpo — é a espécie inteira nele.
        let comprimento: CGFloat = s.traco == .bicoGrande ? 24 : 12
        let espessura: CGFloat = s.traco == .bicoGrande ? 9 : 3
        let by = alturaCabeca - 4 + f * 2
        Draw.polygon(ctx, [CGPoint(x: cx - 15, y: by),
                           CGPoint(x: cx - 15 - comprimento, y: by + espessura * 0.7),
                           CGPoint(x: cx - 15, y: by + espessura + 3)], s.corDetalhe)
        if s.traco == .bicoGrande {
            Draw.line(ctx, from: CGPoint(x: cx - 16, y: by + 2),
                      to: CGPoint(x: cx - 15 - comprimento + 3, y: by + espessura * 0.7),
                      width: 1.6, s.corDetalhe.darker(0.35))
        }
        Draw.circle(ctx, CGPoint(x: cx - 12, y: alturaCabeca - 4 + f * 2), 1.6,
                    SKColor(hex: 0x14100C))
    }

    private static func reptil(_ ctx: CGContext, _ s: FaunaSpec, _ f: CGFloat) {
        let cx = canvas / 2
        // Patas curtas abertas
        for dx in [CGFloat(-13), 9] {
            for dy in [CGFloat(0), 10] {
                Draw.roundRect(ctx, CGRect(x: cx + dx, y: 34 + dy, width: 9, height: 5),
                               radius: 2.5, s.corB)
            }
        }
        // Cauda ondulando
        Draw.polygon(ctx, [CGPoint(x: cx + 12, y: 32), CGPoint(x: cx + 30, y: 36 + f * 5),
                           CGPoint(x: cx + 12, y: 40)], s.corA)
        // Corpo baixo e comprido
        Draw.roundRect(ctx, CGRect(x: cx - 18, y: 28, width: 32, height: 16), radius: 7, s.corA)
        for i in 0..<4 {
            Draw.polygon(ctx, [CGPoint(x: cx - 12 + CGFloat(i) * 7, y: 28),
                               CGPoint(x: cx - 9 + CGFloat(i) * 7, y: 22),
                               CGPoint(x: cx - 6 + CGFloat(i) * 7, y: 28)], s.corB)
        }
        // Cabeça
        Draw.roundRect(ctx, CGRect(x: cx - 28, y: 30, width: 15, height: 11), radius: 4, s.corA)
        Draw.circle(ctx, CGPoint(x: cx - 22, y: 30), 2.2, s.corDetalhe)
        Draw.circle(ctx, CGPoint(x: cx - 22, y: 30), 1.1, SKColor(hex: 0x14100C))
    }

    private static func aquatico(_ ctx: CGContext, _ s: FaunaSpec, _ f: CGFloat) {
        let cx = canvas / 2
        // Só o dorso aparece acima da linha d'água.
        Draw.ellipse(ctx, CGRect(x: cx - 24, y: 30 + f * 2, width: 48, height: 16), s.corA)
        Draw.ellipse(ctx, CGRect(x: cx - 16, y: 32 + f * 2, width: 30, height: 9),
                     s.corDetalhe.withAlphaComponent(0.6))
        // Nadadeira dorsal baixa e cauda
        Draw.leaf(ctx, from: CGPoint(x: cx - 4, y: 30 + f * 2), to: CGPoint(x: cx + 6, y: 22 + f * 3),
                  bulge: 4, s.corB)
        Draw.polygon(ctx, [CGPoint(x: cx + 20, y: 32 + f * 2), CGPoint(x: cx + 32, y: 26 + f * 4),
                           CGPoint(x: cx + 32, y: 40 + f * 4)], s.corB)
        // Bico longo característico
        Draw.roundRect(ctx, CGRect(x: cx - 30, y: 34 + f * 2, width: 13, height: 5),
                       radius: 2.5, s.corA)
        Draw.circle(ctx, CGPoint(x: cx - 17, y: 33 + f * 2), 1.5, SKColor(hex: 0x14100C))
        // Marola
        Draw.line(ctx, from: CGPoint(x: cx - 28, y: 47), to: CGPoint(x: cx + 26, y: 47),
                  width: 2, SKColor(white: 1, alpha: 0.25))
    }

    private static func pendurado(_ ctx: CGContext, _ s: FaunaSpec, _ f: CGFloat) {
        let cx = canvas / 2
        // Galho
        Draw.line(ctx, from: CGPoint(x: cx - 26, y: 14), to: CGPoint(x: cx + 26, y: 12),
                  width: 5, SKColor(hex: 0x4A3A28))
        // Braços agarrados
        Draw.line(ctx, from: CGPoint(x: cx - 8, y: 26), to: CGPoint(x: cx - 12, y: 14),
                  width: 5, s.corA)
        Draw.line(ctx, from: CGPoint(x: cx + 8, y: 26), to: CGPoint(x: cx + 12, y: 13),
                  width: 5, s.corA)
        // Corpo pendurado, balançando devagar
        let balanco = f * 2
        Draw.ellipse(ctx, CGRect(x: cx - 13 + balanco, y: 22, width: 26, height: 26), s.corA)
        Draw.ellipse(ctx, CGRect(x: cx - 8 + balanco, y: 28, width: 16, height: 16),
                     s.corDetalhe.withAlphaComponent(0.55))
        Draw.circle(ctx, CGPoint(x: cx + balanco, y: 44), 9, s.corA)
        Draw.ellipse(ctx, CGRect(x: cx - 6 + balanco, y: 42, width: 12, height: 10), s.corB)
        Draw.circle(ctx, CGPoint(x: cx - 3 + balanco, y: 44), 1.5, SKColor(hex: 0x14100C))
        Draw.circle(ctx, CGPoint(x: cx + 3 + balanco, y: 44), 1.5, SKColor(hex: 0x14100C))
    }
}
