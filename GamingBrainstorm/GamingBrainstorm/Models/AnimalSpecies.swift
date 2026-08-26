//
//  AnimalSpecies.swift
//  GamingBrainstorm
//
//  Created by Gabriel Barbosa on 25/08/26.
//

import Foundation

public enum ConservationStatus: String, CaseIterable, Codable, Sendable {
    case vulnerable = "Vulnerável (VU)"
    case endangered = "Em Perigo (EN)"
    case criticallyEndangered = "Criticamente Ameaçado (CR)"
    
    public var badgeColor: String {
        switch self {
        case .vulnerable: return "yellow"
        case .endangered: return "orange"
        case .criticallyEndangered: return "red"
        }
    }
}

public enum DietType: String, CaseIterable, Codable, Sendable {
    case frugivore = "Frutas e Néctar"
    case carnivore = "Carnívoro / Peixes"
    case insectivore = "Insetos e Formigas"
    case herbivore = "Folhas e Raízes"
    case omnivore = "Onívoro / Frutos Silvestres"
    
    public var iconName: String {
        switch self {
        case .frugivore: return "apple.logo"
        case .carnivore: return "fish.fill"
        case .insectivore: return "ant.fill"
        case .herbivore: return "leaf.fill"
        case .omnivore: return "fork.knife"
        }
    }
}

public struct AnimalSpecies: Identifiable, Codable, Sendable, Equatable, Hashable {
    public let id: String
    public let commonName: String
    public let scientificName: String
    public let nativeBiome: BiomeType
    public let status: ConservationStatus
    public let diet: DietType
    public let habitatNeeds: String
    public let transformationPerk: String
    public let transformationDescription: String
    public let avatarSymbol: String
    public let funFact: String
    
    public static let allSpecies: [AnimalSpecies] = [
        AnimalSpecies(
            id: "mico-leao-dourado",
            commonName: "Mico-Leão-Dourado",
            scientificName: "Leontopithecus rosalia",
            nativeBiome: .mataAtlantica,
            status: .endangered,
            diet: .frugivore,
            habitatNeeds: "Dossel florestal contínuo com bromélias e ocos de árvores.",
            transformationPerk: "Escalada Ágil",
            transformationDescription: "Permite escalar árvores altas, alcançar copas e atravessar fendas no relevo.",
            avatarSymbol: "sparkles",
            funFact: "Símbolo da conservação no Brasil, habita exclusivamente fragmentos da Mata Atlântica no Rio de Janeiro."
        ),
        AnimalSpecies(
            id: "lobo-guara",
            commonName: "Lobo-Guará",
            scientificName: "Chrysocyon brachyurus",
            nativeBiome: .cerrado,
            status: .vulnerable,
            diet: .omnivore,
            habitatNeeds: "Campos abertos e vegetação campestre com lobeiras.",
            transformationPerk: "Faro Rastreador",
            transformationDescription: "Detecta pistas ecológicas ocultas, cheiros e sons de animais distantes.",
            avatarSymbol: "eye.fill",
            funFact: "O maior canídeo da América do Sul; adora o fruto da lobeira, que ajuda na dispersão de sementes."
        ),
        AnimalSpecies(
            id: "tatu-bola",
            commonName: "Tatu-Bola-do-Nordeste",
            scientificName: "Tolypeutes tricinctus",
            nativeBiome: .caatinga,
            status: .endangered,
            diet: .insectivore,
            habitatNeeds: "Solo seco, folhiço e arbustos espinhosos.",
            transformationPerk: "Casco Blindado & Rolamento",
            transformationDescription: "Fecha-se em esfera para atravessar terrenos pontiagudos e escavar barreiras terrosas.",
            avatarSymbol: "shield.fill",
            funFact: "É a única espécie de tatu capaz de se fechar 100% como uma bola para se defender."
        ),
        AnimalSpecies(
            id: "onca-pintada",
            commonName: "Onça-Pintada",
            scientificName: "Panthera onca",
            nativeBiome: .pantanal,
            status: .vulnerable,
            diet: .carnivore,
            habitatNeeds: "Matas ciliares densas e corpos d'água abundantes.",
            transformationPerk: "Passo Furtivo",
            transformationDescription: "Caminha sem emitir ruído e pode afastar predadores invasores ou caçadores.",
            avatarSymbol: "bolt.fill",
            funFact: "Possui a mordida mais potente entre todos os grandes felinos em relação ao seu tamanho."
        ),
        AnimalSpecies(
            id: "ariranha",
            commonName: "Ariranha",
            scientificName: "Pteronura brasiliensis",
            nativeBiome: .amazonia,
            status: .endangered,
            diet: .carnivore,
            habitatNeeds: "Rios limpos de correnteza suave com margens arborizadas.",
            transformationPerk: "Nado Veloz",
            transformationDescription: "Permite mergulhar e navegar por rios caudalosos e canais alagados.",
            avatarSymbol: "drop.fill",
            funFact: "Conhecida como a 'onça-d'água', é a maior lontra do mundo e vive em grupos sociais barulhentos."
        ),
        AnimalSpecies(
            id: "tamandua-bandeira",
            commonName: "Tamanduá-Bandeira",
            scientificName: "Myrmecophaga tridactyla",
            nativeBiome: .pampa,
            status: .vulnerable,
            diet: .insectivore,
            habitatNeeds: "Campos abertos com cupinzeiros e capões de mata.",
            transformationPerk: "Garras Rompedoras",
            transformationDescription: "Quebra cupinzeiros petrificados e remove troncos caídos bloqueando passagens.",
            avatarSymbol: "hand.raised.fill",
            funFact: "Sua língua pode medir até 60 cm de comprimento e não possui dentes!"
        )
    ]
}
