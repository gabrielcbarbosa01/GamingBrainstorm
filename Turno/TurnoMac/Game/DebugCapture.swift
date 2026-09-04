//
//  DebugCapture.swift
//  TurnoMac
//
//  Modo de verificação sem tela: com TURNO_CAPTURE=1 o app monta o mundo,
//  roda um turno roteirizado pelo GameLoop e renderiza PNGs com RealityRenderer.
//  Serve como teste de integração do slice (limpeza, provas, gerente, finais).
//

import AppKit
import Metal
import RealityKit
import ImageIO
import UniformTypeIdentifiers

@MainActor
enum DebugCapture {
    static func runIfRequested() -> Bool {
        guard ProcessInfo.processInfo.environment["TURNO_CAPTURE"] == "1" else { return false }
        Task { @MainActor in
            do { try await run() } catch { print("CAPTURE ERROR: \(error)") }
            exit(0)
        }
        return true
    }

    static func run() async throws {
        setvbuf(stdout, nil, _IOLBF, 0)
        let outDir = FileManager.default.temporaryDirectory.appendingPathComponent("turno-capture", isDirectory: true)
        try? FileManager.default.removeItem(at: outDir)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        print("CAPTURE DIR: \(outDir.path)")

        let world = try GameWorld()
        let state = GameState()
        let input = InputState()
        let audio = ProceduralAudio()
        let loop = GameLoop(state: state, world: world, input: input, audio: audio)

        let renderer = try RealityRenderer()
        renderer.entities.append(contentsOf: [world.root])
        renderer.activeCamera = world.camera
        renderer.cameraSettings.colorBackground = .color(CGColor(red: 0, green: 0, blue: 0, alpha: 1))

        let w = 1280, h = 800
        let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: w, height: h, mipmapped: false)
        td.usage = [.renderTarget, .shaderRead]
        td.storageMode = .shared
        let target = world.device.makeTexture(descriptor: td)!
        let output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: target))

        func frame(_ dt: Double = 1.0 / 60.0) async throws {
            loop.update(dt: Float(dt))
            try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                do {
                    try renderer.updateAndRender(deltaTime: dt, cameraOutput: output, onComplete: { _ in c.resume() })
                } catch { c.resume(throwing: error) }
            }
        }
        func frames(_ n: Int) async throws { for _ in 0..<n { try await frame() } }
        func snap(_ name: String) throws {
            var bytes = [UInt8](repeating: 0, count: w * h * 4)
            bytes.withUnsafeMutableBytes { target.getBytes($0.baseAddress!, bytesPerRow: w * 4, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0) }
            let cs = CGColorSpaceCreateDeviceRGB()
            let info = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
            let data = CFDataCreate(nil, bytes, bytes.count)!
            let provider = CGDataProvider(data: data)!
            let img = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4, space: cs,
                              bitmapInfo: info, provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
            let url = outDir.appendingPathComponent("\(name).png")
            let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
            CGImageDestinationAddImage(dest, img, nil)
            CGImageDestinationFinalize(dest)
            print("SNAP \(name): prompt='\(state.prompt)' tool=\(state.currentTool) suspicion=\(String(format: "%.2f", state.suspicion)) tasks=\(state.tasks.map { "\($0.id):\(Int($0.progress * 100))" }) evidence=\(state.foundEvidence.map(\.id))")
        }
        func stroke(from a: SIMD2<Float>, to b: SIMD2<Float>, frames n: Int) async throws {
            input.use = true
            for i in 0...n {
                let t = Float(i) / Float(n)
                input.pointer = a + (b - a) * t
                try await frame()
            }
            input.use = false
            input.pointer = nil
            try await frames(2)
        }

        // 1. Início do turno, olhando o corredor a partir do elevador.
        loop.startShift()
        try await frames(5)
        try snap("01-corredor")

        // 2. Anda até a janela.
        input.moveY = 1
        var guardCount = 0
        while world.player.position.z > -14.3 && guardCount < 2000 { try await frame(); guardCount += 1 }
        input.moveY = 0
        try await frames(3)
        try snap("02-janela-suja")
        precondition(state.currentTool == .rodo, "esperava prompt do rodo, prompt='\(state.prompt)'")

        // 3. Entra no modo rodo.
        input.actPressed = true
        try await frames(40)
        try snap("03-modo-rodo")
        precondition(state.inToolMode)

        // Gesto errado (horizontal) não deve limpar.
        let before = world.surfaces[0].mask.cleanFraction
        try await stroke(from: [0.1, 0.5], to: [0.9, 0.5], frames: 30)
        precondition(world.surfaces[0].mask.cleanFraction - before < 0.01, "gesto horizontal limpou o vidro")

        // Faixas verticais.
        for u in stride(from: Float(0.1), through: 0.9, by: 0.2) {
            try await stroke(from: [u, 0.97], to: [u, 0.03], frames: 36)
            if u > 0.4 && u < 0.6 { try snap("04-rodo-metade") }
        }
        try await stroke(from: [0.0, 0.97], to: [0.0, 0.03], frames: 36)
        try await stroke(from: [1.0, 0.97], to: [1.0, 0.03], frames: 36)
        print("vidro limpo: \(world.surfaces[0].mask.cleanFraction) revelado: \(world.surfaces[0].revealFraction)")
        try await frames(8)
        try snap("05-vidro-limpo-silhueta")
        precondition(world.surfaces[0].isRevealed, "marca de mão não revelada")
        input.actPressed = true
        try await frames(2)
        precondition(state.hasEvidence("mao"), "não fotografou a mão")
        input.backPressed = true
        try await frames(40)
        try snap("06-silhueta-some")

        // 4. Chão: volta até z=-8.6 e varre.
        input.moveY = -1
        guardCount = 0
        while world.player.position.z < -8.7 && guardCount < 2000 { try await frame(); guardCount += 1 }
        input.moveY = 0
        try await frames(3)
        precondition(state.currentTool == .vassoura, "esperava vassoura, prompt='\(state.prompt)'")
        input.actPressed = true
        try await frames(40)
        try snap("07-modo-vassoura")
        for v in stride(from: Float(0.05), through: 0.95, by: 0.09) {
            try await stroke(from: [0.0, v], to: [1.0, v], frames: 30)
            try await stroke(from: [1.0, v], to: [0.0, v], frames: 30)
        }
        try snap("08-chao-varrido")
        print("chão: \(world.surfaces[1].mask.cleanFraction) revelado: \(world.surfaces[1].revealFraction)")
        precondition(world.surfaces[1].isRevealed, "bituca não revelada")
        input.actPressed = true
        try await frames(2)
        input.backPressed = true
        try await frames(30)

        // 5. Quarto 5: mesa.
        loop.debugSetPose(position: [3.6, 0, -6.0], yaw: 0, pitch: -0.5)
        try await frames(3)
        try snap("09-quarto5")
        precondition(state.currentTool == .pano, "esperava pano, prompt='\(state.prompt)'")
        input.actPressed = true
        try await frames(40)
        for _ in 0..<4 {
            for a in stride(from: Float(0), to: 6.4, by: 0.35) {
                let c = SIMD2<Float>(0.5 + cos(a) * 0.35, 0.5 + sin(a) * 0.35)
                try await stroke(from: c, to: SIMD2(0.5 + cos(a + 0.35) * 0.35, 0.5 + sin(a + 0.35) * 0.35), frames: 3)
            }
        }
        for u in stride(from: Float(0.05), through: 0.95, by: 0.1) {
            try await stroke(from: [u, 0.05], to: [u, 0.95], frames: 12)
            try await stroke(from: [u + 0.05, 0.95], to: [u + 0.05, 0.05], frames: 12)
        }
        try snap("10-mesa-limpa")
        print("mesa: \(world.surfaces[2].mask.cleanFraction) revelado: \(world.surfaces[2].revealFraction)")
        input.actPressed = true
        try await frames(2)
        input.backPressed = true
        try await frames(30)

        // 6. Escuta na porta 7 — espera a gerente estar longe e indo embora.
        loop.debugSetPose(position: [0.9, 0, -12.0], yaw: -.pi / 2, pitch: 0)
        var waitFrames = 0
        while !(world.manager.position.z > -6 && world.managerDirection > 0) && waitFrames < 60 * 60 { try await frame(); waitFrames += 1 }
        print("gerente em z=\(world.manager.position.z) após \(waitFrames) frames, suspeita=\(state.suspicion)")
        try await frames(3)
        precondition(state.currentTool == .ouvido, "esperava escuta, prompt='\(state.prompt)'")
        input.actPressed = true
        try await frames(60)
        try snap("11-escutando")
        var listenFrames = 0
        while !state.hasEvidence("conversa") && listenFrames < 60 * 30 && state.phase == .playing { try await frame(); listenFrames += 1 }
        print("escuta terminou em \(listenFrames) frames, suspeita=\(state.suspicion), fase=\(state.phase)")

        // 7. Elevador e dedução.
        loop.debugSetPose(position: [0, 0, -1.2], yaw: .pi, pitch: 0)
        try await frames(3)
        try snap("12-elevador")
        input.actPressed = true
        try await frames(3)
        print("fase após elevador: \(state.phase) provas=\(state.foundEvidence.map(\.id))")
        precondition(state.phase == .deduction, "esperava dedução")
        state.accuse("almeida")
        print("final: \(state.phase)")
        precondition(state.phase == .ending(.casoResolvido))
        print("CAPTURE OK")
    }
}
