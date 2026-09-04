//
//  GameWorld.swift
//  TurnoMac
//
//  Constrói o 7º andar do Grand Oxford em RealityKit com geometria procedural
//  (sem assets externos): corredor, portas, luminárias, janela do fim, quarto 5,
//  gerente e a silhueta do lado de fora.
//

import AppKit
import RealityKit
import Metal
import simd

@MainActor
final class GameWorld {
    let root = Entity()
    let player = Entity()
    let camera = PerspectiveCamera()
    let manager = Entity()
    var managerDirection: Float = -1
    let silhouette = Entity()
    let ghost = Entity()   // outro jogador (co-op)
    var lights: [PointLight] = []
    var surfaces: [CleaningSurface] = []

    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    // Geometria do andar
    static let corridorHalfWidth: Float = 1.5
    static let corridorEnd: Float = -16          // parede da janela
    static let elevatorZ: Float = 0.0
    static let door5: SIMD3<Float> = [1.5, 0, -6]
    static let door7: SIMD3<Float> = [1.5, 0, -12]
    static let eyeHeight: Float = 1.6

    /// Áreas onde o jogador pode andar (x0, x1, z0, z1).
    let walkable: [(Float, Float, Float, Float)] = [
        (-1.2, 1.2, -15.4, -0.6),      // corredor
        (1.2, 6.2, -7.7, -4.3),         // quarto 5
    ]

    init() throws {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        camera.camera.fieldOfViewInDegrees = 72
        camera.camera.near = 0.05
        camera.camera.far = 80
        player.addChild(camera)
        camera.position = [0, Self.eyeHeight, 0]
        player.position = [0, 0, -1.5]
        root.addChild(player)
        buildCorridor()
        buildRoom5()
        buildOutside()
        buildManager()
        buildGhost()
        try buildSurfaces()
    }

    // MARK: - Helpers

    static func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
        NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
    }

    @discardableResult
    func box(_ size: SIMD3<Float>, at p: SIMD3<Float>, color: NSColor, roughness: Float = 0.85, metallic: Bool = false, parent: Entity? = nil) -> ModelEntity {
        let m = SimpleMaterial(color: color, roughness: MaterialScalarParameter(floatLiteral: roughness), isMetallic: metallic)
        let e = ModelEntity(mesh: .generateBox(size: size), materials: [m])
        e.position = p
        (parent ?? root).addChild(e)
        return e
    }

    func unlitPlane(width: Float, height: Float, color: NSColor) -> ModelEntity {
        ModelEntity(mesh: .generatePlane(width: width, height: height), materials: [UnlitMaterial(color: color)])
    }

    func text(_ s: String, size: CGFloat, color: NSColor, at p: SIMD3<Float>, yaw: Float) {
        let mesh = MeshResource.generateText(s, extrusionDepth: 0.005, font: .systemFont(ofSize: size, weight: .bold),
                                             containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping)
        let e = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, roughness: 0.4, isMetallic: true)])
        let bounds = e.visualBounds(relativeTo: nil)
        e.position = p
        e.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        // centraliza o texto no ponto
        let offset = -bounds.center
        e.position += e.orientation.act(SIMD3(offset.x, offset.y, 0))
        root.addChild(e)
    }

    // MARK: - Corredor

    private func buildCorridor() {
        let hw = Self.corridorHalfWidth
        let len = -Self.corridorEnd
        let zc = Self.corridorEnd / 2
        let carpet = Self.color(0.42, 0.13, 0.14)
        let wall = Self.color(0.86, 0.78, 0.62)
        let wainscot = Self.color(0.36, 0.22, 0.13)
        let ceilingC = Self.color(0.93, 0.9, 0.84)

        box([hw * 2 + 0.2, 0.05, len + 1], at: [0, -0.025, zc], color: carpet, roughness: 1)
        // faixa central do carpete
        box([1.0, 0.052, len + 1], at: [0, -0.024, zc], color: Self.color(0.55, 0.16, 0.16), roughness: 1)
        box([hw * 2 + 0.2, 0.05, len + 1], at: [0, 2.7, zc], color: ceilingC)
        // paredes laterais (topo) + lambri (base)
        for side: Float in [-1, 1] {
            box([0.1, 1.7, len + 1], at: [side * (hw + 0.05), 1.85, zc], color: wall)
            box([0.14, 1.0, len + 1], at: [side * (hw + 0.05), 0.5, zc], color: wainscot, roughness: 0.6)
            box([0.16, 0.06, len + 1], at: [side * (hw + 0.05), 1.02, zc], color: Self.color(0.55, 0.42, 0.22), roughness: 0.4)
        }
        // parede do elevador (z = 0)
        box([hw * 2 + 0.2, 2.7, 0.1], at: [0, 1.35, 0.05], color: wall)
        // portas do elevador
        box([1.2, 2.1, 0.06], at: [0, 1.05, 0.0], color: Self.color(0.75, 0.62, 0.35), roughness: 0.3, metallic: true)
        box([0.02, 2.0, 0.08], at: [0, 1.05, -0.01], color: Self.color(0.2, 0.15, 0.1))
        text("ELEVADOR", size: 0.12, color: Self.color(0.9, 0.8, 0.5), at: [0, 2.35, -0.02], yaw: .pi)

        // parede do fim com a janela (z = -16)
        let wz = Self.corridorEnd
        box([1.2, 2.7, 0.1], at: [-1.0, 1.35, wz - 0.05], color: wall)
        box([1.2, 2.7, 0.1], at: [1.0, 1.35, wz - 0.05], color: wall)
        box([0.8, 0.7, 0.1], at: [0, 0.35, wz - 0.05], color: wall)
        box([0.8, 0.4, 0.1], at: [0, 2.5, wz - 0.05], color: wall)
        // moldura + vidro (0.8 x 1.6)
        let frame = Self.color(0.3, 0.2, 0.12)
        box([0.9, 0.05, 0.14], at: [0, 0.7, wz], color: frame)
        box([0.9, 0.05, 0.14], at: [0, 2.3, wz], color: frame)
        box([0.05, 1.6, 0.14], at: [-0.425, 1.5, wz], color: frame)
        box([0.05, 1.6, 0.14], at: [0.425, 1.5, wz], color: frame)
        var glass = PhysicallyBasedMaterial()
        glass.baseColor = .init(tint: NSColor(calibratedRed: 0.6, green: 0.75, blue: 0.9, alpha: 0.18))
        glass.roughness = .init(floatLiteral: 0.05)
        glass.metallic = .init(floatLiteral: 0.0)
        glass.blending = .transparent(opacity: .init(floatLiteral: 0.18))
        let glassE = ModelEntity(mesh: .generatePlane(width: 0.8, height: 1.6), materials: [glass])
        glassE.position = [0, 1.5, wz]
        root.addChild(glassE)

        // portas
        addDoor(number: "5", at: Self.door5, side: 1)
        addDoor(number: "7", at: Self.door7, side: 1)
        addDoor(number: "6", at: [-1.5, 0, -6], side: -1)
        addDoor(number: "8", at: [-1.5, 0, -12], side: -1)
        // faixa de "manutenção" na porta 7
        box([0.9, 0.06, 0.02], at: [1.46, 1.3, -12], color: Self.color(0.95, 0.75, 0.1), roughness: 0.9)
        box([0.9, 0.06, 0.02], at: [1.46, 0.9, -12], color: Self.color(0.95, 0.75, 0.1), roughness: 0.9)

        // luminárias de parede + luzes quentes
        for z: Float in [-2.5, -6.5, -10.5, -14.5] {
            for side: Float in [-1, 1] {
                box([0.12, 0.25, 0.18], at: [side * (hw - 0.07), 2.05, z], color: Self.color(0.95, 0.85, 0.55), roughness: 0.3)
                if side == 1 {
                    let l = PointLight()
                    l.light.color = NSColor(calibratedRed: 1.0, green: 0.78, blue: 0.5, alpha: 1)
                    l.light.intensity = 9000
                    l.light.attenuationRadius = 9
                    l.position = [0, 2.2, z]
                    root.addChild(l)
                    lights.append(l)
                }
            }
        }
        // mesinha com vaso perto do elevador
        box([0.5, 0.75, 0.35], at: [-1.15, 0.375, -1.2], color: wainscot, roughness: 0.5)
        box([0.2, 0.3, 0.2], at: [-1.15, 0.9, -1.2], color: Self.color(0.3, 0.5, 0.3))
        // quadro na parede
        box([0.02, 0.6, 0.9], at: [-1.48, 1.7, -9], color: Self.color(0.5, 0.35, 0.15), roughness: 0.4)
        box([0.01, 0.5, 0.8], at: [-1.46, 1.7, -9], color: Self.color(0.2, 0.28, 0.4))

        // cabo da ferramenta: carrinho de limpeza perto do elevador
        box([0.6, 0.9, 0.4], at: [1.1, 0.45, -1.6], color: Self.color(0.85, 0.85, 0.82), roughness: 0.7)
        box([0.05, 1.2, 0.05], at: [1.3, 1.4, -1.6], color: Self.color(0.5, 0.35, 0.2))

        // luz fria e fraca de "lua" para as sombras
        let sun = DirectionalLight()
        sun.light.color = NSColor(calibratedRed: 0.55, green: 0.65, blue: 0.9, alpha: 1)
        sun.light.intensity = 400
        sun.look(at: [0, 0, -8], from: [3, 6, -20], relativeTo: nil)
        root.addChild(sun)
        // preenchimento suave vindo do teto (substitui luz ambiente, que o RealityKit não tem)
        let fill = DirectionalLight()
        fill.light.color = NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.75, alpha: 1)
        fill.light.intensity = 900
        fill.look(at: [0.3, 0, -8], from: [0, 5, -8], relativeTo: nil)
        root.addChild(fill)
        let fill2 = DirectionalLight()
        fill2.light.color = NSColor(calibratedRed: 0.9, green: 0.7, blue: 0.5, alpha: 1)
        fill2.light.intensity = 500
        fill2.look(at: [0, 1, -20], from: [0, 1, 0], relativeTo: nil)
        root.addChild(fill2)
    }

    private func addDoor(number: String, at p: SIMD3<Float>, side: Float) {
        let doorC = Self.color(0.36, 0.2, 0.1)
        box([0.06, 2.1, 1.0], at: [p.x - side * 0.02, 1.05, p.z], color: doorC, roughness: 0.5)
        box([0.08, 2.2, 1.12], at: [p.x - side * 0.04, 1.1, p.z], color: Self.color(0.28, 0.16, 0.08), roughness: 0.6)
        box([0.03, 0.03, 0.12], at: [p.x - side * 0.07, 1.0, p.z + 0.38], color: Self.color(0.8, 0.65, 0.3), roughness: 0.3, metallic: true)
        text(number, size: 0.16, color: Self.color(0.9, 0.78, 0.45), at: [p.x - side * 0.08, 1.75, p.z], yaw: side > 0 ? -.pi / 2 : .pi / 2)
    }

    // MARK: - Quarto 5

    private func buildRoom5() {
        let wall = Self.color(0.8, 0.72, 0.6)
        let floor = Self.color(0.5, 0.35, 0.22)
        // piso, teto
        box([5.2, 0.05, 3.6], at: [3.8, -0.025, -6], color: floor, roughness: 0.9)
        box([5.2, 0.05, 3.6], at: [3.8, 2.7, -6], color: Self.color(0.9, 0.88, 0.82))
        // paredes: fundo (x = 6.4), laterais (z = -4.2 e -7.8), frente (x = 1.5, exceto porta)
        box([0.1, 2.7, 3.6], at: [6.45, 1.35, -6], color: wall)
        box([5.2, 2.7, 0.1], at: [3.8, 1.35, -4.15], color: wall)
        box([5.2, 2.7, 0.1], at: [3.8, 1.35, -7.85], color: wall)
        box([0.1, 2.7, 1.2], at: [1.55, 1.35, -4.8], color: wall)
        box([0.1, 2.7, 1.2], at: [1.55, 1.35, -7.2], color: wall)
        box([0.1, 0.6, 1.2], at: [1.55, 2.4, -6], color: wall)
        // cama
        box([2.0, 0.5, 1.6], at: [5.2, 0.25, -5.2], color: Self.color(0.7, 0.6, 0.5))
        box([2.0, 0.25, 1.6], at: [5.2, 0.62, -5.2], color: Self.color(0.85, 0.82, 0.75))
        box([0.6, 0.18, 1.2], at: [5.9, 0.83, -5.2], color: Self.color(0.95, 0.94, 0.9))
        box([0.1, 1.2, 1.7], at: [6.35, 0.8, -5.2], color: Self.color(0.3, 0.18, 0.1))
        // mesa
        box([1.2, 0.05, 0.7], at: [3.6, 0.75, -7.0], color: Self.color(0.4, 0.25, 0.12), roughness: 0.4)
        for (dx, dz): (Float, Float) in [(-0.55, -0.3), (0.55, -0.3), (-0.55, 0.3), (0.55, 0.3)] {
            box([0.05, 0.75, 0.05], at: [3.6 + dx, 0.375, -7.0 + dz], color: Self.color(0.3, 0.18, 0.1))
        }
        // cadeira
        box([0.45, 0.05, 0.45], at: [3.6, 0.45, -6.3], color: Self.color(0.3, 0.18, 0.1))
        box([0.45, 0.5, 0.05], at: [3.6, 0.7, -6.1], color: Self.color(0.3, 0.18, 0.1))
        // abajur + luz
        box([0.3, 0.3, 0.3], at: [2.4, 1.5, -7.6], color: Self.color(0.95, 0.85, 0.6), roughness: 0.4)
        let l = PointLight()
        l.light.color = NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.6, alpha: 1)
        l.light.intensity = 7000
        l.light.attenuationRadius = 8
        l.position = [3.5, 2.2, -6]
        root.addChild(l)
        lights.append(l)
        // janela do quarto 5 (por onde ele saiu)
        box([0.05, 1.4, 1.2], at: [6.4, 1.6, -6.6], color: Self.color(0.12, 0.14, 0.25), roughness: 0.1)
        box([0.06, 0.05, 1.3], at: [6.4, 0.9, -6.6], color: Self.color(0.3, 0.2, 0.12))
        box([0.06, 0.05, 1.3], at: [6.4, 2.3, -6.6], color: Self.color(0.3, 0.2, 0.12))
        // taça caída
        box([0.06, 0.06, 0.16], at: [3.9, 0.8, -6.9], color: Self.color(0.9, 0.9, 0.95), roughness: 0.1)
    }

    // MARK: - Lado de fora

    private func buildOutside() {
        let wz = Self.corridorEnd
        // céu noturno e prédio vizinho
        let sky = unlitPlane(width: 30, height: 20, color: Self.color(0.10, 0.12, 0.22))
        sky.position = [0, 4, wz - 12]
        root.addChild(sky)
        let building = unlitPlane(width: 8, height: 14, color: Self.color(0.05, 0.06, 0.1))
        building.position = [-3, 3, wz - 9]
        root.addChild(building)
        var g = SplitMix(seed: 21)
        for _ in 0..<26 {
            let w = unlitPlane(width: 0.35, height: 0.45, color: g.next() > 0.5 ? Self.color(0.95, 0.8, 0.45) : Self.color(0.7, 0.75, 0.9))
            w.position = [-6.5 + Float(g.next()) * 7, -3 + Float(g.next()) * 12, wz - 8.9]
            root.addChild(w)
        }
        // lua
        let moon = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [UnlitMaterial(color: Self.color(0.9, 0.9, 0.8))])
        moon.position = [5, 7, wz - 11.5]
        root.addChild(moon)

        // silhueta atrás do vidro (aparece uma vez)
        let dark = Self.color(0.01, 0.01, 0.02)
        let torso = ModelEntity(mesh: .generateBox(size: [0.5, 0.8, 0.25]), materials: [UnlitMaterial(color: dark)])
        torso.position = [0, 1.3, 0]
        let head = ModelEntity(mesh: .generateSphere(radius: 0.14), materials: [UnlitMaterial(color: dark)])
        head.position = [0, 1.86, 0]
        let hand = ModelEntity(mesh: .generateBox(size: [0.12, 0.16, 0.05]), materials: [UnlitMaterial(color: dark)])
        hand.position = [0.28, 1.55, 0.1]
        silhouette.addChild(torso); silhouette.addChild(head); silhouette.addChild(hand)
        silhouette.position = [0.1, 0, wz - 0.35]
        silhouette.isEnabled = false
        root.addChild(silhouette)
    }

    // MARK: - Personagens

    private func buildManager() {
        let uniform = Self.color(0.12, 0.28, 0.22)
        box([0.42, 0.9, 0.28], at: [0, 1.0, 0], color: uniform, roughness: 0.9, parent: manager)
        box([0.36, 0.55, 0.26], at: [0, 0.3, 0], color: Self.color(0.1, 0.1, 0.12), parent: manager)
        let head = ModelEntity(mesh: .generateSphere(radius: 0.14), materials: [SimpleMaterial(color: Self.color(0.85, 0.7, 0.6), roughness: 0.8, isMetallic: false)])
        head.position = [0, 1.6, 0]
        manager.addChild(head)
        box([0.3, 0.1, 0.3], at: [0, 1.74, -0.02], color: Self.color(0.35, 0.3, 0.3), parent: manager)
        // crachá
        box([0.08, 0.05, 0.01], at: [0.12, 1.3, 0.15], color: Self.color(0.9, 0.8, 0.4), roughness: 0.3, parent: manager)
        manager.position = [0.6, 0, -3]
        root.addChild(manager)
    }

    private func buildGhost() {
        box([0.4, 0.9, 0.26], at: [0, 1.0, 0], color: Self.color(0.7, 0.75, 0.85), parent: ghost)
        box([0.34, 0.55, 0.24], at: [0, 0.3, 0], color: Self.color(0.2, 0.2, 0.25), parent: ghost)
        let head = ModelEntity(mesh: .generateSphere(radius: 0.14), materials: [SimpleMaterial(color: Self.color(0.85, 0.7, 0.6), roughness: 0.8, isMetallic: false)])
        head.position = [0, 1.6, 0]
        ghost.addChild(head)
        ghost.isEnabled = false
        root.addChild(ghost)
    }

    // MARK: - Superfícies limpáveis

    private func dirtMaterial(_ res: TextureResource) -> UnlitMaterial {
        var m = UnlitMaterial()
        m.color = .init(tint: .white, texture: .init(res))
        m.blending = .transparent(opacity: .init(floatLiteral: 1.0))
        return m
    }

    private func staticTexture(_ pixels: [UInt8], width: Int, height: Int) throws -> TextureResource {
        let mask = try DirtMask(device: device, width: width, height: height, pixels: pixels)
        mask.flush(queue: commandQueue)
        return mask.resource
    }

    private func buildSurfaces() throws {
        let wz = Self.corridorEnd
        // 1. Vidro do fim do corredor — rodo. Prova: marca de mão.
        let winW = 128, winH = 256
        let handRegion = CGRect(x: 0.5, y: 0.35, width: 0.4, height: 0.3)
        let winMask = try DirtMask(device: device, width: winW, height: winH, pixels: Textures.glassGrime(width: winW, height: winH))
        let window = CleaningSurface(index: 0, id: "vidro", taskID: "vidro", tool: .rodo, promptVerb: "Limpar o vidro",
                                     origin: [0, 1.5, wz + 0.02], right: [1, 0, 0], up: [0, 1, 0], width: 0.8, height: 1.6,
                                     mask: winMask, revealRegion: handRegion, evidenceID: "mao",
                                     toolCameraPosition: [0, Self.eyeHeight, wz + 1.25], toolLookAt: [0, 1.5, wz],
                                     phoneYawRange: 0.7, phonePitchRange: 0.8)
        let hand = try staticTexture(Textures.handprint(width: winW, height: winH, region: handRegion), width: winW, height: winH)
        let handE = ModelEntity(mesh: .generatePlane(width: 0.8, height: 1.6), materials: [dirtMaterial(hand)])
        handE.position = [0, 1.5, wz - 0.01]  // do lado de fora do vidro
        root.addChild(handE)
        window.revealEntity = handE
        attach(window, mesh: .generatePlane(width: 0.8, height: 1.6), orientation: simd_quatf(angle: 0, axis: [0, 1, 0]))

        // 2. Chão do corredor perto da suíte 7 — vassoura. Prova: bituca.
        let flW = 192, flH = 256
        let cigRegion = CGRect(x: 0.72, y: 0.3, width: 0.16, height: 0.12)
        let floorMask = try DirtMask(device: device, width: flW, height: flH, pixels: Textures.dust(width: flW, height: flH))
        let floor = CleaningSurface(index: 1, id: "chao", taskID: "chao", tool: .vassoura, promptVerb: "Varrer o corredor",
                                    origin: [0, 0.006, -11.5], right: [1, 0, 0], up: [0, 0, -1], width: 2.9, height: 4.0,
                                    mask: floorMask, revealRegion: cigRegion, evidenceID: "cigarro",
                                    toolCameraPosition: [0, Self.eyeHeight + 0.3, -8.6], toolLookAt: [0, 0, -11.5],
                                    phoneYawRange: 0.8, phonePitchRange: 0.6)
        let cig = try staticTexture(Textures.cigarette(width: flW, height: flH, region: cigRegion), width: flW, height: flH)
        let cigE = ModelEntity(mesh: .generatePlane(width: 2.9, depth: 4.0), materials: [dirtMaterial(cig)])
        cigE.position = [0, 0.004, -11.5]
        root.addChild(cigE)
        floor.revealEntity = cigE
        attach(floor, mesh: .generatePlane(width: 2.9, depth: 4.0), orientation: simd_quatf(angle: 0, axis: [0, 1, 0]))

        // 3. Mesa do quarto 5 — pano. Prova: cartão-chave.
        let tbW = 192, tbH = 128
        let cardRegion = CGRect(x: 0.55, y: 0.25, width: 0.3, height: 0.42)
        let tableMask = try DirtMask(device: device, width: tbW, height: tbH, pixels: Textures.wineStain(width: tbW, height: tbH))
        let table = CleaningSurface(index: 2, id: "mesa", taskID: "mesa", tool: .pano, promptVerb: "Limpar a mesa",
                                    origin: [3.6, 0.781, -7.0], right: [1, 0, 0], up: [0, 0, -1], width: 1.2, height: 0.7,
                                    mask: tableMask, revealRegion: cardRegion, evidenceID: "cartao",
                                    toolCameraPosition: [3.6, Self.eyeHeight - 0.1, -6.0], toolLookAt: [3.6, 0.78, -7.0],
                                    phoneYawRange: 0.7, phonePitchRange: 0.5)
        let card = try staticTexture(Textures.keycard(width: tbW, height: tbH, region: cardRegion), width: tbW, height: tbH)
        let cardE = ModelEntity(mesh: .generatePlane(width: 1.2, depth: 0.7), materials: [dirtMaterial(card)])
        cardE.position = [3.6, 0.779, -7.0]
        root.addChild(cardE)
        table.revealEntity = cardE
        attach(table, mesh: .generatePlane(width: 1.2, depth: 0.7), orientation: simd_quatf(angle: 0, axis: [0, 1, 0]))
    }

    private func attach(_ s: CleaningSurface, mesh: MeshResource, orientation: simd_quatf) {
        let e = ModelEntity(mesh: mesh, materials: [dirtMaterial(s.mask.resource)])
        e.position = s.origin
        e.orientation = orientation
        root.addChild(e)
        s.dirtEntity = e

        // ponta da ferramenta
        let tipMesh: MeshResource
        let tipColor: NSColor
        switch s.tool {
        case .rodo:
            tipMesh = .generateBox(size: [s.width * 0.22, 0.035, 0.03]); tipColor = Self.color(0.1, 0.1, 0.1)
        case .vassoura:
            tipMesh = .generateBox(size: [s.width * 0.18, 0.06, 0.4]); tipColor = Self.color(0.75, 0.6, 0.3)
        default:
            tipMesh = .generateBox(size: [s.width * 0.14, 0.02, s.height * 0.22]); tipColor = Self.color(0.95, 0.9, 0.5)
        }
        let tip = ModelEntity(mesh: tipMesh, materials: [SimpleMaterial(color: tipColor, roughness: 0.6, isMetallic: false)])
        tip.isEnabled = false
        root.addChild(tip)
        s.toolTip = tip
        surfaces.append(s)
    }

    func flushSurfaces() {
        for s in surfaces { s.mask.flush(queue: commandQueue) }
    }

    /// Testa se uma posição (x, z) é andável.
    func canWalk(x: Float, z: Float) -> Bool {
        for r in walkable where x >= r.0 && x <= r.1 && z >= r.2 && z <= r.3 { return true }
        // vão da porta do quarto 5
        if x >= 1.0 && x <= 1.6 && z >= -6.45 && z <= -5.55 { return true }
        return false
    }
}
