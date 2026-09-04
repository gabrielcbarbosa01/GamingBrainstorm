//
//  Textures.swift
//  TurnoMac
//
//  Texturas procedurais desenhadas com CoreGraphics: sujeira, poeira, mancha
//  de vinho e as "provas" escondidas por baixo (marca de mão, bituca, cartão).
//  Sem assets externos no vertical slice.
//

import AppKit
import CoreGraphics

enum Textures {
    /// Buffer RGBA (premultiplied) desenhado por `draw`. Linha 0 = topo.
    static func rgba(width: Int, height: Int, draw: (CGContext) -> Void) -> [UInt8] {
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        pixels.withUnsafeMutableBytes { buf in
            let ctx = CGContext(data: buf.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            // CG tem origem embaixo; queremos linha 0 no topo.
            ctx.translateBy(x: 0, y: CGFloat(height))
            ctx.scaleBy(x: 1, y: -1)
            draw(ctx)
        }
        return pixels
    }

    private static func rand(_ g: inout SplitMix, _ a: CGFloat, _ b: CGFloat) -> CGFloat {
        a + (b - a) * CGFloat(g.next())
    }

    /// Sujeira de vidro: película cinza-marrom + gotas e escorridos.
    static func glassGrime(width: Int, height: Int, seed: UInt64 = 7) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            ctx.setFillColor(NSColor(calibratedRed: 0.42, green: 0.38, blue: 0.32, alpha: 0.78).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for _ in 0..<900 {
                let r = rand(&g, 2, 14)
                ctx.setFillColor(NSColor(calibratedRed: 0.3, green: 0.27, blue: 0.22, alpha: rand(&g, 0.15, 0.6)).cgColor)
                ctx.fillEllipse(in: CGRect(x: rand(&g, -10, w), y: rand(&g, -10, h), width: r, height: r * rand(&g, 0.6, 1.4)))
            }
            for _ in 0..<40 {
                let x = rand(&g, 0, w)
                ctx.setFillColor(NSColor(calibratedRed: 0.25, green: 0.22, blue: 0.18, alpha: rand(&g, 0.3, 0.7)).cgColor)
                ctx.fill(CGRect(x: x, y: rand(&g, 0, h * 0.5), width: rand(&g, 1, 3), height: rand(&g, 20, h * 0.6)))
            }
        }
    }

    /// Poeira de carpete: véu bege com fiapos.
    static func dust(width: Int, height: Int, seed: UInt64 = 11) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            ctx.setFillColor(NSColor(calibratedRed: 0.5, green: 0.46, blue: 0.38, alpha: 0.55).cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            for _ in 0..<1400 {
                ctx.setFillColor(NSColor(calibratedRed: 0.6, green: 0.56, blue: 0.47, alpha: rand(&g, 0.2, 0.8)).cgColor)
                let r = rand(&g, 1, 6)
                ctx.fillEllipse(in: CGRect(x: rand(&g, 0, w), y: rand(&g, 0, h), width: r * 3, height: r))
            }
            for _ in 0..<120 {
                ctx.setStrokeColor(NSColor(calibratedRed: 0.5, green: 0.47, blue: 0.4, alpha: rand(&g, 0.3, 0.8)).cgColor)
                ctx.setLineWidth(rand(&g, 0.5, 1.5))
                let x = rand(&g, 0, w), y = rand(&g, 0, h)
                ctx.move(to: CGPoint(x: x, y: y))
                ctx.addLine(to: CGPoint(x: x + rand(&g, -12, 12), y: y + rand(&g, -12, 12)))
                ctx.strokePath()
            }
        }
    }

    /// Mancha de vinho na mesa.
    static func wineStain(width: Int, height: Int, seed: UInt64 = 3) -> [UInt8] {
        var g = SplitMix(seed: seed)
        return rgba(width: width, height: height) { ctx in
            let w = CGFloat(width), h = CGFloat(height)
            for _ in 0..<60 {
                let r = rand(&g, 20, 70)
                ctx.setFillColor(NSColor(calibratedRed: 0.22, green: 0.02, blue: 0.07, alpha: rand(&g, 0.6, 0.95)).cgColor)
                ctx.fillEllipse(in: CGRect(x: rand(&g, w * 0.1, w * 0.8), y: rand(&g, h * 0.1, h * 0.8), width: r, height: r * rand(&g, 0.6, 1.2)))
            }
            for _ in 0..<200 {
                let r = rand(&g, 2, 8)
                ctx.setFillColor(NSColor(calibratedRed: 0.18, green: 0.02, blue: 0.06, alpha: rand(&g, 0.4, 0.9)).cgColor)
                ctx.fillEllipse(in: CGRect(x: rand(&g, 0, w), y: rand(&g, 0, h), width: r, height: r))
            }
        }
    }

    /// Marca de mão espalmada (vista do lado de fora do vidro).
    static func handprint(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let rx = region.minX * CGFloat(width), ry = (1 - region.maxY) * CGFloat(height)
            let rw = region.width * CGFloat(width), rh = region.height * CGFloat(height)
            ctx.setFillColor(NSColor(calibratedRed: 0.32, green: 0.12, blue: 0.08, alpha: 0.9).cgColor)
            // palma
            ctx.fillEllipse(in: CGRect(x: rx + rw * 0.25, y: ry + rh * 0.45, width: rw * 0.5, height: rh * 0.5))
            // dedos
            let fingers: [(CGFloat, CGFloat, CGFloat)] = [(0.22, 0.05, 0.42), (0.36, 0.0, 0.5), (0.5, 0.0, 0.52), (0.64, 0.06, 0.45)]
            for (fx, fy, fl) in fingers {
                ctx.fillEllipse(in: CGRect(x: rx + rw * fx, y: ry + rh * fy, width: rw * 0.13, height: rh * fl))
            }
            // polegar
            ctx.saveGState()
            ctx.translateBy(x: rx + rw * 0.12, y: ry + rh * 0.55)
            ctx.rotate(by: -0.7)
            ctx.fillEllipse(in: CGRect(x: 0, y: 0, width: rw * 0.14, height: rh * 0.34))
            ctx.restoreGState()
            // escorrido embaixo da palma
            ctx.setFillColor(NSColor(calibratedRed: 0.32, green: 0.12, blue: 0.08, alpha: 0.6).cgColor)
            ctx.fill(CGRect(x: rx + rw * 0.55, y: ry + rh * 0.9, width: rw * 0.04, height: rh * 0.25))
        }
    }

    /// Bituca de cigarro com marca de batom.
    static func cigarette(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let rx = region.minX * CGFloat(width), ry = (1 - region.maxY) * CGFloat(height)
            let rw = region.width * CGFloat(width), rh = region.height * CGFloat(height)
            ctx.saveGState()
            ctx.translateBy(x: rx + rw * 0.5, y: ry + rh * 0.5)
            ctx.rotate(by: 0.5)
            let len = rw * 0.9, thick = rh * 0.28
            ctx.setFillColor(NSColor(calibratedWhite: 0.92, alpha: 1).cgColor)
            ctx.fill(CGRect(x: -len / 2, y: -thick / 2, width: len * 0.6, height: thick))
            ctx.setFillColor(NSColor(calibratedRed: 0.85, green: 0.6, blue: 0.3, alpha: 1).cgColor)
            ctx.fill(CGRect(x: len * 0.1, y: -thick / 2, width: len * 0.32, height: thick))
            ctx.setFillColor(NSColor(calibratedRed: 0.8, green: 0.1, blue: 0.2, alpha: 1).cgColor)
            ctx.fill(CGRect(x: len * 0.3, y: -thick / 2, width: len * 0.12, height: thick))
            ctx.setFillColor(NSColor(calibratedWhite: 0.2, alpha: 1).cgColor)
            ctx.fill(CGRect(x: -len / 2, y: -thick / 2, width: len * 0.06, height: thick))
            ctx.restoreGState()
        }
    }

    /// Cartão-chave da suíte 7.
    static func keycard(width: Int, height: Int, region: CGRect) -> [UInt8] {
        rgba(width: width, height: height) { ctx in
            let rx = region.minX * CGFloat(width), ry = (1 - region.maxY) * CGFloat(height)
            let rw = region.width * CGFloat(width), rh = region.height * CGFloat(height)
            ctx.saveGState()
            ctx.translateBy(x: rx + rw * 0.5, y: ry + rh * 0.5)
            ctx.rotate(by: -0.25)
            let cw = rw * 0.85, ch = rh * 0.6
            ctx.setFillColor(NSColor(calibratedWhite: 0.95, alpha: 1).cgColor)
            ctx.fill(CGRect(x: -cw / 2, y: -ch / 2, width: cw, height: ch))
            ctx.setFillColor(NSColor(calibratedRed: 0.75, green: 0.6, blue: 0.2, alpha: 1).cgColor)
            ctx.fill(CGRect(x: -cw / 2, y: -ch / 2 + ch * 0.2, width: cw, height: ch * 0.18))
            ctx.setFillColor(NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.15, alpha: 1).cgColor)
            ctx.fill(CGRect(x: -cw / 2, y: ch / 2 - ch * 0.2, width: cw, height: ch * 0.12))
            // "7" grande
            ctx.setFillColor(NSColor(calibratedRed: 0.4, green: 0.05, blue: 0.1, alpha: 1).cgColor)
            ctx.fill(CGRect(x: cw * 0.15, y: -ch * 0.05, width: cw * 0.2, height: ch * 0.06))
            ctx.fill(CGRect(x: cw * 0.28, y: -ch * 0.05, width: cw * 0.06, height: ch * 0.22))
            ctx.restoreGState()
        }
    }
}

/// Gerador determinístico simples (sem depender de seed global).
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
}
