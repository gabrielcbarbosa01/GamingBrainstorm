//
//  Draw.swift
//  Guardiões dos Biomas
//
//  Utilitários de desenho. Todo sprite do jogo nasce de um CGContext — não há
//  um único arquivo de imagem no projeto.
//

import SpriteKit
import CoreGraphics

enum Draw {

    /// Desenha num contexto de bitmap sRGB e devolve a imagem resultante.
    static func cgImage(width: Int, height: Int, _ body: (CGContext) -> Void) -> CGImage? {
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: max(1, width), height: max(1, height),
                                  bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        // Todo o desenho do jogo é escrito em coordenadas de tela (Y cresce para
        // baixo): cabeça do bicho no topo, base da árvore embaixo. O CoreGraphics
        // usa Y para cima, então invertemos aqui, num lugar só.
        ctx.translateBy(x: 0, y: CGFloat(max(1, height)))
        ctx.scaleBy(x: 1, y: -1)
        body(ctx)
        return ctx.makeImage()
    }

    /// Cria uma textura de SpriteKit a partir do mesmo desenho.
    static func texture(width: Int, height: Int, _ body: (CGContext) -> Void) -> SKTexture {
        guard let img = cgImage(width: width, height: height, body) else { return SKTexture() }
        return SKTexture(cgImage: img)
    }

    // MARK: Primitivas

    static func fill(_ ctx: CGContext, _ rect: CGRect, _ color: SKColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
    }

    static func ellipse(_ ctx: CGContext, _ rect: CGRect, _ color: SKColor) {
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: rect)
    }

    static func circle(_ ctx: CGContext, _ center: CGPoint, _ radius: CGFloat, _ color: SKColor) {
        ellipse(ctx, CGRect(x: center.x - radius, y: center.y - radius,
                            width: radius * 2, height: radius * 2), color)
    }

    static func roundRect(_ ctx: CGContext, _ rect: CGRect, radius: CGFloat, _ color: SKColor) {
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        ctx.setFillColor(color.cgColor)
        ctx.addPath(path)
        ctx.fillPath()
    }

    static func line(_ ctx: CGContext, from a: CGPoint, to b: CGPoint,
                     width: CGFloat, _ color: SKColor, round: Bool = true) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.setLineCap(round ? .round : .butt)
        ctx.move(to: a)
        ctx.addLine(to: b)
        ctx.strokePath()
    }

    static func polygon(_ ctx: CGContext, _ pts: [CGPoint], _ color: SKColor) {
        guard pts.count > 2 else { return }
        ctx.setFillColor(color.cgColor)
        ctx.move(to: pts[0])
        for p in pts.dropFirst() { ctx.addLine(to: p) }
        ctx.closePath()
        ctx.fillPath()
    }

    /// Curva quadrática preenchida — útil para asas, caudas e folhas.
    static func leaf(_ ctx: CGContext, from a: CGPoint, to b: CGPoint,
                     bulge: CGFloat, _ color: SKColor) {
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let dx = b.x - a.x, dy = b.y - a.y
        let len = max(0.001, (dx * dx + dy * dy).squareRoot())
        let nx = -dy / len, ny = dx / len
        let c1 = CGPoint(x: mid.x + nx * bulge, y: mid.y + ny * bulge)
        let c2 = CGPoint(x: mid.x - nx * bulge, y: mid.y - ny * bulge)
        ctx.setFillColor(color.cgColor)
        ctx.move(to: a)
        ctx.addQuadCurve(to: b, control: c1)
        ctx.addQuadCurve(to: a, control: c2)
        ctx.fillPath()
    }

    /// Sombra elíptica sob personagens e props.
    static func shadow(_ ctx: CGContext, center: CGPoint, w: CGFloat, h: CGFloat, alpha: CGFloat = 0.24) {
        ellipse(ctx, CGRect(x: center.x - w / 2, y: center.y - h / 2, width: w, height: h),
                SKColor(white: 0, alpha: alpha))
    }
}

extension Draw {
    /// Executa um desenho sob rotação/escala em torno de um pivô. É o que
    /// permite inclinar o corpo inteiro de um bicho numa investida ou num voo.
    static func transformed(_ ctx: CGContext, pivot: CGPoint,
                            rotation: CGFloat = 0,
                            scaleX: CGFloat = 1, scaleY: CGFloat = 1,
                            _ body: (CGContext) -> Void) {
        ctx.saveGState()
        ctx.translateBy(x: pivot.x, y: pivot.y)
        ctx.rotate(by: rotation)
        ctx.scaleBy(x: scaleX, y: scaleY)
        ctx.translateBy(x: -pivot.x, y: -pivot.y)
        body(ctx)
        ctx.restoreGState()
    }
}
