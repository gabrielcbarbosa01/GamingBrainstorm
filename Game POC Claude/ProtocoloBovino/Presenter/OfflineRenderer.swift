import AppKit
import SceneKit
import Metal
import GameCore

/// Renderiza a cena para PNG sem abrir janela. Serve para conferir escala,
/// enquadramento e iluminacao em CI ou num terminal sem sessao grafica.
///
///   ProtocoloBovino --render saida.png [--daylight] [--teleport x z yaw] [--seconds 3]
enum OfflineRenderer {

    @MainActor
    static func runIfRequested() -> Bool {
        let args = CommandLine.arguments
        if args.contains("--haul") { haul(); return true }
        if let i = args.firstIndex(of: "--soak") {
            let secs = (i + 1 < args.count ? Float(args[i + 1]) : nil) ?? 60
            soak(seconds: secs)
            return true
        }
        guard let i = args.firstIndex(of: "--render"), i + 1 < args.count else { return false }
        let path = args[i + 1]

        let seconds = value(after: "--seconds", in: args).flatMap(Float.init) ?? 2.0
        let width = value(after: "--width", in: args).flatMap(Int.init) ?? 1600
        let height = value(after: "--height", in: args).flatMap(Int.init) ?? 900

        let controller = GameController()
        var t = CACurrentMediaTime()
        for _ in 0..<max(1, Int(seconds * 60)) {
            t += 1.0 / 60.0
            controller.tick(now: t)
        }

        guard let device = MTLCreateSystemDefaultDevice() else {
            report("sem Metal device"); return true
        }
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = controller.presenter.scene
        renderer.pointOfView = controller.presenter.cameraNode

        // Camera livre para diagnostico: --cam x y z --look x y z
        if let cam = triple(after: "--cam", in: args) {
            let free = SCNNode()
            free.camera = SCNCamera()
            free.camera?.zNear = 0.1
            free.camera?.zFar = 2000
            free.camera?.fieldOfView = 65
            free.position = SCNVector3(cam.0, cam.1, cam.2)
            let look = triple(after: "--look", in: args) ?? (0, 0, 0)
            controller.presenter.scene.rootNode.addChildNode(free)
            free.look(at: SCNVector3(look.0, look.1, look.2))
            renderer.pointOfView = free
        }
        renderer.autoenablesDefaultLighting = false

        let image = renderer.snapshot(atTime: CACurrentMediaTime(),
                                      with: CGSize(width: width, height: height),
                                      antialiasingMode: .multisampling4X)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            report("falha ao converter para PNG"); return true
        }
        do {
            try png.write(to: URL(fileURLWithPath: path))
            report("escrito \(path)  \(width)x\(height)  t=\(String(format: "%.1f", controller.hud.elapsed))s")
        } catch {
            report("falha ao escrever: \(error)")
        }
        return true
    }

    /// Teste de fumaca sem render: o jogador corre em circulos perto do rebanho.
    /// Valida movimento, IA do rebanho, acumulo de alerta e escalada de vigilia.
    static func soak(seconds: Float) {
        let world = World()
        let me = PlayerID(0)
        world.debugTeleport(me, to: Vec3(-8, 0, -24))
        let dt: Float = 1.0 / 60.0
        var t: Float = 0
        var lastVigilia = 0
        var knockdowns = 0
        var panics = 0

        report("    t   alerta  vigilia   panico  acordadas   carga")
        for step in 0..<Int(seconds / dt) {
            world.setInput(PlayerInput(move: Vec2(0, 1), aimYaw: t * 0.9, sprint: true, crouch: false), for: me)
            world.step(dt: dt)
            for e in world.drainEvents() {
                if case .playerKnocked = e { knockdowns += 1 }
                if case .cowPanicked = e { panics += 1 }
            }
            t += dt
            if world.vigilia != lastVigilia {
                lastVigilia = world.vigilia
                report(String(format: "  >> t=%.1fs  DEBANDADA -> vigilia %d", t, world.vigilia))
            }
            if step % 300 == 0 {
                let panicking = world.allCows.filter(\.isPanicking).count
                let awake = world.allCows.filter(\.isAwake).count
                report(String(format: "%5.0f %7.1f %8d %8d %8d %7d",
                              t, world.alert, world.vigilia, panicking, awake, world.cargoCount))
            }
        }
        let knocked = world.player(me)?.isDown ?? false
        report(String(format: "fim: t=%.0fs alerta=%.0f vigilia=%d carga=%d quedas=%d panicos=%d derrubado=%@",
                      t, world.alert, world.vigilia, world.cargoCount,
                      knockdowns, panics, knocked ? "sim" : "nao"))
    }

    /// Laco completo do MVP sem render: erguer, carregar ate o feixe, soltar, extrair.
    /// E a pergunta que o M1 existe para responder, verificada sem abrir janela.
    static func haul() {
        let world = World()
        let me = PlayerID(0)
        let anchor = world.farm.shipAnchor

        // Cenario controlado: a vaca a 9 m ao sul do feixe, sem cerca no meio.
        let target = world.allCows.first { $0.size == .adulta }!
        world.debugMoveCow(target.id, to: Vec3(anchor.x, 0, anchor.z - 9))
        world.debugTeleport(me, to: Vec3(anchor.x, 0, anchor.z - 11), aim: 0)

        let dt: Float = 1.0 / 60.0
        var t: Float = 0
        var grabbed = false
        var droppedAtBeam = false
        var drops = 0

        report("fase                    t      alerta   detalhe")
        world.enqueue(.interact, for: me)

        for step in 0..<(90 * 60) {
            guard let p = world.player(me), let cow = world.cow(target.id) else { break }

            if !grabbed, p.hands.isCarryingCow {
                grabbed = true
                report(String(format: "erguida               %5.1fs  %6.1f   %@ (%@, %.0f%% vel.)",
                              t, world.alert, cow.name, cow.size.displayName, cow.carryFactor * 100))
            }
            // Recolhe se escorregou no caminho.
            if grabbed, !droppedAtBeam, !p.hands.isCarryingCow, cow.isOnGround, p.canAct,
               planarDistance(p.position, cow.position) < Balance.interactReach - 0.3, step % 30 == 0 {
                world.enqueue(.interact, for: me)
            }
            // Chegou no feixe: solta (o feixe nao pega vaca no colo).
            if p.hands.isCarryingCow, !droppedAtBeam,
               planarDistance(p.position, anchor) < Balance.beamRadius - 1.0 {
                world.enqueue(.interact, for: me)
                droppedAtBeam = true
                report(String(format: "solta no feixe        %5.1fs  %6.1f", t, world.alert))
            }

            let focus = (grabbed && !droppedAtBeam) || p.hands.isCarryingCow
                ? anchor
                : (droppedAtBeam ? p.position + p.forward : cow.position)
            let toWP = (focus - p.position).flat
            let yaw = simd_length(toWP) > 0.2 ? atan2(toWP.x, toWP.z) : p.aimYaw
            let move: Vec2 = droppedAtBeam ? .zero : Vec2(0, 1)
            world.setInput(PlayerInput(move: move, aimYaw: yaw, sprint: false, crouch: false), for: me)
            world.step(dt: dt)
            for e in world.drainEvents() { if case .cowDropped = e { drops += 1 } }
            t += dt

            if world.cargoCount > 0 {
                report(String(format: "EXTRAIDA              %5.1fs  %6.1f   vigilia %d, quedas %d",
                              t, world.alert, world.vigilia, drops))
                report(String(format: "carga a bordo: %d vaca(s), %d creditos",
                              world.cargoCount, world.cargoValue))
                return
            }
        }
        report(String(format: "NAO COMPLETOU em %.0fs (carregando=%@ soltou=%@ quedas=%d)",
                      t, (world.player(me)?.hands.isCarryingCow ?? false) ? "sim" : "nao",
                      droppedAtBeam ? "sim" : "nao", drops))
    }

    private static func triple(after flag: String, in args: [String]) -> (Float, Float, Float)? {
        guard let i = args.firstIndex(of: flag), i + 3 < args.count,
              let x = Float(args[i + 1]), let y = Float(args[i + 2]), let z = Float(args[i + 3])
        else { return nil }
        return (x, y, z)
    }

    private static func value(after flag: String, in args: [String]) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    private static func report(_ text: String) {
        FileHandle.standardError.write("[render] \(text)\n".data(using: .utf8)!)
    }
}
