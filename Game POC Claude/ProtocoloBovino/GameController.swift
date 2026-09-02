import SwiftUI
import SceneKit
import GameCore

/// Cola entre input, simulacao e apresentacao. Roda inteiramente na main thread:
/// passo fixo de 60 Hz alimentado pelo CADisplayLink da view.
@MainActor
final class GameController: ObservableObject {

    let world = World()
    let presenter: ScenePresenter
    let localID = PlayerID(0)

    @Published private(set) var hud = HUDState()

    /// A view avisa quando capturou o mouse; sem isso a camera parece travada.
    @Published private(set) var mouseCaptured = false
    private(set) var cameraZoom: Float = 0

    private(set) var aimYaw: Float = 0
    /// Negativo = camera acima olhando para baixo (enquadramento padrao de 3a pessoa).
    private(set) var pitch: Float = -0.22

    private var pressed: Set<UInt16> = []
    private var sprintHeld = false
    private var lastTime: CFTimeInterval = 0
    private var accumulator: Float = 0
    private var hudClock: Float = 0
    private var log: [(text: String, age: Float)] = []

    private let fixedStep: Float = 1.0 / 60.0
    private let sensitivity: Float = 0.0045

    init() {
        presenter = ScenePresenter(world: world)
        applyDebugLaunchArguments()
        refreshHUD()
    }

    /// `--teleport x z [yaw]` posiciona o jogador no boot. Só para capturas e testes.
    private func applyDebugLaunchArguments() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--teleport"), i + 2 < args.count,
              let x = Float(args[i + 1]), let z = Float(args[i + 2]) else { return }
        let yaw = (i + 3 < args.count ? Float(args[i + 3]) : nil) ?? 0
        world.debugTeleport(localID, to: Vec3(x, 0, z), aim: yaw)
        aimYaw = yaw
        if let k = args.firstIndex(of: "--pitch"), k + 1 < args.count, let pv = Float(args[k + 1]) {
            pitch = pv
        }
        // `--grab` pega o que estiver ao alcance logo no primeiro passo.
        if args.contains("--grab") { world.enqueue(.interact, for: localID) }
        if let j = args.firstIndex(of: "--facing"), j + 1 < args.count, let f = Float(args[j + 1]) {
            world.debugSetAllHeadings(f)
        }
    }

    // MARK: Loop
    func tick(now: CFTimeInterval) {
        if lastTime == 0 { lastTime = now }
        let real = Float(min(0.25, now - lastTime))
        lastTime = now
        accumulator += real

        var steps = 0
        while accumulator >= fixedStep && steps < 6 {
            world.setInput(currentInput(), for: localID)
            world.step(dt: fixedStep)
            accumulator -= fixedStep
            steps += 1
        }
        consumeEvents()
        presenter.sync(world: world, playerID: localID, aimYaw: aimYaw, pitch: pitch, zoom: cameraZoom)

        hudClock += real
        for i in log.indices { log[i].age += real }
        log.removeAll { $0.age > 7 }
        if hudClock > 0.08 {
            hudClock = 0
            refreshHUD()
        }
    }

    private func currentInput() -> PlayerInput {
        var move = Vec2.zero
        if pressed.contains(13) || pressed.contains(126) { move.y += 1 }   // W
        if pressed.contains(1)  || pressed.contains(125) { move.y -= 1 }   // S
        if pressed.contains(0)  || pressed.contains(123) { move.x -= 1 }   // A
        if pressed.contains(2)  || pressed.contains(124) { move.x += 1 }   // D
        return PlayerInput(move: normalizedOrZero(move),
                           aimYaw: aimYaw,
                           sprint: sprintHeld,
                           crouch: pressed.contains(8))
    }

    // MARK: Input
    /// deltaY do AppKit e positivo quando o mouse desce; descer a mira e diminuir
    /// o pitch (pitch positivo = camera embaixo, olhando para cima). O sinal estava
    /// invertido e deixava a camera com a sensacao de estar ao contrario.
    func look(dx: Float, dy: Float) {
        aimYaw = wrapAngle(aimYaw - dx * sensitivity)
        // Mais curso para baixo que para cima: e no chao que estao as vacas, a lama e o feno.
        pitch = clampf(pitch - dy * sensitivity * (invertLookY ? -1 : 1), -1.05, 0.45)
    }

    /// Inverter o eixo Y da mira, para quem prefere.
    var invertLookY = false

    func setMouseCaptured(_ on: Bool) {
        guard mouseCaptured != on else { return }
        mouseCaptured = on
        if !on { releaseAllKeys() }
        refreshHUD()
    }

    /// Roda do mouse afasta e aproxima a camera.
    func zoom(by amount: Float) {
        cameraZoom = clampf(cameraZoom - amount * 0.35, -2.0, 5.0)
    }

    func keyDown(_ code: UInt16, isRepeat: Bool) {
        pressed.insert(code)
        guard !isRepeat else { return }
        switch code {
        case 14: world.enqueue(.interact, for: localID)          // E
        case 3:  world.enqueue(.toggleLantern, for: localID)     // F
        case 15: world.enqueue(.pullLever, for: localID)         // R
        default: break
        }
    }

    func keyUp(_ code: UInt16) { pressed.remove(code) }
    func setSprint(_ on: Bool) { sprintHeld = on }
    func releaseAllKeys() { pressed.removeAll(); sprintHeld = false }

    // MARK: Eventos -> log da HUD
    private func consumeEvents() {
        for e in world.drainEvents() {
            switch e {
            case .cowLifted(let id):
                note("Erguendo \(name(id))")
            case .cowDropped(let id):
                note("\(name(id)) caiu no chão  ·  +8 alerta")
            case .cowExtracted(let id):
                note("\(name(id)) subiu para a nave  ·  +12 alerta")
            case .cowPanicked:
                break
            case .lanternPicked: note("Lanterna na mão")
            case .lanternDropped: note("Lanterna no chão")
            case .hayPicked: note("Fardo de feno")
            case .hayDropped: break
            case .gateToggled(_, let open):
                note(open ? "Porteira aberta  ·  +5 alerta" : "Porteira fechada  ·  +5 alerta")
            case .playerKnocked: note("VOCÊ FOI ATROPELADO")
            case .playerSlipped: note("Escorregou na lama e soltou a vaca")
            case .stampede(let v):
                note("DEBANDADA — VIGÍLIA \(v): \(GameController.vigiliaName(v))")
            case .leverPulled: note("ALAVANCA PUXADA — subida em 10 s")
            case .leverAborted: note("Subida abortada")
            case .expeditionEnded: break
            }
        }
    }

    private func name(_ id: CowID) -> String { world.cow(id)?.name ?? "a vaca" }
    private func note(_ text: String) { log.insert((text, 0), at: 0); if log.count > 5 { log.removeLast() } }

    static func vigiliaName(_ level: Int) -> String {
        switch level {
        case 0: return "Noite morna"
        case 1: return "Luz na cozinha"
        case 2: return "O Fazendeiro"
        case 3: return "A vizinhança"
        default: return "Protocolo de emergência"
        }
    }

    // MARK: HUD
    func refreshHUD() {
        guard let p = world.player(localID) else { return }
        var s = HUDState()
        s.alert = world.alert / Balance.alertMax
        s.vigilia = world.vigilia
        s.vigiliaName = GameController.vigiliaName(world.vigilia)
        s.stampede = world.stampedeTimer > 0
        s.cargoCount = world.cargoCount
        s.cargoValue = world.cargoValue
        s.cowsLeft = world.cowsOnField.filter { $0.behavior != .extraida }.count
        s.elapsed = world.elapsed
        s.leverCountdown = world.leverCountdown
        s.isDown = p.isDown
        s.messages = log.map(\.text)
        s.mouseCaptured = mouseCaptured

        switch p.hands {
        case .empty: s.hands = "Mãos livres"
        case .lantern: s.hands = p.lanternOn ? "Lanterna acesa" : "Lanterna apagada"
        case .hay: s.hands = "Fardo de feno"
        case .cow(let id):
            if let c = world.cow(id) {
                s.hands = "\(c.name) · \(c.size.displayName) · \(Int(c.carryFactor * 100))% vel."
            }
        }

        if p.liftingCow != nil {
            s.liftProgress = 1 - (p.liftTimer / max(0.01, liftTotal(for: p)))
        }

        if world.canReachLever(localID) {
            s.leverPrompt = world.leverCountdown != nil ? "[R]  Abortar subida" : "[R]  Puxar a Alavanca de Subida"
        }

        if let target = world.interaction(for: localID) {
            switch target {
            case .liftCow(_, let size, let name, let bell):
                s.prompt = "[E]  Erguer \(name) · \(size.displayName)\(bell ? " · com sino" : "")"
                s.promptDetail = "\(Int(size.soloCarryFactor * 100))% de velocidade sozinho"
            case .dropCow(_, let name): s.prompt = "[E]  Soltar \(name)"
            case .takeLantern: s.prompt = "[E]  Pegar a lanterna"
            case .dropLantern: s.prompt = "[E]  Largar a lanterna"
            case .takeHay: s.prompt = "[E]  Pegar o fardo de feno"
            case .dropHay: s.prompt = "[E]  Largar o fardo"
            case .gate(_, let open): s.prompt = open ? "[E]  Fechar a porteira" : "[E]  Abrir a porteira"
            }
        }

        if world.isFinished, let sum = world.summary {
            s.summary = sum
        }
        hud = s
    }

    private func liftTotal(for p: Player) -> Float {
        guard let id = p.liftingCow, let c = world.cow(id) else { return 1 }
        return c.size.liftTime
    }
}

struct HUDState {
    var alert: Float = 0
    var vigilia: Int = 0
    var vigiliaName: String = "Noite morna"
    var stampede = false
    var cargoCount = 0
    var cargoValue = 0
    var cowsLeft = 0
    var elapsed: Float = 0
    var hands: String = "Mãos livres"
    var prompt: String?
    var promptDetail: String?
    var leverPrompt: String?
    var leverCountdown: Float?
    var liftProgress: Float?
    var isDown = false
    var mouseCaptured = false
    var messages: [String] = []
    var summary: ExpeditionSummary?
}
