import SceneKit
import GameCore

/// Bloco 13: camada fina que espelha o estado do `World` em nos de cena.
/// Nao contem regra de jogo. Trocar SceneKit por RealityKit e trocar este arquivo.
/// Ajustes que dependem de como os .usdz foram exportados.
enum Tuning {
    /// A malha da vaca aponta para +X. O jogo usa +Z como frente.
    static let cowYawOffset: Float = -.pi / 2
}

@MainActor
final class ScenePresenter {

    let scene = SCNScene()
    let cameraNode = SCNNode()

    private var cowNodes: [CowID: SCNNode] = [:]
    private var playerNode = SCNNode()
    private var playerModel = SCNNode()
    private var lanternHandNode = SCNNode()
    private var lanternGroundNode = SCNNode()
    private var lanternLight = SCNNode()
    private var hayNodes: [Int: SCNNode] = [:]
    private var gateLeaves: [Int: SCNNode] = [:]
    private var leverPivot: SCNNode?
    private var beamNode = SCNNode()
    private var shipNode = SCNNode()

    private var cameraDistance: Float = 5.0
    private var cameraPivot = SIMD3<Float>(0, 1.5, 0)
    private var pivotInitialized = false

    // MARK: Construcao
    init(world: World) {
        buildEnvironment(world: world)
        buildFarm(world: world)
        buildShip(world: world)
        buildPlayer(world: world)
        buildCows(world: world)
    }

    /// `--daylight` acende tudo: serve para conferir escala, orientacao e layout.
    private var inspectionMode: Bool { CommandLine.arguments.contains("--daylight") }

    private func buildEnvironment(world: World) {
        let day = inspectionMode
        scene.background.contents = day
            ? NSColor(calibratedRed: 0.42, green: 0.55, blue: 0.78, alpha: 1)
            : NSColor(calibratedRed: 0.035, green: 0.045, blue: 0.090, alpha: 1)
        scene.fogColor = day
            ? NSColor(calibratedRed: 0.42, green: 0.55, blue: 0.78, alpha: 1)
            : NSColor(calibratedRed: 0.055, green: 0.070, blue: 0.130, alpha: 1)
        scene.fogStartDistance = day ? 140 : 38
        scene.fogEndDistance = day ? 400 : 150
        scene.fogDensityExponent = 1.4

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = day
            ? NSColor(calibratedWhite: 1, alpha: 1)
            : NSColor(calibratedRed: 0.30, green: 0.36, blue: 0.62, alpha: 1)
        ambient.light?.intensity = day ? 900 : 430
        scene.rootNode.addChildNode(ambient)

        // Lua: fraca, azulada, com sombra. A escuridao e uma mecanica (Bloco 1).
        let moon = SCNNode()
        moon.light = SCNLight()
        moon.light?.type = .directional
        moon.light?.color = day
            ? NSColor(calibratedWhite: 1, alpha: 1)
            : NSColor(calibratedRed: 0.62, green: 0.70, blue: 1.0, alpha: 1)
        moon.light?.intensity = day ? 1200 : 760
        // .deferred pinta de preto tudo fora do alcance do shadow map. .forward nao.
        moon.light?.castsShadow = true
        moon.light?.shadowMode = .forward
        moon.light?.shadowRadius = 3
        moon.light?.shadowSampleCount = 8
        moon.light?.shadowMapSize = CGSize(width: 2048, height: 2048)
        moon.light?.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.5)
        moon.light?.orthographicScale = 30
        moon.light?.zNear = 1
        moon.light?.zFar = 220
        moon.eulerAngles = SCNVector3(-0.95, 0.7, 0)
        scene.rootNode.addChildNode(moon)

        scene.rootNode.addChildNode(Prop.ground())
        scene.rootNode.addChildNode(Prop.grassTufts(count: 3200, bounds: world.farm.bounds))

        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 400
        cameraNode.camera?.fieldOfView = 66
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.bloomIntensity = 0.6
        cameraNode.camera?.bloomThreshold = 0.75
        cameraNode.camera?.wantsExposureAdaptation = false
        scene.rootNode.addChildNode(cameraNode)
    }

    private func buildFarm(world: World) {
        for (i, f) in world.farm.fences.enumerated() {
            if f.isGate {
                let g = Prop.gate(from: f.a, to: f.b)
                scene.rootNode.addChildNode(g)
                gateLeaves[i] = g.childNode(withName: "leaf", recursively: true)
            } else {
                scene.rootNode.addChildNode(Prop.fence(from: f.a, to: f.b))
            }
        }
        for m in world.farm.mud {
            let n = Prop.mud(radius: m.radius)
            n.position = SCNVector3(m.center.x, 0.02, m.center.z)
            scene.rootNode.addChildNode(n)
        }
        for bale in world.farm.hay {
            let n = Prop.hayBale()
            n.position = SCNVector3(bale.position.x, 0, bale.position.z)
            scene.rootNode.addChildNode(n)
            hayNodes[bale.id] = n
        }

        let lever = Prop.lever()
        lever.position = SCNVector3(world.farm.leverPosition.x, 0, world.farm.leverPosition.z)
        scene.rootNode.addChildNode(lever)
        leverPivot = lever.childNode(withName: "leverPivot", recursively: true)

        lanternGroundNode = Prop.lantern()
        lanternGroundNode.position = SCNVector3(world.farm.lanternSpawn.x, 0, world.farm.lanternSpawn.z)
        scene.rootNode.addChildNode(lanternGroundNode)
    }

    private func buildShip(world: World) {
        shipNode = AssetLoader.model("Nave_Espacial_UFO", height: 4.2, fallback: Prop.shipFallback)
        let holder = SCNNode()
        holder.addChildNode(shipNode)
        holder.position = SCNVector3(world.farm.shipAnchor.x,
                                     Balance.shipHeight,
                                     world.farm.shipAnchor.z)
        holder.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 40)))
        scene.rootNode.addChildNode(holder)

        let underglow = SCNNode()
        underglow.light = SCNLight()
        underglow.light?.type = .omni
        underglow.light?.color = Prop.beamColor
        underglow.light?.intensity = 620
        underglow.light?.attenuationEndDistance = 26
        underglow.position = SCNVector3(world.farm.shipAnchor.x, 3.5, world.farm.shipAnchor.z)
        scene.rootNode.addChildNode(underglow)

        beamNode = Prop.beam(radius: Balance.beamRadius, height: Balance.shipHeight)
        beamNode.position = SCNVector3(world.farm.shipAnchor.x, 0, world.farm.shipAnchor.z)
        let beamHolder = SCNNode()
        beamHolder.addChildNode(beamNode)
        beamNode.position.y = CGFloat(Balance.shipHeight) / 2
        beamHolder.position = SCNVector3(world.farm.shipAnchor.x, 0, world.farm.shipAnchor.z)
        scene.rootNode.addChildNode(beamHolder)
    }

    private func buildPlayer(world: World) {
        playerModel = AssetLoader.model("Alien_Frank", height: 1.75, fallback: Prop.alienFallback)
        playerNode = SCNNode()
        playerNode.addChildNode(playerModel)
        scene.rootNode.addChildNode(playerNode)

        lanternHandNode = Prop.lantern()
        lanternHandNode.position = SCNVector3(0.34, 1.05, 0.28)
        playerNode.addChildNode(lanternHandNode)

        lanternLight.light = SCNLight()
        lanternLight.light?.type = .spot
        lanternLight.light?.color = NSColor(calibratedRed: 1.0, green: 0.95, blue: 0.82, alpha: 1)
        lanternLight.light?.intensity = 2600
        lanternLight.light?.spotInnerAngle = 16
        lanternLight.light?.spotOuterAngle = 44
        lanternLight.light?.attenuationEndDistance = CGFloat(Balance.lanternRange + 6)
        lanternLight.light?.castsShadow = true
        lanternLight.light?.shadowMode = .forward
        lanternLight.light?.shadowRadius = 3
        lanternLight.light?.shadowSampleCount = 8
        lanternLight.light?.zNear = 0.4
        lanternLight.light?.zFar = CGFloat(Balance.lanternRange + 10)
        lanternLight.position = SCNVector3(0.3, 1.3, 0.3)
        lanternLight.eulerAngles = SCNVector3(0, CGFloat.pi, 0)
        playerNode.addChildNode(lanternLight)
    }

    private func buildCows(world: World) {
        for cow in world.allCows {
            let modelName = cow.isCurio ? "vaca_morango_et" : "Cow"
            let holder = SCNNode()
            let model = AssetLoader.model(modelName,
                                          height: CGFloat(cow.size.bodyHeight),
                                          fallback: Prop.cowFallback)
            holder.addChildNode(model)
            for a in cow.adornments {
                holder.addChildNode(Prop.adornment(a,
                                                   bodyRadius: cow.size.bodyRadius,
                                                   bodyHeight: cow.size.bodyHeight))
            }
            holder.name = "cow-\(cow.id.raw)"
            scene.rootNode.addChildNode(holder)
            cowNodes[cow.id] = holder
        }
    }

    // MARK: Sincronizacao por frame
    func sync(world: World, playerID: PlayerID, aimYaw: Float, pitch: Float, zoom: Float = 0) {
        guard let p = world.player(playerID) else { return }

        playerNode.position = SCNVector3(p.position.x, 0, p.position.z)
        playerNode.eulerAngles.y = CGFloat(p.yaw)
        // Caido: deita o modelo. Erguendo: agacha um pouco.
        let targetRoll: Float = p.isDown ? -.pi / 2.2 : 0
        playerModel.eulerAngles.x = CGFloat(targetRoll)
        playerModel.position.y = p.isDown ? 0.3 : (p.liftingCow != nil ? -0.22 : 0)

        let lit = p.hasLanternLit
        lanternHandNode.isHidden = p.hands != .lantern
        lanternLight.light?.intensity = lit ? 2600 : 0
        lanternGroundNode.isHidden = p.hands == .lantern
        if p.hands != .lantern {
            lanternGroundNode.position = SCNVector3(world.farm.lanternSpawn.x, 0, world.farm.lanternSpawn.z)
        }

        for cow in world.allCows {
            guard let n = cowNodes[cow.id] else { continue }
            if cow.behavior == .extraida {
                n.isHidden = true
                continue
            }
            n.isHidden = false
            n.position = SCNVector3(cow.position.x, cow.position.y, cow.position.z)
            n.eulerAngles.y = CGFloat(cow.heading + Tuning.cowYawOffset)
            // Cambaleio: mola visual, nao simulacao (Bloco 10).
            if cow.behavior == .carregada {
                let t = Float(CACurrentMediaTime())
                let amp = 0.05 * cow.size.struggle
                n.eulerAngles.z = CGFloat(sin(t * 7.5) * amp)
                n.eulerAngles.x = CGFloat(sin(t * 5.1) * amp * 0.7)
            } else if cow.behavior == .subindo {
                n.eulerAngles.y += 0.03
                n.eulerAngles.z = CGFloat(sin(Float(CACurrentMediaTime()) * 3) * 0.12)
            } else {
                n.eulerAngles.z = 0
                n.eulerAngles.x = 0
            }
        }

        for bale in world.farm.hay {
            guard let n = hayNodes[bale.id] else { continue }
            if let carrier = bale.carriedBy, let cp = world.player(carrier) {
                let anchor = cp.position + cp.forward * 0.85
                n.position = SCNVector3(anchor.x, 0.55, anchor.z)
                n.eulerAngles.y = CGFloat(cp.yaw)
            } else {
                n.position = SCNVector3(bale.position.x, 0, bale.position.z)
            }
        }

        for (i, f) in world.farm.fences.enumerated() where f.isGate {
            guard let leaf = gateLeaves[i] else { continue }
            let base = atan2(f.b.x - f.a.x, f.b.y - f.a.y)
            let target = base + (f.isOpen ? 1.9 : 0)
            leaf.eulerAngles.y += (CGFloat(target) - leaf.eulerAngles.y) * 0.18
        }

        if let pivot = leverPivot {
            let target: Float = world.leverCountdown != nil ? 0.7 : -0.35
            pivot.eulerAngles.x += (CGFloat(target) - pivot.eulerAngles.x) * 0.2
        }

        // O feixe pulsa mais forte enquanto sobe uma vaca.
        let lifting = world.allCows.contains { $0.behavior == .subindo }
        let mat = beamNode.geometry?.firstMaterial
        let pulse = CGFloat(0.13 + 0.05 * sin(CACurrentMediaTime() * (lifting ? 8 : 2)))
        mat?.emission.contents = Prop.beamColor.withAlphaComponent(lifting ? pulse * 2.2 : pulse)

        syncCamera(player: p, world: world, aimYaw: aimYaw, pitch: pitch, zoom: zoom)
    }

    private func syncCamera(player p: Player, world: World, aimYaw: Float, pitch: Float, zoom: Float) {
        // Vaca grande no colo empurra a camera para tras: o porte ocupa a tela.
        var desired: Float = 5.0
        if let c = p.hands.cowID.flatMap({ world.cow($0) }) {
            desired = 5.0 + c.size.modelScale * 1.9
        }
        desired = max(2.5, desired + zoom)
        cameraDistance += (desired - cameraDistance) * 0.08

        // O pivo segue o jogador com um amortecimento leve: os empurroes da vaca
        // se debatendo sacodem o corpo, nao a camera.
        let wanted = SIMD3<Float>(p.position.x, 1.5, p.position.z)
        if !pivotInitialized {
            cameraPivot = wanted
            pivotInitialized = true
        } else {
            cameraPivot += (wanted - cameraPivot) * 0.45
        }

        // Camera sobre o ombro: o alienigena sai do centro exato da tela.
        let right = SIMD3<Float>(-cos(aimYaw), 0, sin(aimYaw))
        let anchor = cameraPivot + right * 0.6

        let view = SIMD3<Float>(sin(aimYaw) * cos(pitch), sin(pitch), cos(aimYaw) * cos(pitch))

        // Ao raspar no chao, encurta a distancia em vez de achatar o Y: manter o
        // angulo pedido e o que impede a camera de tombar.
        var dist = cameraDistance
        let floorY: Float = 0.55
        if view.y > 0.001 {
            dist = min(dist, max(1.3, (anchor.y - floorY) / view.y))
        }
        let pos = anchor - view * dist

        cameraNode.position = SCNVector3(pos.x, max(floorY, pos.y), pos.z)
        // Angulos explicitos com roll = 0. `look(at:)` degenera em certos angulos
        // e gira a tela inteira 90 graus — era esse o bug.
        cameraNode.eulerAngles = SCNVector3(CGFloat(pitch), CGFloat(aimYaw + .pi), 0)
    }

}
