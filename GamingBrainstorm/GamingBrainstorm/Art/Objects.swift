//
//  Objects.swift
//  Guardiões dos Biomas
//
//  Sprites dos elementos interativos: pontos de missão, essência, ameaças,
//  segredos, portais e placas de leitura.
//

import SpriteKit

enum Objects {

    private static var cache: [String: SKTexture] = [:]

    private static func cached(_ chave: String, _ w: Int, _ h: Int,
                               _ body: @escaping (CGContext) -> Void) -> SKTexture {
        if let t = cache[chave] { return t }
        let t = Draw.texture(width: w, height: h, body)
        cache[chave] = t
        return t
    }

    // MARK: - Pontos de missão

    static func objetivo(_ kind: ObjectiveKind, bioma: BiomeID) -> SKTexture {
        cached("obj_\(kind.rawValue)_\(bioma.rawValue)", 52, 52) { ctx in
            desenharObjetivo(ctx, kind: kind, bioma: bioma)
        }
    }

    static func desenharObjetivo(_ ctx: CGContext, kind: ObjectiveKind, bioma: BiomeID) {
        let p = Biome[bioma].palette
        let c = CGPoint(x: 26, y: 26)
        // Halo suave para o ponto se destacar na vegetação.
        Draw.circle(ctx, c, 24, p.accent.withAlphaComponent(0.12))
        Draw.circle(ctx, c, 17, p.accent.withAlphaComponent(0.20))
        switch kind {
        case .rastro: pegada(ctx, c: c, cor: p.accent)
        case .resgate: gaiola(ctx, c: c)
        case .restauro: muda(ctx, c: c, palette: p)
        case .ameaca: alerta(ctx, c: c)
        case .desafio: desafio(ctx, c: c, bioma: bioma, palette: p)
        case .corrida: largada(ctx, c: c, palette: p)
        case .acesso: pegada(ctx, c: c, cor: p.accent)
        }
    }

    /// Largada da prova arcade: pórtico com bandeira quadriculada.
    private static func largada(_ ctx: CGContext, c: CGPoint, palette p: BiomePalette) {
        Draw.roundRect(ctx, CGRect(x: c.x - 17, y: c.y - 4, width: 5, height: 20),
                       radius: 2, SKColor(hex: 0x6A4E2E))
        Draw.roundRect(ctx, CGRect(x: c.x + 12, y: c.y - 4, width: 5, height: 20),
                       radius: 2, SKColor(hex: 0x6A4E2E))
        Draw.roundRect(ctx, CGRect(x: c.x - 18, y: c.y - 14, width: 36, height: 12),
                       radius: 2, SKColor(hex: 0xF0EAE0))
        for linha in 0..<2 {
            for col in 0..<6 where (col + linha) % 2 == 0 {
                Draw.fill(ctx, CGRect(x: c.x - 18 + CGFloat(col) * 6,
                                      y: c.y - 14 + CGFloat(linha) * 6,
                                      width: 6, height: 6), SKColor(hex: 0x1E1E22))
            }
        }
        // Setas de velocidade
        for i in 0..<3 {
            let x = c.x - 8 + CGFloat(i) * 8
            Draw.polygon(ctx, [CGPoint(x: x, y: c.y + 6), CGPoint(x: x + 5, y: c.y + 11),
                               CGPoint(x: x, y: c.y + 16)], p.accent)
        }
    }

    /// Marca do desafio característico de cada bioma — cada um com o seu ícone.
    private static func desafio(_ ctx: CGContext, c: CGPoint,
                                bioma: BiomeID, palette p: BiomePalette) {
        switch bioma {
        case .mataAtlantica:
            // Comitiva: três vultos numa linha, sobre um galho.
            Draw.line(ctx, from: CGPoint(x: c.x - 15, y: c.y + 8),
                      to: CGPoint(x: c.x + 15, y: c.y + 6), width: 3, SKColor(hex: 0x4A3A28))
            for (i, dx) in [CGFloat(-9), 0, 9].enumerated() {
                let dy = CGFloat(i) * -1.5
                Draw.circle(ctx, CGPoint(x: c.x + dx, y: c.y + dy), 5.2, SKColor(hex: 0xE8952C))
                Draw.circle(ctx, CGPoint(x: c.x + dx, y: c.y - 3 + dy), 3.4, SKColor(hex: 0xF6C860))
            }
        case .cerrado:
            // Aceiro: chama cortada por uma faixa de terra nua.
            Draw.polygon(ctx, [CGPoint(x: c.x, y: c.y - 14), CGPoint(x: c.x + 10, y: c.y + 6),
                               CGPoint(x: c.x - 10, y: c.y + 6)], SKColor(hex: 0xE8541E))
            Draw.polygon(ctx, [CGPoint(x: c.x, y: c.y - 5), CGPoint(x: c.x + 5, y: c.y + 6),
                               CGPoint(x: c.x - 5, y: c.y + 6)], SKColor(hex: 0xF6D24E))
            Draw.roundRect(ctx, CGRect(x: c.x - 16, y: c.y + 7, width: 32, height: 6),
                           radius: 3, SKColor(hex: 0x7A5A34))
        case .pantanal:
            // Ninho com ovos no oco.
            Draw.ellipse(ctx, CGRect(x: c.x - 14, y: c.y - 2, width: 28, height: 16),
                         SKColor(hex: 0x6A4E2E))
            Draw.ellipse(ctx, CGRect(x: c.x - 10, y: c.y, width: 20, height: 10),
                         SKColor(hex: 0x4A3524))
            Draw.circle(ctx, CGPoint(x: c.x - 4, y: c.y + 3), 3.4, SKColor(hex: 0xF0EAD8))
            Draw.circle(ctx, CGPoint(x: c.x + 4, y: c.y + 4), 3.4, SKColor(hex: 0xF0EAD8))
            Draw.circle(ctx, CGPoint(x: c.x, y: c.y - 8), 4, SKColor(hex: 0x2F6FD8))
        case .amazonia:
            // Malha de rede sob a linha d'água.
            Draw.line(ctx, from: CGPoint(x: c.x - 16, y: c.y - 11),
                      to: CGPoint(x: c.x + 16, y: c.y - 11), width: 2, SKColor(hex: 0x9AD8E0))
            ctx.setStrokeColor(SKColor(hex: 0xE0ECE8, alpha: 0.9).cgColor)
            ctx.setLineWidth(1.5)
            for i in 0...4 {
                let x = c.x - 14 + CGFloat(i) * 7
                ctx.move(to: CGPoint(x: x, y: c.y - 6)); ctx.addLine(to: CGPoint(x: x, y: c.y + 12))
            }
            for i in 0...3 {
                let y = c.y - 6 + CGFloat(i) * 6
                ctx.move(to: CGPoint(x: c.x - 14, y: y)); ctx.addLine(to: CGPoint(x: c.x + 14, y: y))
            }
            ctx.strokePath()
        case .pampa:
            // Lâmina do arado sobre galerias.
            Draw.polygon(ctx, [CGPoint(x: c.x - 14, y: c.y - 10), CGPoint(x: c.x + 14, y: c.y - 10),
                               CGPoint(x: c.x + 6, y: c.y)], SKColor(hex: 0x9AA0A6))
            Draw.roundRect(ctx, CGRect(x: c.x - 16, y: c.y + 2, width: 32, height: 5),
                           radius: 2.5, SKColor(hex: 0xC6B584))
            for dx in [CGFloat(-8), 2] {
                ctx.setStrokeColor(SKColor(hex: 0x5E4A32).cgColor)
                ctx.setLineWidth(3)
                ctx.move(to: CGPoint(x: c.x + dx, y: c.y + 14))
                ctx.addQuadCurve(to: CGPoint(x: c.x + dx + 10, y: c.y + 8),
                                 control: CGPoint(x: c.x + dx + 3, y: c.y + 15))
                ctx.strokePath()
            }
        case .refugio:
            alerta(ctx, c: c)
        }
        _ = p
    }

    private static func pegada(_ ctx: CGContext, c: CGPoint, cor: SKColor) {
        // Sombra deslocada + marca clara: a pegada precisa saltar sobre solo escuro.
        let sombra = SKColor(hex: 0x14100C, alpha: 0.55)
        let marca = Palette.parchment
        for (off, tinta) in [(CGPoint(x: 1.5, y: 2), sombra), (.zero, marca)] {
            Draw.ellipse(ctx, CGRect(x: c.x - 7 + off.x, y: c.y - 1 + off.y,
                                     width: 14, height: 12), tinta)
            for dx in [CGFloat(-8), -3, 3, 8] {
                let dy: CGFloat = abs(dx) > 5 ? -4 : -7
                Draw.circle(ctx, CGPoint(x: c.x + dx + off.x, y: c.y + dy + off.y), 2.8, tinta)
            }
        }
        Draw.circle(ctx, CGPoint(x: c.x, y: c.y + 3), 3.2, cor)
    }

    private static func gaiola(_ ctx: CGContext, c: CGPoint) {
        let madeira = SKColor(hex: 0x6A4E2E)
        Draw.roundRect(ctx, CGRect(x: c.x - 13, y: c.y - 12, width: 26, height: 24), radius: 3, madeira)
        Draw.roundRect(ctx, CGRect(x: c.x - 10, y: c.y - 9, width: 20, height: 18), radius: 2,
                       SKColor(hex: 0x2A2418))
        for i in 0..<4 {
            let x = c.x - 9 + CGFloat(i) * 6
            Draw.line(ctx, from: CGPoint(x: x, y: c.y - 10), to: CGPoint(x: x, y: c.y + 9),
                      width: 2, madeira.lighter(0.18))
        }
        Draw.circle(ctx, CGPoint(x: c.x, y: c.y + 13), 3.2, SKColor(hex: 0xB0B0B8)) // cadeado
    }

    private static func muda(_ ctx: CGContext, c: CGPoint, palette p: BiomePalette) {
        Draw.ellipse(ctx, CGRect(x: c.x - 13, y: c.y + 4, width: 26, height: 12), SKColor(hex: 0x5A4630))
        Draw.line(ctx, from: CGPoint(x: c.x, y: c.y + 8), to: CGPoint(x: c.x, y: c.y - 8),
                  width: 2.6, SKColor(hex: 0x4E7A34))
        Draw.leaf(ctx, from: CGPoint(x: c.x, y: c.y - 2), to: CGPoint(x: c.x - 12, y: c.y - 9),
                  bulge: 5, p.foliage.lighter(0.10))
        Draw.leaf(ctx, from: CGPoint(x: c.x, y: c.y - 5), to: CGPoint(x: c.x + 12, y: c.y - 12),
                  bulge: 5, p.foliage)
    }

    private static func alerta(_ ctx: CGContext, c: CGPoint) {
        Draw.polygon(ctx, [CGPoint(x: c.x, y: c.y - 14), CGPoint(x: c.x + 14, y: c.y + 10),
                           CGPoint(x: c.x - 14, y: c.y + 10)], SKColor(hex: 0xE8B23A))
        Draw.polygon(ctx, [CGPoint(x: c.x, y: c.y - 9), CGPoint(x: c.x + 10, y: c.y + 7),
                           CGPoint(x: c.x - 10, y: c.y + 7)], SKColor(hex: 0x2A2010))
        Draw.roundRect(ctx, CGRect(x: c.x - 1.5, y: c.y - 5, width: 3, height: 8), radius: 1.5,
                       SKColor(hex: 0xE8B23A))
        Draw.circle(ctx, CGPoint(x: c.x, y: c.y + 5), 1.8, SKColor(hex: 0xE8B23A))
    }

    // MARK: - Essência

    static func essencia() -> SKTexture {
        cached("essencia", 40, 40) { ctx in
            let c = CGPoint(x: 20, y: 20)
            Draw.circle(ctx, c, 18, Palette.essence.withAlphaComponent(0.10))
            Draw.circle(ctx, c, 13, Palette.essence.withAlphaComponent(0.22))
            Draw.circle(ctx, c, 8, Palette.essence)
            Draw.circle(ctx, CGPoint(x: c.x - 2.5, y: c.y - 3), 2.8, .white)
        }
    }

    // MARK: - Ameaças

    static func ameaca(_ kind: HazardKind) -> SKTexture {
        cached("ameaca_\(kind.rawValue)", 64, 64) { ctx in
            desenharAmeaca(ctx, kind: kind)
        }
    }

    static func desenharAmeaca(_ ctx: CGContext, kind: HazardKind) {
        let c = CGPoint(x: 32, y: 34)
        Draw.shadow(ctx, center: CGPoint(x: 32, y: 54), w: 34, h: 12)
        switch kind {
        case .queimada: fogo(ctx, c: c)
        case .desmatamento: motosserra(ctx, c: c)
        case .trafico: cacador(ctx, c: c)
        case .pescaIlegal: rede(ctx, c: c)
        case .monocultura: maquina(ctx, c: c)
        case .nenhuma: break
        }
    }

    private static func fogo(_ ctx: CGContext, c: CGPoint) {
        Draw.polygon(ctx, [CGPoint(x: c.x, y: c.y - 22), CGPoint(x: c.x + 15, y: c.y + 16),
                           CGPoint(x: c.x - 15, y: c.y + 16)], SKColor(hex: 0xE8541E))
        Draw.polygon(ctx, [CGPoint(x: c.x + 2, y: c.y - 12), CGPoint(x: c.x + 11, y: c.y + 16),
                           CGPoint(x: c.x - 8, y: c.y + 16)], SKColor(hex: 0xF2903A))
        Draw.polygon(ctx, [CGPoint(x: c.x - 1, y: c.y - 2), CGPoint(x: c.x + 5, y: c.y + 16),
                           CGPoint(x: c.x - 7, y: c.y + 16)], SKColor(hex: 0xF6D24E))
        Draw.ellipse(ctx, CGRect(x: c.x - 17, y: c.y + 12, width: 34, height: 10),
                     SKColor(hex: 0x2A1810, alpha: 0.6))
    }

    private static func motosserra(_ ctx: CGContext, c: CGPoint) {
        Draw.roundRect(ctx, CGRect(x: c.x - 16, y: c.y - 4, width: 20, height: 16), radius: 4,
                       SKColor(hex: 0xC8442E))
        Draw.roundRect(ctx, CGRect(x: c.x + 2, y: c.y + 1, width: 22, height: 6), radius: 3,
                       SKColor(hex: 0xB0B4BA))
        for i in 0..<7 {
            let x = c.x + 4 + CGFloat(i) * 3
            Draw.polygon(ctx, [CGPoint(x: x, y: c.y + 1), CGPoint(x: x + 2, y: c.y + 1),
                               CGPoint(x: x + 1, y: c.y - 2)], SKColor(hex: 0xE0E4EA))
        }
        Draw.roundRect(ctx, CGRect(x: c.x - 14, y: c.y - 12, width: 5, height: 10), radius: 2.5,
                       SKColor(hex: 0x2A2620))
        // Toco cortado
        Draw.ellipse(ctx, CGRect(x: c.x - 10, y: c.y + 12, width: 22, height: 10), SKColor(hex: 0x8A6A42))
    }

    private static func cacador(_ ctx: CGContext, c: CGPoint) {
        Draw.roundRect(ctx, CGRect(x: c.x - 9, y: c.y + 6, width: 7, height: 16), radius: 3, SKColor(hex: 0x3A3428))
        Draw.roundRect(ctx, CGRect(x: c.x + 2, y: c.y + 6, width: 7, height: 16), radius: 3, SKColor(hex: 0x3A3428))
        Draw.roundRect(ctx, CGRect(x: c.x - 12, y: c.y - 10, width: 24, height: 22), radius: 8, SKColor(hex: 0x54503E))
        Draw.circle(ctx, CGPoint(x: c.x, y: c.y - 15), 10, SKColor(hex: 0x9A7048))
        Draw.ellipse(ctx, CGRect(x: c.x - 14, y: c.y - 24, width: 28, height: 10), SKColor(hex: 0x2E2A20))
        // Gaiola de transporte na mão
        Draw.roundRect(ctx, CGRect(x: c.x + 10, y: c.y + 2, width: 16, height: 14), radius: 2, SKColor(hex: 0x6A5A3A))
        for i in 0..<3 {
            Draw.line(ctx, from: CGPoint(x: c.x + 13 + CGFloat(i) * 5, y: c.y + 3),
                      to: CGPoint(x: c.x + 13 + CGFloat(i) * 5, y: c.y + 15), width: 1.6, SKColor(hex: 0x2A2418))
        }
    }

    private static func rede(_ ctx: CGContext, c: CGPoint) {
        Draw.roundRect(ctx, CGRect(x: c.x - 22, y: c.y - 14, width: 44, height: 30), radius: 4,
                       SKColor(hex: 0x1E3A42, alpha: 0.55))
        ctx.setStrokeColor(SKColor(hex: 0xD8E4E0, alpha: 0.85).cgColor)
        ctx.setLineWidth(1.4)
        for i in 0...6 {
            let x = c.x - 21 + CGFloat(i) * 7
            ctx.move(to: CGPoint(x: x, y: c.y - 14)); ctx.addLine(to: CGPoint(x: x, y: c.y + 16))
        }
        for i in 0...4 {
            let y = c.y - 14 + CGFloat(i) * 7.5
            ctx.move(to: CGPoint(x: c.x - 22, y: y)); ctx.addLine(to: CGPoint(x: c.x + 22, y: y))
        }
        ctx.strokePath()
        // Boias
        Draw.circle(ctx, CGPoint(x: c.x - 14, y: c.y - 16), 4, SKColor(hex: 0xE8541E))
        Draw.circle(ctx, CGPoint(x: c.x + 6, y: c.y - 16), 4, SKColor(hex: 0xE8541E))
    }

    private static func maquina(_ ctx: CGContext, c: CGPoint) {
        Draw.roundRect(ctx, CGRect(x: c.x - 20, y: c.y - 12, width: 34, height: 20), radius: 4,
                       SKColor(hex: 0x2E7A3E))
        Draw.roundRect(ctx, CGRect(x: c.x - 6, y: c.y - 22, width: 18, height: 14), radius: 3,
                       SKColor(hex: 0x1E5A2E))
        Draw.roundRect(ctx, CGRect(x: c.x - 3, y: c.y - 19, width: 12, height: 8), radius: 2,
                       SKColor(hex: 0x9AC8D8))
        Draw.circle(ctx, CGPoint(x: c.x - 12, y: c.y + 10), 9, SKColor(hex: 0x24201A))
        Draw.circle(ctx, CGPoint(x: c.x - 12, y: c.y + 10), 4, SKColor(hex: 0x8A8A82))
        Draw.circle(ctx, CGPoint(x: c.x + 10, y: c.y + 12), 6, SKColor(hex: 0x24201A))
        // Arado revirando a terra
        Draw.polygon(ctx, [CGPoint(x: c.x + 14, y: c.y + 2), CGPoint(x: c.x + 26, y: c.y + 8),
                           CGPoint(x: c.x + 14, y: c.y + 14)], SKColor(hex: 0x8A8A82))
    }

    // MARK: - Segredo

    static func segredo(revelado: Bool) -> SKTexture {
        cached("segredo_\(revelado)", 48, 48) { ctx in
            let c = CGPoint(x: 24, y: 26)
            if revelado {
                Draw.circle(ctx, c, 22, Palette.gold.withAlphaComponent(0.14))
                Draw.circle(ctx, c, 14, Palette.gold.withAlphaComponent(0.28))
            }
            Draw.ellipse(ctx, CGRect(x: c.x - 16, y: c.y - 2, width: 32, height: 16),
                         SKColor(hex: 0x6A5A3E))
            Draw.ellipse(ctx, CGRect(x: c.x - 11, y: c.y - 5, width: 22, height: 12),
                         SKColor(hex: 0x8A7A54))
            if revelado {
                Draw.roundRect(ctx, CGRect(x: c.x - 8, y: c.y - 14, width: 16, height: 12),
                               radius: 3, SKColor(hex: 0x8A6A3E))
                Draw.roundRect(ctx, CGRect(x: c.x - 8, y: c.y - 9, width: 16, height: 3),
                               radius: 1, Palette.gold)
            }
        }
    }

    // MARK: - Portal

    static func portal(_ id: BiomeID) -> SKTexture {
        let p = Biome[id].palette
        return cached("portal_\(id.rawValue)", 120, 150) { ctx in
            let cx: CGFloat = 60
            Draw.shadow(ctx, center: CGPoint(x: cx, y: 138), w: 84, h: 20, alpha: 0.3)
            // Arco de pedra
            Draw.roundRect(ctx, CGRect(x: cx - 46, y: 24, width: 20, height: 114), radius: 8,
                           SKColor(hex: 0x6E6858))
            Draw.roundRect(ctx, CGRect(x: cx + 26, y: 24, width: 20, height: 114), radius: 8,
                           SKColor(hex: 0x6E6858))
            Draw.roundRect(ctx, CGRect(x: cx - 50, y: 10, width: 100, height: 24), radius: 12,
                           SKColor(hex: 0x7E7866))
            // Portal em si: a cor do bioma de destino
            Draw.ellipse(ctx, CGRect(x: cx - 28, y: 34, width: 56, height: 100),
                         p.foliage.withAlphaComponent(0.85))
            Draw.ellipse(ctx, CGRect(x: cx - 20, y: 44, width: 40, height: 80),
                         p.grass.withAlphaComponent(0.9))
            Draw.ellipse(ctx, CGRect(x: cx - 11, y: 58, width: 22, height: 52),
                         p.accent.withAlphaComponent(0.75))
            // Musgo nas pedras
            for i in 0..<6 {
                let y = 34 + CGFloat(i) * 17
                Draw.circle(ctx, CGPoint(x: cx - 40 + CGFloat(i % 2) * 4, y: y), 4,
                            p.foliage.withAlphaComponent(0.6))
                Draw.circle(ctx, CGPoint(x: cx + 40 - CGFloat(i % 2) * 4, y: y + 6), 3.4,
                            p.foliage.withAlphaComponent(0.5))
            }
        }
    }

    // MARK: - Placa

    static func placa() -> SKTexture {
        cached("placa", 64, 72) { ctx in
            Draw.shadow(ctx, center: CGPoint(x: 32, y: 66), w: 28, h: 9)
            Draw.roundRect(ctx, CGRect(x: 29, y: 30, width: 6, height: 34), radius: 2,
                           SKColor(hex: 0x5A4630))
            Draw.roundRect(ctx, CGRect(x: 8, y: 10, width: 48, height: 28), radius: 4,
                           SKColor(hex: 0x8A6A3E))
            Draw.roundRect(ctx, CGRect(x: 11, y: 13, width: 42, height: 22), radius: 3,
                           SKColor(hex: 0xB08A4E))
            for i in 0..<4 {
                let y = 17 + CGFloat(i) * 5
                Draw.line(ctx, from: CGPoint(x: 15, y: y), to: CGPoint(x: 47 - CGFloat(i % 2) * 12, y: y),
                          width: 1.6, SKColor(hex: 0x5A4630, alpha: 0.7), round: false)
            }
        }
    }
}

// MARK: - Estruturas do Refúgio

extension Objects {

    /// Canteiro do viveiro. 0 vazio · 1 brotando · 2 pronto · 3 ainda não construído.
    static func canteiro(_ etapa: Int) -> SKTexture {
        cached("canteiro_\(etapa)", 56, 56) { ctx in
            let c = CGPoint(x: 28, y: 32)
            Draw.shadow(ctx, center: CGPoint(x: 28, y: 44), w: 40, h: 12, alpha: 0.18)

            if etapa == 3 {
                // Terreno ainda por abrir: mato e estacas soltas.
                Draw.roundRect(ctx, CGRect(x: 6, y: 22, width: 44, height: 22), radius: 4,
                               SKColor(hex: 0x4A5038, alpha: 0.6))
                Draw.line(ctx, from: CGPoint(x: 10, y: 22), to: CGPoint(x: 46, y: 44),
                          width: 2, SKColor(hex: 0x6A6A5A, alpha: 0.7))
                return
            }

            // Canteiro lavrado, com moldura de madeira.
            Draw.roundRect(ctx, CGRect(x: 5, y: 20, width: 46, height: 26), radius: 4,
                           SKColor(hex: 0x6A4E2E))
            Draw.roundRect(ctx, CGRect(x: 8, y: 23, width: 40, height: 20), radius: 3,
                           SKColor(hex: 0x4A3524))
            for i in 0..<3 {
                Draw.line(ctx, from: CGPoint(x: 11, y: 27 + CGFloat(i) * 6),
                          to: CGPoint(x: 45, y: 27 + CGFloat(i) * 6),
                          width: 1.6, SKColor(hex: 0x33241A, alpha: 0.7), round: false)
            }

            switch etapa {
            case 1:
                // Broto
                Draw.line(ctx, from: CGPoint(x: c.x, y: 34), to: CGPoint(x: c.x, y: 24),
                          width: 2.2, SKColor(hex: 0x4E7A34))
                Draw.leaf(ctx, from: CGPoint(x: c.x, y: 27), to: CGPoint(x: c.x - 8, y: 22),
                          bulge: 3.5, SKColor(hex: 0x5E9440))
                Draw.leaf(ctx, from: CGPoint(x: c.x, y: 25), to: CGPoint(x: c.x + 8, y: 20),
                          bulge: 3.5, SKColor(hex: 0x6EA44C))
            case 2:
                // Muda pronta para o transplante
                Draw.line(ctx, from: CGPoint(x: c.x, y: 36), to: CGPoint(x: c.x, y: 12),
                          width: 3, SKColor(hex: 0x4A6A2E))
                Draw.circle(ctx, CGPoint(x: c.x - 7, y: 14), 8, SKColor(hex: 0x2E5A2B))
                Draw.circle(ctx, CGPoint(x: c.x + 7, y: 15), 7.5, SKColor(hex: 0x2E5A2B))
                Draw.circle(ctx, CGPoint(x: c.x, y: 9), 9, SKColor(hex: 0x3E7434))
                Draw.circle(ctx, CGPoint(x: c.x - 3, y: 6), 4, SKColor(hex: 0x56904A))
            default:
                break
            }
        }
    }

    /// Cais de pesca do açude.
    static func cais() -> SKTexture {
        cached("cais", 76, 68) { ctx in
            Draw.shadow(ctx, center: CGPoint(x: 38, y: 56), w: 52, h: 14, alpha: 0.2)
            // Tábuas
            Draw.roundRect(ctx, CGRect(x: 10, y: 26, width: 56, height: 26), radius: 3,
                           SKColor(hex: 0x7A5A38))
            for i in 0..<4 {
                Draw.line(ctx, from: CGPoint(x: 12, y: 30 + CGFloat(i) * 6),
                          to: CGPoint(x: 64, y: 30 + CGFloat(i) * 6),
                          width: 1.4, SKColor(hex: 0x5A4028, alpha: 0.8), round: false)
            }
            // Estacas
            Draw.roundRect(ctx, CGRect(x: 13, y: 48, width: 6, height: 14), radius: 2,
                           SKColor(hex: 0x5A4028))
            Draw.roundRect(ctx, CGRect(x: 57, y: 48, width: 6, height: 14), radius: 2,
                           SKColor(hex: 0x5A4028))
            // Vara de pescar encostada
            Draw.line(ctx, from: CGPoint(x: 20, y: 30), to: CGPoint(x: 58, y: 4),
                      width: 2.4, SKColor(hex: 0x8A6A3E))
            Draw.line(ctx, from: CGPoint(x: 58, y: 4), to: CGPoint(x: 64, y: 24),
                      width: 1, SKColor(white: 1, alpha: 0.55))
            Draw.circle(ctx, CGPoint(x: 64, y: 25), 3, SKColor(hex: 0xE8541E))
        }
    }

    /// Bancada da oficina de campo.
    static func oficina() -> SKTexture {
        cached("oficina", 76, 72) { ctx in
            Draw.shadow(ctx, center: CGPoint(x: 38, y: 60), w: 50, h: 14, alpha: 0.22)
            // Telhadinho
            Draw.polygon(ctx, [CGPoint(x: 6, y: 24), CGPoint(x: 70, y: 24),
                               CGPoint(x: 38, y: 4)], SKColor(hex: 0x8A4E2E))
            Draw.roundRect(ctx, CGRect(x: 10, y: 22, width: 56, height: 5), radius: 2,
                           SKColor(hex: 0x6A3A22))
            // Bancada
            Draw.roundRect(ctx, CGRect(x: 12, y: 34, width: 52, height: 10), radius: 3,
                           SKColor(hex: 0x8A6A3E))
            Draw.roundRect(ctx, CGRect(x: 15, y: 44, width: 6, height: 18), radius: 2,
                           SKColor(hex: 0x5A4028))
            Draw.roundRect(ctx, CGRect(x: 55, y: 44, width: 6, height: 18), radius: 2,
                           SKColor(hex: 0x5A4028))
            // Ferramentas
            Draw.line(ctx, from: CGPoint(x: 22, y: 34), to: CGPoint(x: 22, y: 20),
                      width: 2.4, SKColor(hex: 0x6A4E2E))
            Draw.roundRect(ctx, CGRect(x: 17, y: 15, width: 11, height: 6), radius: 2,
                           SKColor(hex: 0xB0B4BA))
            Draw.circle(ctx, CGPoint(x: 44, y: 29), 6, SKColor(hex: 0x3E7A8C))
            Draw.roundRect(ctx, CGRect(x: 50, y: 26, width: 10, height: 8), radius: 2,
                           SKColor(hex: 0xE8B23A))
        }
    }
}

// MARK: - A pena da Harpia

extension Objects {

    /// Sombra difusa de asas abertas, para o sobrevoo de abertura.
    static func sombraDeAsas() -> SKTexture {
        cached("sombra_asas", 900, 380) { ctx in
            // Corpo e asas em manchas concêntricas: dá contorno sem borda dura.
            func borrao(_ c: CGPoint, _ rx: CGFloat, _ ry: CGFloat) {
                for i in stride(from: CGFloat(1.0), through: 0.2, by: -0.16) {
                    Draw.ellipse(ctx, CGRect(x: c.x - rx * i, y: c.y - ry * i,
                                             width: rx * 2 * i, height: ry * 2 * i),
                                 SKColor(white: 0, alpha: 0.10))
                }
            }
            borrao(CGPoint(x: 450, y: 190), 90, 130)     // corpo
            borrao(CGPoint(x: 250, y: 165), 210, 62)     // asa esquerda
            borrao(CGPoint(x: 650, y: 165), 210, 62)     // asa direita
            borrao(CGPoint(x: 450, y: 300), 55, 90)      // cauda
            borrao(CGPoint(x: 450, y: 80), 45, 45)       // cabeça
        }
    }

    /// A pena que ela deixa cair.
    static func pena() -> SKTexture {
        cached("pena", 40, 96) { ctx in
            // Halo, para achar no meio do mato.
            Draw.ellipse(ctx, CGRect(x: 2, y: 14, width: 36, height: 70),
                         Palette.gold.withAlphaComponent(0.10))
            // Barbas
            Draw.leaf(ctx, from: CGPoint(x: 20, y: 8), to: CGPoint(x: 20, y: 82),
                      bulge: 13, SKColor(hex: 0x585E68))
            Draw.leaf(ctx, from: CGPoint(x: 20, y: 16), to: CGPoint(x: 20, y: 76),
                      bulge: 8, SKColor(hex: 0x6E747E))
            // Faixas claras, como as da cauda
            for i in 0..<3 {
                let y = 28 + CGFloat(i) * 17
                Draw.line(ctx, from: CGPoint(x: 10, y: y), to: CGPoint(x: 30, y: y + 3),
                          width: 2.4, SKColor(hex: 0xD9DCD8, alpha: 0.7))
            }
            // Raque
            Draw.line(ctx, from: CGPoint(x: 20, y: 6), to: CGPoint(x: 20, y: 90),
                      width: 2.2, SKColor(hex: 0xE8E4DC))
        }
    }
}

// MARK: - Sinais deixados pelo bicho

extension Objects {

    /// O vestígio que se recolhe enquanto se segue o guia. Cada bioma tem o seu.
    static func sinal(_ bioma: BiomeID) -> SKTexture {
        let p = Biome[bioma].palette
        return cached("sinal_\(bioma.rawValue)", 44, 44) { ctx in
            let c = CGPoint(x: 22, y: 22)
            Draw.circle(ctx, c, 19, p.accent.withAlphaComponent(0.13))
            Draw.circle(ctx, c, 13, p.accent.withAlphaComponent(0.22))

            switch bioma {
            case .mataAtlantica:
                // Fruto mordido
                Draw.circle(ctx, c, 9, SKColor(hex: 0xC8442E))
                Draw.circle(ctx, CGPoint(x: c.x + 6, y: c.y - 4), 5, SKColor(hex: 0x2A1E14))
                Draw.line(ctx, from: CGPoint(x: c.x, y: c.y - 8),
                          to: CGPoint(x: c.x + 3, y: c.y - 14), width: 2, SKColor(hex: 0x4A6A2E))
            case .cerrado:
                // Tufo de pelo ruivo
                for i in 0..<6 {
                    let a = Double(i) / 6 * .pi * 2
                    Draw.line(ctx, from: c,
                              to: CGPoint(x: c.x + CGFloat(cos(a)) * 11,
                                          y: c.y + CGFloat(sin(a)) * 11),
                              width: 3, SKColor(hex: 0xC96A2E))
                }
                Draw.circle(ctx, c, 4, SKColor(hex: 0x241E18))
            case .pantanal:
                // Pena azul
                Draw.leaf(ctx, from: CGPoint(x: c.x, y: c.y - 11),
                          to: CGPoint(x: c.x, y: c.y + 11), bulge: 6, SKColor(hex: 0x2F6FD8))
                Draw.line(ctx, from: CGPoint(x: c.x, y: c.y - 12),
                          to: CGPoint(x: c.x, y: c.y + 12), width: 1.6, SKColor(hex: 0xE8E4DC))
            case .amazonia:
                // Escama grande
                Draw.ellipse(ctx, CGRect(x: c.x - 9, y: c.y - 10, width: 18, height: 20),
                             SKColor(hex: 0x4E6E62))
                Draw.ellipse(ctx, CGRect(x: c.x - 6, y: c.y - 6, width: 12, height: 14),
                             SKColor(hex: 0xC24A44))
            case .pampa:
                // Montículo de areia revirada
                Draw.ellipse(ctx, CGRect(x: c.x - 12, y: c.y - 2, width: 24, height: 12),
                             SKColor(hex: 0xC6B584))
                Draw.ellipse(ctx, CGRect(x: c.x - 7, y: c.y - 6, width: 14, height: 9),
                             SKColor(hex: 0x9A8A5E))
            case .refugio:
                Draw.circle(ctx, c, 8, p.accent)
            }
        }
    }
}

// MARK: - Combate e sombras

extension Objects {

    /// Sombra elíptica genérica, usada por inimigos e objetos em pé.
    static func sombraChao() -> SKTexture {
        cached("sombra_chao", 64, 26) { ctx in
            Draw.ellipse(ctx, CGRect(x: 0, y: 0, width: 64, height: 26),
                         SKColor(white: 0, alpha: 0.32))
        }
    }

    /// Arco do golpe do bastão de campo.
    static func golpe() -> SKTexture {
        cached("golpe", 110, 96) { ctx in
            let c = CGPoint(x: 18, y: 48)
            for i in 0..<3 {
                let r = CGFloat(58 + i * 12)
                ctx.setStrokeColor(SKColor(white: 1, alpha: 0.55 - CGFloat(i) * 0.16).cgColor)
                ctx.setLineWidth(CGFloat(9 - i * 2))
                ctx.setLineCap(.round)
                ctx.addArc(center: c, radius: r, startAngle: -0.7, endAngle: 0.7, clockwise: false)
                ctx.strokePath()
            }
            ctx.setStrokeColor(Palette.parchment.withAlphaComponent(0.9).cgColor)
            ctx.setLineWidth(4)
            ctx.addArc(center: c, radius: 62, startAngle: -0.55, endAngle: 0.55, clockwise: false)
            ctx.strokePath()
        }
    }
}
