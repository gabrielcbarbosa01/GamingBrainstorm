//
//  DebugCapture.swift
//  TurnoMac
//
//  Modo de verificação sem tela: com TURNO_CAPTURE=1 o app joga a campanha
//  inteira com entrada roteirizada, confere as regras e grava PNGs de cada
//  noite com o RealityRenderer. É o teste de integração do protótipo.
//

import AppKit
import Metal
import RealityKit
import ImageIO
import UniformTypeIdentifiers
import simd
import SwiftUI

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

    // Estado do harness
    private static var world: GameWorld!
    private static var state: GameState!
    private static var input: InputState!
    private static var loop: GameLoop!
    private static var renderer: RealityRenderer!
    private static var output: RealityRenderer.CameraOutput!
    private static var target: MTLTexture!
    private static var outDir: URL!
    private static let W = 1280, H = 800

    static func run() async throws {
        setvbuf(stdout, nil, _IOLBF, 0)
        outDir = FileManager.default.temporaryDirectory.appendingPathComponent("turno-capture", isDirectory: true)
        try? FileManager.default.removeItem(at: outDir)
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        print("CAPTURE DIR: \(outDir.path)")

        ProgressStore.reset()
        world = try GameWorld()
        state = GameState()
        input = InputState()
        loop = GameLoop(state: state, world: world, input: input, audio: ProceduralAudio())
        state.progress = CampaignProgress()

        renderer = try RealityRenderer()
        renderer.entities.append(contentsOf: [world.root])
        renderer.activeCamera = world.camera
        renderer.cameraSettings.colorBackground = .color(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        let td = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm_srgb, width: W, height: H, mipmapped: false)
        td.usage = [.renderTarget, .shaderRead]
        td.storageMode = .shared
        target = world.device.makeTexture(descriptor: td)!
        output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture: target))

        // Papel de cada noite, como uma equipe de quatro se dividiria.
        let roles: [Role] = [.camareira, .recepcao, .camareira, .zelador, .vidros]

        for n in 1...Campaign.count {
            state.progress.night = n
            state.role = roles[n - 1]
            state.progress.role = roles[n - 1]
            // A partir da noite 4 a equipe já teria comprado a lanterna.
            if n == 4 && !state.progress.hasUpgrade("lanterna") {
                state.progress.upgrades.append("lanterna")
                state.progress.upgrades.append("spray")
            }
            try await playNight(n)
        }

        // Dedução final
        precondition(state.progress.night > Campaign.count, "campanha não chegou ao fim")
        state.phase = .deduction
        for q in CaseQuestion.allCases {
            let options = state.answers(for: q)
            print("PERGUNTA \(q.rawValue): \(options.count) opção(ões) — \(options.map(\.id))")
            precondition(options.contains { $0.correct }, "a resposta certa de \(q.rawValue) não está disponível")
            state.deductionChoice[q] = options.first { $0.correct }!.id
        }
        state.resolveVerdict()
        print("VEREDITO: \(state.verdictCorrect)/3 · fase \(state.phase)")
        precondition(state.verdictCorrect == 3, "veredito incompleto")
        precondition(state.phase == .ending(.casoResolvido))

        let found = state.boardEvidence.count
        print("PROVAS NO MURAL: \(found)/\(Campaign.evidence.count) · estrelas \(state.progress.stars) · confiança \(String(format: "%.2f", state.progress.trust))")
        precondition(found == Campaign.evidence.count, "faltaram provas")
        precondition(state.progress.stars >= 10, "poucas estrelas para comprar as melhorias")
        try snapUI()
        print("CAPTURE OK")
    }

    // MARK: - Telas da campanha em PNG

    private static func snapUI() throws {
        // Estado a meio da campanha, para o vestiário
        let mid = GameState()
        mid.progress = CampaignProgress()
        mid.progress.night = 3
        mid.progress.stars = 5
        mid.progress.trust = 0.72
        mid.progress.upgrades = ["lanterna"]
        mid.progress.evidence = Campaign.evidence.filter { $0.night <= 2 }.map(\.id)
        mid.night = Campaign.night(3)
        mid.role = .camareira
        mid.coopPeers = ["MacBook do Téo": .vidros, "iMac da sala": .zelador]
        mid.coopPeerNames = ["MacBook do Téo", "iMac da sala"]
        try render(HubView(state: mid, start: {}), "ui-01-vestiario")

        let board = GameState()
        board.progress = mid.progress
        board.night = Campaign.night(3)
        try render(
            ZStack {
                Color.black.opacity(0.93)
                CaseBoardView(state: board, scrolls: false).padding(28)
            },
            "ui-02-mural")

        // Relatório da noite
        let rep = GameState()
        rep.progress = mid.progress
        rep.beginNight(Campaign.night(2), role: .recepcao)
        for t in rep.tasks { rep.setTask(t.id, progress: 1) }
        rep.foundTonight = ["pagina", "recibo", "chave"]
        rep.reportStars = 3
        try render(ReportView(state: rep, next: {}), "ui-03-relatorio")

        // Dedução com tudo na mão
        let ded = GameState()
        ded.progress.evidence = Campaign.evidence.map(\.id)
        ded.deductionChoice = [.quem: "almeida", .porque: "venda"]
        try render(DeductionView(state: ded, accuse: {}, scrolls: false), "ui-04-deducao")

        // Final
        let end = GameState()
        end.progress.evidence = Campaign.evidence.map(\.id)
        end.progress.stars = 15
        end.verdictCorrect = 3
        try render(EndingView(state: end, ending: .casoResolvido, close: {}), "ui-05-final")
        print("TELAS: vestiário, mural, relatório, dedução, final")
    }

    private static func render(_ view: some View, _ name: String) throws {
        let r = ImageRenderer(content: view.frame(width: 1280, height: 820).background(Color.black).preferredColorScheme(.dark))
        r.scale = 1
        guard let img = r.cgImage else { print("falhou render \(name)"); return }
        let url = outDir.appendingPathComponent("\(name).png")
        let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, img, nil)
        CGImageDestinationFinalize(dest)
    }

    // MARK: - Uma noite

    private static func playNight(_ n: Int) async throws {
        loop.startNight()
        try await frames(4)
        let spec = state.night
        print("--- NOITE \(n): \(spec.title) · papel \(state.role.name) · áreas \(spec.areas.map(\.short))")
        try snap(String(format: "n%d-00-%@", n, spec.areas[0].rawValue))

        // Confere que o turno começa na área certa e que dá para andar.
        precondition(GameWorld.region(state.currentArea) == GameWorld.region(spec.areas[0]),
                     "spawn na região errada: \(state.currentArea)")

        for (i, surface) in world.surfaces.enumerated() {
            // vai até a superfície e confere o prompt
            let approach = surface.toolCameraPosition - SIMD3<Float>(0, GameWorld.eyeHeight, 0)
            let look = surface.toolLookAt - surface.toolCameraPosition
            loop.debugSetPose(position: approach, yaw: atan2(-look.x, -look.z),
                              pitch: asin(max(-1, min(1, look.y / simd_length(look)))))
            try await frames(3)
            precondition(state.currentTool == surface.tool,
                         "esperava \(surface.tool) em \(surface.id), veio \(state.currentTool) — prompt '\(state.prompt)'")
            input.actPressed = true
            try await frames(45)
            precondition(state.inToolMode, "não entrou no modo ferramenta em \(surface.id)")

            // gesto errado não pode limpar
            if surface.tool == .rodo || surface.tool == .vassoura {
                let before = surface.mask.cleanFraction
                let wrong: (SIMD2<Float>, SIMD2<Float>) = surface.tool == .rodo
                    ? ([0.1, 0.5], [0.9, 0.5])
                    : ([0.5, 0.05], [0.5, 0.95])
                try await stroke(from: wrong.0, to: wrong.1, steps: 24)
                precondition(surface.mask.cleanFraction - before < 0.01,
                             "gesto errado limpou \(surface.id)")
            }

            try await clean(surface)
            let frac = surface.mask.cleanFraction
            print("  \(surface.id): limpo \(Int(frac * 100))% · revelado \(Int(surface.revealFraction * 100))%")
            precondition(frac > 0.88, "não deu para terminar \(surface.id): \(frac)")
            if let ev = surface.evidenceID {
                precondition(surface.isRevealed, "prova \(ev) não apareceu em \(surface.id)")
                input.actPressed = true
                try await frames(3)
                precondition(state.hasEvidence(ev), "não fotografou \(ev)")
            }
            if i == 0 { try snap(String(format: "n%d-01-%@", n, surface.id)) }
            input.backPressed = true
            try await frames(40)
        }

        // interações da noite
        for inter in spec.interactions {
            guard let marker = world.interactionMarkers[inter.id] else { continue }
            let stand = marker.position + SIMD3<Float>(inter.kind == .escuta ? -0.7 : 0.9, 0, 0.2)
            let d = marker.position - stand
            loop.debugSetPose(position: [stand.x, 0, stand.z], yaw: atan2(-d.x, -d.z), pitch: 0)
            try await frames(3)
            precondition(state.prompt.contains(inter.prompt), "sem prompt de '\(inter.prompt)' — veio '\(state.prompt)'")
            // como uma jogadora faria: espera a gerente virar as costas e retoma quando ela olha
            var guardCount = 0
            var attempts = 0
            while !(inter.evidenceID.map { state.hasEvidence($0) } ?? true) && guardCount < 60 * 120 {
                if state.managerSees {
                    try await frame(); guardCount += 1; continue
                }
                // espera um instante para ter certeza de que ela virou as costas
                try await frames(24); guardCount += 24
                if state.managerSees { continue }
                input.actPressed = true
                attempts += 1
                try await frames(2)
                while state.phase == .playing, self.isInteracting, guardCount < 60 * 120 {
                    try await frame(); guardCount += 1
                }
                guard state.phase == .playing else { break }
                // como uma jogadora: se afasta, finge que está arrumando outra
                // coisa e volta quando ela sai
                let hidePos = world.isInCover(GameWorld.spawn(spec.areas[0]))
                    ? GameWorld.spawn(spec.areas[0])
                    : stand + SIMD3<Float>(0, 0, 3.0)
                loop.debugSetPose(position: [hidePos.x, 0, hidePos.z], yaw: 0, pitch: 0)
                try await frames(90); guardCount += 90
                loop.debugSetPose(position: [stand.x, 0, stand.z], yaw: atan2(-d.x, -d.z), pitch: 0)
                try await frames(4); guardCount += 4
            }
            if let ev = inter.evidenceID {
                print("  \(inter.id): \(state.hasEvidence(ev) ? "ok" : "FALHOU") em \(guardCount) frames, \(attempts) tentativa(s) · suspeita \(String(format: "%.2f", state.suspicion))")
            }
            if let ev = inter.evidenceID {
                precondition(state.hasEvidence(ev), "interação \(inter.id) não rendeu a prova")
            }
        }
        let vista = GameWorld.spawn(spec.areas[0])
        loop.debugSetPose(position: vista, yaw: 0, pitch: -0.05)
        try await frames(3)
        try snap(String(format: "n%d-02-fim", n))

        // encerra o turno pelo elevador da área atual
        let area = state.currentArea
        let point = GameWorld.travelPoint(area)
        loop.debugSetPose(position: [point.x, 0, point.z + 1.0], yaw: 0, pitch: 0)
        try await frames(3)
        precondition(state.prompt.contains("turno"), "sem o prompt do elevador em \(area): '\(state.prompt)'")
        input.backPressed = true
        try await frames(3)
        precondition(state.phase == .report, "a noite \(n) não terminou em relatório (fase \(state.phase))")
        print("  relatório: \(state.tasksDone)/\(state.tasks.count) tarefas · \(state.foundTonight.count) provas · \(state.reportStars) estrelas · confiança \(String(format: "%.2f", state.progress.trust))")
        precondition(state.reportStars == 3, "esperava 3 estrelas na noite \(n)")
        loop.afterReport()
        try await frames(2)
    }

    /// Verdadeiro enquanto uma conversa/escuta está rolando.
    private static var isInteracting: Bool { state.currentTool == .ouvido || state.prompt.contains("SAIR para parar") }

    // MARK: - Limpeza roteirizada

    private static func clean(_ s: CleaningSurface) async throws {
        var pass = 0
        while s.mask.cleanFraction < 0.93 && pass < 8 {
            pass += 1
            switch s.tool {
            case .rodo:
                for u in stride(from: Float(0.0), through: 1.0, by: 0.12) {
                    try await stroke(from: [u, 0.99], to: [u, 0.01], steps: 30)
                }
            case .vassoura:
                for v in stride(from: Float(0.0), through: 1.0, by: 0.07) {
                    try await stroke(from: [0.0, v], to: [1.0, v], steps: 26)
                    try await stroke(from: [1.0, v], to: [0.0, v], steps: 26)
                }
            default:
                for v in stride(from: Float(0.02), through: 0.98, by: 0.06) {
                    try await stroke(from: [0.02, v], to: [0.98, v], steps: 20)
                    try await stroke(from: [0.98, v], to: [0.02, v + 0.03], steps: 20)
                }
            }
        }
    }

    private static func stroke(from a: SIMD2<Float>, to b: SIMD2<Float>, steps: Int) async throws {
        input.use = true
        for i in 0...steps {
            let t = Float(i) / Float(steps)
            input.pointer = a + (b - a) * t
            try await frame()
        }
        input.use = false
        input.pointer = nil
        try await frames(1)
    }

    // MARK: - Render

    private static func frame(_ dt: Double = 1.0 / 60.0) async throws {
        loop.update(dt: Float(dt))
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            do { try renderer.updateAndRender(deltaTime: dt, cameraOutput: output, onComplete: { _ in c.resume() }) }
            catch { c.resume(throwing: error) }
        }
    }

    private static func frames(_ n: Int) async throws {
        for _ in 0..<n { try await frame() }
    }

    private static func snap(_ name: String) throws {
        var bytes = [UInt8](repeating: 0, count: W * H * 4)
        bytes.withUnsafeMutableBytes {
            target.getBytes($0.baseAddress!, bytesPerRow: W * 4, from: MTLRegionMake2D(0, 0, W, H), mipmapLevel: 0)
        }
        let info = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
        let data = CFDataCreate(nil, bytes, bytes.count)!
        let provider = CGDataProvider(data: data)!
        let img = CGImage(width: W, height: H, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: W * 4,
                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info, provider: provider,
                          decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
        let url = outDir.appendingPathComponent("\(name).png")
        let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, img, nil)
        CGImageDestinationFinalize(dest)
    }
}
