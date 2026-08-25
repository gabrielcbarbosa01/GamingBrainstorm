//
//  Biome.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation
import SwiftUI

public enum BiomeType: String, CaseIterable, Identifiable, Codable, Sendable {
    case amazonia = "Amazônia"
    case cerrado = "Cerrado"
    case pantanal = "Pantanal"
    case mataAtlantica = "Mata Atlântica"
    case caatinga = "Caatinga"
    case pampa = "Pampa"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .amazonia:
            return "Maior floresta tropical do planeta, rica em rios sinuosos e copa densa."
        case .cerrado:
            return "Savana brasileira com árvores retorcidas, gramíneas e grande biodiversidade."
        case .pantanal:
            return "Maior planície inundável do mundo, com rica vida aquática e aves exuberantes."
        case .mataAtlantica:
            return "Floresta litorânea de encosta, com alta densidade de espécies endêmicas."
        case .caatinga:
            return "Bioma semiárido exclusivo do Brasil, com cactos e vegetação adaptada à seca."
        case .pampa:
            return "Campos sulistas planos e suaves, com rica fauna campestre."
        }
    }
    
    public var primaryColor: Color {
        switch self {
        case .amazonia: return Color.green
        case .cerrado: return Color.orange
        case .pantanal: return Color.teal
        case .mataAtlantica: return Color.mint
        case .caatinga: return Color.yellow
        case .pampa: return Color.brown
        }
    }
    
    public var iconName: String {
        switch self {
        case .amazonia: return "leaf.fill"
        case .cerrado: return "sun.max.fill"
        case .pantanal: return "water.waves"
        case .mataAtlantica: return "tree.fill"
        case .caatinga: return "sun.dust.fill"
        case .pampa: return "wind"
        }
    }
    
    public var typicalHazards: [String] {
        switch self {
        case .amazonia: return ["Inundações repentinas", "Desmatamento ilegal"]
        case .cerrado: return ["Queimadas sazonais", "Perda de vegetação nativa"]
        case .pantanal: return ["Seca extrema", "Incêndios florestais"]
        case .mataAtlantica: return ["Fragmentação de habitat", "Caça ilegal"]
        case .caatinga: return ["Escassez hídrica severa", "Desertificação"]
        case .pampa: return ["Monoculturas agressivas", "Erosão do solo"]
        }
    }
}
