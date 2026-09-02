import Foundation
import simd

public struct PlayerID: Hashable, Codable, Sendable {
    public let raw: Int
    public init(_ raw: Int) { self.raw = raw }
}

/// Bloco 1 (decidido): quem carrega uma vaca nao carrega a lanterna.
public enum Hands: Equatable, Sendable {
    case empty
    case lantern
    case cow(CowID)
    case hay(Int)

    public var isCarryingCow: Bool { if case .cow = self { return true }; return false }
    public var cowID: CowID? { if case .cow(let id) = self { return id }; return nil }
    public var hayID: Int? { if case .hay(let id) = self { return id }; return nil }
    public var isEmpty: Bool { self == .empty }
}

public struct Player: Identifiable, Sendable {
    public let id: PlayerID
    public var position: Vec3
    /// Angulo do corpo. Segue a camera com atraso.
    public var yaw: Float
    /// Angulo para onde a camera aponta (vem do mouse).
    public var aimYaw: Float
    public var velocity: Vec3

    public var hands: Hands
    public var lanternOn: Bool

    public var wantsSprint: Bool
    public var wantsCrouch: Bool
    public var isDown: Bool
    public var downTimer: Float
    /// Tempo restante de tropeco (nao anda, nao pega nada).
    public var stumbleTimer: Float
    /// Progresso de erguer a vaca que esta sendo pega.
    public var liftingCow: CowID?
    public var liftTimer: Float

    public init(id: PlayerID, position: Vec3) {
        self.id = id
        self.position = position
        self.yaw = 0
        self.aimYaw = 0
        self.velocity = .zero
        self.hands = .empty
        self.lanternOn = true
        self.wantsSprint = false
        self.wantsCrouch = false
        self.isDown = false
        self.downTimer = 0
        self.stumbleTimer = 0
        self.liftingCow = nil
        self.liftTimer = 0
    }

    public var canAct: Bool { !isDown && stumbleTimer <= 0 && liftingCow == nil }
    public var hasLanternLit: Bool { hands == .lantern && lanternOn && !isDown }
    public var forward: Vec3 { Vec3(sin(yaw), 0, cos(yaw)) }
    public var aimForward: Vec3 { Vec3(sin(aimYaw), 0, cos(aimYaw)) }
}

/// Comando de movimento de um frame. Bloco 10: e isto que vai pela rede.
public struct PlayerInput: Sendable, Equatable {
    /// x = direita, y = frente. Ja normalizado.
    public var move: Vec2
    /// Yaw absoluto da camera.
    public var aimYaw: Float
    public var sprint: Bool
    public var crouch: Bool

    public init(move: Vec2 = .zero, aimYaw: Float = 0, sprint: Bool = false, crouch: Bool = false) {
        self.move = move
        self.aimYaw = aimYaw
        self.sprint = sprint
        self.crouch = crouch
    }

    public static let idle = PlayerInput()
}

public enum PlayerAction: Sendable, Equatable {
    /// Pegar/soltar o que estiver ao alcance. Um verbo, uma tecla.
    case interact
    case toggleLantern
    case pullLever
}
