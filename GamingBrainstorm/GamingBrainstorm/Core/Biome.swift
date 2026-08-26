//
//  Biome.swift
//  Guardiões dos Biomas
//
//  Definição dos sete territórios do jogo: o Refúgio (centro seguro) e os
//  seis biomas brasileiros, cada um com um animal ameaçado e um amuleto.
//

import SpriteKit

enum BiomeID: String, CaseIterable, Codable, Identifiable {
    case refugio
    case mataAtlantica
    case cerrado
    case pantanal
    case caatinga
    case amazonia
    case pampa

    var id: String { rawValue }

    /// Os seis biomas exploráveis, na ordem da história.
    static var exploraveis: [BiomeID] {
        [.mataAtlantica, .cerrado, .pantanal, .caatinga, .amazonia, .pampa]
    }
}

/// Regras de geração procedural de um bioma.
struct BiomeTerrainRules {
    var escalaRelevo: Double        // frequência do ruído principal
    var limiarAgua: Double          // abaixo disso vira água
    var limiarCharco: Double
    var densidadeArvore: Double
    var densidadeRocha: Double
    var densidadeGramaAlta: Double
    var densidadeEspecial: Double   // frequência do terreno-chave do bioma
    var terrenoEspecial: Terrain    // barreira que exige amuleto
    var terrenoEspecialSecundario: Terrain
    var chaoBase: Terrain
    var chaoAlternativo: Terrain
}

struct Biome: Identifiable {
    let id: BiomeID
    let nome: String
    let subtitulo: String
    let regiao: String
    let animal: AnimalForm
    let palette: BiomePalette
    let rules: BiomeTerrainRules
    let ameaca: HazardKind
    let ordem: Int
    /// Amuleto necessário para atravessar o portal até aqui.
    let requisito: AnimalForm?
    let semente: UInt64

    static let todos: [BiomeID: Biome] = {
        var m: [BiomeID: Biome] = [:]
        for b in lista { m[b.id] = b }
        return m
    }()

    static subscript(id: BiomeID) -> Biome { todos[id]! }

    static let lista: [Biome] = [
        Biome(id: .refugio,
              nome: "Refúgio Raízes",
              subtitulo: "Estação de campo dos Guardiões",
              regiao: "Serra do Mar, entre biomas",
              animal: .humano,
              palette: Palette.refugio,
              rules: BiomeTerrainRules(escalaRelevo: 0.045, limiarAgua: -0.72, limiarCharco: -0.55,
                                       densidadeArvore: 0.05, densidadeRocha: 0.02,
                                       densidadeGramaAlta: 0.06, densidadeEspecial: 0.0,
                                       terrenoEspecial: .cipos, terrenoEspecialSecundario: .terraDura,
                                       chaoBase: .grama, chaoAlternativo: .trilha),
              ameaca: .nenhuma,
              ordem: 0,
              requisito: nil,
              semente: 1001),

        Biome(id: .mataAtlantica,
              nome: "Mata Atlântica",
              subtitulo: "Onde o dourado ainda salta entre as copas",
              regiao: "Baixadas do Rio de Janeiro",
              animal: .micoLeaoDourado,
              palette: Palette.mataAtlantica,
              rules: BiomeTerrainRules(escalaRelevo: 0.055, limiarAgua: -0.60, limiarCharco: -0.48,
                                       densidadeArvore: 0.20, densidadeRocha: 0.05,
                                       densidadeGramaAlta: 0.13, densidadeEspecial: 0.14,
                                       terrenoEspecial: .cipos, terrenoEspecialSecundario: .agua,
                                       chaoBase: .folhagem, chaoAlternativo: .grama),
              ameaca: .desmatamento,
              ordem: 1,
              requisito: nil,
              semente: 2211),

        Biome(id: .cerrado,
              nome: "Cerrado",
              subtitulo: "O berço das águas e das pernas longas",
              regiao: "Chapadas de Goiás e Minas",
              animal: .loboGuara,
              palette: Palette.cerrado,
              rules: BiomeTerrainRules(escalaRelevo: 0.038, limiarAgua: -0.74, limiarCharco: -0.62,
                                       densidadeArvore: 0.09, densidadeRocha: 0.07,
                                       densidadeGramaAlta: 0.22, densidadeEspecial: 0.11,
                                       terrenoEspecial: .espinheiro, terrenoEspecialSecundario: .cipos,
                                       chaoBase: .terra, chaoAlternativo: .grama),
              ameaca: .queimada,
              ordem: 2,
              requisito: .micoLeaoDourado,
              semente: 3317),

        Biome(id: .pantanal,
              nome: "Pantanal",
              subtitulo: "Planície que respira com a cheia",
              regiao: "Mato Grosso do Sul",
              animal: .oncaPintada,
              palette: Palette.pantanal,
              rules: BiomeTerrainRules(escalaRelevo: 0.032, limiarAgua: -0.34, limiarCharco: -0.06,
                                       densidadeArvore: 0.12, densidadeRocha: 0.03,
                                       densidadeGramaAlta: 0.16, densidadeEspecial: 0.10,
                                       terrenoEspecial: .matagalDenso, terrenoEspecialSecundario: .espinheiro,
                                       chaoBase: .grama, chaoAlternativo: .areia),
              ameaca: .conflitoRebanho,
              ordem: 3,
              requisito: .loboGuara,
              semente: 4423),

        Biome(id: .caatinga,
              nome: "Caatinga",
              subtitulo: "Onde a seca vira paisagem viva",
              regiao: "Norte da Bahia, vale do São Francisco",
              animal: .araraAzul,
              palette: Palette.caatinga,
              rules: BiomeTerrainRules(escalaRelevo: 0.042, limiarAgua: -0.82, limiarCharco: -0.70,
                                       densidadeArvore: 0.06, densidadeRocha: 0.10,
                                       densidadeGramaAlta: 0.05, densidadeEspecial: 0.10,
                                       terrenoEspecial: .abismo, terrenoEspecialSecundario: .terraDura,
                                       chaoBase: .terra, chaoAlternativo: .areia),
              ameaca: .trafico,
              ordem: 4,
              requisito: .oncaPintada,
              semente: 7759),

        Biome(id: .amazonia,
              nome: "Amazônia",
              subtitulo: "Rios que são estradas, floresta que é oceano",
              regiao: "Médio Solimões",
              animal: .pirarucu,
              palette: Palette.amazonia,
              rules: BiomeTerrainRules(escalaRelevo: 0.030, limiarAgua: -0.30, limiarCharco: -0.16,
                                       densidadeArvore: 0.24, densidadeRocha: 0.02,
                                       densidadeGramaAlta: 0.10, densidadeEspecial: 0.12,
                                       terrenoEspecial: .agua, terrenoEspecialSecundario: .abismo,
                                       chaoBase: .folhagem, chaoAlternativo: .charco),
              ameaca: .pescaIlegal,
              ordem: 5,
              requisito: .araraAzul,
              semente: 5531),

        Biome(id: .pampa,
              nome: "Pampa",
              subtitulo: "Campo aberto, vida escondida sob o chão",
              regiao: "Litoral do Rio Grande do Sul",
              animal: .tucoTuco,
              palette: Palette.pampa,
              rules: BiomeTerrainRules(escalaRelevo: 0.028, limiarAgua: -0.66, limiarCharco: -0.52,
                                       densidadeArvore: 0.04, densidadeRocha: 0.05,
                                       densidadeGramaAlta: 0.26, densidadeEspecial: 0.13,
                                       terrenoEspecial: .terraDura, terrenoEspecialSecundario: .agua,
                                       chaoBase: .grama, chaoAlternativo: .areia),
              ameaca: .monocultura,
              ordem: 6,
              requisito: .pirarucu,
              semente: 6647)
    ]
}

/// A pressão real que ameaça cada bioma, virada em obstáculo de jogo.
enum HazardKind: String, Codable {
    case nenhuma
    case desmatamento    // motosserras avançando sobre a mata
    case queimada        // fogo que se alastra pelo capim
    case conflitoRebanho // queimada de pasto e retaliação contra predador
    case trafico         // traficantes de animais patrulhando ninhos
    case pescaIlegal     // redes de malha fina no rio
    case monocultura     // maquinário revirando o campo

    var nome: String {
        switch self {
        case .nenhuma: return "—"
        case .desmatamento: return "Frente de desmatamento"
        case .queimada: return "Queimada"
        case .conflitoRebanho: return "Conflito com o gado"
        case .trafico: return "Tráfico de animais"
        case .pescaIlegal: return "Pesca predatória"
        case .monocultura: return "Avanço da monocultura"
        }
    }

    var descricao: String {
        switch self {
        case .nenhuma: return "Território protegido."
        case .desmatamento: return "Equipes derrubam árvores e isolam os grupos de micos em fragmentos."
        case .queimada: return "O fogo corre pelo capim seco e fecha os corredores do lobo-guará."
        case .conflitoRebanho: return "Queimadas de pastagem empurram a onça para perto do gado, e o conflito vira sentença de morte para a fera."
        case .trafico: return "Ninhos de ararinha são saqueados para o comércio ilegal."
        case .pescaIlegal: return "Redes de malha fina levam pirarucus jovens antes da desova."
        case .monocultura: return "O arado destrói as galerias do tuco-tuco nas dunas."
        }
    }

    var icone: String {
        switch self {
        case .nenhuma: return "leaf.fill"
        case .desmatamento: return "hammer.fill"
        case .queimada: return "flame.fill"
        case .conflitoRebanho: return "smoke.fill"
        case .trafico: return "shippingbox.fill"
        case .pescaIlegal: return "net"
        case .monocultura: return "gearshape.2.fill"
        }
    }
}
