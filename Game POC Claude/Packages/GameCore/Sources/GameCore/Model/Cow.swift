import Foundation
import simd

public struct CowID: Hashable, Codable, Sendable {
    public let raw: Int
    public init(_ raw: Int) { self.raw = raw }
}

public enum CowBehavior: String, Sendable {
    case dormindo      // parada em pe, estado inicial da noite
    case pastando      // caminha para um alvo proximo
    case alerta        // ouviu algo, olha na direcao
    case panico        // foge da fonte de barulho
    case carregada     // no colo de um ou mais jogadores
    case subindo       // dentro do feixe
    case extraida      // ja esta na nave
}

public struct Cow: Identifiable, Sendable {
    public let id: CowID
    public var name: String
    public var size: CowSize
    public var adornments: Set<Adornment>

    public var position: Vec3
    public var heading: Float
    public var velocity: Vec3

    public var behavior: CowBehavior
    public var behaviorTimer: Float
    public var wanderTarget: Vec3
    /// 0...1 — o quanto este individuo esta agitado.
    public var alarm: Float

    public var carriers: [PlayerID]
    public var liftProgress: Float
    public var beamProgress: Float
    public var struggleTimer: Float
    /// De onde ela esta fugindo.
    public var fleeFrom: Vec3
    /// Marca visual: usa o modelo alternativo (easter egg, sem efeito mecanico).
    public var isCurio: Bool

    public init(id: CowID, name: String, size: CowSize, adornments: Set<Adornment> = [],
                position: Vec3, heading: Float = 0, isCurio: Bool = false) {
        self.id = id
        self.name = name
        self.size = size
        self.adornments = adornments
        self.position = position
        self.heading = heading
        self.velocity = .zero
        self.behavior = .dormindo
        self.behaviorTimer = 0
        self.wanderTarget = position
        self.alarm = 0
        self.carriers = []
        self.liftProgress = 0
        self.beamProgress = 0
        self.struggleTimer = 0
        self.fleeFrom = position
        self.isCurio = isCurio
    }

    public var hasBell: Bool { adornments.contains(.sino) }
    public var isCarried: Bool { !carriers.isEmpty }
    public var isOnGround: Bool { behavior != .carregada && behavior != .extraida }
    public var isAwake: Bool { behavior != .dormindo && behavior != .extraida }
    public var isPanicking: Bool { behavior == .panico }

    /// Bloco 5: valor = base x (1 + 0,25 x adornos).
    public var value: Int {
        Int(Float(size.baseValue) * (1 + 0.25 * Float(adornments.count)))
    }

    public var carryFactor: Float { size.carryFactor(handlers: carriers.count) }
}
