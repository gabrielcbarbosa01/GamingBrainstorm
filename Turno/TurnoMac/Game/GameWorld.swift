//
//  GameWorld.swift
//  TurnoMac
//
//  O Grand Oxford inteiro em geometria procedural: sétimo andar, quarto 5,
//  suíte 7, lobby, porão, a fachada com a gôndola e o oitavo andar lacrado.
//  Todas as áreas coexistem em regiões separadas do mesmo espaço; a troca
//  entre elas é um teleporte pelo elevador de serviço.
//

import AppKit
import RealityKit
import Metal
import simd

@MainActor
final class GameWorld {
    let root = Entity()
    let nightRoot = Entity()
    let player = Entity()
    let camera = PerspectiveCamera()
    let headlamp = SpotLight()

    let manager = Entity()          // Dona Celeste
    let npc = Entity()              // Rui / hóspede, conforme a noite
    let ghost = Entity()            // Osvaldo
    var peerAvatars: [String: Entity] = [:]

    var lights: [AreaID: [PointLight]] = [:]
    var surfaces: [CleaningSurface] = []
    var interactionMarkers: [String: Entity] = [:]

    let device: MTLDevice
    let commandQueue: MTLCommandQueue

    static let eyeHeight: Float = 1.6

    /// Regiões andáveis em coordenadas de mundo: (x0, x1, z0, z1, área).
    private(set) var walkRects: [(Float, Float, Float, Float, AreaID)] = []
    /// Lugares onde a gerente não te vê: dentro dos quartos, na gôndola,
    /// atrás do balcão, atrás da prateleira do porão.
    private(set) var coverRects: [(Float, Float, Float, Float)] = []

    // MARK: Offsets de cada área

    static func offset(_ a: AreaID) -> SIMD3<Float> {
        switch a {
        case .corredor7, .quarto5, .suite7: return [0, 0, 0]
        case .lobby: return [40, 0, 0]
        case .porao: return [80, 0, 0]
        case .fachada: return [-40, 0, 0]
        case .andar8: return [120, 0, 0]
        }
    }

    /// Áreas fisicamente conectadas entre si (sem teleporte).
    static func region(_ a: AreaID) -> String {
        switch a {
        case .corredor7, .quarto5, .suite7: return "andar7"
        default: return a.rawValue
        }
    }

    /// Onde fica o ponto de viagem (elevador, escada, gôndola) de cada região.
    static func travelPoint(_ a: AreaID) -> SIMD3<Float> {
        offset(a) + {
            switch a {
            case .corredor7, .quarto5, .suite7: return SIMD3<Float>(0, 1.2, -0.7)
            case .lobby: return SIMD3<Float>(4.6, 1.2, -1.0)
            case .porao: return SIMD3<Float>(4.0, 1.2, -1.0)
            case .fachada: return SIMD3<Float>(1.7, 1.2, 1.5)
            case .andar8: return SIMD3<Float>(-0.9, 1.2, -0.8)
            }
        }()
    }

    static func spawn(_ a: AreaID) -> SIMD3<Float> {
        offset(a) + {
            switch a {
            case .corredor7, .quarto5, .suite7: return SIMD3<Float>(0, 0, -1.9)
            case .lobby: return SIMD3<Float>(3.4, 0, -2.2)
            case .porao: return SIMD3<Float>(3.0, 0, -2.2)
            case .fachada: return SIMD3<Float>(0.6, 0, 1.2)
            case .andar8: return SIMD3<Float>(0, 0, -2.0)
            }
        }()
    }

    // MARK: Init

    init() throws {
        device = MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!
        camera.camera.fieldOfViewInDegrees = 72
        camera.camera.near = 0.05
        camera.camera.far = 90
        player.addChild(camera)
        camera.position = [0, Self.eyeHeight, 0]
        player.position = Self.spawn(.corredor7)
        root.addChild(player)
        root.addChild(nightRoot)

        headlamp.light.color = NSColor(calibratedRed: 1.0, green: 0.94, blue: 0.85, alpha: 1)
        headlamp.light.intensity = 42000
        headlamp.light.innerAngleInDegrees = 30
        headlamp.light.outerAngleInDegrees = 68
        headlamp.light.attenuationRadius = 26
        headlamp.isEnabled = false
        camera.addChild(headlamp)
        headlamp.position = [0.1, 0, 0]
        headlamp.orientation = simd_quatf(angle: 0, axis: [0, 1, 0])

        buildFloor7()
        buildRoom5()
        buildSuite7()
        buildLobby()
        buildBasement()
        buildFacade()
        buildFloor8()
        buildCharacters()
    }

    // MARK: Primitivas

    static func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
        NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
    }

    @discardableResult
    func box(_ size: SIMD3<Float>, at p: SIMD3<Float>, color: NSColor, roughness: Float = 0.85,
             metallic: Bool = false, parent: Entity? = nil) -> ModelEntity {
        let m = SimpleMaterial(color: color, roughness: MaterialScalarParameter(floatLiteral: roughness), isMetallic: metallic)
        let e = ModelEntity(mesh: .generateBox(size: size), materials: [m])
        e.position = p
        (parent ?? root).addChild(e)
        return e
    }

    @discardableResult
    func unlitBox(_ size: SIMD3<Float>, at p: SIMD3<Float>, color: NSColor, parent: Entity? = nil) -> ModelEntity {
        let e = ModelEntity(mesh: .generateBox(size: size), materials: [UnlitMaterial(color: color)])
        e.position = p
        (parent ?? root).addChild(e)
        return e
    }

    func unlitPlane(width: Float, height: Float, color: NSColor) -> ModelEntity {
        ModelEntity(mesh: .generatePlane(width: width, height: height), materials: [UnlitMaterial(color: color)])
    }

    @discardableResult
    func lamp(at p: SIMD3<Float>, area: AreaID, color: NSColor, intensity: Float, radius: Float) -> PointLight {
        let l = PointLight()
        l.light.color = color
        l.light.intensity = intensity
        l.light.attenuationRadius = radius
        l.position = p
        root.addChild(l)
        lights[area, default: []].append(l)
        return l
    }

    func text(_ s: String, size: CGFloat, color: NSColor, at p: SIMD3<Float>, yaw: Float, parent: Entity? = nil) {
        let mesh = MeshResource.generateText(s, extrusionDepth: 0.005, font: .systemFont(ofSize: size, weight: .bold),
                                             containerFrame: .zero, alignment: .center, lineBreakMode: .byWordWrapping)
        let e = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: color, roughness: 0.4, isMetallic: true)])
        let bounds = e.visualBounds(relativeTo: nil)
        e.position = p
        e.orientation = simd_quatf(angle: yaw, axis: [0, 1, 0])
        e.position += e.orientation.act(SIMD3(-bounds.center.x, -bounds.center.y, 0))
        (parent ?? root).addChild(e)
    }

    func walk(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float, _ area: AreaID) {
        let o = Self.offset(area)
        walkRects.append((x0 + o.x, x1 + o.x, z0 + o.z, z1 + o.z, area))
    }

    func cover(_ x0: Float, _ x1: Float, _ z0: Float, _ z1: Float, _ area: AreaID) {
        let o = Self.offset(area)
        coverRects.append((x0 + o.x, x1 + o.x, z0 + o.z, z1 + o.z))
    }

    func isInCover(_ p: SIMD3<Float>) -> Bool {
        coverRects.contains { p.x >= $0.0 && p.x <= $0.1 && p.z >= $0.2 && p.z <= $0.3 }
    }

    // MARK: Sétimo andar

    static let corridorHalfWidth: Float = 1.5
    static let corridorEnd: Float = -16
    static let door5: SIMD3<Float> = [1.5, 0, -6]
    static let door7: SIMD3<Float> = [1.5, 0, -12]

    private func buildFloor7() {
        let hw = Self.corridorHalfWidth
        let len = -Self.corridorEnd
        let zc = Self.corridorEnd / 2
        let carpet = Self.color(0.42, 0.13, 0.14)
        let wall = Self.color(0.86, 0.78, 0.62)
        let wainscot = Self.color(0.36, 0.22, 0.13)

        box([hw * 2 + 0.2, 0.05, len + 1], at: [0, -0.025, zc], color: carpet, roughness: 1)
        box([1.0, 0.052, len + 1], at: [0, -0.024, zc], color: Self.color(0.55, 0.16, 0.16), roughness: 1)
        box([hw * 2 + 0.2, 0.05, len + 1], at: [0, 2.7, zc], color: Self.color(0.93, 0.9, 0.84))
        for side: Float in [-1, 1] {
            box([0.1, 1.7, len + 1], at: [side * (hw + 0.05), 1.85, zc], color: wall)
            box([0.14, 1.0, len + 1], at: [side * (hw + 0.05), 0.5, zc], color: wainscot, roughness: 0.6)
            box([0.16, 0.06, len + 1], at: [side * (hw + 0.05), 1.02, zc], color: Self.color(0.55, 0.42, 0.22), roughness: 0.4)
        }
        // elevador
        box([hw * 2 + 0.2, 2.7, 0.1], at: [0, 1.35, 0.05], color: wall)
        box([1.2, 2.1, 0.06], at: [0, 1.05, 0.0], color: Self.color(0.75, 0.62, 0.35), roughness: 0.3, metallic: true)
        box([0.02, 2.0, 0.08], at: [0, 1.05, -0.01], color: Self.color(0.2, 0.15, 0.1))
        text("ELEVADOR", size: 0.12, color: Self.color(0.9, 0.8, 0.5), at: [0, 2.35, -0.02], yaw: .pi)

        // parede do fim, com janela
        let wz = Self.corridorEnd
        box([1.2, 2.7, 0.1], at: [-1.0, 1.35, wz - 0.05], color: wall)
        box([1.2, 2.7, 0.1], at: [1.0, 1.35, wz - 0.05], color: wall)
        box([0.8, 0.7, 0.1], at: [0, 0.35, wz - 0.05], color: wall)
        box([0.8, 0.4, 0.1], at: [0, 2.5, wz - 0.05], color: wall)
        let frame = Self.color(0.3, 0.2, 0.12)
        box([0.9, 0.05, 0.14], at: [0, 0.7, wz], color: frame)
        box([0.9, 0.05, 0.14], at: [0, 2.3, wz], color: frame)
        box([0.05, 1.6, 0.14], at: [-0.425, 1.5, wz], color: frame)
        box([0.05, 1.6, 0.14], at: [0.425, 1.5, wz], color: frame)
        nightSkyPanel(at: [0, 1.5, wz - 0.4], width: 1.4, height: 2.0, seed: 5)

        addDoor(number: "5", at: Self.door5, side: 1)
        addDoor(number: "7", at: Self.door7, side: 1)
        addDoor(number: "6", at: [-1.5, 0, -6], side: -1)
        addDoor(number: "8", at: [-1.5, 0, -12], side: -1)

        for z: Float in [-2.5, -6.5, -10.5, -14.5] {
            for side: Float in [-1, 1] {
                box([0.12, 0.25, 0.18], at: [side * (hw - 0.07), 2.05, z], color: Self.color(0.95, 0.85, 0.55), roughness: 0.3)
            }
            lamp(at: [0, 2.2, z], area: .corredor7, color: Self.color(1.0, 0.78, 0.5), intensity: 16000, radius: 11)
        }
        lamp(at: [0, 1.2, -8], area: .corredor7, color: Self.color(0.9, 0.72, 0.5), intensity: 5000, radius: 16)

        box([0.5, 0.75, 0.35], at: [-1.15, 0.375, -1.2], color: wainscot, roughness: 0.5)
        box([0.2, 0.3, 0.2], at: [-1.15, 0.9, -1.2], color: Self.color(0.3, 0.5, 0.3))
        box([0.02, 0.6, 0.9], at: [-1.48, 1.7, -9], color: Self.color(0.5, 0.35, 0.15), roughness: 0.4)
        box([0.01, 0.5, 0.8], at: [-1.46, 1.7, -9], color: Self.color(0.2, 0.28, 0.4))
        // carrinho de limpeza
        box([0.6, 0.9, 0.4], at: [1.1, 0.45, -1.6], color: Self.color(0.85, 0.85, 0.82), roughness: 0.7)
        box([0.05, 1.2, 0.05], at: [1.3, 1.4, -1.6], color: Self.color(0.5, 0.35, 0.2))

        walk(-1.2, 1.2, -15.4, -0.6, .corredor7)
    }

    private func addDoor(number: String, at p: SIMD3<Float>, side: Float, parent: Entity? = nil) {
        let doorC = Self.color(0.36, 0.2, 0.1)
        box([0.06, 2.1, 1.0], at: [p.x - side * 0.02, 1.05, p.z], color: doorC, roughness: 0.5, parent: parent)
        box([0.08, 2.2, 1.12], at: [p.x - side * 0.04, 1.1, p.z], color: Self.color(0.28, 0.16, 0.08), roughness: 0.6, parent: parent)
        box([0.03, 0.03, 0.12], at: [p.x - side * 0.07, 1.0, p.z + 0.38], color: Self.color(0.8, 0.65, 0.3), roughness: 0.3, metallic: true, parent: parent)
        text(number, size: 0.16, color: Self.color(0.9, 0.78, 0.45), at: [p.x - side * 0.08, 1.75, p.z], yaw: side > 0 ? -.pi / 2 : .pi / 2, parent: parent)
    }

    /// Painel de céu noturno com prédio vizinho, usado nas janelas.
    private func nightSkyPanel(at p: SIMD3<Float>, width: Float, height: Float, seed: UInt64) {
        var g = SplitMix(seed: seed)
        let sky = unlitPlane(width: width, height: height, color: Self.color(0.06, 0.08, 0.16))
        sky.position = p
        root.addChild(sky)
        for _ in 0..<10 {
            let lit = g.next() > 0.55
            let w = unlitPlane(width: width * 0.09, height: height * 0.06,
                               color: lit ? Self.color(0.95, 0.8, 0.45) : Self.color(0.1, 0.12, 0.2))
            w.position = p + SIMD3(Float(g.range(-Double(width) * 0.42, Double(width) * 0.42)),
                                   Float(g.range(-Double(height) * 0.4, Double(height) * 0.4)), 0.01)
            root.addChild(w)
        }
    }

    // MARK: Quarto 5

    private func buildRoom5() {
        let wall = Self.color(0.8, 0.72, 0.6)
        box([5.2, 0.05, 3.6], at: [3.8, -0.025, -6], color: Self.color(0.5, 0.35, 0.22), roughness: 0.9)
        box([5.2, 0.05, 3.6], at: [3.8, 2.7, -6], color: Self.color(0.9, 0.88, 0.82))
        box([0.1, 2.7, 3.6], at: [6.45, 1.35, -6], color: wall)
        box([5.2, 2.7, 0.1], at: [3.8, 1.35, -4.15], color: wall)
        box([5.2, 2.7, 0.1], at: [3.8, 1.35, -7.85], color: wall)
        box([0.1, 2.7, 1.2], at: [1.55, 1.35, -4.8], color: wall)
        box([0.1, 2.7, 1.2], at: [1.55, 1.35, -7.2], color: wall)
        box([0.1, 0.6, 1.2], at: [1.55, 2.4, -6], color: wall)
        box([2.0, 0.5, 1.6], at: [5.2, 0.25, -5.2], color: Self.color(0.7, 0.6, 0.5))
        box([2.0, 0.25, 1.6], at: [5.2, 0.62, -5.2], color: Self.color(0.85, 0.82, 0.75))
        box([0.6, 0.18, 1.2], at: [5.9, 0.83, -5.2], color: Self.color(0.95, 0.94, 0.9))
        box([0.1, 1.2, 1.7], at: [6.35, 0.8, -5.2], color: Self.color(0.3, 0.18, 0.1))
        box([1.2, 0.05, 0.7], at: [3.6, 0.75, -7.0], color: Self.color(0.4, 0.25, 0.12), roughness: 0.4)
        for (dx, dz): (Float, Float) in [(-0.55, -0.3), (0.55, -0.3), (-0.55, 0.3), (0.55, 0.3)] {
            box([0.05, 0.75, 0.05], at: [3.6 + dx, 0.375, -7.0 + dz], color: Self.color(0.3, 0.18, 0.1))
        }
        box([0.45, 0.05, 0.45], at: [3.6, 0.45, -6.3], color: Self.color(0.3, 0.18, 0.1))
        box([0.45, 0.5, 0.05], at: [3.6, 0.7, -6.1], color: Self.color(0.3, 0.18, 0.1))
        box([0.3, 0.3, 0.3], at: [2.4, 1.5, -7.6], color: Self.color(0.95, 0.85, 0.6), roughness: 0.4)
        lamp(at: [3.5, 2.2, -6], area: .quarto5, color: Self.color(1.0, 0.82, 0.6), intensity: 13000, radius: 9)
        // janela por onde ele saiu
        box([0.06, 0.05, 1.3], at: [6.4, 0.9, -6.6], color: Self.color(0.3, 0.2, 0.12))
        box([0.06, 0.05, 1.3], at: [6.4, 2.3, -6.6], color: Self.color(0.3, 0.2, 0.12))
        let sky = unlitPlane(width: 1.2, height: 1.4, color: Self.color(0.06, 0.08, 0.16))
        sky.position = [6.42, 1.6, -6.6]
        sky.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        root.addChild(sky)
        box([0.06, 0.06, 0.16], at: [3.9, 0.8, -6.9], color: Self.color(0.9, 0.9, 0.95), roughness: 0.1)

        walk(1.2, 6.2, -7.7, -4.3, .quarto5)
        walk(1.0, 1.6, -6.45, -5.55, .quarto5)
        cover(1.7, 6.2, -7.7, -4.3, .quarto5)
    }

    // MARK: Suíte 7

    private func buildSuite7() {
        let wall = Self.color(0.78, 0.7, 0.62)
        box([5.2, 0.05, 3.6], at: [3.8, -0.025, -12], color: Self.color(0.32, 0.2, 0.2), roughness: 1)
        box([5.2, 0.05, 3.6], at: [3.8, 2.7, -12], color: Self.color(0.9, 0.88, 0.82))
        box([0.1, 2.7, 3.6], at: [6.45, 1.35, -12], color: wall)
        box([5.2, 2.7, 0.1], at: [3.8, 1.35, -10.15], color: wall)
        box([5.2, 2.7, 0.1], at: [3.8, 1.35, -13.85], color: wall)
        box([0.1, 2.7, 1.2], at: [1.55, 1.35, -10.8], color: wall)
        box([0.1, 2.7, 1.2], at: [1.55, 1.35, -13.2], color: wall)
        box([0.1, 0.6, 1.2], at: [1.55, 2.4, -12], color: wall)
        // cama desfeita e fita de isolamento
        box([2.0, 0.5, 1.6], at: [5.2, 0.25, -11.0], color: Self.color(0.65, 0.55, 0.48))
        box([2.0, 0.22, 1.6], at: [5.2, 0.6, -11.0], color: Self.color(0.8, 0.78, 0.72))
        box([0.1, 1.2, 1.7], at: [6.35, 0.8, -11.0], color: Self.color(0.3, 0.18, 0.1))
        // banheiro ao fundo com espelho
        box([0.1, 2.7, 2.0], at: [6.4, 1.35, -13.2], color: Self.color(0.86, 0.86, 0.84))
        box([0.02, 1.3, 1.1], at: [6.36, 1.55, -13.2], color: Self.color(0.75, 0.8, 0.82), roughness: 0.05, metallic: true)
        box([0.5, 0.15, 0.9], at: [6.1, 0.85, -13.2], color: Self.color(0.95, 0.95, 0.93), roughness: 0.2)
        // janela da suíte
        box([0.06, 0.05, 1.3], at: [6.4, 0.9, -11.6], color: Self.color(0.3, 0.2, 0.12))
        box([0.06, 0.05, 1.3], at: [6.4, 2.3, -11.6], color: Self.color(0.3, 0.2, 0.12))
        let sky = unlitPlane(width: 1.2, height: 1.4, color: Self.color(0.06, 0.08, 0.16))
        sky.position = [6.42, 1.6, -11.6]
        sky.orientation = simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        root.addChild(sky)
        lamp(at: [3.7, 2.2, -12], area: .suite7, color: Self.color(0.95, 0.8, 0.62), intensity: 11000, radius: 9)
        lamp(at: [6.0, 1.9, -13.2], area: .suite7, color: Self.color(0.85, 0.9, 1.0), intensity: 4000, radius: 5)

        walk(1.2, 6.2, -13.7, -10.3, .suite7)
        walk(1.0, 1.6, -12.45, -11.55, .suite7)
        cover(1.7, 6.2, -13.7, -10.3, .suite7)
    }

    // MARK: Personagens

    private func buildCharacters() {
        // Dona Celeste
        let uniform = Self.color(0.12, 0.28, 0.22)
        box([0.42, 0.9, 0.28], at: [0, 1.0, 0], color: uniform, roughness: 0.9, parent: manager)
        box([0.36, 0.55, 0.26], at: [0, 0.3, 0], color: Self.color(0.1, 0.1, 0.12), parent: manager)
        let head = ModelEntity(mesh: .generateSphere(radius: 0.14),
                               materials: [SimpleMaterial(color: Self.color(0.85, 0.7, 0.6), roughness: 0.8, isMetallic: false)])
        head.position = [0, 1.6, 0]
        manager.addChild(head)
        box([0.3, 0.1, 0.3], at: [0, 1.74, -0.02], color: Self.color(0.35, 0.3, 0.3), parent: manager)
        box([0.08, 0.05, 0.01], at: [0.12, 1.3, 0.15], color: Self.color(0.9, 0.8, 0.4), roughness: 0.3, parent: manager)
        manager.isEnabled = false
        root.addChild(manager)

        // Rui / NPC da noite
        box([0.44, 0.9, 0.28], at: [0, 1.0, 0], color: Self.color(0.25, 0.3, 0.45), roughness: 0.9, parent: npc)
        box([0.38, 0.55, 0.26], at: [0, 0.3, 0], color: Self.color(0.2, 0.22, 0.26), parent: npc)
        let head2 = ModelEntity(mesh: .generateSphere(radius: 0.145),
                                materials: [SimpleMaterial(color: Self.color(0.7, 0.55, 0.44), roughness: 0.85, isMetallic: false)])
        head2.position = [0, 1.6, 0]
        npc.addChild(head2)
        npc.isEnabled = false
        root.addChild(npc)

        // Osvaldo: silhueta escura, sempre com o rodo
        let dark = Self.color(0.015, 0.015, 0.02)
        unlitBox([0.5, 0.8, 0.25], at: [0, 1.3, 0], color: dark, parent: ghost)
        let gh = ModelEntity(mesh: .generateSphere(radius: 0.14), materials: [UnlitMaterial(color: dark)])
        gh.position = [0, 1.86, 0]
        ghost.addChild(gh)
        unlitBox([0.12, 0.16, 0.05], at: [0.28, 1.55, 0.1], color: dark, parent: ghost)
        unlitBox([0.04, 1.1, 0.04], at: [0.34, 1.15, 0.12], color: dark, parent: ghost)
        unlitBox([0.42, 0.05, 0.05], at: [0.34, 0.62, 0.12], color: dark, parent: ghost)
        ghost.isEnabled = false
        root.addChild(ghost)
    }

    func avatar(for peer: String, role: Role) -> Entity {
        if let e = peerAvatars[peer] { return e }
        let e = Entity()
        let c = role.uniformColor
        box([0.4, 0.9, 0.26], at: [0, 1.0, 0], color: Self.color(CGFloat(c.x), CGFloat(c.y), CGFloat(c.z)), parent: e)
        box([0.34, 0.55, 0.24], at: [0, 0.3, 0], color: Self.color(0.2, 0.2, 0.25), parent: e)
        let h = ModelEntity(mesh: .generateSphere(radius: 0.14),
                            materials: [SimpleMaterial(color: Self.color(0.85, 0.7, 0.6), roughness: 0.8, isMetallic: false)])
        h.position = [0, 1.6, 0]
        e.addChild(h)
        root.addChild(e)
        peerAvatars[peer] = e
        return e
    }

    // MARK: Consultas

    func canWalk(x: Float, z: Float) -> Bool {
        for r in walkRects where x >= r.0 && x <= r.1 && z >= r.2 && z <= r.3 { return true }
        return false
    }

    func area(at p: SIMD3<Float>) -> AreaID {
        var best: AreaID = .corredor7
        var bestScore = Float.greatestFiniteMagnitude
        for r in walkRects {
            if p.x >= r.0 && p.x <= r.1 && p.z >= r.2 && p.z <= r.3 { return r.4 }
            let cx = (r.0 + r.1) / 2, cz = (r.2 + r.3) / 2
            let d = abs(p.x - cx) + abs(p.z - cz)
            if d < bestScore { bestScore = d; best = r.4 }
        }
        return best
    }

    /// Acende só as luzes das áreas da noite; escurece o resto e aplica a lanterna.
    func applyLighting(night: NightSpec, hasFlashlight: Bool) {
        let active = Set(night.areas.map { Self.region($0) })
        for (area, ls) in lights {
            let on = active.contains(Self.region(area))
            for l in ls { l.isEnabled = on }
        }
        headlamp.isEnabled = hasFlashlight
    }

    func flicker(_ on: Bool, area: AreaID) {
        for l in lights[area] ?? [] { l.isEnabled = on }
    }

    // MARK: Construção da noite

    func buildNight(_ night: NightSpec, progress: CampaignProgress) throws {
        nightRoot.children.removeAll()
        surfaces.removeAll()
        interactionMarkers.removeAll()

        for (i, spec) in night.surfaces.enumerated() {
            try addSurface(index: i, spec: spec, progress: progress)
        }
        for inter in night.interactions {
            addInteractionMarker(inter)
        }
        applyLighting(night: night, hasFlashlight: progress.hasUpgrade("lanterna"))
    }

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

    private func addSurface(index: Int, spec: SurfaceSpec, progress: CampaignProgress) throws {
        let aspect = spec.width / max(spec.height, 0.01)
        let base = 168
        let w = max(96, min(288, Int(Float(base) * max(0.6, min(1.7, aspect)))))
        let h = max(96, min(288, Int(Float(base) / max(0.6, min(1.7, aspect)))))
        let seed = UInt64(abs(spec.id.hashValue % 9973))
        let mask = try DirtMask(device: device, width: w, height: h,
                                pixels: Textures.dirt(spec.dirt, width: w, height: h, seed: seed))
        let offset = Self.offset(spec.area)
        let surface = CleaningSurface(index: index, spec: spec, offset: offset, mask: mask)
        surface.wideBrush = progress.hasUpgrade("rodo-largo")

        let mesh: MeshResource = spec.isHorizontal
            ? .generatePlane(width: spec.width, depth: spec.height)
            : .generatePlane(width: spec.width, height: spec.height)

        // prova por baixo
        if let region = spec.revealRegion, spec.reveal != .nada {
            let tex = try staticTexture(Textures.reveal(spec.reveal, width: w, height: h, region: region), width: w, height: h)
            let e = ModelEntity(mesh: mesh, materials: [dirtMaterial(tex)])
            e.position = surface.origin - surface.normal * 0.002
            e.orientation = orientation(for: spec)
            nightRoot.addChild(e)
            surface.revealEntity = e
        }

        // camada de sujeira
        let dirt = ModelEntity(mesh: mesh, materials: [dirtMaterial(mask.resource)])
        dirt.position = surface.origin
        dirt.orientation = orientation(for: spec)
        nightRoot.addChild(dirt)
        surface.dirtEntity = dirt

        // ponta da ferramenta
        let tipMesh: MeshResource
        let tipColor: NSColor
        switch spec.tool {
        case .rodo:
            tipMesh = .generateBox(size: [spec.width * 0.22, 0.035, 0.03]); tipColor = Self.color(0.1, 0.1, 0.1)
        case .vassoura:
            tipMesh = .generateBox(size: [spec.width * 0.18, 0.06, 0.4]); tipColor = Self.color(0.75, 0.6, 0.3)
        case .flanela:
            tipMesh = .generateBox(size: [spec.width * 0.16, 0.02, spec.height * 0.2]); tipColor = Self.color(0.95, 0.95, 0.9)
        default:
            tipMesh = .generateBox(size: [spec.width * 0.14, 0.02, spec.height * 0.22]); tipColor = Self.color(0.95, 0.9, 0.5)
        }
        let tip = ModelEntity(mesh: tipMesh, materials: [SimpleMaterial(color: tipColor, roughness: 0.6, isMetallic: false)])
        tip.isEnabled = false
        nightRoot.addChild(tip)
        surface.toolTip = tip
        surfaces.append(surface)
    }

    private func orientation(for spec: SurfaceSpec) -> simd_quatf {
        if spec.isHorizontal { return simd_quatf(angle: 0, axis: [0, 1, 0]) }
        // plano vertical: o normal padrão é +z, gira para bater com right/up
        let n = simd_normalize(simd_cross(simd_normalize(spec.right), simd_normalize(spec.up)))
        return simd_quaternion(SIMD3<Float>(0, 0, 1), n)
    }

    private func addInteractionMarker(_ spec: InteractionSpec) {
        let e = Entity()
        e.position = spec.position + Self.offset(spec.area)
        nightRoot.addChild(e)
        interactionMarkers[spec.id] = e
        if spec.kind == .examinar {
            // objeto examinável: uma caixinha discreta
            box([0.28, 0.12, 0.2], at: [0, 0, 0], color: Self.color(0.2, 0.2, 0.22), roughness: 0.5, parent: e)
            box([0.06, 0.05, 0.05], at: [0.1, 0.08, 0], color: Self.color(0.7, 0.2, 0.2), parent: e)
        }
    }

    func flushSurfaces() {
        for s in surfaces { s.mask.flush(queue: commandQueue) }
    }
}
