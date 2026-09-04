//
//  CleaningSurface.swift
//  TurnoMac
//
//  Uma superfície limpável: máscara de sujeira (RGBA na CPU) espelhada numa
//  LowLevelTexture do RealityKit via blit Metal. Embaixo da sujeira pode haver
//  uma "prova" desenhada numa segunda textura estática.
//

import Foundation
import Metal
import RealityKit
import simd
import CoreGraphics

@MainActor
final class DirtMask {
    let width: Int
    let height: Int
    private(set) var pixels: [UInt8]
    private let initialAlphaSum: Double
    private(set) var cleanFraction: Float = 0
    private var dirty = true

    private let device: MTLDevice
    private let staging: MTLTexture
    let texture: LowLevelTexture
    let resource: TextureResource

    init(device: MTLDevice, width: Int, height: Int, pixels: [UInt8]) throws {
        self.device = device
        self.width = width
        self.height = height
        self.pixels = pixels
        var sum: Double = 0
        for i in stride(from: 3, to: pixels.count, by: 4) { sum += Double(pixels[i]) }
        initialAlphaSum = max(sum, 1)

        let sd = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb, width: width, height: height, mipmapped: false)
        sd.usage = [.shaderRead]
        sd.storageMode = device.hasUnifiedMemory ? .shared : .managed
        staging = device.makeTexture(descriptor: sd)!

        let desc = LowLevelTexture.Descriptor(pixelFormat: .rgba8Unorm_srgb, width: width, height: height,
                                              textureUsage: [.shaderRead, .shaderWrite])
        texture = try LowLevelTexture(descriptor: desc)
        resource = try TextureResource(from: texture)
    }

    /// Remove sujeira ao longo do segmento a→b (uv, v para cima), com um pincel retangular ou circular.
    func clean(from a: SIMD2<Float>, to b: SIMD2<Float>, halfW: Float, halfH: Float, amount: Float, round: Bool) {
        let step = max(min(halfW, halfH) * 0.5, 0.004)
        let d = b - a
        let len = simd_length(d)
        let n = max(1, Int(len / step))
        let remove = Int(amount * 255)
        for i in 0...n {
            let t = n == 0 ? 0 : Float(i) / Float(n)
            stamp(at: a + d * t, halfW: halfW, halfH: halfH, remove: remove, round: round)
        }
        dirty = true
    }

    private func stamp(at uv: SIMD2<Float>, halfW: Float, halfH: Float, remove: Int, round: Bool) {
        let cx = uv.x * Float(width), cy = (1 - uv.y) * Float(height)
        let rx = halfW * Float(width), ry = halfH * Float(height)
        let x0 = max(0, Int(cx - rx)), x1 = min(width - 1, Int(cx + rx))
        let y0 = max(0, Int(cy - ry)), y1 = min(height - 1, Int(cy + ry))
        guard x0 <= x1, y0 <= y1 else { return }
        pixels.withUnsafeMutableBufferPointer { p in
            for y in y0...y1 {
                let dy = (Float(y) - cy) / max(ry, 0.5)
                for x in x0...x1 {
                    if round {
                        let dx = (Float(x) - cx) / max(rx, 0.5)
                        if dx * dx + dy * dy > 1 { continue }
                    }
                    let idx = (y * width + x) * 4 + 3
                    let a = Int(p[idx])
                    if a > 0 { p[idx] = UInt8(max(0, a - remove)) }
                }
            }
        }
    }

    /// Fração de pixels limpos dentro de uma região uv (v para cima).
    func cleanFraction(in region: CGRect) -> Float {
        let x0 = max(0, Int(region.minX * CGFloat(width))), x1 = min(width - 1, Int(region.maxX * CGFloat(width)))
        let y0 = max(0, Int((1 - region.maxY) * CGFloat(height))), y1 = min(height - 1, Int((1 - region.minY) * CGFloat(height)))
        guard x0 < x1, y0 < y1 else { return 0 }
        var clean = 0, total = 0
        pixels.withUnsafeBufferPointer { p in
            for y in stride(from: y0, through: y1, by: 2) {
                for x in stride(from: x0, through: x1, by: 2) {
                    total += 1
                    if p[(y * width + x) * 4 + 3] < 60 { clean += 1 }
                }
            }
        }
        return total == 0 ? 0 : Float(clean) / Float(total)
    }

    private func recomputeFraction() {
        var sum: Double = 0
        pixels.withUnsafeBufferPointer { p in
            for i in stride(from: 3, to: p.count, by: 4) { sum += Double(p[i]) }
        }
        cleanFraction = Float(1 - sum / initialAlphaSum)
    }

    /// Sobe os pixels para a GPU se algo mudou.
    func flush(queue: MTLCommandQueue) {
        guard dirty else { return }
        dirty = false
        recomputeFraction()
        pixels.withUnsafeBytes { buf in
            staging.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0,
                            withBytes: buf.baseAddress!, bytesPerRow: width * 4)
        }
        guard let cmd = queue.makeCommandBuffer() else { return }
        let target = texture.replace(using: cmd)
        if let blit = cmd.makeBlitCommandEncoder() {
            blit.copy(from: staging, to: target)
            blit.endEncoding()
        }
        cmd.commit()
    }
}

/// Superfície do mundo com sujeira, ferramenta associada e prova escondida.
@MainActor
final class CleaningSurface {
    let index: Int
    let id: String
    let taskID: String
    let tool: ToolKind
    let promptVerb: String
    let origin: SIMD3<Float>
    let right: SIMD3<Float>
    let up: SIMD3<Float>
    let normal: SIMD3<Float>
    let width: Float
    let height: Float
    let mask: DirtMask
    let revealRegion: CGRect?
    let evidenceID: String?
    let toolCameraPosition: SIMD3<Float>
    let toolLookAt: SIMD3<Float>
    /// Faixa de yaw/pitch (rad) do iPhone que cobre a superfície inteira.
    let phoneYawRange: Float
    let phonePitchRange: Float

    var dirtEntity: ModelEntity!
    var revealEntity: ModelEntity?
    var toolTip: ModelEntity!
    var lastUV: SIMD2<Float>? = nil
    var strokeDistance: Float = 0

    init(index: Int, id: String, taskID: String, tool: ToolKind, promptVerb: String,
         origin: SIMD3<Float>, right: SIMD3<Float>, up: SIMD3<Float>, width: Float, height: Float,
         mask: DirtMask, revealRegion: CGRect?, evidenceID: String?,
         toolCameraPosition: SIMD3<Float>, toolLookAt: SIMD3<Float>,
         phoneYawRange: Float = 0.9, phonePitchRange: Float = 0.7) {
        self.index = index
        self.id = id
        self.taskID = taskID
        self.tool = tool
        self.promptVerb = promptVerb
        self.origin = origin
        self.right = simd_normalize(right)
        self.up = simd_normalize(up)
        self.normal = simd_normalize(simd_cross(self.right, self.up))
        self.width = width
        self.height = height
        self.mask = mask
        self.revealRegion = revealRegion
        self.evidenceID = evidenceID
        self.toolCameraPosition = toolCameraPosition
        self.toolLookAt = toolLookAt
        self.phoneYawRange = phoneYawRange
        self.phonePitchRange = phonePitchRange
    }

    func worldPoint(u: Float, v: Float, lift: Float = 0.01) -> SIMD3<Float> {
        origin + right * ((u - 0.5) * width) + up * ((v - 0.5) * height) + normal * lift
    }

    var revealFraction: Float {
        guard let r = revealRegion else { return 0 }
        return mask.cleanFraction(in: r)
    }

    var isRevealed: Bool { revealFraction > 0.62 }

    /// Tamanho do pincel em uv, por ferramenta.
    var brush: (halfW: Float, halfH: Float, amount: Float, round: Bool) {
        switch tool {
        case .rodo: return (0.11, 0.012, 1.0, false)
        case .vassoura: return (0.09, 0.05, 0.45, true)
        case .pano: return (0.07, 0.11, 0.3, true)
        default: return (0.05, 0.05, 0.5, true)
        }
    }

    /// Verifica se o gesto combina com a ferramenta (rodo vertical, vassoura lateral).
    func gestureMatches(delta: SIMD2<Float>) -> Bool {
        let ax = abs(delta.x), ay = abs(delta.y)
        switch tool {
        case .rodo: return ay > ax * 1.1
        case .vassoura: return ax > ay * 1.1
        default: return true
        }
    }
}
