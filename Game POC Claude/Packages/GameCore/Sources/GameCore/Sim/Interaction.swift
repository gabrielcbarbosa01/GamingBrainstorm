import Foundation

/// O que a tecla de acao faria agora. A UI le isto para montar o prompt.
public enum InteractionTarget: Sendable, Equatable {
    case liftCow(CowID, CowSize, name: String, hasBell: Bool)
    case takeLantern
    case takeHay(Int)
    case gate(Int, isOpen: Bool)
    case dropCow(CowID, name: String)
    case dropHay
    case dropLantern
}

extension World {
    /// Alvo de interacao do jogador, ou nil se nao ha nada ao alcance.
    public func interaction(for pid: PlayerID) -> InteractionTarget? {
        guard let p = players[pid], p.canAct else { return nil }

        switch p.hands {
        case .cow(let cid):
            return .dropCow(cid, name: cows[cid]?.name ?? "vaca")
        case .hay:
            return .dropHay
        case .lantern, .empty:
            break
        }

        guard let pick = nearestPickup(for: p) else {
            return p.hands == .lantern ? .dropLantern : nil
        }
        switch pick {
        case .cow(let cid):
            guard let c = cows[cid] else { return nil }
            return .liftCow(cid, c.size, name: c.name, hasBell: c.hasBell)
        case .lantern: return .takeLantern
        case .hay(let h): return .takeHay(h)
        case .gate(let i): return .gate(i, isOpen: farm.fences[i].isOpen)
        }
    }

    /// True se o jogador esta perto o bastante da Alavanca de Subida.
    public func canReachLever(_ pid: PlayerID) -> Bool {
        guard let p = players[pid], p.canAct else { return false }
        return planarDistance(p.position, farm.leverPosition) < 2.6
    }
}

extension World {
    /// Apenas para depuracao e capturas de tela.
    public func debugTeleport(_ id: PlayerID, to point: Vec3, aim: Float = 0) {
        mutate(id) { p in
            p.position = point
            p.yaw = aim
            p.aimYaw = aim
        }
    }
}

extension World {
    /// Apenas para depuracao: forca a direcao de todas as vacas.
    public func debugSetAllHeadings(_ yaw: Float) {
        for c in Array(cows.values) { mutate(c.id) { $0.heading = yaw } }
    }
}

extension World {
    /// Apenas para depuracao: reposiciona uma vaca.
    public func debugMoveCow(_ id: CowID, to point: Vec3) {
        mutate(id) { cow in
            cow.position = point
            cow.wanderTarget = point
            cow.velocity = .zero
            cow.behavior = .dormindo
            cow.alarm = 0
        }
    }
}
