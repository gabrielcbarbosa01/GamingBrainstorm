//
//  Textures.swift
//  TurnoMac
//
//  Tudo desenhado com CoreGraphics em tempo de carga: as camadas de sujeira
//  de cada superfície e as provas que aparecem por baixo delas. Sem assets.
//

import AppKit
import CoreGraphics

/// Gerador determinístico simples.
struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> Double {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return Double(z >> 11) / Double(1 << 53)
    }
    mutating func range(_ a: CGFloat, _ b: CGFloat) -> CGFloat { a + (b - a) * CGFloat(next()) }
}

enum Textures {
    /// Buffer RGBA (premultiplied) desenhado por `draw`. Linha 0 = topo.
    static func rgba(width: Int, height: Int, draw: (CGContext) -> Void) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { buf in
            let ctx = CGContext(data: buf.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.translateBy(x: 0, y: CGFloat(height))
            ctx.scaleBy(x: 1, y: -1)
            draw(ctx)
        }
        return pixels
    }

    private static func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat) -> CGColor {
        NSColor(calibratedRed: r, green: g, blue: b, alpha: a).cgColor
    }

    // MARK: - Sujeira

    static func dirt(_ kind: DirtKind, width: Int, height: Int, seed: UInt64) -> [UInt8] {
        switch kind {
        case .vidro: return glassGrime(width: width, height: height, seed: seed)
        case .poeira: return dust(width: width, height: height, seed: seed)
        case .vinho: return wineStain(width: width, height: height, seed: seed)
        case .graxa: return grease(width: width, height: height, seed: seed)
        case .cinza: return ash(width: width, height: height, seed: seed)
        case .sangueVelho: return oldBlood(width: width, height: height, seed: seed)
        case .mofo: return mildew(width: width, height: height, seed: seed)
        }
    }

    /// Película cinza-marrom com gotas e escorridos.
    static func glassGrime(width: Int, height: Int, seed: UInt64 = 7) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            ctx.setFillColor(rgb(0.42, 0.38, 0.32, 0.78))
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for _ in 0..<900 {
                let r = g.range(2, 14)
                ctx.setFillColor(rgb(0.3, 0.27, 0.22, g.range(0.15, 0.6)))
                ctx.fillEllipse(in: CGRect(x: g.range(-10, w), y: g.range(-10, h), width: r, height: r * g.range(0.6, 1.4)))
            }
            for _ in 0..<40 {
                let x = g.range(0, w)
                ctx.setFillColor(rgb(0.25, 0.22, 0.18, g.range(0.3, 0.7)))
                ctx.fill(CGRect(x: x, y: g.range(0, h * 0.5), width: g.range(1, 3), height: g.range(20, h * 0.6)))
            }
        }
    }

    /// Véu bege com fiapos.
    static func dust(width: Int, height: Int, seed: UInt64 = 11) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            ctx.setFillColor(rgb(0.5, 0.46, 0.38, 0.55))
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for _ in 0..<1400 {
                ctx.setFillColor(rgb(0.6, 0.56, 0.47, g.range(0.2, 0.8)))
                let r = g.range(1, 6)
                ctx.fillEllipse(in: CGRect(x: g.range(0, w), y: g.range(0, h), width: r * 3, height: r))
            }
            for _ in 0..<120 {
                ctx.setStrokeColor(rgb(0.4, 0.37, 0.3, g.range(0.3, 0.8)))
                ctx.setLineWidth(g.range(0.5, 1.5))
                let x = g.range(0, w), y = g.range(0, h)
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addLine(to: CGPoint(x: x + g.range(-12, 12), y: y + g.range(-12, 12)))
                ctx.strokePath()
            }
        }
    }

    static func wineStain(width: Int, height: Int, seed: UInt64 = 3) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            for _ in 0..<60 {
                let r = g.range(20, 70)
                ctx.setFillColor(rgb(0.22, 0.02, 0.07, g.range(0.6, 0.95)))
                ctx.fillEllipse(in: CGRect(x: g.range(w * 0.1, w * 0.8), y: g.range(h * 0.1, h * 0.8), width: r, height: r * g.range(0.6, 1.2)))
            }
            for _ in 0..<200 {
                let r = g.range(2, 8)
                ctx.setFillColor(rgb(0.18, 0.02, 0.06, g.range(0.4, 0.9)))
                ctx.fillEllipse(in: CGRect(x: g.range(0, w), y: g.range(0, h), width: r, height: r))
            }
        }
    }

    /// Graxa de lavanderia: manchas escuras e brilhantes, com poças.
    static func grease(width: Int, height: Int, seed: UInt64 = 17) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            ctx.setFillColor(rgb(0.16, 0.14, 0.12, 0.75))
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for _ in 0..<70 {
                let r = g.range(14, 60)
                ctx.setFillColor(rgb(0.09, 0.08, 0.07, g.range(0.5, 0.95)))
                ctx.fillEllipse(in: CGRect(x: g.range(0, w), y: g.range(0, h), width: r * g.range(0.8, 2.0), height: r))
            }
            for _ in 0..<50 {
                ctx.setStrokeColor(rgb(0.32, 0.3, 0.26, g.range(0.2, 0.5)))
                ctx.setLineWidth(g.range(1, 4))
                let x = g.range(0, w), y = g.range(0, h)
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addCurve(to: CGPoint(x: x + g.range(-60, 60), y: y + g.range(-30, 30)),
                             control1: CGPoint(x: x + g.range(-30, 30), y: y + g.range(-20, 20)),
                             control2: CGPoint(x: x + g.range(-40, 40), y: y + g.range(-25, 25)))
                ctx.strokePath()
            }
        }
    }

    /// Cinza fria de cinquenta anos: cobertura uniforme, clara e sem brilho.
    static func ash(width: Int, height: Int, seed: UInt64 = 23) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            ctx.setFillColor(rgb(0.30, 0.29, 0.28, 0.9))
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for _ in 0..<900 {
                let r = g.range(3, 22)
                let v = g.range(0.2, 0.42)
                ctx.setFillColor(rgb(v, v * 0.97, v * 0.92, g.range(0.25, 0.7)))
                ctx.fillEllipse(in: CGRect(x: g.range(0, w), y: g.range(0, h), width: r, height: r * g.range(0.7, 1.3)))
            }
            for _ in 0..<160 {
                let r = g.range(1, 5)
                ctx.setFillColor(rgb(0.06, 0.05, 0.05, g.range(0.4, 0.9)))
                ctx.fillEllipse(in: CGRect(x: g.range(0, w), y: g.range(0, h), width: r, height: r))
            }
        }
    }

    /// Mancha antiga no carpete, escura e marrom, já lavada várias vezes.
    static func oldBlood(width: Int, height: Int, seed: UInt64 = 29) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            ctx.setFillColor(rgb(0.28, 0.24, 0.2, 0.5))
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            let cx = w * 0.5, cy = h * 0.55
            for _ in 0..<50 {
                let r = g.range(20, 90)
                ctx.setFillColor(rgb(0.15, 0.05, 0.04, g.range(0.35, 0.8)))
                ctx.fillEllipse(in: CGRect(x: cx + g.range(-w * 0.28, w * 0.28) - r / 2,
                                           y: cy + g.range(-h * 0.28, h * 0.28) - r / 2, width: r, height: r * g.range(0.7, 1.2)))
            }
            for _ in 0..<300 {
                let r = g.range(1, 6)
                ctx.setFillColor(rgb(0.12, 0.04, 0.03, g.range(0.3, 0.8)))
                ctx.fillEllipse(in: CGRect(x: g.range(0, w), y: g.range(0, h), width: r, height: r))
            }
        }
    }

    /// Mofo e vapor no espelho.
    static func mildew(width: Int, height: Int, seed: UInt64 = 31) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            ctx.setFillColor(rgb(0.72, 0.74, 0.72, 0.72))
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for _ in 0..<420 {
                let r = g.range(4, 26)
                ctx.setFillColor(rgb(g.range(0.3, 0.5), g.range(0.35, 0.5), g.range(0.3, 0.42), g.range(0.15, 0.5)))
                ctx.fillEllipse(in: CGRect(x: g.range(0, w), y: g.range(0, h), width: r, height: r))
            }
            for _ in 0..<26 {
                let x = g.range(0, w)
                ctx.setFillColor(rgb(0.85, 0.88, 0.88, g.range(0.3, 0.6)))
                ctx.fill(CGRect(x: x, y: g.range(0, h * 0.4), width: g.range(2, 5), height: g.range(30, h * 0.55)))
            }
        }
    }

    // MARK: - Provas

    static func reveal(_ art: RevealArt, width: Int, height: Int, region: CGRect) -> [UInt8] {
        switch art {
        case .mao: return handprint(width: width, height: height, region: region)
        case .cigarro: return cigarette(width: width, height: height, region: region)
        case .cartao: return keycard(width: width, height: height, region: region, title: "7")
        case .chave: return oldKey(width: width, height: height, region: region)
        case .cracha: return badge(width: width, height: height, region: region)
        case .bilhete: return writtenWord(width: width, height: height, region: region, word: "OITO")
        case .arranhao: return scuffs(width: width, height: height, region: region)
        case .uniforme: return burntOverall(width: width, height: height, region: region)
        case .carrinho: return cart(width: width, height: height, region: region)
        case .gondola: return gondola(width: width, height: height, region: region)
        case .pagina: return paper(width: width, height: height, region: region, title: "REGISTRO", lines: 7, tint: (0.93, 0.9, 0.82), torn: true)
        case .recibo: return paper(width: width, height: height, region: region, title: "RECIBO", lines: 5, tint: (0.95, 0.93, 0.8), torn: false)
        case .planta: return blueprint(width: width, height: height, region: region)
        case .ponto: return paper(width: width, height: height, region: region, title: "PONTO 1974", lines: 8, tint: (0.86, 0.83, 0.7), torn: false)
        case .contrato: return paper(width: width, height: height, region: region, title: "COMPRA E VENDA", lines: 9, tint: (0.95, 0.94, 0.9), torn: false)
        case .apolice: return paper(width: width, height: height, region: region, title: "APOLICE", lines: 8, tint: (0.9, 0.92, 0.95), torn: false)
        case .nada: return rgba(width: width, height: height) { _ in }
        }
    }

    private static func inRegion(_ region: CGRect, _ width: Int, _ height: Int) -> CGRect {
        CGRect(x: region.minX * CGFloat(width), y: (1 - region.maxY) * CGFloat(height),
               width: region.width * CGFloat(width), height: region.height * CGFloat(height))
    }

    static func handprint(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.setFillColor(rgb(0.32, 0.12, 0.08, 0.9))
            ctx.fillEllipse(in: CGRect(x: r.minX + r.width * 0.25, y: r.minY + r.height * 0.45, width: r.width * 0.5, height: r.height * 0.5))
            for (fx, fy, fl) in [(0.22, 0.05, 0.42), (0.36, 0.0, 0.5), (0.5, 0.0, 0.52), (0.64, 0.06, 0.45)] as [(CGFloat, CGFloat, CGFloat)] {
                ctx.fillEllipse(in: CGRect(x: r.minX + r.width * fx, y: r.minY + r.height * fy, width: r.width * 0.13, height: r.height * fl))
            }
            ctx.saveGState()
            ctx.translateBy(x: r.minX + r.width * 0.12, y: r.minY + r.height * 0.55)
            ctx.rotate(by: -0.7)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: r.width * 0.14, height: r.height * 0.34))
            ctx.restoreGState()
            ctx.setFillColor(rgb(0.32, 0.12, 0.08, 0.6))
            ctx.fill(CGRect(x: r.minX + r.width * 0.55, y: r.minY + r.height * 0.9, width: r.width * 0.04, height: r.height * 0.25))
        }
    }

    static func cigarette(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.saveGState()
            ctx.translateBy(x: r.midX, y: r.midY)
            ctx.rotate(by: 0.5)
            let len = r.width * 0.9, thick = r.height * 0.28
            ctx.setFillColor(rgb(0.92, 0.92, 0.92, 1))
            ctx.fill(CGRect(x: -len / 2, y: -thick / 2, width: len * 0.6, height: thick))
            ctx.setFillColor(rgb(0.85, 0.6, 0.3, 1))
            ctx.fill(CGRect(x: len * 0.1, y: -thick / 2, width: len * 0.32, height: thick))
            ctx.setFillColor(rgb(0.8, 0.1, 0.2, 1))
            ctx.fill(CGRect(x: len * 0.3, y: -thick / 2, width: len * 0.12, height: thick))
            ctx.setFillColor(rgb(0.2, 0.2, 0.2, 1))
            ctx.fill(CGRect(x: -len / 2, y: -thick / 2, width: len * 0.06, height: thick))
            ctx.restoreGState()
        }
    }

    static func keycard(width: Int, height: Int, region: CGRect, title: String) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.saveGState()
            ctx.translateBy(x: r.midX, y: r.midY)
            ctx.rotate(by: -0.25)
            let cw = r.width * 0.85, ch = r.height * 0.6
            ctx.setFillColor(rgb(0.95, 0.95, 0.95, 1))
            ctx.fill(CGRect(x: -cw / 2, y: -ch / 2, width: cw, height: ch))
            ctx.setFillColor(rgb(0.75, 0.6, 0.2, 1))
            ctx.fill(CGRect(x: -cw / 2, y: -ch / 2 + ch * 0.2, width: cw, height: ch * 0.18))
            ctx.setFillColor(rgb(0.1, 0.1, 0.15, 1))
            ctx.fill(CGRect(x: -cw / 2, y: ch / 2 - ch * 0.2, width: cw, height: ch * 0.12))
            ctx.setFillColor(rgb(0.4, 0.05, 0.1, 1))
            ctx.fill(CGRect(x: cw * 0.15, y: -ch * 0.05, width: cw * 0.2, height: ch * 0.06))
            ctx.fill(CGRect(x: cw * 0.28, y: -ch * 0.05, width: cw * 0.06, height: ch * 0.22))
            ctx.restoreGState()
        }
    }

    static func oldKey(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.saveGState()
            ctx.translateBy(x: r.midX, y: r.midY)
            ctx.rotate(by: 0.3)
            let len = r.width * 0.8, t = r.height * 0.14
            ctx.setFillColor(rgb(0.62, 0.55, 0.32, 1))
            ctx.fill(CGRect(x: -len * 0.2, y: -t / 2, width: len * 0.7, height: t))
            ctx.setStrokeColor(rgb(0.62, 0.55, 0.32, 1))
            ctx.setLineWidth(t * 0.9)
            ctx.strokeEllipse(in: CGRect(x: -len * 0.45, y: -t * 1.9, width: t * 5, height: t * 3.8))
            ctx.setFillColor(rgb(0.62, 0.55, 0.32, 1))
            ctx.fill(CGRect(x: len * 0.36, y: -t * 1.7, width: t * 0.9, height: t * 1.7))
            ctx.fill(CGRect(x: len * 0.2, y: -t * 1.4, width: t * 0.8, height: t * 1.4))
            // etiqueta
            ctx.setFillColor(rgb(0.9, 0.88, 0.78, 1))
            ctx.fill(CGRect(x: -len * 0.55, y: t * 1.2, width: t * 4.6, height: t * 2.6))
            ctx.setFillColor(rgb(0.2, 0.18, 0.16, 1))
            ctx.fill(CGRect(x: -len * 0.5, y: t * 2.0, width: t * 3.4, height: t * 0.5))
            ctx.restoreGState()
        }
    }

    static func badge(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.saveGState()
            ctx.translateBy(x: r.midX, y: r.midY)
            ctx.rotate(by: -0.15)
            let cw = r.width * 0.7, ch = r.height * 0.85
            ctx.setFillColor(rgb(0.94, 0.94, 0.92, 1))
            ctx.fill(CGRect(x: -cw / 2, y: -ch / 2, width: cw, height: ch))
            ctx.setFillColor(rgb(0.16, 0.24, 0.4, 1))
            ctx.fill(CGRect(x: -cw / 2, y: -ch / 2, width: cw, height: ch * 0.28))
            ctx.setFillColor(rgb(0.6, 0.62, 0.66, 1))
            ctx.fillEllipse(in: CGRect(x: -cw * 0.28, y: -ch * 0.12, width: cw * 0.3, height: cw * 0.3))
            ctx.setFillColor(rgb(0.3, 0.3, 0.32, 1))
            for i in 0..<3 {
                ctx.fill(CGRect(x: cw * 0.08, y: -ch * 0.1 + CGFloat(i) * ch * 0.11, width: cw * 0.32, height: ch * 0.05))
            }
            // cordão arrebentado
            ctx.setStrokeColor(rgb(0.2, 0.2, 0.25, 1))
            ctx.setLineWidth(max(1, cw * 0.05))
            ctx.move(to: CGPoint(x: -cw * 0.1, y: ch / 2))
            ctx.addLine(to: CGPoint(x: -cw * 0.35, y: ch * 0.85))
            ctx.strokePath()
            ctx.restoreGState()
        }
    }

    /// Palavra escrita com o dedo no vidro embaçado.
    static func writtenWord(width: Int, height: Int, region: CGRect, word: String) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: r.height * 0.78, weight: .heavy),
                .foregroundColor: NSColor(calibratedRed: 0.08, green: 0.1, blue: 0.12, alpha: 0.92),
            ]
            let s = NSAttributedString(string: word, attributes: attrs)
            let size = s.size()
            ctx.saveGState()
            ctx.translateBy(x: r.midX, y: r.midY)
            ctx.scaleBy(x: 1, y: -1)
            let g = NSGraphicsContext(cgContext: ctx, flipped: true)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = g
            s.draw(at: NSPoint(x: -size.width / 2, y: -size.height / 2))
            NSGraphicsContext.restoreGraphicsState()
            ctx.restoreGState()
        }
    }

    /// Riscos de sola de sapato na cornija.
    static func scuffs(width: Int, height: Int, region: CGRect) -> [UInt8] {
        var g = SplitMix(seed: 77)
        return rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            for i in 0..<5 {
                let x = r.minX + r.width * (0.06 + CGFloat(i) * 0.2)
                ctx.saveGState()
                ctx.translateBy(x: x, y: r.midY + g.range(-r.height * 0.2, r.height * 0.2))
                ctx.rotate(by: g.range(-0.3, 0.3))
                ctx.setFillColor(rgb(0.13, 0.12, 0.12, 0.85))
                let w = r.width * 0.14, h = r.height * 0.5
                ctx.fill(CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
                ctx.setFillColor(rgb(0.3, 0.28, 0.28, 0.7))
                for k in 0..<4 {
                    ctx.fill(CGRect(x: -w / 2, y: -h / 2 + CGFloat(k) * h * 0.24, width: w, height: h * 0.06))
                }
                ctx.restoreGState()
            }
        }
    }

    static func burntOverall(width: Int, height: Int, region: CGRect) -> [UInt8] {
        var g = SplitMix(seed: 91)
        return rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.setFillColor(rgb(0.28, 0.32, 0.42, 1))
            ctx.fill(CGRect(x: r.minX + r.width * 0.2, y: r.minY, width: r.width * 0.6, height: r.height * 0.62))
            ctx.fill(CGRect(x: r.minX + r.width * 0.05, y: r.minY + r.height * 0.06, width: r.width * 0.9, height: r.height * 0.22))
            // queimado
            ctx.setFillColor(rgb(0.08, 0.07, 0.07, 1))
            for _ in 0..<40 {
                let s = g.range(r.width * 0.06, r.width * 0.26)
                ctx.fillEllipse(in: CGRect(x: g.range(r.minX, r.maxX - s), y: g.range(r.minY + r.height * 0.3, r.maxY - s), width: s, height: s))
            }
            // bordado do nome
            ctx.setFillColor(rgb(0.9, 0.86, 0.7, 1))
            ctx.fill(CGRect(x: r.minX + r.width * 0.26, y: r.minY + r.height * 0.12, width: r.width * 0.26, height: r.height * 0.06))
        }
    }

    static func cart(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.setFillColor(rgb(0.55, 0.54, 0.5, 1))
            ctx.fill(CGRect(x: r.minX + r.width * 0.1, y: r.minY + r.height * 0.25, width: r.width * 0.55, height: r.height * 0.5))
            ctx.setFillColor(rgb(0.3, 0.29, 0.27, 1))
            ctx.fill(CGRect(x: r.minX + r.width * 0.12, y: r.minY + r.height * 0.72, width: r.width * 0.5, height: r.height * 0.08))
            // balde
            ctx.setFillColor(rgb(0.35, 0.42, 0.45, 1))
            ctx.fillEllipse(in: CGRect(x: r.minX + r.width * 0.68, y: r.minY + r.height * 0.42, width: r.width * 0.24, height: r.height * 0.34))
            // rodo, limpo
            ctx.setStrokeColor(rgb(0.72, 0.66, 0.5, 1))
            ctx.setLineWidth(max(1.5, r.height * 0.05))
            ctx.move(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY + r.height * 0.24))
            ctx.addLine(to: CGPoint(x: r.minX + r.width * 0.42, y: r.minY - r.height * 0.18))
            ctx.strokePath()
            ctx.setFillColor(rgb(0.1, 0.1, 0.1, 1))
            ctx.fill(CGRect(x: r.minX + r.width * 0.3, y: r.minY - r.height * 0.24, width: r.width * 0.26, height: r.height * 0.07))
        }
    }

    static func gondola(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.setStrokeColor(rgb(0.5, 0.48, 0.42, 1))
            ctx.setLineWidth(max(1.5, r.width * 0.02))
            ctx.move(to: CGPoint(x: r.minX + r.width * 0.28, y: r.minY))
            ctx.addLine(to: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.55))
            ctx.strokePath()
            // cabo rompido do outro lado
            ctx.move(to: CGPoint(x: r.minX + r.width * 0.76, y: r.minY))
            ctx.addLine(to: CGPoint(x: r.minX + r.width * 0.8, y: r.minY + r.height * 0.28))
            ctx.strokePath()
            // plataforma tombada
            ctx.saveGState()
            ctx.translateBy(x: r.midX, y: r.minY + r.height * 0.66)
            ctx.rotate(by: 0.24)
            ctx.setFillColor(rgb(0.42, 0.4, 0.36, 1))
            ctx.fill(CGRect(x: -r.width * 0.32, y: -r.height * 0.07, width: r.width * 0.64, height: r.height * 0.14))
            ctx.setStrokeColor(rgb(0.42, 0.4, 0.36, 1))
            ctx.setLineWidth(max(1, r.width * 0.014))
            ctx.stroke(CGRect(x: -r.width * 0.32, y: -r.height * 0.3, width: r.width * 0.64, height: r.height * 0.3))
            ctx.restoreGState()
        }
    }

    static func paper(width: Int, height: Int, region: CGRect, title: String, lines: Int, tint: (CGFloat, CGFloat, CGFloat), torn: Bool) -> [UInt8] {
        var g = SplitMix(seed: UInt64(title.count) &+ 5)
        return rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.saveGState()
            ctx.translateBy(x: r.midX, y: r.midY)
            ctx.rotate(by: g.range(-0.16, 0.16))
            let w = r.width * 0.92, h = r.height * 0.92
            ctx.setFillColor(rgb(tint.0, tint.1, tint.2, 1))
            if torn {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: -w / 2, y: -h / 2))
                p.addLine(to: CGPoint(x: w / 2, y: -h / 2))
                p.addLine(to: CGPoint(x: w / 2, y: h / 2))
                var x = w / 2
                while x > -w / 2 {
                    p.addLine(to: CGPoint(x: x, y: h / 2 - g.range(0, h * 0.14)))
                    x -= w * 0.08
                }
                p.addLine(to: CGPoint(x: -w / 2, y: h / 2))
                p.closeSubpath()
                ctx.addPath(p)
                ctx.fillPath()
            } else {
                ctx.fill(CGRect(x: -w / 2, y: -h / 2, width: w, height: h))
            }
            // título
            ctx.setFillColor(rgb(0.15, 0.14, 0.13, 0.9))
            ctx.fill(CGRect(x: -w * 0.34, y: -h * 0.38, width: w * 0.5, height: h * 0.07))
            // linhas de texto
            ctx.setFillColor(rgb(0.25, 0.24, 0.22, 0.65))
            for i in 0..<lines {
                let y = -h * 0.22 + CGFloat(i) * (h * 0.62 / CGFloat(max(1, lines)))
                ctx.fill(CGRect(x: -w * 0.36, y: y, width: w * g.range(0.4, 0.72), height: max(1, h * 0.028)))
            }
            // assinatura
            ctx.setStrokeColor(rgb(0.1, 0.12, 0.35, 0.85))
            ctx.setLineWidth(max(1, h * 0.02))
            ctx.move(to: CGPoint(x: w * 0.02, y: h * 0.34))
            ctx.addCurve(to: CGPoint(x: w * 0.34, y: h * 0.32),
                         control1: CGPoint(x: w * 0.12, y: h * 0.2),
                         control2: CGPoint(x: w * 0.22, y: h * 0.44))
            ctx.strokePath()
            ctx.restoreGState()
        }
    }

    static func blueprint(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let r = inRegion(region, width, height)
            ctx.setFillColor(rgb(0.13, 0.24, 0.42, 1))
            ctx.fill(r)
            ctx.setStrokeColor(rgb(0.82, 0.88, 0.95, 0.9))
            ctx.setLineWidth(max(1, r.height * 0.012))
            // corte do prédio: oito andares
            let floors = 8
            let fh = r.height * 0.82 / CGFloat(floors)
            for i in 0..<floors {
                let y = r.minY + r.height * 0.1 + CGFloat(i) * fh
                ctx.stroke(CGRect(x: r.minX + r.width * 0.2, y: y, width: r.width * 0.6, height: fh))
                for k in 0..<4 {
                    let x = r.minX + r.width * (0.26 + CGFloat(k) * 0.14)
                    ctx.stroke(CGRect(x: x, y: y + fh * 0.25, width: r.width * 0.06, height: fh * 0.45))
                }
            }
            // o oitavo riscado a tinta
            let topY = r.minY + r.height * 0.1
            ctx.setStrokeColor(rgb(0.75, 0.12, 0.12, 0.95))
            ctx.setLineWidth(max(1.5, r.height * 0.02))
            ctx.move(to: CGPoint(x: r.minX + r.width * 0.18, y: topY - fh * 0.1))
            ctx.addLine(to: CGPoint(x: r.minX + r.width * 0.82, y: topY + fh * 1.1))
            ctx.move(to: CGPoint(x: r.minX + r.width * 0.18, y: topY + fh * 1.1))
            ctx.addLine(to: CGPoint(x: r.minX + r.width * 0.82, y: topY - fh * 0.1))
            ctx.strokePath()
        }
    }
}
