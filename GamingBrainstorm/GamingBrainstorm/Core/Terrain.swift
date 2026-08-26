//
//  Terrain.swift
//  Guardiões dos Biomas
//
//  O mundo é uma grade de tiles. A passabilidade depende da forma animal
//  atual do jogador — é isso que transforma cada amuleto numa chave de mapa.
//

import SpriteKit

enum Terrain: UInt8, Codable {
    // --- chão livre ---
    case grama
    case gramaAlta      // desacelera um pouco, esconde coletáveis
    case terra
    case areia
    case pedraChao
    case trilha         // caminho batido: mais rápido
    case charco         // lama rasa: mais lento
    case folhagem       // serapilheira de floresta

    // --- bloqueios absolutos ---
    case rocha
    case tronco

    // --- bloqueios que um amuleto abre ---
    case cipos          // Mico-leão-dourado
    case espinheiro     // Lobo-guará
    case matagalDenso   // Onça-pintada
    case abismo         // Ararinha-azul
    case agua           // Pirarucu
    case terraDura      // Tuco-tuco

    /// Verdadeiro para terrenos que qualquer forma atravessa.
    var livre: Bool {
        switch self {
        case .grama, .gramaAlta, .terra, .areia, .pedraChao, .trilha, .charco, .folhagem:
            return true
        default:
            return false
        }
    }

    /// Bloqueio permanente, nenhum amuleto abre.
    var intransponivel: Bool { self == .rocha || self == .tronco }

    /// A forma que destrava este terreno, se houver.
    var formaNecessaria: AnimalForm? {
        switch self {
        case .cipos: return .micoLeaoDourado
        case .espinheiro: return .loboGuara
        case .matagalDenso: return .oncaPintada
        case .abismo: return .araraAzul
        case .agua: return .pirarucu
        case .terraDura: return .tucoTuco
        default: return nil
        }
    }

    /// Nome curto usado nas dicas de "você ainda não consegue passar aqui".
    var nome: String {
        switch self {
        case .grama: return "campo"
        case .gramaAlta: return "capim alto"
        case .terra: return "solo"
        case .areia: return "areia"
        case .pedraChao: return "laje"
        case .trilha: return "trilha"
        case .charco: return "charco"
        case .folhagem: return "serapilheira"
        case .rocha: return "paredão de rocha"
        case .tronco: return "tronco caído"
        case .cipos: return "cipoal fechado"
        case .espinheiro: return "espinheiro"
        case .matagalDenso: return "matagal denso"
        case .abismo: return "abismo"
        case .agua: return "água funda"
        case .terraDura: return "terra compactada"
        }
    }

    /// Multiplicador de velocidade ao andar sobre o tile.
    func fatorVelocidade(para forma: AnimalForm) -> CGFloat {
        switch self {
        case .trilha: return 1.18
        case .gramaAlta: return 0.86
        case .charco: return forma == .pirarucu ? 1.15 : 0.68
        case .agua: return forma == .pirarucu ? 1.35 : 1.0
        case .terraDura: return forma == .tucoTuco ? 1.1 : 1.0
        case .areia: return 0.92
        default: return 1.0
        }
    }

    /// O jogador pode ocupar este tile com a forma indicada?
    func passavel(para forma: AnimalForm) -> Bool {
        // A harpia voa: nenhuma barreira do mundo se aplica a ela.
        if forma.atravessaTudo { return true }
        if livre {
            // O pirarucu se arrasta fora d'água, mas ainda consegue andar.
            return true
        }
        if intransponivel { return false }
        return formaNecessaria == forma
    }
}

/// Coordenada inteira na grade do mundo.
struct GridPoint: Hashable, Codable {
    var x: Int
    var y: Int

    static func + (a: GridPoint, b: GridPoint) -> GridPoint {
        GridPoint(x: a.x + b.x, y: a.y + b.y)
    }
}

enum WorldMetrics {
    /// Lado de um tile em pontos.
    static let tileSize: CGFloat = 44
    /// Tiles por lado de chunk. O mundo é gerado e descartado em chunks.
    static let chunkTiles: Int = 16
    static var chunkSize: CGFloat { tileSize * CGFloat(chunkTiles) }

    static func tile(at position: CGPoint) -> GridPoint {
        GridPoint(x: Int(floor(position.x / tileSize)),
                  y: Int(floor(position.y / tileSize)))
    }

    static func center(of tile: GridPoint) -> CGPoint {
        CGPoint(x: (CGFloat(tile.x) + 0.5) * tileSize,
                y: (CGFloat(tile.y) + 0.5) * tileSize)
    }

    static func chunk(containing tile: GridPoint) -> GridPoint {
        GridPoint(x: Int(floor(Double(tile.x) / Double(chunkTiles))),
                  y: Int(floor(Double(tile.y) / Double(chunkTiles))))
    }
}
