import Foundation

/// Bloco 1 (decidido): existe um unico modelo base de vaca.
/// Toda variacao vem de escala, atributos e adornos.
public enum CowSize: String, Codable, CaseIterable, Sendable, Comparable {
    case bezerro, novilha, adulta, matrona, colossal

    public var displayName: String {
        switch self {
        case .bezerro: return "Bezerro"
        case .novilha: return "Novilha"
        case .adulta: return "Adulta"
        case .matrona: return "Matrona"
        case .colossal: return "Colossal"
        }
    }

    /// Escala aplicada a malha base. Um bezerro e literalmente uma vaca minuscula.
    public var modelScale: Float {
        switch self {
        case .bezerro: return 0.55
        case .novilha: return 0.80
        case .adulta: return 1.00
        case .matrona: return 1.35
        case .colossal: return 1.90
        }
    }

    public var bayUnits: Int {
        switch self {
        case .bezerro: return 1
        case .novilha: return 2
        case .adulta: return 3
        case .matrona: return 4
        case .colossal: return 6
        }
    }

    public var baseValue: Int {
        switch self {
        case .bezerro: return 45
        case .novilha: return 95
        case .adulta: return 170
        case .matrona: return 320
        case .colossal: return 640
        }
    }

    /// Fator de velocidade carregando sozinho. Nunca e zero: solo sempre e possivel.
    public var soloCarryFactor: Float {
        switch self {
        case .bezerro: return 0.85
        case .novilha: return 0.65
        case .adulta: return 0.45
        case .matrona: return 0.26
        case .colossal: return 0.14
        }
    }

    /// Fator de velocidade carregando em dupla.
    public var pairCarryFactor: Float {
        switch self {
        case .bezerro: return 0.95
        case .novilha: return 0.90
        case .adulta: return 0.78
        case .matrona: return 0.62
        case .colossal: return 0.44
        }
    }

    public func carryFactor(handlers: Int) -> Float {
        switch handlers {
        case 0, 1: return soloCarryFactor
        case 2: return pairCarryFactor
        default: return min(0.95, pairCarryFactor * 1.6)
        }
    }

    /// Matrona e Colossal nao deixam correr.
    public var allowsSprintWhileCarried: Bool { self <= .adulta }

    /// Quanto o corpo atrapalha o giro de quem carrega.
    public var carryTurnFactor: Float {
        switch self {
        case .bezerro: return 0.95
        case .novilha: return 0.85
        case .adulta: return 0.65
        case .matrona: return 0.40
        case .colossal: return 0.22
        }
    }

    /// Segundos para erguer do chao.
    public var liftTime: Float {
        switch self {
        case .bezerro: return 0.35
        case .novilha: return 0.6
        case .adulta: return 0.95
        case .matrona: return 1.4
        case .colossal: return 2.1
        }
    }

    /// Quanto ela se debate no colo (multiplicador de empurrao lateral).
    public var struggle: Float {
        switch self {
        case .bezerro: return 0.4
        case .novilha: return 0.7
        case .adulta: return 1.0
        case .matrona: return 1.5
        case .colossal: return 2.2
        }
    }

    public var bodyRadius: Float { 0.55 * modelScale }
    public var bodyHeight: Float { 1.45 * modelScale }

    public static func < (a: CowSize, b: CowSize) -> Bool {
        guard let i = allCases.firstIndex(of: a), let j = allCases.firstIndex(of: b) else { return false }
        return i < j
    }
}

/// Bloco 1 (decidido): o Conselho le adornos como insignias de patente.
public enum Adornment: String, Codable, CaseIterable, Sendable {
    case sino, brinco, coleira, faixa

    public var valueBonus: Float { 0.25 }
    /// Apenas o sino produz som durante o transporte.
    public var isNoisy: Bool { self == .sino }
}
