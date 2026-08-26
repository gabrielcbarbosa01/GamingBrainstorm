//
//  Creatures.swift
//  Guardiões dos Biomas
//
//  Os bichos não são imagens fixas: cada quadro é desenhado a partir de uma
//  Pose. Isso dá ciclo de caminhada, salto, investida, batida de asa e
//  escavação de verdade — tudo em código, sem nenhum arquivo de sprite.
//

import SpriteKit
import AppKit

/// Estado do corpo num instante da animação. Todo bicho lê os mesmos campos;
/// cada um interpreta do seu jeito.
struct Pose {
    /// -1..1, fase do ciclo de passos (perna esquerda à frente / atrás).
    var passo: CGFloat = 0
    /// -1 achatado (aterrissando) .. +1 esticado (impulso).
    var squash: CGFloat = 0
    /// 0 membros estendidos .. 1 membros recolhidos ao corpo (voo, salto).
    var recolhido: CGFloat = 0
    /// -1 asa embaixo .. +1 asa no alto.
    var asa: CGFloat = 0
    /// Inclinação do corpo, em radianos.
    var giro: CGFloat = 0
    /// Deslocamento lateral da cauda.
    var cauda: CGFloat = 0
    /// 0..1, abertura do bico/boca.
    var boca: CGFloat = 0
}

enum Creatures {

    static let canvas: CGFloat = 76

    enum Anim: String, CaseIterable {
        case parado, andar, especial

        var quadros: Int {
            switch self {
            case .parado: return 6
            case .andar: return 8
            case .especial: return 8
            }
        }

        /// Duração de um quadro, em segundos.
        var passoTempo: TimeInterval {
            switch self {
            case .parado: return 0.16
            case .andar: return 0.075
            case .especial: return 0.065
            }
        }
    }

    private static var cacheQuadros: [String: [SKTexture]] = [:]
    private static var cacheImagens: [String: NSImage] = [:]

    // MARK: - API

    static func quadros(_ f: AnimalForm, _ anim: Anim) -> [SKTexture] {
        let chave = "\(f.rawValue)_\(anim.rawValue)"
        if let q = cacheQuadros[chave] { return q }
        let n = anim.quadros
        let lista = (0..<n).map { i -> SKTexture in
            let t = CGFloat(i) / CGFloat(n)
            let pose = self.pose(f, anim, t)
            return Draw.texture(width: Int(canvas), height: Int(canvas)) { ctx in
                desenhar(f, pose, ctx)
            }
        }
        cacheQuadros[chave] = lista
        return lista
    }

    /// Quadro neutro — usado como textura inicial e nos retratos.
    static func texture(for f: AnimalForm) -> SKTexture {
        quadros(f, .parado)[0]
    }

    static func npcTexture(_ chave: String) -> SKTexture {
        let k = "npc_" + chave
        if let q = cacheQuadros[k] { return q[0] }
        let t = Draw.texture(width: Int(canvas), height: Int(canvas)) { ctx in
            desenharNPC(chave, ctx)
        }
        cacheQuadros[k] = [t]
        return t
    }

    // MARK: - Poses

    static func pose(_ f: AnimalForm, _ anim: Anim, _ t: CGFloat) -> Pose {
        let ciclo = t * .pi * 2
        var p = Pose()

        switch anim {
        case .parado:
            // Respiração: quase imperceptível, mas tira o boneco da estátua.
            p.squash = sin(ciclo) * 0.06
            p.passo = sin(ciclo) * 0.08
            p.asa = sin(ciclo) * 0.18
            p.cauda = sin(ciclo) * 1.6

        case .andar:
            p.passo = sin(ciclo)
            // Dois quiques por passada: o corpo sobe e desce duas vezes.
            p.squash = sin(ciclo * 2) * 0.10
            p.cauda = sin(ciclo) * 4
            p.asa = sin(ciclo) * 0.25

        case .especial:
            switch f.verbo {
            case .pulo:
                // Agacha, estica no impulso, recolhe as patas no ápice.
                p.squash = t < 0.18 ? -0.45 + t * 2.0 : cos((t - 0.18) * .pi * 1.4) * 0.55
                p.recolhido = min(1, sin(t * .pi) * 1.4)
                p.cauda = sin(ciclo) * 10
                p.giro = sin(t * .pi) * 0.18
                p.boca = 0.5

            case .investida:
                p.squash = 0.42
                p.recolhido = 0.25
                p.passo = sin(ciclo * 1.5) * 1.35
                p.giro = 0.22
                p.cauda = sin(ciclo) * 8
                p.boca = 0.7

            case .espreitar:
                // Corpo baixo, passo contido: o oposto da investida, deliberadamente.
                p.giro = 0.08
                p.recolhido = 0.35
                p.passo = sin(ciclo * 1.8) * 1.0
                p.squash = -0.12 + sin(ciclo * 2) * 0.06
                p.cauda = sin(ciclo) * 6

            case .planar, .voo:
                p.asa = sin(ciclo)
                p.recolhido = 0.9
                p.squash = 0.15 + sin(ciclo) * 0.10
                p.giro = sin(ciclo) * 0.08
                p.cauda = sin(ciclo) * 3

            case .arranco:
                // Ondulação do corpo inteiro, da cabeça à cauda.
                p.passo = sin(ciclo) * 1.4
                p.cauda = sin(ciclo - 0.9) * 12
                p.squash = 0.3
                p.recolhido = 0.6

            case .escavar:
                p.giro = 0.30
                p.recolhido = 0.55
                p.passo = sin(ciclo * 2) * 1.1
                p.squash = -0.20 + sin(ciclo * 2) * 0.12

            case .nenhum:
                p.passo = sin(ciclo) * 1.25
                p.squash = sin(ciclo * 2) * 0.16
                p.giro = 0.10
            }
        }
        return p
    }

    // MARK: - Roteador

    private static func desenhar(_ f: AnimalForm, _ p: Pose, _ ctx: CGContext) {
        // A sombra encolhe conforme o bicho recolhe as patas (está no ar).
        let noAr = p.recolhido
        Draw.shadow(ctx, center: CGPoint(x: canvas / 2, y: canvas - 12),
                    w: 40 - noAr * 14, h: 13 - noAr * 5, alpha: 0.24 - noAr * 0.10)

        Draw.transformed(ctx, pivot: CGPoint(x: canvas / 2, y: canvas - 14),
                         rotation: p.giro,
                         scaleX: 1 - p.squash * 0.16,
                         scaleY: 1 + p.squash * 0.20) {
            switch f {
            case .humano: guardiao($0, p)
            case .micoLeaoDourado: mico($0, p)
            case .loboGuara: lobo($0, p)
            case .oncaPintada: onca($0, p)
            case .araraAzul: arara($0, p)
            case .pirarucu: pirarucu($0, p)
            case .tucoTuco: tucoTuco($0, p)
            case .harpia: harpia($0, p)
            }
        }
    }

    private static func desenharNPC(_ chave: String, _ ctx: CGContext) {
        switch chave {
        case "teo": teo(ctx)
        case "harpia": desenhar(.harpia, Pose(recolhido: 0.5, asa: 0.6), ctx)
        default: iara(ctx)
        }
    }

    // MARK: - Peças reutilizáveis

    /// Membro simples: desloca com a fase do passo e encurta quando recolhido.
    private static func membro(_ ctx: CGContext, x: CGFloat, y: CGFloat,
                               comprimento: CGFloat, largura: CGFloat,
                               fase: CGFloat, recolhido: CGFloat, cor: SKColor) {
        let c = comprimento * (1 - recolhido * 0.72)
        let dx = fase * comprimento * 0.30
        let dy = -abs(fase) * comprimento * 0.10 - recolhido * comprimento * 0.18
        Draw.roundRect(ctx, CGRect(x: x + dx - largura / 2, y: y + dy,
                                   width: largura, height: c),
                       radius: largura / 2, cor)
    }

    /// Cauda como curva: a ponta oscila com `cauda`.
    private static func cauda(_ ctx: CGContext, base: CGPoint, ponta: CGPoint,
                              curvatura: CGFloat, largura: CGFloat, cor: SKColor) {
        ctx.setStrokeColor(cor.cgColor)
        ctx.setLineWidth(largura)
        ctx.setLineCap(.round)
        ctx.move(to: base)
        ctx.addQuadCurve(to: ponta,
                         control: CGPoint(x: (base.x + ponta.x) / 2 + curvatura,
                                          y: (base.y + ponta.y) / 2))
        ctx.strokePath()
    }

    // MARK: - Guardião (forma humana)

    private static func guardiao(_ ctx: CGContext, _ p: Pose) {
        let cx = canvas / 2
        let pele = SKColor(hex: 0xC98B5B)
        let colete = SKColor(hex: 0x3E6A4E)
        let calca = SKColor(hex: 0x33402E)

        membro(ctx, x: cx - 6, y: 44, comprimento: 20, largura: 8,
               fase: p.passo, recolhido: p.recolhido, cor: calca)
        membro(ctx, x: cx + 6, y: 44, comprimento: 20, largura: 8,
               fase: -p.passo, recolhido: p.recolhido, cor: calca)

        Draw.roundRect(ctx, CGRect(x: cx - 16, y: 24, width: 32, height: 22), radius: 8,
                       SKColor(hex: 0x6A4E2E))
        Draw.roundRect(ctx, CGRect(x: cx - 13, y: 22, width: 26, height: 26), radius: 9, colete)
        Draw.roundRect(ctx, CGRect(x: cx - 4, y: 24, width: 8, height: 22), radius: 3,
                       colete.lighter(0.16))

        membro(ctx, x: cx - 15.5, y: 26, comprimento: 18, largura: 7,
               fase: -p.passo * 0.7, recolhido: p.recolhido * 0.6, cor: pele)
        membro(ctx, x: cx + 15.5, y: 26, comprimento: 18, largura: 7,
               fase: p.passo * 0.7, recolhido: p.recolhido * 0.6, cor: pele)

        Draw.circle(ctx, CGPoint(x: cx, y: 17), 11, pele)
        Draw.circle(ctx, CGPoint(x: cx, y: 12), 10.5, SKColor(hex: 0x2E2118))
        Draw.roundRect(ctx, CGRect(x: cx - 3, y: 6, width: 6, height: 9), radius: 3,
                       SKColor(hex: 0x2E2118))
        Draw.ellipse(ctx, CGRect(x: cx - 17, y: 8, width: 34, height: 11), SKColor(hex: 0x8A6A3E))
        Draw.roundRect(ctx, CGRect(x: cx - 9, y: 2, width: 18, height: 10), radius: 5,
                       SKColor(hex: 0x9A7A4A))
        Draw.circle(ctx, CGPoint(x: cx - 4, y: 19), 1.7, SKColor(hex: 0x1A1410))
        Draw.circle(ctx, CGPoint(x: cx + 4, y: 19), 1.7, SKColor(hex: 0x1A1410))
    }

    // MARK: - Mico-leão-dourado

    private static func mico(_ ctx: CGContext, _ p: Pose) {
        let cx = canvas / 2
        let laranja = SKColor(hex: 0xE8952C)
        let dourado = SKColor(hex: 0xF6C860)
        let ruivo = SKColor(hex: 0xC9701E)

        // A cauda é longa e chicoteia: é o que mais comunica movimento no salto.
        cauda(ctx, base: CGPoint(x: cx + 9, y: 54),
              ponta: CGPoint(x: cx + 26 + p.cauda, y: 30 - p.recolhido * 14),
              curvatura: 18 + p.cauda, largura: 5.5, cor: ruivo)

        // Pernas
        membro(ctx, x: cx - 8, y: 52, comprimento: 15, largura: 6,
               fase: p.passo, recolhido: p.recolhido, cor: ruivo)
        membro(ctx, x: cx + 8, y: 52, comprimento: 15, largura: 6,
               fase: -p.passo, recolhido: p.recolhido, cor: ruivo)

        // Corpo — abaixo da cabeça, para o bicho não virar só uma juba.
        Draw.ellipse(ctx, CGRect(x: cx - 13, y: 33, width: 26, height: 27), laranja)
        Draw.ellipse(ctx, CGRect(x: cx - 8, y: 40, width: 16, height: 18), laranja.lighter(0.10))

        // Braços: sobem quando ele se lança.
        let braco = p.recolhido
        membro(ctx, x: cx - 14, y: 36 - braco * 12, comprimento: 14, largura: 5,
               fase: -p.passo * 0.8, recolhido: braco * 0.35, cor: ruivo)
        membro(ctx, x: cx + 14, y: 36 - braco * 12, comprimento: 14, largura: 5,
               fase: p.passo * 0.8, recolhido: braco * 0.35, cor: ruivo)

        // Juba: tufos redondos sobrepostos. Linhas radiais viravam pétalas de
        // girassol; massas arredondadas leem como pelo.
        let hy: CGFloat = 21
        let rx: CGFloat = 15 + p.recolhido * 1.5
        let ry: CGFloat = 13.5 + p.recolhido * 1.5
        for i in 0..<18 {
            let a = Double(i) / 18.0 * .pi * 2
            // Jitter determinístico: sem isto a borda fica regular demais.
            let j = CGFloat(sin(Double(i) * 2.7)) * 1.6
            let px = cx + CGFloat(cos(a)) * (rx + j)
            let py = hy + CGFloat(sin(a)) * (ry + j)
            Draw.circle(ctx, CGPoint(x: px, y: py), 5.2 + j * 0.35,
                        i % 3 == 0 ? dourado.darker(0.12) : dourado)
        }
        Draw.ellipse(ctx, CGRect(x: cx - rx, y: hy - ry, width: rx * 2, height: ry * 2), dourado)
        Draw.ellipse(ctx, CGRect(x: cx - rx * 0.72, y: hy - ry * 0.85,
                                 width: rx * 1.1, height: ry * 1.1), dourado.lighter(0.10))

        // Face escura e pequena
        Draw.ellipse(ctx, CGRect(x: cx - 6, y: hy - 6, width: 12, height: 14),
                     SKColor(hex: 0x33241A))
        Draw.circle(ctx, CGPoint(x: cx - 3, y: hy - 1), 1.9, SKColor(hex: 0xF2E6C8))
        Draw.circle(ctx, CGPoint(x: cx + 3, y: hy - 1), 1.9, SKColor(hex: 0xF2E6C8))
        Draw.circle(ctx, CGPoint(x: cx - 3, y: hy - 1), 1.0, .black)
        Draw.circle(ctx, CGPoint(x: cx + 3, y: hy - 1), 1.0, .black)
        Draw.ellipse(ctx, CGRect(x: cx - 1.8, y: hy + 3, width: 3.6, height: 2.5 + p.boca * 4),
                     SKColor(hex: 0x1A1210))
    }

    // MARK: - Lobo-guará

    private static func lobo(_ ctx: CGContext, _ p: Pose) {
        let cx = canvas / 2
        let ruivo = SKColor(hex: 0xC96A2E)
        let preto = SKColor(hex: 0x241E18)

        // Galope: dianteiras e traseiras em oposição.
        membro(ctx, x: cx - 12, y: 40, comprimento: 26, largura: 5,
               fase: p.passo, recolhido: p.recolhido, cor: preto)
        membro(ctx, x: cx - 5, y: 40, comprimento: 26, largura: 5,
               fase: -p.passo * 0.8, recolhido: p.recolhido, cor: preto)
        membro(ctx, x: cx + 5, y: 40, comprimento: 26, largura: 5,
               fase: -p.passo, recolhido: p.recolhido, cor: preto)
        membro(ctx, x: cx + 12, y: 40, comprimento: 26, largura: 5,
               fase: p.passo * 0.8, recolhido: p.recolhido, cor: preto)

        cauda(ctx, base: CGPoint(x: cx + 12, y: 44),
              ponta: CGPoint(x: cx + 27 + p.cauda, y: 30 - p.squash * 8),
              curvatura: 14, largura: 8, cor: ruivo)
        Draw.circle(ctx, CGPoint(x: cx + 27 + p.cauda, y: 29 - p.squash * 8), 4.5,
                    SKColor(hex: 0xF0EAE0))

        Draw.ellipse(ctx, CGRect(x: cx - 16, y: 30, width: 32, height: 20), ruivo)
        Draw.roundRect(ctx, CGRect(x: cx - 13, y: 28, width: 26, height: 7), radius: 3.5, preto)

        Draw.roundRect(ctx, CGRect(x: cx - 5, y: 20, width: 10, height: 14), radius: 5, ruivo)
        Draw.ellipse(ctx, CGRect(x: cx - 10, y: 10, width: 20, height: 17), ruivo)
        Draw.roundRect(ctx, CGRect(x: cx - 4, y: 20, width: 8, height: 9 + p.boca * 3),
                       radius: 4, ruivo.lighter(0.10))
        Draw.circle(ctx, CGPoint(x: cx, y: 27 + p.boca * 3), 2.2, preto)

        // Orelhas: erguem na investida.
        let orelha = 1 + p.squash * 0.4
        Draw.polygon(ctx, [CGPoint(x: cx - 11, y: 14), CGPoint(x: cx - 15, y: 1 * orelha),
                           CGPoint(x: cx - 4, y: 9)], ruivo)
        Draw.polygon(ctx, [CGPoint(x: cx + 11, y: 14), CGPoint(x: cx + 15, y: 1 * orelha),
                           CGPoint(x: cx + 4, y: 9)], ruivo)
        Draw.polygon(ctx, [CGPoint(x: cx - 10, y: 13), CGPoint(x: cx - 13, y: 4),
                           CGPoint(x: cx - 6, y: 10)], preto)
        Draw.polygon(ctx, [CGPoint(x: cx + 10, y: 13), CGPoint(x: cx + 13, y: 4),
                           CGPoint(x: cx + 6, y: 10)], preto)

        Draw.circle(ctx, CGPoint(x: cx - 4.5, y: 17), 1.9, SKColor(hex: 0xF6D98A))
        Draw.circle(ctx, CGPoint(x: cx + 4.5, y: 17), 1.9, SKColor(hex: 0xF6D98A))
    }

    // MARK: - Onça-pintada

    private static func onca(_ ctx: CGContext, _ p: Pose) {
        let cx = canvas / 2
        let dourado = SKColor(hex: 0xD9A233)
        let roseta = SKColor(hex: 0x2A1E14)
        let ventre = SKColor(hex: 0xF0DBA0)

        // Passo contido e corpo mais baixo que o lobo: robusta, não veloz.
        membro(ctx, x: cx - 12, y: 42, comprimento: 22, largura: 6.5,
               fase: p.passo, recolhido: p.recolhido, cor: roseta)
        membro(ctx, x: cx - 5, y: 42, comprimento: 22, largura: 6.5,
               fase: -p.passo * 0.8, recolhido: p.recolhido, cor: roseta)
        membro(ctx, x: cx + 5, y: 42, comprimento: 22, largura: 6.5,
               fase: -p.passo, recolhido: p.recolhido, cor: roseta)
        membro(ctx, x: cx + 12, y: 42, comprimento: 22, largura: 6.5,
               fase: p.passo * 0.8, recolhido: p.recolhido, cor: roseta)

        cauda(ctx, base: CGPoint(x: cx + 13, y: 45),
              ponta: CGPoint(x: cx + 24 + p.cauda, y: 32 - p.squash * 6),
              curvatura: 10, largura: 7, cor: dourado)
        Draw.circle(ctx, CGPoint(x: cx + 24 + p.cauda, y: 31 - p.squash * 6), 4, roseta)

        // Corpo compacto e largo — mais massa que o lobo.
        Draw.ellipse(ctx, CGRect(x: cx - 18, y: 28, width: 36, height: 20), dourado)
        Draw.ellipse(ctx, CGRect(x: cx - 10, y: 32, width: 20, height: 13), ventre)

        // Rosetas: manchas escuras espalhadas pelo dorso, marca registrada.
        for (dx, dy, r) in [(CGFloat(-10), CGFloat(34), CGFloat(2.6)),
                            (CGFloat(-2), CGFloat(31), CGFloat(2.2)),
                            (CGFloat(7), CGFloat(33), CGFloat(2.4)),
                            (CGFloat(13), CGFloat(37), CGFloat(2.0)),
                            (CGFloat(-13), CGFloat(41), CGFloat(2.0))] {
            Draw.circle(ctx, CGPoint(x: cx + dx, y: dy), r, roseta)
        }

        // Cabeça larga e mandíbula robusta.
        Draw.circle(ctx, CGPoint(x: cx, y: 19), 11.5, dourado)
        Draw.roundRect(ctx, CGRect(x: cx - 5, y: 12, width: 10, height: 10 + p.boca * 3),
                       radius: 4, dourado.darker(0.05))
        Draw.circle(ctx, CGPoint(x: cx, y: 16 + p.boca * 3), 2.0, roseta)

        // Orelhas pequenas e arredondadas.
        Draw.circle(ctx, CGPoint(x: cx - 9, y: 12), 3.6, dourado)
        Draw.circle(ctx, CGPoint(x: cx + 9, y: 12), 3.6, dourado)
        Draw.circle(ctx, CGPoint(x: cx - 9, y: 12), 1.8, roseta)
        Draw.circle(ctx, CGPoint(x: cx + 9, y: 12), 1.8, roseta)

        Draw.circle(ctx, CGPoint(x: cx - 4.3, y: 19), 1.8, SKColor(hex: 0xE8D060))
        Draw.circle(ctx, CGPoint(x: cx + 4.3, y: 19), 1.8, SKColor(hex: 0xE8D060))
        Draw.circle(ctx, CGPoint(x: cx - 4.3, y: 19), 0.8, roseta)
        Draw.circle(ctx, CGPoint(x: cx + 4.3, y: 19), 0.8, roseta)
    }

    // MARK: - Arara-azul

    private static func arara(_ ctx: CGContext, _ p: Pose) {
        let cx = canvas / 2
        let azul = SKColor(hex: 0x2F6FD8)
        let azulEscuro = SKColor(hex: 0x1E4C9E)
        let amarelo = SKColor(hex: 0xF2D24E)

        // `recolhido` diz se ela está no ar: pousada, a asa fica colada ao corpo.
        let voando = p.recolhido
        let leque = 1 + max(0, p.asa) * 0.35 * voando

        // Cauda longa e pontuda
        Draw.polygon(ctx, [CGPoint(x: cx - 6, y: 46), CGPoint(x: cx - 9 * leque, y: 73),
                           CGPoint(x: cx - 1, y: 50)], azulEscuro)
        Draw.polygon(ctx, [CGPoint(x: cx + 6, y: 46), CGPoint(x: cx + 9 * leque, y: 73),
                           CGPoint(x: cx + 1, y: 50)], azulEscuro)

        // Asa: interpola entre dobrada (colada) e aberta (quase horizontal).
        let altura = p.asa * 18 * voando
        let pontaX = 12 + voando * 22
        let pontaY = 48 - voando * 20 - altura
        let bulge = 6 + voando * 6
        for lado in [CGFloat(-1), 1] {
            Draw.leaf(ctx, from: CGPoint(x: cx + lado * 8, y: 27),
                      to: CGPoint(x: cx + lado * pontaX, y: pontaY),
                      bulge: bulge * lado, azul)
            Draw.leaf(ctx, from: CGPoint(x: cx + lado * 8, y: 30),
                      to: CGPoint(x: cx + lado * pontaX * 0.75, y: pontaY + 5),
                      bulge: bulge * 0.7 * lado, azulEscuro)
        }

        // Pés: aparecem só quando pousada
        if voando < 0.6 {
            membro(ctx, x: cx - 5, y: 52, comprimento: 11, largura: 4.5,
                   fase: p.passo, recolhido: voando, cor: SKColor(hex: 0x33333A))
            membro(ctx, x: cx + 5, y: 52, comprimento: 11, largura: 4.5,
                   fase: -p.passo, recolhido: voando, cor: SKColor(hex: 0x33333A))
        }

        Draw.ellipse(ctx, CGRect(x: cx - 12, y: 24, width: 24, height: 30), azul)
        Draw.ellipse(ctx, CGRect(x: cx - 7, y: 32, width: 14, height: 20), azul.lighter(0.10))

        Draw.circle(ctx, CGPoint(x: cx, y: 19), 12, azul)
        let bico = p.boca * 3
        Draw.polygon(ctx, [CGPoint(x: cx - 5, y: 22), CGPoint(x: cx + 5, y: 22),
                           CGPoint(x: cx + 2, y: 34 + bico), CGPoint(x: cx - 2, y: 34 + bico)],
                     SKColor(hex: 0x141414))
        Draw.circle(ctx, CGPoint(x: cx, y: 30 + bico), 4, SKColor(hex: 0x141414))
        Draw.circle(ctx, CGPoint(x: cx - 5, y: 17), 4.2, amarelo)
        Draw.circle(ctx, CGPoint(x: cx + 5, y: 17), 4.2, amarelo)
        Draw.circle(ctx, CGPoint(x: cx - 5, y: 17), 2.2, SKColor(hex: 0x141414))
        Draw.circle(ctx, CGPoint(x: cx + 5, y: 17), 2.2, SKColor(hex: 0x141414))
        Draw.ellipse(ctx, CGRect(x: cx - 8, y: 24, width: 5, height: 4), amarelo)
        Draw.ellipse(ctx, CGRect(x: cx + 3, y: 24, width: 5, height: 4), amarelo)
    }

    // MARK: - Pirarucu

    private static func pirarucu(_ ctx: CGContext, _ p: Pose) {
        let cx = canvas / 2
        let verde = SKColor(hex: 0x4E6E62)
        let vermelho = SKColor(hex: 0xC24A44)

        // O corpo é uma sequência de segmentos: a onda percorre do focinho à cauda.
        let onda = p.passo
        func desvio(_ y: CGFloat) -> CGFloat {
            let fase = (y - 10) / 52
            return sin(Double(fase) * .pi * 1.6 - Double(onda) * 1.4) * Double(onda) * 5
        }

        for i in stride(from: CGFloat(10), through: 58, by: 6) {
            let d = desvio(i)
            let larg = 28 - abs(i - 32) * 0.28
            Draw.ellipse(ctx, CGRect(x: cx - larg / 2 + d, y: i, width: larg, height: 10), verde)
        }
        for i in stride(from: CGFloat(16), through: 52, by: 6) {
            let d = desvio(i)
            let larg = 18 - abs(i - 32) * 0.20
            Draw.ellipse(ctx, CGRect(x: cx - larg / 2 + d, y: i, width: larg, height: 8),
                         verde.lighter(0.10))
        }

        // Nadadeiras peitorais batem com a onda.
        let peito = desvio(32)
        Draw.leaf(ctx, from: CGPoint(x: cx - 12 + peito, y: 30),
                  to: CGPoint(x: cx - 25 + peito, y: 40 + onda * 4), bulge: 5, verde.darker(0.10))
        Draw.leaf(ctx, from: CGPoint(x: cx + 12 + peito, y: 30),
                  to: CGPoint(x: cx + 25 + peito, y: 40 - onda * 4), bulge: 5, verde.darker(0.10))

        // Traseira avermelhada e cauda
        let dCauda = desvio(58) + p.cauda * 0.6
        Draw.ellipse(ctx, CGRect(x: cx - 12 + dCauda, y: 44, width: 24, height: 22),
                     vermelho.blended(with: verde, amount: 0.35))
        Draw.leaf(ctx, from: CGPoint(x: cx - 11 + dCauda, y: 58),
                  to: CGPoint(x: cx + 11 + dCauda, y: 58), bulge: 12, vermelho)
        Draw.polygon(ctx, [CGPoint(x: cx - 12 + dCauda, y: 62), CGPoint(x: cx + 12 + dCauda, y: 62),
                           CGPoint(x: cx + dCauda * 1.6, y: 74)], vermelho)

        // Escamas
        ctx.setStrokeColor(verde.darker(0.22).withAlphaComponent(0.7).cgColor)
        ctx.setLineWidth(1.2)
        for linha in 0..<5 {
            let y = 24 + CGFloat(linha) * 6
            let d = desvio(y)
            for col in 0..<3 {
                let x = cx - 8 + CGFloat(col) * 8 + d
                ctx.addArc(center: CGPoint(x: x, y: y), radius: 4,
                           startAngle: .pi, endAngle: 0, clockwise: true)
                ctx.strokePath()
            }
        }

        let dCabeca = desvio(12)
        Draw.ellipse(ctx, CGRect(x: cx - 11 + dCabeca, y: 6, width: 22, height: 18),
                     verde.darker(0.12))
        Draw.ellipse(ctx, CGRect(x: cx - 5 + dCabeca, y: 18, width: 10, height: 4 + p.boca * 5),
                     SKColor(hex: 0x2A1A18))
        Draw.circle(ctx, CGPoint(x: cx - 5 + dCabeca, y: 13), 2.6, SKColor(hex: 0xE8E0C8))
        Draw.circle(ctx, CGPoint(x: cx + 5 + dCabeca, y: 13), 2.6, SKColor(hex: 0xE8E0C8))
        Draw.circle(ctx, CGPoint(x: cx - 5 + dCabeca, y: 13), 1.3, .black)
        Draw.circle(ctx, CGPoint(x: cx + 5 + dCabeca, y: 13), 1.3, .black)
    }

    // MARK: - Tuco-tuco

    private static func tucoTuco(_ ctx: CGContext, _ p: Pose) {
        let cx = canvas / 2
        let marrom = SKColor(hex: 0x9A7A4E)
        let escuro = SKColor(hex: 0x5E4A32)

        // Terra levantada pela escavação
        let terra = max(0, p.giro) * 3
        Draw.ellipse(ctx, CGRect(x: cx - 22 - terra, y: 48, width: 44 + terra * 2, height: 16),
                     SKColor(hex: 0xC6B584, alpha: 0.65))
        if p.giro > 0.2 {
            for i in 0..<4 {
                let a = Double(i) * 1.3
                Draw.circle(ctx, CGPoint(x: cx + CGFloat(cos(a)) * (18 + terra),
                                         y: 44 + CGFloat(sin(a)) * 8),
                            2.5, SKColor(hex: 0xC6B584))
            }
        }

        membro(ctx, x: cx - 10, y: 46, comprimento: 10, largura: 8,
               fase: p.passo, recolhido: p.recolhido, cor: escuro)
        membro(ctx, x: cx + 10, y: 46, comprimento: 10, largura: 8,
               fase: -p.passo, recolhido: p.recolhido, cor: escuro)

        Draw.ellipse(ctx, CGRect(x: cx - 17, y: 24, width: 34, height: 28), marrom)
        Draw.ellipse(ctx, CGRect(x: cx - 11, y: 32, width: 22, height: 18), marrom.lighter(0.14))

        Draw.circle(ctx, CGPoint(x: cx, y: 22), 13, marrom)
        Draw.circle(ctx, CGPoint(x: cx - 10, y: 14), 3.6, escuro)
        Draw.circle(ctx, CGPoint(x: cx + 10, y: 14), 3.6, escuro)
        Draw.ellipse(ctx, CGRect(x: cx - 7, y: 24, width: 14, height: 10), marrom.lighter(0.20))
        Draw.circle(ctx, CGPoint(x: cx, y: 26), 2.0, SKColor(hex: 0x3A2A20))
        // Os incisivos avançam quando ele está cavando.
        let dente = 7 + max(0, p.giro) * 10
        Draw.roundRect(ctx, CGRect(x: cx - 4, y: 29, width: 3.5, height: dente), radius: 1.4,
                       SKColor(hex: 0xE8C860))
        Draw.roundRect(ctx, CGRect(x: cx + 0.5, y: 29, width: 3.5, height: dente), radius: 1.4,
                       SKColor(hex: 0xE8C860))
        Draw.circle(ctx, CGPoint(x: cx - 5, y: 19), 1.7, SKColor(hex: 0x1A1410))
        Draw.circle(ctx, CGPoint(x: cx + 5, y: 19), 1.7, SKColor(hex: 0x1A1410))
        Draw.roundRect(ctx, CGRect(x: cx - 2, y: 50, width: 4, height: 9), radius: 2, escuro)
    }

    // MARK: - Harpia

    private static func harpia(_ ctx: CGContext, _ p: Pose) {
        let cx = canvas / 2
        let ardosia = SKColor(hex: 0x585E68)
        let ardosiaEscura = SKColor(hex: 0x33383F)
        let claro = SKColor(hex: 0xD9DCD8)
        let garra = SKColor(hex: 0xE8C24E)

        let voando = p.recolhido

        // Cauda: estreita e barrada, não uma saia listrada.
        let leque = 8 + max(0, p.asa) * 3 * voando
        Draw.polygon(ctx, [CGPoint(x: cx - 6, y: 48), CGPoint(x: cx - leque, y: 70),
                           CGPoint(x: cx + leque, y: 70), CGPoint(x: cx + 6, y: 48)],
                     ardosiaEscura)
        for i in 0..<2 {
            let y = 57 + CGFloat(i) * 7
            Draw.line(ctx, from: CGPoint(x: cx - leque * 0.85, y: y),
                      to: CGPoint(x: cx + leque * 0.85, y: y), width: 2.2,
                      claro.withAlphaComponent(0.45))
        }

        // Asas: enormes e quase horizontais quando abertas — é a assinatura dela.
        let altura = p.asa * 20 * voando
        let pontaX = 13 + voando * 24
        let pontaY = 46 - voando * 22 - altura
        for lado in [CGFloat(-1), 1] {
            Draw.leaf(ctx, from: CGPoint(x: cx + lado * 9, y: 26),
                      to: CGPoint(x: cx + lado * pontaX, y: pontaY),
                      bulge: (8 + voando * 7) * lado, ardosia)
            Draw.leaf(ctx, from: CGPoint(x: cx + lado * 9, y: 30),
                      to: CGPoint(x: cx + lado * pontaX * 0.72, y: pontaY + 6),
                      bulge: (6 + voando * 4) * lado, ardosiaEscura)
            // Primárias abertas como dedos na ponta da asa
            if voando > 0.4 {
                for g in 0..<3 {
                    Draw.line(ctx,
                              from: CGPoint(x: cx + lado * pontaX * 0.88, y: pontaY + 3),
                              to: CGPoint(x: cx + lado * (pontaX + 5),
                                          y: pontaY - 3 + CGFloat(g) * 5),
                              width: 2.8, ardosiaEscura)
                }
            }
        }

        // Garras amarelas: recolhidas em voo, estendidas no mergulho.
        let garraY = 50 + (1 - voando) * 8
        for lado in [CGFloat(-1), 1] {
            Draw.roundRect(ctx, CGRect(x: cx + lado * 6 - 2.5, y: garraY - 6,
                                       width: 5, height: 11), radius: 2.5, garra)
            for g in 0..<3 {
                let a = Double(g) * 0.55 - 0.55
                Draw.line(ctx, from: CGPoint(x: cx + lado * 6, y: garraY + 4),
                          to: CGPoint(x: cx + lado * 6 + CGFloat(sin(a)) * 6,
                                      y: garraY + 4 + CGFloat(cos(a)) * 7),
                          width: 2.4, garra.darker(0.18))
            }
        }

        // Corpo: dorso ardósia, peito claro com barras finas.
        Draw.ellipse(ctx, CGRect(x: cx - 14, y: 24, width: 28, height: 32), ardosia)
        Draw.ellipse(ctx, CGRect(x: cx - 10, y: 32, width: 20, height: 23), claro)
        Draw.roundRect(ctx, CGRect(x: cx - 11, y: 29, width: 22, height: 4.5), radius: 2.2,
                       ardosiaEscura)
        for i in 0..<3 {
            let larg: CGFloat = 8 - CGFloat(i)
            Draw.line(ctx, from: CGPoint(x: cx - larg, y: 40 + CGFloat(i) * 5),
                      to: CGPoint(x: cx + larg, y: 40 + CGFloat(i) * 5), width: 1.5,
                      ardosia.withAlphaComponent(0.45))
        }

        // Cabeça clara e a crista dupla, bem visível.
        Draw.circle(ctx, CGPoint(x: cx, y: 19), 11.5, claro.darker(0.08))
        let crista = 13 + voando * 5
        Draw.polygon(ctx, [CGPoint(x: cx - 6, y: 12), CGPoint(x: cx - 13, y: 12 - crista),
                           CGPoint(x: cx - 1, y: 7)], ardosia)
        Draw.polygon(ctx, [CGPoint(x: cx + 6, y: 12), CGPoint(x: cx + 13, y: 12 - crista),
                           CGPoint(x: cx + 1, y: 7)], ardosia)

        let bico = p.boca * 3
        Draw.polygon(ctx, [CGPoint(x: cx - 4, y: 22), CGPoint(x: cx + 4, y: 22),
                           CGPoint(x: cx + 2.5, y: 30 + bico), CGPoint(x: cx - 2.5, y: 30 + bico)],
                     SKColor(hex: 0x2A2A2E))
        Draw.polygon(ctx, [CGPoint(x: cx - 2.5, y: 29 + bico), CGPoint(x: cx + 2.5, y: 29 + bico),
                           CGPoint(x: cx, y: 35 + bico)], SKColor(hex: 0x17171B))
        Draw.circle(ctx, CGPoint(x: cx, y: 23), 2.2, garra)

        Draw.circle(ctx, CGPoint(x: cx - 4.5, y: 18), 3.2, SKColor(hex: 0xF0EFEA))
        Draw.circle(ctx, CGPoint(x: cx + 4.5, y: 18), 3.2, SKColor(hex: 0xF0EFEA))
        Draw.circle(ctx, CGPoint(x: cx - 4.5, y: 18), 2.0, SKColor(hex: 0x14140F))
        Draw.circle(ctx, CGPoint(x: cx + 4.5, y: 18), 2.0, SKColor(hex: 0x14140F))
    }

    // MARK: - Habitantes do Refúgio

    private static func iara(_ ctx: CGContext) {
        let cx = canvas / 2
        Draw.shadow(ctx, center: CGPoint(x: cx, y: canvas - 12), w: 36, h: 12)
        let pele = SKColor(hex: 0x8A5E3C)
        Draw.roundRect(ctx, CGRect(x: cx - 10, y: 44, width: 8, height: 20), radius: 4,
                       SKColor(hex: 0x4A4436))
        Draw.roundRect(ctx, CGRect(x: cx + 2, y: 44, width: 8, height: 20), radius: 4,
                       SKColor(hex: 0x4A4436))
        Draw.roundRect(ctx, CGRect(x: cx - 13, y: 22, width: 26, height: 26), radius: 9,
                       SKColor(hex: 0x8A6A3E))
        Draw.roundRect(ctx, CGRect(x: cx - 13, y: 30, width: 26, height: 8), radius: 3,
                       SKColor(hex: 0x6A4E2E))
        Draw.roundRect(ctx, CGRect(x: cx - 19, y: 26, width: 7, height: 18), radius: 3.5, pele)
        Draw.roundRect(ctx, CGRect(x: cx + 12, y: 26, width: 7, height: 18), radius: 3.5, pele)
        Draw.circle(ctx, CGPoint(x: cx, y: 17), 11, pele)
        Draw.circle(ctx, CGPoint(x: cx, y: 11), 11, SKColor(hex: 0xE8E4DC))
        Draw.roundRect(ctx, CGRect(x: cx - 3, y: 4, width: 6, height: 12), radius: 3,
                       SKColor(hex: 0xE8E4DC))
        Draw.circle(ctx, CGPoint(x: cx - 4, y: 19), 1.7, SKColor(hex: 0x1A1410))
        Draw.circle(ctx, CGPoint(x: cx + 4, y: 19), 1.7, SKColor(hex: 0x1A1410))
        Draw.roundRect(ctx, CGRect(x: cx + 14, y: 38, width: 11, height: 14), radius: 2,
                       SKColor(hex: 0xD8C89A))
    }

    private static func teo(_ ctx: CGContext) {
        let cx = canvas / 2
        Draw.shadow(ctx, center: CGPoint(x: cx, y: canvas - 12), w: 36, h: 12)
        let pele = SKColor(hex: 0xB07848)
        Draw.roundRect(ctx, CGRect(x: cx - 10, y: 44, width: 8, height: 20), radius: 4,
                       SKColor(hex: 0x2E3A44))
        Draw.roundRect(ctx, CGRect(x: cx + 2, y: 44, width: 8, height: 20), radius: 4,
                       SKColor(hex: 0x2E3A44))
        Draw.roundRect(ctx, CGRect(x: cx - 13, y: 22, width: 26, height: 26), radius: 9,
                       SKColor(hex: 0x3E7A8C))
        Draw.roundRect(ctx, CGRect(x: cx - 19, y: 26, width: 7, height: 18), radius: 3.5, pele)
        Draw.roundRect(ctx, CGRect(x: cx + 12, y: 26, width: 7, height: 18), radius: 3.5, pele)
        Draw.circle(ctx, CGPoint(x: cx, y: 17), 11, pele)
        Draw.circle(ctx, CGPoint(x: cx, y: 12), 11, SKColor(hex: 0x241C14))
        Draw.ellipse(ctx, CGRect(x: cx - 12, y: 5, width: 24, height: 12), SKColor(hex: 0xC8542E))
        Draw.ellipse(ctx, CGRect(x: cx - 16, y: 7, width: 12, height: 6), SKColor(hex: 0xA8442A))
        Draw.circle(ctx, CGPoint(x: cx - 4, y: 19), 1.7, SKColor(hex: 0x1A1410))
        Draw.circle(ctx, CGPoint(x: cx + 4, y: 19), 1.7, SKColor(hex: 0x1A1410))
        Draw.roundRect(ctx, CGRect(x: cx - 26, y: 34, width: 12, height: 16), radius: 2,
                       SKColor(hex: 0x22282E))
        Draw.roundRect(ctx, CGRect(x: cx - 25, y: 36, width: 10, height: 11), radius: 1,
                       SKColor(hex: 0x6FE3D0))
    }

    // MARK: - Retratos para a interface

    static func retrato(_ forma: AnimalForm) -> NSImage {
        if let i = cacheImagens[forma.rawValue] { return i }
        let lado = Int(canvas)
        let pose = Pose(recolhido: forma == .harpia ? 0.4 : 0, asa: 0.4, cauda: 2)
        guard let cg = Draw.cgImage(width: lado, height: lado, { ctx in
            desenhar(forma, pose, ctx)
        }) else { return NSImage(size: .zero) }
        let img = NSImage(cgImage: cg, size: NSSize(width: canvas, height: canvas))
        cacheImagens[forma.rawValue] = img
        return img
    }

    static func retratoNPC(_ chave: String) -> NSImage {
        if let i = cacheImagens["npc_" + chave] { return i }
        let lado = Int(canvas)
        guard let cg = Draw.cgImage(width: lado, height: lado, { ctx in
            desenharNPC(chave, ctx)
        }) else { return NSImage(size: .zero) }
        let img = NSImage(cgImage: cg, size: NSSize(width: canvas, height: canvas))
        cacheImagens["npc_" + chave] = img
        return img
    }

    /// Ponto de entrada usado pelas ferramentas de pré-visualização de arte.
    static func desenharPublico(_ f: AnimalForm, _ ctx: CGContext, pose: Pose = Pose()) {
        desenhar(f, pose, ctx)
    }
}
