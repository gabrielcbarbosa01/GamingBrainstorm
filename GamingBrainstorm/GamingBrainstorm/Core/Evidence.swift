//
//  Evidence.swift
//  Guardiões dos Biomas
//
//  Vestígios concretos que substituem o marcador genérico de missão. Cada
//  evidência tem uma leitura visual própria e uma interpretação de campo.
//

import Foundation

enum EvidenceKind: String, CaseIterable {
    case pegadas
    case frutaMordida
    case peloNoGalho
    case cascaArranhada
    case fezesComSementes
    case lobeiraMordida
    case penaAzul
    case cascaDoOco
    case nozQuebrada
    case bolhasDeRespiracao
    case escama
    case ondulacao
    case monticulo
    case terraFresca
    case capimRoido

    var nome: String {
        switch self {
        case .pegadas: return "pegadas"
        case .frutaMordida: return "fruta mordida"
        case .peloNoGalho: return "pelo preso no galho"
        case .cascaArranhada: return "casca arranhada"
        case .fezesComSementes: return "fezes com sementes"
        case .lobeiraMordida: return "lobeira mordida"
        case .penaAzul: return "pena azul"
        case .cascaDoOco: return "casca do oco"
        case .nozQuebrada: return "noz quebrada"
        case .bolhasDeRespiracao: return "bolhas de respiração"
        case .escama: return "escama"
        case .ondulacao: return "ondulação recente"
        case .monticulo: return "montículo de areia"
        case .terraFresca: return "terra recém-revirada"
        case .capimRoido: return "capim roído"
        }
    }

    var leitura: String {
        switch self {
        case .pegadas: return "A direção e a distância entre as marcas revelam uma passagem recente."
        case .frutaMordida: return "As marcas pequenas de incisivos e a polpa ainda úmida indicam alimentação recente."
        case .peloNoGalho: return "Fios dourados presos na altura da copa marcam a rota do grupo."
        case .cascaArranhada: return "Sulcos paralelos na casca mostram onde o animal se apoiou para subir."
        case .fezesComSementes: return "Sementes de frutos do Cerrado revelam dieta e deslocamento."
        case .lobeiraMordida: return "A polpa arrancada e a mordida estreita são típicas do lobo-guará."
        case .penaAzul: return "Uma pena de voo íntegra indica uso frequente da árvore próxima."
        case .cascaDoOco: return "Lascas novas abaixo do oco mostram atividade recente no ninho."
        case .nozQuebrada: return "A quebra limpa e os fragmentos juntos sugerem alimentação no local."
        case .bolhasDeRespiracao: return "A sequência de bolhas marca a subida de um peixe que respira ar."
        case .escama: return "A escama grande e iridescente confirma a passagem de um pirarucu."
        case .ondulacao: return "Ondas concêntricas sem vento indicam uma subida recente à superfície."
        case .monticulo: return "A areia fofa sobre a entrada denuncia uma galeria ativa."
        case .terraFresca: return "Grãos claros e úmidos foram empurrados para fora há pouco tempo."
        case .capimRoido: return "Talos cortados rente ao chão delimitam a área de forrageio."
        }
    }

    static func kinds(for biome: BiomeID) -> [EvidenceKind] {
        switch biome {
        case .refugio: return [.pegadas, .penaAzul, .frutaMordida]
        case .mataAtlantica: return [.frutaMordida, .peloNoGalho, .cascaArranhada]
        case .cerrado: return [.pegadas, .fezesComSementes, .lobeiraMordida]
        case .pantanal: return [.penaAzul, .cascaDoOco, .nozQuebrada]
        case .amazonia: return [.bolhasDeRespiracao, .escama, .ondulacao]
        case .pampa: return [.monticulo, .terraFresca, .capimRoido]
        }
    }

    static func at(_ tile: GridPoint, biome: BiomeID) -> EvidenceKind {
        let choices = kinds(for: biome)
        let hash = Hashing.hash(tile.x, tile.y, Biome[biome].semente &+ 0xE71D)
        return choices[Int(hash % UInt64(choices.count))]
    }
}
