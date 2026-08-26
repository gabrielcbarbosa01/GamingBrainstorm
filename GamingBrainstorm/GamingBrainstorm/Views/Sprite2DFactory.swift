//
//  Sprite2DFactory.swift
//  Guardiões dos Biomas
//
//  Fábrica procedural de sprites 2D de alta resolução para estética 2.5D (billboards).
//  Gera texturas com transparência via CoreGraphics em tempo de execução,
//  com cache em memória e suporte a substituição por arquivos PNG em Assets.xcassets.
//

#if os(macOS)
import AppKit
import CoreGraphics

public final class Sprite2DFactory {
    public static let shared = Sprite2DFactory()
    
    private var imageCache: [String: NSImage] = [:]
    
    private init() {}
    
    // MARK: - Core Bitmap Context Renderer
    private func renderImage(width: Int, height: Int, key: String, draw: (CGContext, CGFloat, CGFloat) -> Void) -> NSImage {
        if let cached = imageCache[key] {
            return cached
        }
        
        // Suporte a asset customizado existente no projeto
        if let custom = NSImage(named: key) {
            imageCache[key] = custom
            return custom
        }
        
        let w = CGFloat(width)
        let h = CGFloat(height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            let fallback = NSImage(size: NSSize(width: width, height: height))
            return fallback
        }
        
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
        
        // Coordenadas orientadas com Y para cima
        draw(ctx, w, h)
        
        guard let cgImg = ctx.makeImage() else {
            return NSImage(size: NSSize(width: width, height: height))
        }
        
        let nsImg = NSImage(cgImage: cgImg, size: NSSize(width: width, height: height))
        imageCache[key] = nsImg
        return nsImg
    }
    
    // MARK: - 1. Portais Místicos dos Biomas (2.5D)
    public func portalImage(for portal: BiomePortal) -> NSImage {
        let key = "sprite_portal_\(portal.id)"
        return renderImage(width: 280, height: 360, key: key) { ctx, w, h in
            let cx = w / 2
            let pColor = portal.nsColor
            
            // Sombra oval na base do portal
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.28).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 110, y: 8, width: 220, height: 36))
            
            // Coluna Esquerda de Pedra Talhada
            let leftPillar = CGRect(x: cx - 96, y: 24, width: 38, height: 260)
            ctx.setFillColor(NSColor(red: 0.44, green: 0.42, blue: 0.40, alpha: 1.0).cgColor)
            ctx.fill(leftPillar)
            ctx.setFillColor(NSColor(red: 0.36, green: 0.34, blue: 0.32, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 96, y: 24, width: 10, height: 260))
            
            // Coluna Direita de Pedra Talhada
            let rightPillar = CGRect(x: cx + 58, y: 24, width: 38, height: 260)
            ctx.setFillColor(NSColor(red: 0.44, green: 0.42, blue: 0.40, alpha: 1.0).cgColor)
            ctx.fill(rightPillar)
            ctx.setFillColor(NSColor(red: 0.50, green: 0.48, blue: 0.46, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx + 86, y: 24, width: 10, height: 260))
            
            // Base dos Pilares
            ctx.setFillColor(NSColor(red: 0.32, green: 0.30, blue: 0.28, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 106, y: 16, width: 58, height: 24))
            ctx.fill(CGRect(x: cx + 48, y: 16, width: 58, height: 24))
            
            // Lintel Superior Arqueado
            ctx.setFillColor(NSColor(red: 0.48, green: 0.46, blue: 0.44, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 108, y: 274, width: 216, height: 42))
            ctx.setFillColor(NSColor(red: 0.56, green: 0.54, blue: 0.52, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 108, y: 310, width: 216, height: 10))
            
            // Vórtice Místico Central (Energia do Bioma)
            let vortexRect = CGRect(x: cx - 56, y: 44, width: 112, height: 226)
            ctx.setFillColor(pColor.withAlphaComponent(0.20).cgColor)
            ctx.fillEllipse(in: vortexRect.insetBy(dx: -12, dy: -12))
            ctx.setFillColor(pColor.withAlphaComponent(0.55).cgColor)
            ctx.fillEllipse(in: vortexRect)
            ctx.setFillColor(pColor.withAlphaComponent(0.85).cgColor)
            ctx.fillEllipse(in: vortexRect.insetBy(dx: 22, dy: 30))
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.92).cgColor)
            ctx.fillEllipse(in: vortexRect.insetBy(dx: 42, dy: 65))
            
            // Runa Mística Central
            ctx.setStrokeColor(NSColor.white.cgColor)
            ctx.setLineWidth(4.0)
            ctx.addEllipse(in: CGRect(x: cx - 22, y: 135, width: 44, height: 44))
            ctx.move(to: CGPoint(x: cx, y: 125))
            ctx.addLine(to: CGPoint(x: cx, y: 189))
            ctx.strokePath()
            
            // Musgo e Trepadeiras nas Pedras
            ctx.setFillColor(NSColor(red: 0.22, green: 0.52, blue: 0.26, alpha: 0.85).cgColor)
            for my in [40, 85, 140, 210, 278] as [CGFloat] {
                ctx.fillEllipse(in: CGRect(x: cx - 94, y: my, width: 16, height: 12))
                ctx.fillEllipse(in: CGRect(x: cx + 78, y: my + 15, width: 14, height: 10))
            }
        }
    }
    
    // MARK: - 2. Oficina de Campo (2.5D)
    public func workshopImage() -> NSImage {
        let key = "sprite_refugio_oficina"
        return renderImage(width: 320, height: 280, key: key) { ctx, w, h in
            let cx = w / 2
            
            // Sombra
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.25).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 130, y: 10, width: 260, height: 35))
            
            // Estrutura de Madeira (Pilares)
            ctx.setFillColor(NSColor(red: 0.36, green: 0.24, blue: 0.16, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 110, y: 24, width: 18, height: 155))
            ctx.fill(CGRect(x: cx + 92, y: 24, width: 18, height: 155))
            
            // Parede de Fundo e Tábua de Ferramentas
            ctx.setFillColor(NSColor(red: 0.48, green: 0.36, blue: 0.24, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 96, y: 55, width: 192, height: 120))
            
            // Bancada de Trabalho
            ctx.setFillColor(NSColor(red: 0.58, green: 0.42, blue: 0.28, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 118, y: 45, width: 236, height: 42))
            ctx.setFillColor(NSColor(red: 0.44, green: 0.30, blue: 0.18, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 118, y: 35, width: 236, height: 10))
            
            // Ferramentas Penduradas (Martelo, Serrote, Alicate)
            ctx.setFillColor(NSColor(red: 0.72, green: 0.74, blue: 0.78, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 60, y: 120, width: 22, height: 8)) // Cabeça martelo
            ctx.setFillColor(NSColor(red: 0.42, green: 0.26, blue: 0.16, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 52, y: 92, width: 6, height: 32))  // Cabo martelo
            
            // Serrote de Campo
            ctx.setFillColor(NSColor(red: 0.78, green: 0.80, blue: 0.84, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 10, y: 105, width: 42, height: 14))
            
            // Baú de Suprimentos ao Lado
            ctx.setFillColor(NSColor(red: 0.38, green: 0.24, blue: 0.15, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx + 45, y: 22, width: 56, height: 38))
            ctx.setFillColor(NSColor(red: 0.85, green: 0.70, blue: 0.25, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx + 69, y: 32, width: 8, height: 12)) // Fechadura dourada
            
            // Telhado Cerâmico de Duas Águas
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: cx - 145, y: 172))
            roofPath.addLine(to: CGPoint(x: cx, y: 260))
            roofPath.addLine(to: CGPoint(x: cx + 145, y: 172))
            roofPath.closeSubpath()
            ctx.setFillColor(NSColor(red: 0.68, green: 0.30, blue: 0.18, alpha: 1.0).cgColor)
            ctx.addPath(roofPath)
            ctx.fillPath()
            
            // Borda do Telhado
            ctx.setFillColor(NSColor(red: 0.52, green: 0.22, blue: 0.12, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 145, y: 164, width: 290, height: 12))
        }
    }
    
    // MARK: - 3. Cais do Açude de Pesca (2.5D)
    public func fishingDockImage() -> NSImage {
        let key = "sprite_refugio_cais"
        return renderImage(width: 280, height: 240, key: key) { ctx, w, h in
            let cx = w / 2
            
            // Água límpida sob o píer
            ctx.setFillColor(NSColor(red: 0.16, green: 0.58, blue: 0.74, alpha: 0.60).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 120, y: 6, width: 240, height: 48))
            
            // Estacas do Cais fincadas na água
            ctx.setFillColor(NSColor(red: 0.34, green: 0.22, blue: 0.14, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 85, y: 18, width: 14, height: 85))
            ctx.fill(CGRect(x: cx + 71, y: 18, width: 14, height: 85))
            ctx.fill(CGRect(x: cx - 10, y: 18, width: 14, height: 95))
            
            // Deck de Tábuas de Madeira
            for i in 0..<7 {
                let ty = 92 + CGFloat(i * 12)
                let cTone = (i % 2 == 0) ? 0.52 : 0.46
                ctx.setFillColor(NSColor(red: cTone, green: 0.36, blue: 0.24, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 95, y: ty, width: 190, height: 10))
            }
            
            // Cabeço de Amarração com Corda Náutica
            ctx.setFillColor(NSColor(red: 0.28, green: 0.18, blue: 0.12, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 88, y: 175, width: 16, height: 26))
            ctx.setFillColor(NSColor(red: 0.82, green: 0.76, blue: 0.60, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 90, y: 182, width: 20, height: 6))
            
            // Vara de Pescar Apoiada
            ctx.setStrokeColor(NSColor(red: 0.40, green: 0.28, blue: 0.18, alpha: 1.0).cgColor)
            ctx.setLineWidth(3.5)
            ctx.move(to: CGPoint(x: cx + 35, y: 120))
            ctx.addLine(to: CGPoint(x: cx + 115, y: 225))
            ctx.strokePath()
            
            // Linha e Boia Vermelha/Branca
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.8).cgColor)
            ctx.setLineWidth(1.2)
            ctx.move(to: CGPoint(x: cx + 115, y: 225))
            ctx.addLine(to: CGPoint(x: cx + 115, y: 40))
            ctx.strokePath()
            ctx.setFillColor(NSColor.red.cgColor)
            ctx.fillEllipse(in: CGRect(x: cx + 110, y: 35, width: 10, height: 10))
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: cx + 110, y: 35, width: 10, height: 5))
        }
    }
    
    // MARK: - 4. Canteiro do Viveiro de Mudas (2.5D)
    public func seedlingBedImage(index: Int) -> NSImage {
        let key = "sprite_refugio_canteiro_\(index)"
        return renderImage(width: 140, height: 110, key: key) { ctx, w, h in
            let cx = w / 2
            
            // Sombra
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.20).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 55, y: 4, width: 110, height: 22))
            
            // Moldura de Madeira do Canteiro
            ctx.setFillColor(NSColor(red: 0.42, green: 0.28, blue: 0.16, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 58, y: 14, width: 116, height: 38))
            
            // Terra Escura Adubada
            ctx.setFillColor(NSColor(red: 0.22, green: 0.14, blue: 0.08, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 52, y: 20, width: 104, height: 26))
            
            // Três Brotos Verdes de Mudas Nativas
            let sproutTints: [NSColor] = [
                NSColor(red: 0.20, green: 0.72, blue: 0.28, alpha: 1.0),
                NSColor(red: 0.28, green: 0.82, blue: 0.35, alpha: 1.0),
                NSColor(red: 0.18, green: 0.65, blue: 0.22, alpha: 1.0)
            ]
            for (i, sx) in [cx - 30, cx, cx + 30].enumerated() {
                let tint = sproutTints[i % sproutTints.count]
                // Haste
                ctx.setStrokeColor(tint.cgColor)
                ctx.setLineWidth(2.5)
                ctx.move(to: CGPoint(x: sx, y: 34))
                ctx.addLine(to: CGPoint(x: sx, y: 66))
                ctx.strokePath()
                
                // Folhas
                ctx.setFillColor(tint.cgColor)
                ctx.fillEllipse(in: CGRect(x: sx - 12, y: 55, width: 12, height: 8))
                ctx.fillEllipse(in: CGRect(x: sx, y: 58, width: 12, height: 8))
                ctx.fillEllipse(in: CGRect(x: sx - 5, y: 64, width: 10, height: 12))
            }
        }
    }
    
    // MARK: - 5. Altar Sagrado da Harpia (2.5D)
    public func harpiaAltarImage() -> NSImage {
        let key = "sprite_refugio_altar_harpia"
        return renderImage(width: 240, height: 300, key: key) { ctx, w, h in
            let cx = w / 2
            
            // Sombra
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.26).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 95, y: 8, width: 190, height: 32))
            
            // Degraus de Pedra
            ctx.setFillColor(NSColor(red: 0.52, green: 0.50, blue: 0.46, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 85, y: 16, width: 170, height: 22))
            ctx.setFillColor(NSColor(red: 0.60, green: 0.58, blue: 0.54, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 65, y: 38, width: 130, height: 24))
            
            // Monólito Cerimonial
            ctx.setFillColor(NSColor(red: 0.42, green: 0.40, blue: 0.38, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 35, y: 62, width: 70, height: 140))
            
            // Asas Sagradas da Harpia Entalhadas no Topo
            ctx.setFillColor(NSColor(red: 0.85, green: 0.72, blue: 0.30, alpha: 1.0).cgColor)
            // Asa esquerda
            let leftWing = CGMutablePath()
            leftWing.move(to: CGPoint(x: cx - 15, y: 190))
            leftWing.addLine(to: CGPoint(x: cx - 75, y: 265))
            leftWing.addLine(to: CGPoint(x: cx - 25, y: 220))
            leftWing.closeSubpath()
            ctx.addPath(leftWing)
            ctx.fillPath()
            
            // Asa direita
            let rightWing = CGMutablePath()
            rightWing.move(to: CGPoint(x: cx + 15, y: 190))
            rightWing.addLine(to: CGPoint(x: cx + 75, y: 265))
            rightWing.addLine(to: CGPoint(x: cx + 25, y: 220))
            rightWing.closeSubpath()
            ctx.addPath(rightWing)
            ctx.fillPath()
            
            // Disco Solar de Ouro no Topo
            ctx.setFillColor(NSColor(red: 1.0, green: 0.84, blue: 0.28, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 24, y: 205, width: 48, height: 48))
            ctx.setFillColor(NSColor.white.withAlphaComponent(0.8).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 14, y: 215, width: 28, height: 28))
        }
    }
    
    // MARK: - 6. Totens dos Biomas (2.5D)
    public func totemImage(for totem: BiomeTotem) -> NSImage {
        let key = "sprite_totem_\(totem.id)_\(totem.isPurified)"
        return renderImage(width: 180, height: 280, key: key) { ctx, w, h in
            let cx = w / 2
            let isPurified = totem.isPurified
            
            // Sombra
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.25).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 65, y: 6, width: 130, height: 24))
            
            // Base
            ctx.setFillColor(NSColor(red: 0.38, green: 0.36, blue: 0.34, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 45, y: 16, width: 90, height: 22))
            
            // Pilar de Pedra Ancestral
            let bodyColor = isPurified ?
                NSColor(red: 0.30, green: 0.52, blue: 0.36, alpha: 1.0) :
                NSColor(red: 0.42, green: 0.38, blue: 0.36, alpha: 1.0)
            ctx.setFillColor(bodyColor.cgColor)
            ctx.fill(CGRect(x: cx - 32, y: 38, width: 64, height: 185))
            
            // Topo Talhado
            ctx.setFillColor(NSColor(red: 0.48, green: 0.44, blue: 0.42, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 40, y: 223, width: 80, height: 26))
            
            // Runa Mística Entalhada
            let runeColor = isPurified ?
                NSColor(red: 0.35, green: 1.0, blue: 0.55, alpha: 0.95) :
                NSColor(red: 0.85, green: 0.30, blue: 0.25, alpha: 0.85)
            ctx.setStrokeColor(runeColor.cgColor)
            ctx.setLineWidth(4.0)
            ctx.addEllipse(in: CGRect(x: cx - 18, y: 125, width: 36, height: 36))
            ctx.move(to: CGPoint(x: cx, y: 85))
            ctx.addLine(to: CGPoint(x: cx, y: 195))
            ctx.strokePath()
            
            // Olhos Brilhantes da Entidade Guardiã
            ctx.setFillColor(runeColor.cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 18, y: 175, width: 10, height: 10))
            ctx.fillEllipse(in: CGRect(x: cx + 8, y: 175, width: 10, height: 10))
        }
    }
    
    // MARK: - 7. Ameaças e Inimigos (2.5D)
    public func enemyImage(for enemy: WorldEnemy) -> NSImage {
        let key = "sprite_enemy_\(enemy.type.rawValue)"
        return renderImage(width: 220, height: 220, key: key) { ctx, w, h in
            let cx = w / 2
            let cy = h / 2
            
            // Sombra
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.28).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 70, y: 10, width: 140, height: 28))
            
            switch enemy.type {
            case .poacher:
                // Caçador com lanterna e armadilha
                ctx.setFillColor(NSColor(red: 0.35, green: 0.28, blue: 0.18, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 26, y: 38, width: 52, height: 75)) // Casaco
                ctx.setFillColor(NSColor(red: 0.44, green: 0.38, blue: 0.28, alpha: 1.0).cgColor)
                ctx.fillEllipse(in: CGRect(x: cx - 34, y: 122, width: 68, height: 26)) // Chapéu
                ctx.fill(CGRect(x: cx - 20, y: 132, width: 40, height: 24))
                // Lanterna na mão
                ctx.setFillColor(NSColor.yellow.cgColor)
                ctx.fillEllipse(in: CGRect(x: cx + 28, y: 55, width: 14, height: 14))
                
            case .nestPoacher:
                // Saqueador de ninhos com gaiola e caixa nas costas
                ctx.setFillColor(NSColor(red: 0.28, green: 0.32, blue: 0.22, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 26, y: 38, width: 52, height: 75))
                ctx.setFillColor(NSColor(red: 0.44, green: 0.38, blue: 0.28, alpha: 1.0).cgColor)
                ctx.fillEllipse(in: CGRect(x: cx - 36, y: 125, width: 72, height: 26))
                ctx.fill(CGRect(x: cx - 22, y: 135, width: 44, height: 26))
                // Gaiola na mão
                ctx.setStrokeColor(NSColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0).cgColor)
                ctx.setLineWidth(2.5)
                ctx.stroke(CGRect(x: cx + 30, y: 40, width: 36, height: 42))
                
            case .chainsawCrew:
                // Motosserra e tora de madeira
                ctx.setFillColor(NSColor(red: 0.40, green: 0.25, blue: 0.15, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 80, y: 22, width: 160, height: 36)) // Tora
                ctx.setFillColor(NSColor(red: 0.90, green: 0.22, blue: 0.18, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 45, y: 62, width: 55, height: 42)) // Corpo motosserra
                ctx.setFillColor(NSColor(red: 0.75, green: 0.78, blue: 0.82, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx + 10, y: 72, width: 68, height: 18)) // Lâmina
                
            case .wildfireEntity:
                // Labaredas ardentes
                let firePath = CGMutablePath()
                firePath.move(to: CGPoint(x: cx - 55, y: 22))
                firePath.addLine(to: CGPoint(x: cx - 35, y: 130))
                firePath.addLine(to: CGPoint(x: cx - 10, y: 75))
                firePath.addLine(to: CGPoint(x: cx + 5, y: 160))
                firePath.addLine(to: CGPoint(x: cx + 25, y: 85))
                firePath.addLine(to: CGPoint(x: cx + 55, y: 140))
                firePath.addLine(to: CGPoint(x: cx + 55, y: 22))
                firePath.closeSubpath()
                ctx.setFillColor(NSColor(red: 0.95, green: 0.32, blue: 0.12, alpha: 1.0).cgColor)
                ctx.addPath(firePath)
                ctx.fillPath()
                ctx.setFillColor(NSColor(red: 1.0, green: 0.85, blue: 0.25, alpha: 0.95).cgColor)
                ctx.fillEllipse(in: CGRect(x: cx - 32, y: 30, width: 64, height: 80))
                
            case .malhadeiraNet:
                // Rede de pesca predatória com boias
                ctx.setStrokeColor(NSColor(red: 0.85, green: 0.90, blue: 0.95, alpha: 0.9).cgColor)
                ctx.setLineWidth(2.0)
                for gx in 0...5 {
                    let lx = cx - 65 + CGFloat(gx * 26)
                    ctx.move(to: CGPoint(x: lx, y: 25))
                    ctx.addLine(to: CGPoint(x: lx, y: 125))
                }
                for gy in 0...4 {
                    let ly = 25 + CGFloat(gy * 25)
                    ctx.move(to: CGPoint(x: cx - 65, y: ly))
                    ctx.addLine(to: CGPoint(x: cx + 65, y: ly))
                }
                ctx.strokePath()
                ctx.setFillColor(NSColor(red: 1.0, green: 0.45, blue: 0.15, alpha: 1.0).cgColor)
                for bx in [-55, -20, 15, 50] as [CGFloat] {
                    ctx.fillEllipse(in: CGRect(x: cx + bx, y: 120, width: 16, height: 16))
                }
                
            case .plowTractor:
                // Trator pesado com lâmina de arado
                ctx.setFillColor(NSColor(red: 0.95, green: 0.75, blue: 0.18, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 55, y: 55, width: 110, height: 50)) // Cabine
                ctx.setFillColor(NSColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1.0).cgColor)
                ctx.fillEllipse(in: CGRect(x: cx - 65, y: 22, width: 44, height: 44)) // Roda
                ctx.fillEllipse(in: CGRect(x: cx + 22, y: 22, width: 44, height: 44)) // Roda
                ctx.setFillColor(NSColor(red: 0.65, green: 0.68, blue: 0.72, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx + 62, y: 25, width: 18, height: 48)) // Lâmina
                
            case .surveillanceDrone:
                // Drone de queimada com hélices
                ctx.setFillColor(NSColor(red: 0.25, green: 0.25, blue: 0.28, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 35, y: 80, width: 70, height: 28))
                ctx.setFillColor(NSColor.red.cgColor)
                ctx.fillEllipse(in: CGRect(x: cx - 8, y: 72, width: 16, height: 16)) // Lente infravermelha
                // Braços e hélices
                ctx.setFillColor(NSColor.darkGray.cgColor)
                ctx.fill(CGRect(x: cx - 65, y: 90, width: 30, height: 6))
                ctx.fill(CGRect(x: cx + 35, y: 90, width: 30, height: 6))
                ctx.fillEllipse(in: CGRect(x: cx - 75, y: 94, width: 22, height: 6))
                ctx.fillEllipse(in: CGRect(x: cx + 53, y: 94, width: 22, height: 6))
            }
            _ = cy
        }
    }
    
    // MARK: - 8. Placa de Campo e Leitura (2.5D)
    public func fieldSignImage() -> NSImage {
        let key = "sprite_placa_campo"
        return renderImage(width: 160, height: 150, key: key) { ctx, w, h in
            let cx = w / 2
            
            // Sombra
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.22).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 45, y: 4, width: 90, height: 18))
            
            // Postes de Madeira
            ctx.setFillColor(NSColor(red: 0.36, green: 0.24, blue: 0.16, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 28, y: 12, width: 10, height: 95))
            ctx.fill(CGRect(x: cx + 18, y: 12, width: 10, height: 95))
            
            // Tábua Entalhada
            ctx.setFillColor(NSColor(red: 0.54, green: 0.38, blue: 0.24, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 60, y: 68, width: 120, height: 60))
            
            // Moldura da Tábua
            ctx.setStrokeColor(NSColor(red: 0.42, green: 0.28, blue: 0.18, alpha: 1.0).cgColor)
            ctx.setLineWidth(3.0)
            ctx.stroke(CGRect(x: cx - 58, y: 70, width: 116, height: 56))
            
            // Linhas de Texto Entalhado
            ctx.setFillColor(NSColor(red: 0.28, green: 0.18, blue: 0.12, alpha: 0.85).cgColor)
            ctx.fill(CGRect(x: cx - 42, y: 106, width: 84, height: 5))
            ctx.fill(CGRect(x: cx - 36, y: 94, width: 72, height: 5))
            ctx.fill(CGRect(x: cx - 40, y: 82, width: 80, height: 5))
        }
    }
    
    // MARK: - 9. NPCs Amigáveis da História (2.5D)
    public func npcImage(for npc: GameNPC) -> NSImage {
        let key = "sprite_npc_\(npc.id)"
        return renderImage(width: 160, height: 220, key: key) { ctx, w, h in
            let cx = w / 2
            
            // Sombra no chão
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.24).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 38, y: 6, width: 76, height: 18))
            
            // Corpo / Colete de Pesquisador de Campo
            ctx.setFillColor(NSColor(red: 0.25, green: 0.48, blue: 0.35, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 22, y: 34, width: 44, height: 72))
            
            // Bolsos do Colete
            ctx.setFillColor(NSColor(red: 0.20, green: 0.40, blue: 0.28, alpha: 1.0).cgColor)
            ctx.fill(CGRect(x: cx - 18, y: 44, width: 14, height: 18))
            ctx.fill(CGRect(x: cx + 4, y: 44, width: 14, height: 18))
            
            // Cabeça / Rosto
            ctx.setFillColor(NSColor(red: 0.88, green: 0.72, blue: 0.58, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 18, y: 106, width: 36, height: 42))
            
            // Chapéu de Expedição de Campo
            ctx.setFillColor(NSColor(red: 0.58, green: 0.48, blue: 0.32, alpha: 1.0).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 30, y: 135, width: 60, height: 22))
            ctx.fill(CGRect(x: cx - 18, y: 145, width: 36, height: 24))
            
            // Balão de Diálogo / Ícone de Amizade acima da cabeça
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 18, y: 180, width: 36, height: 28))
            ctx.setFillColor(NSColor(red: 0.15, green: 0.65, blue: 0.35, alpha: 1.0).cgColor)
            // Três pontos de diálogo
            ctx.fillEllipse(in: CGRect(x: cx - 10, y: 191, width: 5, height: 5))
            ctx.fillEllipse(in: CGRect(x: cx - 2, y: 191, width: 5, height: 5))
            ctx.fillEllipse(in: CGRect(x: cx + 6, y: 191, width: 5, height: 5))
        }
    }
    
    // MARK: - 10. Marcos dos Biomas (2.5D)
    public func landmarkImage(id: String) -> NSImage {
        let key = "sprite_landmark_\(id)"
        return renderImage(width: 260, height: 280, key: key) { ctx, w, h in
            let cx = w / 2
            
            ctx.setFillColor(NSColor.black.withAlphaComponent(0.22).cgColor)
            ctx.fillEllipse(in: CGRect(x: cx - 80, y: 6, width: 160, height: 26))
            
            switch id {
            case "canopyPlatform":
                // Estação das Copas (Dossel Suspenso)
                ctx.setFillColor(NSColor(red: 0.38, green: 0.24, blue: 0.14, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 60, y: 15, width: 14, height: 170))
                ctx.fill(CGRect(x: cx + 46, y: 15, width: 14, height: 170))
                ctx.setFillColor(NSColor(red: 0.52, green: 0.36, blue: 0.22, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 85, y: 185, width: 170, height: 24))
                // Guarda-corpo de corda
                ctx.setStrokeColor(NSColor(red: 0.78, green: 0.68, blue: 0.45, alpha: 1.0).cgColor)
                ctx.setLineWidth(3.0)
                ctx.move(to: CGPoint(x: cx - 85, y: 220))
                ctx.addLine(to: CGPoint(x: cx + 85, y: 220))
                ctx.strokePath()
                
            case "rangerTent":
                // Tenda dos Brigadistas
                let tent = CGMutablePath()
                tent.move(to: CGPoint(x: cx - 90, y: 18))
                tent.addLine(to: CGPoint(x: cx, y: 195))
                tent.addLine(to: CGPoint(x: cx + 90, y: 18))
                tent.closeSubpath()
                ctx.setFillColor(NSColor(red: 0.55, green: 0.50, blue: 0.35, alpha: 1.0).cgColor)
                ctx.addPath(tent)
                ctx.fillPath()
                // Abertura da tenda
                let door = CGMutablePath()
                door.move(to: CGPoint(x: cx - 35, y: 18))
                door.addLine(to: CGPoint(x: cx, y: 125))
                door.addLine(to: CGPoint(x: cx + 35, y: 18))
                door.closeSubpath()
                ctx.setFillColor(NSColor(red: 0.22, green: 0.18, blue: 0.12, alpha: 1.0).cgColor)
                ctx.addPath(door)
                ctx.fillPath()
                
            case "manduviTree":
                // Tronco Gigante com Ninho de Arara
                ctx.setFillColor(NSColor(red: 0.32, green: 0.22, blue: 0.15, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx - 32, y: 15, width: 64, height: 160))
                // Copa volumosa
                ctx.setFillColor(NSColor(red: 0.15, green: 0.52, blue: 0.26, alpha: 1.0).cgColor)
                ctx.fillEllipse(in: CGRect(x: cx - 95, y: 140, width: 190, height: 125))
                // Caixa de ninho
                ctx.setFillColor(NSColor(red: 0.48, green: 0.32, blue: 0.18, alpha: 1.0).cgColor)
                ctx.fill(CGRect(x: cx + 22, y: 95, width: 34, height: 42))
                ctx.setFillColor(NSColor.black.cgColor)
                ctx.fillEllipse(in: CGRect(x: cx + 32, y: 115, width: 14, height: 14)) // Entrada circular
                
            default:
                // Marco Padrão
                ctx.setFillColor(NSColor.darkGray.cgColor)
                ctx.fill(CGRect(x: cx - 20, y: 15, width: 40, height: 140))
            }
        }
    }
}
#endif
