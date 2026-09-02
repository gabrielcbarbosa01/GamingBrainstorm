import Foundation
import simd

public struct MudPatch: Sendable {
    public var center: Vec3
    public var radius: Float
}

/// Cerca e porteira sao o mesmo objeto: a porteira e um segmento que abre.
public struct FenceSegment: Sendable {
    public var a: Vec2
    public var b: Vec2
    public var isGate: Bool
    public var isOpen: Bool

    public init(_ a: Vec2, _ b: Vec2, isGate: Bool = false) {
        self.a = a
        self.b = b
        self.isGate = isGate
        self.isOpen = false
    }

    public var blocks: Bool { !(isGate && isOpen) }
    public var midpoint: Vec2 { (a + b) * 0.5 }
}

public struct HayBale: Sendable {
    public var id: Int
    public var position: Vec3
    public var carriedBy: PlayerID?
}

public struct Farm: Sendable {
    public var bounds: Float = 46
    public var mud: [MudPatch] = []
    public var fences: [FenceSegment] = []
    public var hay: [HayBale] = []
    public var shipAnchor: Vec3 = .zero
    public var lanternSpawn: Vec3 = .zero
    public var leverPosition: Vec3 = .zero

    public func isInMud(_ p: Vec3) -> Bool {
        for m in mud where planarDistance(p, m.center) < m.radius { return true }
        return false
    }

    /// Empurra um circulo para fora de qualquer cerca que bloqueia.
    public func resolveFences(_ position: Vec3, radius: Float) -> Vec3 {
        var p = Vec2(position.x, position.z)
        for f in fences where f.blocks {
            let c = closestPointOnSegment(p, f.a, f.b)
            let d = p - c
            let dist = simd_length(d)
            let minDist = radius + 0.12
            if dist < minDist {
                let n = dist > 1e-4 ? d / dist : Vec2(0, 1)
                p = c + n * minDist
            }
        }
        let b = bounds
        p.x = clampf(p.x, -b, b)
        p.y = clampf(p.y, -b, b)
        return Vec3(p.x, position.y, p.y)
    }

    /// Fazenda do MVP: um pasto, um lamacal, uma cerca com uma porteira.
    public static func mvp() -> Farm {
        var farm = Farm()
        farm.shipAnchor = Vec3(0, 0, 0)
        farm.leverPosition = Vec3(6.5, 0, 1.5)
        farm.lanternSpawn = Vec3(-2.5, 0, 2.0)

        // Cerca principal separando o pasto da area da nave, com uma porteira.
        let z: Float = -17
        farm.fences = [
            FenceSegment(Vec2(-32, z), Vec2(2.5, z)),
            FenceSegment(Vec2(2.5, z), Vec2(6.5, z), isGate: true),
            FenceSegment(Vec2(6.5, z), Vec2(32, z)),
            // Corral lateral: obriga a contornar.
            FenceSegment(Vec2(-32, z), Vec2(-32, -42)),
            FenceSegment(Vec2(32, z), Vec2(32, -42)),
            FenceSegment(Vec2(-14, -30), Vec2(-14, -42)),
            FenceSegment(Vec2(-14, -30), Vec2(-4, -30))
        ]

        // Lamacal no caminho entre a porteira e o feixe — obstaculo, nao parede:
        // da para contornar, e atravessar carregando custa tempo e uma queda provavel.
        farm.mud = [
            MudPatch(center: Vec3(4.0, 0, -11), radius: 3.2),
            MudPatch(center: Vec3(-1.5, 0, -7), radius: 2.6),
            MudPatch(center: Vec3(-9, 0, -14), radius: 3.0)
        ]

        farm.hay = [
            HayBale(id: 0, position: Vec3(-20, 0, -24), carriedBy: nil),
            HayBale(id: 1, position: Vec3(-21.5, 0, -26), carriedBy: nil),
            HayBale(id: 2, position: Vec3(14, 0, -33), carriedBy: nil)
        ]
        return farm
    }
}

public struct ExpeditionSummary: Sendable {
    public var extracted: [(name: String, size: CowSize, value: Int)]
    public var duration: Float
    public var maxVigilia: Int
    public var totalValue: Int { extracted.reduce(0) { $0 + $1.value } }
}

public enum WorldEvent: Sendable {
    case cowLifted(CowID)
    case cowDropped(CowID)
    case cowExtracted(CowID)
    case cowPanicked(CowID)
    case lanternPicked
    case lanternDropped
    case hayPicked(Int)
    case hayDropped(Int)
    case gateToggled(index: Int, open: Bool)
    case playerKnocked(PlayerID)
    case playerSlipped(PlayerID)
    case stampede(vigilia: Int)
    case leverPulled
    case leverAborted
    case expeditionEnded(ExpeditionSummary)
}
